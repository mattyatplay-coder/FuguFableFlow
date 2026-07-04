import Foundation

enum SmartFormattingProcessor {
    struct Options {
        var writingStyle: WritingStyle
        var backtrackEnabled: Bool
        var frontmostBundleIdentifier: String?
    }

    static func process(_ text: String, options: Options) -> String {
        var output = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !output.isEmpty else { return output }

        if options.backtrackEnabled {
            output = applyBacktrack(output)
        }

        output = replacePunctuationCommands(output)
        output = createSimpleLists(output)
        output = normalizeWhitespace(output)
        output = removeTrailingPeriodIfNeeded(output, options: options)
        return output.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static func applyBacktrack(_ text: String) -> String {
        let triggerPatterns = [
            #"(?i)\bscratch that[, ]+"#,
            #"(?i)\bdelete that[, ]+"#,
            #"(?i)\bno[, ]+"#,
            #"(?i)\bactually[, ]+"#
        ]

        for pattern in triggerPatterns {
            guard let regex = try? NSRegularExpression(pattern: pattern) else { continue }
            let range = NSRange(text.startIndex..<text.endIndex, in: text)
            if let match = regex.matches(in: text, range: range).last,
               let swiftRange = Range(match.range, in: text) {
                return String(text[swiftRange.upperBound...])
                    .trimmingCharacters(in: .whitespacesAndNewlines)
            }
        }

        return text
    }

    private static func replacePunctuationCommands(_ text: String) -> String {
        var output = " \(text) "
        let replacements: [(String, String)] = [
            (#"\b(?:period|full stop)\b"#, "."),
            (#"\bcomma\b"#, ","),
            (#"\bquestion mark\b"#, "?"),
            (#"\b(?:exclamation point|exclamation mark)\b"#, "!"),
            (#"\bcolon\b"#, ":"),
            (#"\bsemicolon\b"#, ";"),
            (#"\b(?:em dash|em-dash|emdash)\b"#, " - "),
            (#"\b(?:quotation mark|quote)\b"#, "\""),
            (#"\b(?:apostrophe|single quote)\b"#, "'"),
            (#"\b(?:asterisk|star)\b"#, "*"),
            (#"\bampersand\b"#, "&"),
            (#"\b(?:percent sign|per cent|percentage symbol)\b"#, "%"),
            (#"\bellipsis\b"#, "..."),
            (#"\b(?:slash|forward slash|per|divided by)\b"#, "/"),
            (#"\bbackslash\b"#, "\\"),
            (#"\bunderscore\b"#, "_"),
            (#"\b(?:hashtag|hash)\b"#, "#"),
            (#"\btilde\b"#, "~"),
            (#"\b(?:at sign|at symbol)\b"#, "@"),
            (#"\b(?:plus sign|plus)\b"#, "+"),
            (#"\b(?:minus sign|negative)\b"#, "-"),
            (#"\b(?:equals sign|equals)\b"#, "="),
            (#"\b(?:trademark|tm)\b"#, "TM"),
            (#"\bregistered trademark\b"#, "R"),
            (#"\b(?:copyright symbol|copyright)\b"#, "C"),
            (#"\b(?:degree sign|degree symbol)\b"#, "deg"),
            (#"\b(?:degrees celsius|degrees centigrade)\b"#, "deg C"),
            (#"\b(?:degrees fahrenheit|degrees f)\b"#, "deg F"),
            (#"\b(?:new line|next line|line break)\b"#, "\n"),
            (#"\b(?:new paragraph|skip a line|start a new paragraph)\b"#, "\n\n"),
            (#"\b(?:open parenthesis|open paren|open parentheses)\b"#, "("),
            (#"\b(?:close parenthesis|close paren|close parentheses)\b"#, ")"),
            (#"\b(?:open bracket|left bracket)\b"#, "["),
            (#"\b(?:close bracket|right bracket)\b"#, "]"),
            (#"\b(?:open brace|left brace)\b"#, "{"),
            (#"\b(?:close brace|right brace)\b"#, "}")
        ]

        for (pattern, replacement) in replacements {
            output = output.replacingOccurrences(
                of: pattern,
                with: replacement,
                options: [.regularExpression, .caseInsensitive]
            )
        }

        return output
    }

    private static func createSimpleLists(_ text: String) -> String {
        let ordinalPattern = #"(?i)\b(first|second|third|fourth|fifth|sixth|seventh|eighth|ninth|tenth)\b"#
        guard let regex = try? NSRegularExpression(pattern: ordinalPattern) else { return text }
        let range = NSRange(text.startIndex..<text.endIndex, in: text)
        let matches = regex.matches(in: text, range: range)
        guard matches.count >= 2 else { return text }

        var output = text
        let ordinals = [
            "first": "1.",
            "second": "2.",
            "third": "3.",
            "fourth": "4.",
            "fifth": "5.",
            "sixth": "6.",
            "seventh": "7.",
            "eighth": "8.",
            "ninth": "9.",
            "tenth": "10."
        ]

        for (word, marker) in ordinals {
            output = output.replacingOccurrences(
                of: #"(?i)\b\#(word)\b"#,
                with: "\n\(marker)",
                options: [.regularExpression]
            )
        }
        return output.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static func normalizeWhitespace(_ text: String) -> String {
        var output = text
        output = output.replacingOccurrences(of: #"[ \t]+\n"#, with: "\n", options: .regularExpression)
        output = output.replacingOccurrences(of: #"\n[ \t]+"#, with: "\n", options: .regularExpression)
        output = output.replacingOccurrences(of: #"[ \t]{2,}"#, with: " ", options: .regularExpression)
        output = output.replacingOccurrences(of: #" ?([,.;:!?])"#, with: "$1", options: .regularExpression)
        output = output.replacingOccurrences(of: #"([,.;:!?])(?=\S)"#, with: "$1 ", options: .regularExpression)
        output = output.replacingOccurrences(of: #"\( "#, with: "(", options: .regularExpression)
        output = output.replacingOccurrences(of: #" \)"#, with: ")", options: .regularExpression)
        output = output.replacingOccurrences(of: #"\n{3,}"#, with: "\n\n", options: .regularExpression)
        return output
    }

    private static func removeTrailingPeriodIfNeeded(_ text: String, options: Options) -> String {
        guard text.hasSuffix(".") else { return text }
        let sentenceCount = text.filter { ".!?".contains($0) }.count
        let messagingApp = isMessagingApp(bundleIdentifier: options.frontmostBundleIdentifier)

        let shouldRemove: Bool
        switch options.writingStyle {
        case .automatic:
            shouldRemove = messagingApp && sentenceCount <= 2
        case .casual:
            shouldRemove = sentenceCount <= 10
        case .veryCasual:
            shouldRemove = true
        case .formal:
            shouldRemove = messagingApp && sentenceCount <= 2
        }

        guard shouldRemove else { return text }
        return String(text.dropLast()).trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static func isMessagingApp(bundleIdentifier: String?) -> Bool {
        guard let bundleIdentifier else { return false }
        return [
            "com.apple.MobileSMS",
            "com.tinyspeck.slackmacgap",
            "com.hnc.Discord",
            "ru.keepcoder.Telegram",
            "org.whispersystems.signal-desktop",
            "com.microsoft.teams",
            "net.whatsapp.WhatsApp",
            "com.automattic.beeper.desktop",
            "com.texts.desktop"
        ].contains(bundleIdentifier)
    }
}
