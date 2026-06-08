import Foundation

enum RolloverEngine {
    static func apply(
        to state: inout AppState,
        now: Date = Date(),
        calendar: Calendar = .current
    ) {
        let today = DateRules.dateKey(now, calendar: calendar)
        let week = DateRules.weekKey(now, calendar: calendar)

        if state.currentWeekStart != week {
            if !state.currentWeekGoals.isEmpty {
                state.weeklyArchives.append(
                    WeeklyArchive(
                        weekStart: state.currentWeekStart,
                        goals: state.currentWeekGoals
                    )
                )
            }
            state.currentWeekGoals = state.nextWeekDraft.compactMap(GoalParser.parse)
            state.nextWeekDraft = []
            state.currentWeekStart = week
        }

        if state.days[today] == nil {
            let tasks = state.tomorrowDraft.map { DaymarkTask(text: $0) }
            state.days[today] = DayRecord(date: today, plannedTasks: tasks)
            state.tomorrowDraft = []
        }

        state.lastOpenedDate = today
    }
}
