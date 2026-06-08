import Foundation

enum WeeklyAnalytics {
    static func report(
        state: AppState,
        now: Date = Date(),
        calendar: Calendar = .current
    ) -> String {
        let start = DateRules.weekStart(now, calendar: calendar)
        let end = calendar.date(byAdding: .day, value: 6, to: start)!
        let startKey = DateRules.dateKey(start, calendar: calendar)
        let endKey = DateRules.dateKey(end, calendar: calendar)
        let days = state.days.values
            .filter { $0.date >= startKey && $0.date <= endKey }
            .sorted { $0.date < $1.date }
        let completed = days.flatMap(\.plannedTasks).filter(\.completed)
        let activeDays = days.filter {
            !$0.reflection.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                || $0.plannedTasks.contains(where: \.completed)
        }

        let goals = state.currentWeekGoals.isEmpty
            ? ["- No weekly goals recorded."]
            : state.currentWeekGoals.map { goal in
                if let target = goal.target {
                    return "- \(goal.text): \(goal.current ?? 0)/\(target)"
                }
                return "- \(goal.text): \(goal.completed ? "complete" : "open")"
            }

        return [
            "DAYMARK WEEKLY REPORT",
            "\(startKey) to \(endKey)",
            "",
            "SUMMARY",
            "\(completed.count) tasks completed across \(activeDays.count) active days.",
            "",
            "WEEKLY GOALS",
            goals.joined(separator: "\n"),
            "",
            "COMPLETED",
            completed.isEmpty ? "- Nothing logged yet." : completed.map { "- \($0.text)" }.joined(separator: "\n"),
            "",
            "DAILY NOTES",
            notes(days)
        ].joined(separator: "\n")
    }

    private static func notes(_ days: [DayRecord]) -> String {
        let entries = days.filter { !$0.reflection.isEmpty }
            .map { "- \($0.date): \($0.reflection)" }
        return entries.isEmpty ? "- No reflections recorded." : entries.joined(separator: "\n")
    }
}
