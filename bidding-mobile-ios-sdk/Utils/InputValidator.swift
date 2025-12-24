import Foundation

internal struct InputValidator {
    
    private static let maxUserIdLength = 256
    private static let maxStringFieldLength = 1024
    private static let maxKeywordLength = 256
    private static let maxPayloadLength = 65536
    
    private static let scriptPattern = try! NSRegularExpression(
        pattern: "<script[^>]*>.*?</script>",
        options: [.caseInsensitive, .dotMatchesLineSeparators]
    )
    
    private static let htmlTagPattern = try! NSRegularExpression(
        pattern: "<[^>]+>",
        options: []
    )
    
    private static let sqlInjectionPattern = try! NSRegularExpression(
        pattern: "('|--|;|/\\*|\\*/|@@|char|nchar|varchar|nvarchar|alter|begin|cast|create|cursor|declare|delete|drop|end|exec|execute|fetch|insert|kill|open|select|sys|sysobjects|syscolumns|table|update)",
        options: [.caseInsensitive]
    )
    
    /// Sanitize string value
    /// - Parameters:
    ///   - value: String value to sanitize
    ///   - maxLength: Maximum length (default: 1024)
    /// - Returns: Sanitized string or nil if input is nil/empty
    static func sanitizeString(_ value: String?, maxLength: Int = maxStringFieldLength) -> String? {
        guard let value = value else {
            return nil
        }
        
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            // If only whitespace, return empty string
            return ""
        }
        
        var sanitized = value
        
        // Truncate if exceeds max length
        if sanitized.count > maxLength {
            sanitized = String(sanitized.prefix(maxLength))
            Logger.i("Input truncated to \(maxLength) characters")
        }
        
        // Remove script tags
        let scriptRange = NSRange(sanitized.startIndex..<sanitized.endIndex, in: sanitized)
        sanitized = scriptPattern.stringByReplacingMatches(
            in: sanitized,
            options: [],
            range: scriptRange,
            withTemplate: ""
        )
        
        // Remove HTML tags
        let htmlRange = NSRange(sanitized.startIndex..<sanitized.endIndex, in: sanitized)
        sanitized = htmlTagPattern.stringByReplacingMatches(
            in: sanitized,
            options: [],
            range: htmlRange,
            withTemplate: ""
        )
        
        // Remove null bytes
        sanitized = sanitized.replacingOccurrences(of: "\u{0000}", with: "")
        
        // Sanitize SQL injection
        sanitized = sanitizeSqlInjection(sanitized) ?? sanitized
        
        return sanitized.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    /// Sanitize SQL injection patterns
    /// - Parameter value: String value
    /// - Returns: Sanitized string or nil if input is nil/empty
    private static func sanitizeSqlInjection(_ value: String?) -> String? {
        guard let value = value, !value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return value
        }
        
        let range = NSRange(value.startIndex..<value.endIndex, in: value)
        return sqlInjectionPattern.stringByReplacingMatches(
            in: value,
            options: [],
            range: range,
            withTemplate: ""
        )
    }
    
    /// Check if string contains SQL injection patterns
    /// - Parameter value: String value to check
    /// - Returns: true if contains SQL injection patterns
    static func containsSqlInjection(_ value: String?) -> Bool {
        guard let value = value, !value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return false
        }
        
        let range = NSRange(value.startIndex..<value.endIndex, in: value)
        return sqlInjectionPattern.firstMatch(in: value, options: [], range: range) != nil
    }
    
    /// Sanitize user ID
    /// - Parameter userId: User ID string
    /// - Returns: Sanitized user ID or nil
    static func sanitizeUserId(_ userId: String?) -> String? {
        return sanitizeString(userId, maxLength: maxUserIdLength)
    }
    
    /// Sanitize keyword
    /// - Parameter keyword: Keyword string
    /// - Returns: Sanitized keyword or nil
    static func sanitizeKeyword(_ keyword: String?) -> String? {
        return sanitizeString(keyword, maxLength: maxKeywordLength)
    }
    
    /// Sanitize product list (no SQL injection check, only script/HTML/null byte removal)
    /// - Parameter productList: Product list string
    /// - Returns: Sanitized product list or nil
    static func sanitizeProductList(_ productList: String?) -> String? {
        guard let productList = productList else {
            return nil
        }
        
        let trimmed = productList.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            // If only whitespace, return empty string
            return ""
        }
        
        var sanitized = productList
        
        // Remove script tags
        let scriptRange = NSRange(sanitized.startIndex..<sanitized.endIndex, in: sanitized)
        sanitized = scriptPattern.stringByReplacingMatches(
            in: sanitized,
            options: [],
            range: scriptRange,
            withTemplate: ""
        )
        
        // Remove HTML tags
        let htmlRange = NSRange(sanitized.startIndex..<sanitized.endIndex, in: sanitized)
        sanitized = htmlTagPattern.stringByReplacingMatches(
            in: sanitized,
            options: [],
            range: htmlRange,
            withTemplate: ""
        )
        
        // Remove null bytes
        sanitized = sanitized.replacingOccurrences(of: "\u{0000}", with: "")
        
        return sanitized.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    /// Sanitize payload
    /// - Parameter payload: Payload string
    /// - Returns: Sanitized payload or nil
    static func sanitizePayload(_ payload: String?) -> String? {
        return sanitizeString(payload, maxLength: maxPayloadLength)
    }
}

