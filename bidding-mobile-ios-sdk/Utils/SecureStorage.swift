import Foundation
import Security
import CryptoKit

internal struct SecureStorage {
    
    private static let serviceName = "com.mimeda.sdk"
    private static let suiteName = "com.mimeda.sdk.storage" // Eski UserDefaults migration için
    
    // Keychain erişim seviyesi - sadece cihaz unlock olduğunda ve bu cihazda erişilebilir
    private static let accessibility: CFString = kSecAttrAccessibleWhenUnlockedThisDeviceOnly
    
    // Keychain'den veri okuma
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
    
    // Keychain'e veri yazma
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
        
        // Önce mevcut item'ı sil, sonra yenisini ekle
        SecItemDelete(query as CFDictionary)
        
        let addQuery = query.merging(attributes) { (_, new) in new }
        let status = SecItemAdd(addQuery as CFDictionary, nil)
        
        return status == errSecSuccess
    }
    
    // Keychain'den veri silme
    private static func removeFromKeychain(key: String) -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: key
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        return status == errSecSuccess || status == errSecItemNotFound
    }
    
    // Tüm Keychain verilerini temizleme
    private static func clearKeychain() {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName
        ]
        
        SecItemDelete(query as CFDictionary)
    }
    
    // CryptoKit ile AES-GCM encryption
    private static func encrypt(value: String) -> Data? {
        guard let data = value.data(using: .utf8) else {
            return nil
        }
        
        // Keychain'den encryption key'i al veya oluştur
        guard let key = getOrCreateEncryptionKey() else {
            return nil
        }
        
        do {
            let sealedBox = try AES.GCM.seal(data, using: key)
            // Nonce ve ciphertext'i birleştir
            var encryptedData = Data()
            encryptedData.append(sealedBox.nonce.withUnsafeBytes { Data($0) })
            encryptedData.append(sealedBox.ciphertext)
            if let tag = sealedBox.tag {
                encryptedData.append(tag)
            }
            return encryptedData
        } catch {
            Logger.e("Encryption failed: \(error.localizedDescription)")
            return nil
        }
    }
    
    // CryptoKit ile AES-GCM decryption
    private static func decrypt(data: Data) -> String? {
        guard data.count > 12 else { // Nonce (12 bytes) + minimum ciphertext
            return nil
        }
        
        // Keychain'den encryption key'i al
        guard let key = getOrCreateEncryptionKey() else {
            return nil
        }
        
        // Nonce, ciphertext ve tag'i ayır
        let nonceData = data.prefix(12)
        let ciphertextAndTag = data.suffix(from: 12)
        
        guard let nonce = try? AES.GCM.Nonce(data: nonceData),
              ciphertextAndTag.count >= 16 else { // Minimum tag size
            return nil
        }
        
        let ciphertext = ciphertextAndTag.prefix(ciphertextAndTag.count - 16)
        let tag = ciphertextAndTag.suffix(16)
        
        do {
            let sealedBox = try AES.GCM.SealedBox(
                nonce: nonce,
                ciphertext: Data(ciphertext),
                tag: Data(tag)
            )
            let decryptedData = try AES.GCM.open(sealedBox, using: key)
            return String(data: decryptedData, encoding: .utf8)
        } catch {
            Logger.e("Decryption failed: \(error.localizedDescription)")
            return nil
        }
    }
    
    // Encryption key'i Keychain'den al veya oluştur
    private static func getOrCreateEncryptionKey() -> SymmetricKey? {
        let keyKey = "__encryption_key__"
        
        // Önce Keychain'den key'i al
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
        
        // Key yoksa yeni oluştur
        let newKey = SymmetricKey(size: .bits256)
        let keyData = newKey.withUnsafeBytes { Data($0) }
        
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
    
    // UserDefaults'tan Keychain'e migration (backward compatibility)
    private static func migrateFromUserDefaultsIfNeeded(key: String) {
        // Sadece Keychain'de yoksa ve UserDefaults'ta varsa migrate et
        if getFromKeychain(key: key) == nil {
            let obfuscatedKey = obfuscateKey(key)
            if let obfuscatedValue = UserDefaults(suiteName: suiteName)?.string(forKey: obfuscatedKey),
               let value = deobfuscateValue(obfuscatedValue) {
                // Keychain'e kaydet
                _ = setToKeychain(key: key, value: value)
                // UserDefaults'tan sil
                UserDefaults(suiteName: suiteName)?.removeObject(forKey: obfuscatedKey)
            }
        }
    }
    
    // Eski obfuscation metodları (migration için)
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
    
    // Public API - String operations
    static func getString(_ key: String, defaultValue: String? = nil) -> String? {
        // Önce migration kontrolü yap
        migrateFromUserDefaultsIfNeeded(key: key)
        
        return getFromKeychain(key: key) ?? defaultValue
    }
    
    static func setString(_ key: String, value: String) {
        _ = setToKeychain(key: key, value: value)
        
        // Eski UserDefaults'tan da sil (temizlik için)
        let obfuscatedKey = obfuscateKey(key)
        UserDefaults(suiteName: suiteName)?.removeObject(forKey: obfuscatedKey)
    }
    
    // Public API - Long operations
    static func getLong(_ key: String, defaultValue: Int64 = 0) -> Int64 {
        // Önce migration kontrolü yap
        migrateFromUserDefaultsIfNeeded(key: key)
        
        guard let stringValue = getFromKeychain(key: key),
              let longValue = Int64(stringValue) else {
            return defaultValue
        }
        return longValue
    }
    
    static func setLong(_ key: String, value: Int64) {
        _ = setToKeychain(key: key, value: String(value))
        
        // Eski UserDefaults'tan da sil (temizlik için)
        let obfuscatedKey = obfuscateKey(key)
        UserDefaults(suiteName: suiteName)?.removeObject(forKey: obfuscatedKey)
    }
    
    // Public API - Remove and Clear
    static func remove(_ key: String) {
        _ = removeFromKeychain(key: key)
        
        // Eski UserDefaults'tan da sil
        let obfuscatedKey = obfuscateKey(key)
        UserDefaults(suiteName: suiteName)?.removeObject(forKey: obfuscatedKey)
    }
    
    static func clear() {
        clearKeychain()
        
        // Eski UserDefaults'u da temizle
        guard let defaults = UserDefaults(suiteName: suiteName) else { return }
        let dictionary = defaults.dictionaryRepresentation()
        dictionary.keys.forEach { key in
            defaults.removeObject(forKey: key)
        }
    }
}
