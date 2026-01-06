import Foundation

internal struct InputValidator {

    private static let maxUserIdLength = 256
    private static let maxStringFieldLength = 1024
    private static let maxKeywordLength = 256
    private static let maxPayloadLength = 65536

    private static func createRegex(pattern: String, options: NSRegularExpression.Options) -> NSRegularExpression? {
        return try? NSRegularExpression(pattern: pattern, options: options)
    }
    
    private static func getFallbackRegex() -> NSRegularExpression {
        if let regex = try? NSRegularExpression(pattern: "^$", options: []) {
            return regex
        }
        if let regex = try? NSRegularExpression(pattern: ".", options: []) {
            Logger.e("Using '.' as fallback regex")
            return regex
        }
        Logger.e("Critical: All regex initialization failed")
        // swiftlint:disable:next force_try
        return try! NSRegularExpression(pattern: ".", options: [])
    }
    
    private static let _scriptPattern: NSRegularExpression = {
        if let pattern = createRegex(
            pattern: "<script[^>]*>.*?</script>",
            options: [.caseInsensitive, .dotMatchesLineSeparators]
        ) {
            return pattern
        }
        Logger.e("Failed to create scriptPattern regex, using fallback")
        return createRegex(pattern: "^$", options: []) ?? getFallbackRegex()
    }()
    
    private static let _htmlTagPattern: NSRegularExpression = {
        if let pattern = createRegex(pattern: "<[^>]+>", options: []) {
            return pattern
        }
        Logger.e("Failed to create htmlTagPattern regex, using fallback")
        return createRegex(pattern: "^$", options: []) ?? getFallbackRegex()
    }()
    
    private static let _sqlInjectionPattern: NSRegularExpression = {
        if let pattern = createRegex(
            pattern: "('|--|;|/\\*|\\*/|@@|char|nchar|varchar|nvarchar|alter|begin|cast|create|cursor|declare|delete|drop|end|exec|execute|fetch|insert|kill|open|select|sys|sysobjects|syscolumns|table|update)",
            options: [.caseInsensitive]
        ) {
            return pattern
        }
        Logger.e("Failed to create sqlInjectionPattern regex, using fallback")
        return createRegex(pattern: "^$", options: []) ?? getFallbackRegex()
    }()
    
    private static let _sqlInjectionPatternForProductList: NSRegularExpression = {
        if let pattern = createRegex(
            pattern: "('|--|/\\*|\\*/|@@|char|nchar|varchar|nvarchar|alter|begin|cast|create|cursor|declare|delete|drop|end|exec|execute|fetch|insert|kill|open|select|sys|sysobjects|syscolumns|table|update)",
            options: [.caseInsensitive]
        ) {
            return pattern
        }
        Logger.e("Failed to create sqlInjectionPatternForProductList regex, using fallback")
        return createRegex(pattern: "^$", options: []) ?? getFallbackRegex()
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

    static func containsSqlInjection(_ value: String?) -> Bool {
        guard let value = value, !value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return false
        }

        let range = NSRange(value.startIndex..<value.endIndex, in: value)
        return sqlInjectionPattern.firstMatch(in: value, options: [], range: range) != nil
    }

    static func sanitizeUserId(_ userId: String?) -> String? {
        return sanitizeString(userId, maxLength: maxUserIdLength)
    }

    static func sanitizeKeyword(_ keyword: String?) -> String? {
        return sanitizeString(keyword, maxLength: maxKeywordLength)
    }

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

        let sqlRange = NSRange(sanitized.startIndex..<sanitized.endIndex, in: sanitized)
        sanitized = sqlInjectionPatternForProductList.stringByReplacingMatches(
            in: sanitized,
            options: [],
            range: sqlRange,
            withTemplate: ""
        )

        return sanitized.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    static func sanitizePayload(_ payload: String?) -> String? {
        return sanitizeString(payload, maxLength: maxPayloadLength)
    }
}

