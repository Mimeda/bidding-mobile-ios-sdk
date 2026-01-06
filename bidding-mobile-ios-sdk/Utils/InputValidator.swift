import Foundation

internal struct InputValidator {

    private static let maxUserIdLength = 256
    private static let maxStringFieldLength = 1024
    private static let maxKeywordLength = 256
    private static let maxPayloadLength = 65536

    /// Güvenli regex oluşturma - lazy static property kullanarak crash'i önliyoruz
    private static func createRegex(pattern: String, options: NSRegularExpression.Options) -> NSRegularExpression? {
        return try? NSRegularExpression(pattern: pattern, options: options)
    }
    
    // Lazy static property'ler - sadece ilk kullanımda oluşturulur ve hata durumunda fallback kullanılır
    private static let _scriptPattern: NSRegularExpression = {
        if let pattern = createRegex(
            pattern: "<script[^>]*>.*?</script>",
            options: [.caseInsensitive, .dotMatchesLineSeparators]
        ) {
            return pattern
        }
        Logger.e("Failed to create scriptPattern regex, using fallback")
        return createRegex(pattern: "^$", options: []) ?? createRegex(pattern: ".", options: []) ?? {
            // Bu noktaya gelinmemeli ama yine de crash olmaması için bir şey döndürmeliyiz
            Logger.e("Critical: All regex fallbacks failed for scriptPattern")
            // Son çare: en basit geçerli pattern
            return try! NSRegularExpression(pattern: ".", options: [])
        }()
    }()
    
    private static let _htmlTagPattern: NSRegularExpression = {
        if let pattern = createRegex(pattern: "<[^>]+>", options: []) {
            return pattern
        }
        Logger.e("Failed to create htmlTagPattern regex, using fallback")
        return createRegex(pattern: "^$", options: []) ?? createRegex(pattern: ".", options: []) ?? {
            Logger.e("Critical: All regex fallbacks failed for htmlTagPattern")
            return try! NSRegularExpression(pattern: ".", options: [])
        }()
    }()
    
    private static let _sqlInjectionPattern: NSRegularExpression = {
        if let pattern = createRegex(
            pattern: "('|--|;|/\\*|\\*/|@@|char|nchar|varchar|nvarchar|alter|begin|cast|create|cursor|declare|delete|drop|end|exec|execute|fetch|insert|kill|open|select|sys|sysobjects|syscolumns|table|update)",
            options: [.caseInsensitive]
        ) {
            return pattern
        }
        Logger.e("Failed to create sqlInjectionPattern regex, using fallback")
        return createRegex(pattern: "^$", options: []) ?? createRegex(pattern: ".", options: []) ?? {
            Logger.e("Critical: All regex fallbacks failed for sqlInjectionPattern")
            return try! NSRegularExpression(pattern: ".", options: [])
        }()
    }()
    
    private static let _sqlInjectionPatternForProductList: NSRegularExpression = {
        if let pattern = createRegex(
            pattern: "('|--|/\\*|\\*/|@@|char|nchar|varchar|nvarchar|alter|begin|cast|create|cursor|declare|delete|drop|end|exec|execute|fetch|insert|kill|open|select|sys|sysobjects|syscolumns|table|update)",
            options: [.caseInsensitive]
        ) {
            return pattern
        }
        Logger.e("Failed to create sqlInjectionPatternForProductList regex, using fallback")
        return createRegex(pattern: "^$", options: []) ?? createRegex(pattern: ".", options: []) ?? {
            Logger.e("Critical: All regex fallbacks failed for sqlInjectionPatternForProductList")
            return try! NSRegularExpression(pattern: ".", options: [])
        }()
    }()

    private static var scriptPattern: NSRegularExpression {
        return _scriptPattern
    }

    private static var htmlTagPattern: NSRegularExpression {
        return _htmlTagPattern
    }

    private static var sqlInjectionPattern: NSRegularExpression {
        return _sqlInjectionPattern
    }

    private static var sqlInjectionPatternForProductList: NSRegularExpression {
        return _sqlInjectionPatternForProductList
    }

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
            return ""
        }

        var sanitized = value

        if sanitized.count > maxLength {
            sanitized = String(sanitized.prefix(maxLength))
            Logger.i("Input truncated to \(maxLength) characters")
        }

        let scriptRange = NSRange(sanitized.startIndex..<sanitized.endIndex, in: sanitized)
        sanitized = scriptPattern.stringByReplacingMatches(
            in: sanitized,
            options: [],
            range: scriptRange,
            withTemplate: ""
        )

        let htmlRange = NSRange(sanitized.startIndex..<sanitized.endIndex, in: sanitized)
        sanitized = htmlTagPattern.stringByReplacingMatches(
            in: sanitized,
            options: [],
            range: htmlRange,
            withTemplate: ""
        )

        sanitized = sanitized.replacingOccurrences(of: "\u{0000}", with: "")

        sanitized = sanitizeSqlInjection(sanitized) ?? sanitized

        return sanitized.trimmingCharacters(in: .whitespacesAndNewlines)
    }

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

    /// - Parameter value: String value to check
    /// - Returns: true if contains SQL injection patterns
    static func containsSqlInjection(_ value: String?) -> Bool {
        guard let value = value, !value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return false
        }

        let range = NSRange(value.startIndex..<value.endIndex, in: value)
        return sqlInjectionPattern.firstMatch(in: value, options: [], range: range) != nil
    }

    /// - Parameter userId: User ID string
    /// - Returns: Sanitized user ID or nil
    static func sanitizeUserId(_ userId: String?) -> String? {
        return sanitizeString(userId, maxLength: maxUserIdLength)
    }

    /// - Parameter keyword: Keyword string
    /// - Returns: Sanitized keyword or nil
    static func sanitizeKeyword(_ keyword: String?) -> String? {
        return sanitizeString(keyword, maxLength: maxKeywordLength)
    }

    /// - Parameter productList: Product list string
    /// - Returns: Sanitized product list or nil
    static func sanitizeProductList(_ productList: String?) -> String? {
        guard let productList = productList else {
            return nil
        }

        let trimmed = productList.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return ""
        }

        var sanitized = productList

        let scriptRange = NSRange(sanitized.startIndex..<sanitized.endIndex, in: sanitized)
        sanitized = scriptPattern.stringByReplacingMatches(
            in: sanitized,
            options: [],
            range: scriptRange,
            withTemplate: ""
        )

        let htmlRange = NSRange(sanitized.startIndex..<sanitized.endIndex, in: sanitized)
        sanitized = htmlTagPattern.stringByReplacingMatches(
            in: sanitized,
            options: [],
            range: htmlRange,
            withTemplate: ""
        )

        sanitized = sanitized.replacingOccurrences(of: "\u{0000}", with: "")

        // SQL injection kontrolü (; ve : karakterlerine izin veriliyor)
        let sqlRange = NSRange(sanitized.startIndex..<sanitized.endIndex, in: sanitized)
        sanitized = sqlInjectionPatternForProductList.stringByReplacingMatches(
            in: sanitized,
            options: [],
            range: sqlRange,
            withTemplate: ""
        )

        return sanitized.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// - Parameter payload: Payload string
    /// - Returns: Sanitized payload or nil
    static func sanitizePayload(_ payload: String?) -> String? {
        return sanitizeString(payload, maxLength: maxPayloadLength)
    }
}

