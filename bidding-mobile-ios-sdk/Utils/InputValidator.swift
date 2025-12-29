import Foundation

internal struct InputValidator {

    private static let maxUserIdLength = 256
    private static let maxStringFieldLength = 1024
    private static let maxKeywordLength = 256
    private static let maxPayloadLength = 65536

    private static var scriptPattern: NSRegularExpression {
        // swiftlint:disable:next force_try
        return try! NSRegularExpression(
            pattern: "<script[^>]*>.*?</script>",
            options: [.caseInsensitive, .dotMatchesLineSeparators]
        )
    }

    private static var htmlTagPattern: NSRegularExpression {
        // swiftlint:disable:next force_try
        return try! NSRegularExpression(
            pattern: "<[^>]+>",
            options: []
        )
    }

    private static var sqlInjectionPattern: NSRegularExpression {
        // swiftlint:disable:next force_try line_length
        return try! NSRegularExpression(
            pattern: "('|--|;|/\\*|\\*/|@@|char|nchar|varchar|nvarchar|alter|begin|cast|create|cursor|declare|delete|drop|end|exec|execute|fetch|insert|kill|open|select|sys|sysobjects|syscolumns|table|update)",
            options: [.caseInsensitive]
        )
    }

    private static var sqlInjectionPatternForProductList: NSRegularExpression {
        // swiftlint:disable:next force_try line_length
        // SQL injection pattern without ; and : to allow them in product lists
        return try! NSRegularExpression(
            pattern: "('|--|/\\*|\\*/|@@|char|nchar|varchar|nvarchar|alter|begin|cast|create|cursor|declare|delete|drop|end|exec|execute|fetch|insert|kill|open|select|sys|sysobjects|syscolumns|table|update)",
            options: [.caseInsensitive]
        )
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

