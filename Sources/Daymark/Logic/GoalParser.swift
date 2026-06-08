import Foundation

enum GoalParser {
    static func parse(_ line: String) -> WeeklyGoal? {
        let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        let pattern = #"^(.*?)\s+(\d+)\s*/\s*(\d+)(?:\s+days?)?$"#
        guard let expression = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive),
              let match = expression.firstMatch(
                in: trimmed,
                range: NSRange(trimmed.startIndex..., in: trimmed)
              ),
              let textRange = Range(match.range(at: 1), in: trimmed),
              let currentRange = Range(match.range(at: 2), in: trimmed),
              let targetRange = Range(match.range(at: 3), in: trimmed)
        else {
            return WeeklyGoal(text: trimmed)
        }

        return WeeklyGoal(
            text: String(trimmed[textRange]).trimmingCharacters(in: .whitespaces),
            current: Int(trimmed[currentRange]),
            target: Int(trimmed[targetRange])
        )
    }

    static func parseLines(_ text: String) -> [WeeklyGoal] {
        text.components(separatedBy: .newlines).compactMap(parse)
    }
}
