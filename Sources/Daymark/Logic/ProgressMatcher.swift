import Foundation

struct ProgressMatches: Equatable {
    var taskIDs: [UUID]
    var goalIDs: [UUID]
}

enum ProgressMatcher {
    private static let ignored: Set<String> = [
        "a", "an", "and", "at", "did", "do", "for", "get", "got", "i", "in",
        "it", "my", "of", "on", "the", "to", "was", "went", "with"
    ]

    private static let aliases = [
        "groceries": "grocery",
        "workout": "gym",
        "exercise": "gym",
        "exercised": "gym",
        "finished": "finish",
        "completed": "complete"
    ]

    static func detect(
        reflection: String,
        tasks: [DaymarkTask],
        goals: [WeeklyGoal],
        alreadyCredited: Set<UUID>
    ) -> ProgressMatches {
        ProgressMatches(
            taskIDs: tasks.filter { !$0.completed && matches(reflection, label: $0.text) }.map(\.id),
            goalIDs: goals.filter {
                !alreadyCredited.contains($0.id)
                    && !isComplete($0)
                    && matches(reflection, label: $0.text)
            }.map(\.id)
        )
    }

    static func matches(_ source: String, label: String) -> Bool {
        let sourceWords = Set(words(source))
        let targetWords = words(label)
        guard !targetWords.isEmpty else { return false }
        let hits = targetWords.filter(sourceWords.contains).count
        return hits >= min(2, targetWords.count)
            || Double(hits) / Double(targetWords.count) >= 0.6
    }

    private static func isComplete(_ goal: WeeklyGoal) -> Bool {
        if let target = goal.target { return (goal.current ?? 0) >= target }
        return goal.completed
    }

    private static func words(_ value: String) -> [String] {
        value.lowercased()
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { $0.count > 1 && !ignored.contains($0) }
            .map { aliases[$0] ?? stem($0) }
    }

    private static func stem(_ word: String) -> String {
        for suffix in ["ing", "ed", "es", "s"] where word.count > suffix.count + 2 {
            if word.hasSuffix(suffix) {
                return String(word.dropLast(suffix.count))
            }
        }
        return word
    }
}
