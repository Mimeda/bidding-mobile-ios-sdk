import Foundation

internal struct SecureStorage {
    
    private static let suiteName = "com.mimeda.sdk.storage"
    
    private static var userDefaults: UserDefaults? {
        return UserDefaults(suiteName: suiteName)
    }
    
    private static func obfuscateKey(_ key: String) -> String {
        guard let data = key.data(using: .utf8) else { return key }
        return data.base64EncodedString()
    }
    
    private static func obfuscateValue(_ value: String) -> String {
        guard let data = value.data(using: .utf8) else { return value }
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
        let obfuscatedKey = obfuscateKey(key)
        guard let obfuscatedValue = userDefaults?.string(forKey: obfuscatedKey) else {
            return defaultValue
        }
        return deobfuscateValue(obfuscatedValue) ?? defaultValue
    }
    
    static func setString(_ key: String, value: String) {
        let obfuscatedKey = obfuscateKey(key)
        let obfuscatedValue = obfuscateValue(value)
        userDefaults?.set(obfuscatedValue, forKey: obfuscatedKey)
    }
    
    static func getLong(_ key: String, defaultValue: Int64 = 0) -> Int64 {
        let obfuscatedKey = obfuscateKey(key)
        guard let stringValue = userDefaults?.string(forKey: obfuscatedKey),
              let deobfuscated = deobfuscateValue(stringValue),
              let longValue = Int64(deobfuscated) else {
            return defaultValue
        }
        return longValue
    }

    static func setLong(_ key: String, value: Int64) {
        let obfuscatedKey = obfuscateKey(key)
        let obfuscatedValue = obfuscateValue(String(value))
        userDefaults?.set(obfuscatedValue, forKey: obfuscatedKey)
    }
    
    static func remove(_ key: String) {
        let obfuscatedKey = obfuscateKey(key)
        userDefaults?.removeObject(forKey: obfuscatedKey)
    }
    
    static func clear() {
        guard let defaults = userDefaults else { return }
        let dictionary = defaults.dictionaryRepresentation()
        dictionary.keys.forEach { key in
            defaults.removeObject(forKey: key)
        }
    }
}

