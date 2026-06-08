import Foundation

enum MonthlyAnalytics {
    static func report(
        state: AppState,
        monthContaining now: Date = Date(),
        calendar: Calendar = .current
    ) -> String {
        let interval = calendar.dateInterval(of: .month, for: now)!
        let lastDay = calendar.date(byAdding: .day, value: -1, to: interval.end)!
        let startKey = DateRules.dateKey(interval.start, calendar: calendar)
        let endKey = DateRules.dateKey(lastDay, calendar: calendar)
        let days = state.days.values.filter { $0.date >= startKey && $0.date <= endKey }
        let completed = days.flatMap(\.plannedTasks).filter(\.completed)
        let active = days.filter {
            !$0.reflection.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                || $0.plannedTasks.contains(where: \.completed)
        }
        let archivedGoals = state.weeklyArchives
            .filter { $0.weekStart >= startKey && $0.weekStart <= endKey }
            .flatMap(\.goals)
        let completedGoals = archivedGoals.filter {
            $0.completed || ($0.target != nil && ($0.current ?? 0) >= $0.target!)
        }

        return [
            "DAYMARK MONTHLY REPORT",
            "\(startKey) to \(endKey)",
            "",
            "OUTCOMES",
            "- \(completed.count) daily tasks completed",
            "- \(completedGoals.count) weekly goals completed",
            "",
            "CONSISTENCY",
            "- \(active.count) active days",
            "",
            "REVIEW",
            "- Revisit repeated carryovers before choosing next month's focus."
        ].joined(separator: "\n")
    }
}
