import Foundation

struct DaymarkTask: Codable, Equatable, Identifiable {
    var id = UUID()
    var text: String
    var completed = false
    var completedAt: Date?
}

struct WeeklyGoal: Codable, Equatable, Identifiable {
    var id = UUID()
    var text: String
    var current: Int?
    var target: Int?
    var completed = false
}

struct DayRecord: Codable, Equatable {
    var date: String
    var plannedTasks: [DaymarkTask] = []
    var reflection = ""
    var creditedGoalIDs: Set<UUID> = []
    var loggedAt: Date?
}

struct WeeklyArchive: Codable, Equatable {
    var weekStart: String
    var goals: [WeeklyGoal]
    var createdAt = Date()
}

struct AppState: Codable, Equatable {
    var lastOpenedDate: String
    var currentWeekStart: String
    var currentWeekGoals: [WeeklyGoal] = []
    var nextWeekDraft: [String] = []
    var tomorrowDraft: [String] = []
    var days: [String: DayRecord] = [:]
    var weeklyArchives: [WeeklyArchive] = []

    static func empty(now: Date = Date(), calendar: Calendar = .current) -> AppState {
        AppState(
            lastOpenedDate: DateRules.dateKey(now, calendar: calendar),
            currentWeekStart: DateRules.weekKey(now, calendar: calendar)
        )
    }
}
