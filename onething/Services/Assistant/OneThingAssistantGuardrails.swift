import Foundation

enum OneThingAssistantGuardrails {
    static let maxLines: Int = 5

    static func enforce(_ raw: String) -> String {
        var text = raw
        text = stripEmojis(from: text)
        text = removeBannedWords(from: text)
        text = enforceSingleQuestion(in: text)
        text = enforceMaxLines(in: text, maxLines: maxLines)
        return text.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static func enforceMaxLines(in text: String, maxLines: Int) -> String {
        let lines = text
            .split(whereSeparator: \.isNewline)
            .map { String($0).trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        if lines.count <= maxLines { return lines.joined(separator: "\n") }
        return lines.prefix(maxLines).joined(separator: "\n")
    }

    private static func enforceSingleQuestion(in text: String) -> String {
        let questionMarks = text.filter { $0 == "?" }.count
        guard questionMarks > 1 else { return text }

        var out = ""
        var seenFirst = false
        for ch in text {
            if ch == "?" {
                if seenFirst {
                    out.append(".")
                } else {
                    seenFirst = true
                    out.append(ch)
                }
            } else {
                out.append(ch)
            }
        }
        return out
    }

    private static func removeBannedWords(from text: String) -> String {
        // Keep this tiny and product-focused.
        let replacements: [(pattern: String, replacement: String)] = [
            ("(?i)\\bembark\\b", "start"),
            ("(?i)\\bcrush\\b", "do"),
            ("(?i)\\bhustle\\b", "work"),
            ("(?i)\\boptimi[sz]e\\b", "simplify"),
            ("(?i)\\bmaximi[sz]e\\b", "improve"),
        ]

        var out = text
        for (pattern, replacement) in replacements {
            out = out.replacingOccurrences(of: pattern, with: replacement, options: .regularExpression)
        }
        return out
    }

    private static func stripEmojis(from text: String) -> String {
        // Rough emoji removal to satisfy "No emojis" guardrail.
        let scalars = text.unicodeScalars.filter { scalar in
            switch scalar.value {
            case 0x1F300...0x1FAFF, 0x2600...0x27BF, 0xFE00...0xFE0F:
                return false
            default:
                return true
            }
        }
        return String(String.UnicodeScalarView(scalars))
    }
}

