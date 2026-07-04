import Foundation

enum CodingCommandProcessor {
    static let contextualTerms: [String] = [
        "async", "await", "actor", "binding", "boolean", "camelCase",
        "class", "closure", "console log", "constant", "dictionary",
        "enum", "false", "function", "guard let", "import", "interface",
        "JSON", "let", "nil", "null", "optional", "private", "protocol",
        "public", "snake case", "struct", "SwiftUI", "throw", "throws",
        "true", "tuple", "TypeScript", "useEffect", "useState", "variable"
    ]

    static func process(_ text: String) -> String {
        var output = text
        let replacements: [(String, String)] = [
            (" new line ", "\n"),
            (" newline ", "\n"),
            (" tab ", "\t"),
            (" open parenthesis ", "("),
            (" close parenthesis ", ")"),
            (" open parentheses ", "("),
            (" close parentheses ", ")"),
            (" open bracket ", "["),
            (" close bracket ", "]"),
            (" open brace ", "{"),
            (" close brace ", "}"),
            (" comma ", ", "),
            (" semicolon ", ";"),
            (" colon ", ": "),
            (" equals ", " = "),
            (" double equals ", " == "),
            (" triple equals ", " === "),
            (" arrow ", " -> "),
            (" fat arrow ", " => "),
            (" dot ", "."),
            (" slash ", "/"),
            (" backslash ", "\\"),
            (" underscore ", "_"),
            (" dash ", "-"),
            (" quote ", "\""),
            (" single quote ", "'"),
            (" back tick ", "`")
        ]

        for (spoken, replacement) in replacements {
            output = output.replacingOccurrences(
                of: spoken,
                with: replacement,
                options: [.caseInsensitive]
            )
        }
        return output.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
