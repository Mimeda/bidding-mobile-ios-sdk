import Foundation
import Security
import CryptoKit

internal struct SecureStorage {

    private static let serviceName = "com.mimeda.sdk"
    private static let suiteName = "com.mimeda.sdk.storage"

    private static let accessibility: CFString = kSecAttrAccessibleWhenUnlockedThisDeviceOnly

    private static func getFromKeychain(key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess,
              let data = result as? Data,
              let decryptedString = decrypt(data: data) else {
            return nil
        }

        return decryptedString
    }

    private static func setToKeychain(key: String, value: String) -> Bool {
        guard let encryptedData = encrypt(value: value) else {
            return false
        }

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: key
        ]

        let attributes: [String: Any] = [
            kSecValueData as String: encryptedData,
            kSecAttrAccessible as String: accessibility
        ]
        
        SecItemDelete(query as CFDictionary)

        let addQuery = query.merging(attributes) { (_, new) in new }
        let status = SecItemAdd(addQuery as CFDictionary, nil)

        return status == errSecSuccess
    }

    private static func removeFromKeychain(key: String) -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: key
        ]

        let status = SecItemDelete(query as CFDictionary)
        return status == errSecSuccess || status == errSecItemNotFound
    }

    private static func clearKeychain() {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName
        ]

        SecItemDelete(query as CFDictionary)
    }

    private static func encrypt(value: String) -> Data? {
        guard let data = value.data(using: .utf8) else {
            return nil
        }

        guard let key = getOrCreateEncryptionKey() else {
            return nil
        }

        do {
            let sealedBox = try AES.GCM.seal(data, using: key)
            var encryptedData = Data()
            let nonceBytes = sealedBox.nonce.withUnsafeBytes { bufferPointer in
                Data(bufferPointer)
            }
            encryptedData.append(nonceBytes)
            encryptedData.append(sealedBox.ciphertext)
            encryptedData.append(sealedBox.tag)
            return encryptedData
        } catch {
            Logger.e("Encryption failed: \(error.localizedDescription)")
            return nil
        }
    }

    private static func decrypt(data: Data) -> String? {
        guard data.count > 12 else {
            return nil
        }

        guard let key = getOrCreateEncryptionKey() else {
            return nil
        }

        guard data.count > 28 else {
            return nil
        }

        let nonceData = Data(data.prefix(12))
        let remainingData = Data(data.dropFirst(12))

        guard let nonce = try? AES.GCM.Nonce(data: nonceData),
              remainingData.count >= 16 else {
            return nil
        }

        let tagSize = 16
        let ciphertext = Data(remainingData.prefix(remainingData.count - tagSize))
        let tagData = Data(remainingData.suffix(tagSize))

        do {
            let sealedBox = try AES.GCM.SealedBox(
                nonce: nonce,
                ciphertext: ciphertext,
                tag: tagData
            )
            let decryptedData = try AES.GCM.open(sealedBox, using: key)
            return String(data: decryptedData, encoding: .utf8)
        } catch {
            Logger.e("Decryption failed: \(error.localizedDescription)")
            return nil
        }
    }

    private static func getOrCreateEncryptionKey() -> SymmetricKey? {
        let keyKey = "__encryption_key__"

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: keyKey,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        if status == errSecSuccess, let keyData = result as? Data {
            return SymmetricKey(data: keyData)
        }

        let newKey = SymmetricKey(size: .bits256)
        let keyData = newKey.withUnsafeBytes { bufferPointer in
            Data(bufferPointer)
        }

        let addQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: keyKey,
            kSecValueData as String: keyData,
            kSecAttrAccessible as String: accessibility
        ]

        let addStatus = SecItemAdd(addQuery as CFDictionary, nil)
        if addStatus == errSecSuccess {
            return newKey
        }

        Logger.e("Failed to create encryption key in Keychain")
        return nil
    }

    private static func migrateFromUserDefaultsIfNeeded(key: String) {
        if getFromKeychain(key: key) == nil {
            let obfuscatedKey = obfuscateKey(key)
            if let obfuscatedValue = UserDefaults(suiteName: suiteName)?.string(forKey: obfuscatedKey),
               let value = deobfuscateValue(obfuscatedValue) {
                _ = setToKeychain(key: key, value: value)
                UserDefaults(suiteName: suiteName)?.removeObject(forKey: obfuscatedKey)
            }
        }
    }

    private static func obfuscateKey(_ key: String) -> String {
        guard let data = key.data(using: .utf8) else { return key }
        return data.base64EncodedString()
    }

    private static func deobfuscateValue(_ value: String) -> String? {
        guard let data = Data(base64Encoded: value),
              let string = String(data: data, encoding: .utf8) else {
            return nil
        }
        return string
    }

    static func getString(_ key: String, defaultValue: String? = nil) -> String? {
        migrateFromUserDefaultsIfNeeded(key: key)

        return getFromKeychain(key: key) ?? defaultValue
    }

    static func setString(_ key: String, value: String) {
        _ = setToKeychain(key: key, value: value)

        let obfuscatedKey = obfuscateKey(key)
        UserDefaults(suiteName: suiteName)?.removeObject(forKey: obfuscatedKey)
    }

    static func getLong(_ key: String, defaultValue: Int64 = 0) -> Int64 {
        migrateFromUserDefaultsIfNeeded(key: key)

        guard let stringValue = getFromKeychain(key: key),
              let longValue = Int64(stringValue) else {
            return defaultValue
        }
        return longValue
    }

    static func setLong(_ key: String, value: Int64) {
        _ = setToKeychain(key: key, value: String(value))

        let obfuscatedKey = obfuscateKey(key)
        UserDefaults(suiteName: suiteName)?.removeObject(forKey: obfuscatedKey)
    }

    static func remove(_ key: String) {
        _ = removeFromKeychain(key: key)

        let obfuscatedKey = obfuscateKey(key)
        UserDefaults(suiteName: suiteName)?.removeObject(forKey: obfuscatedKey)
    }

    static func clear() {
        clearKeychain()

        guard let defaults = UserDefaults(suiteName: suiteName) else { return }
        let dictionary = defaults.dictionaryRepresentation()
        dictionary.keys.forEach { key in
            defaults.removeObject(forKey: key)
        }
    }
}

