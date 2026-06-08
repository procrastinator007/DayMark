import Foundation
import Testing
@testable import Daymark

@Test
func parsesTrackedGoal() {
    let goal = GoalParser.parse("Gym 0/7 days")
    #expect(goal?.text == "Gym")
    #expect(goal?.current == 0)
    #expect(goal?.target == 7)
}

@Test
func matchesNaturalLanguage() {
    #expect(ProgressMatcher.matches("I got groceries after work", label: "Get groceries"))
    #expect(!ProgressMatcher.matches("Read a book", label: "Call dentist"))
}

@Test
func sundayDraftBecomesLockedOnNewWeek() {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(secondsFromGMT: 0)!
    let sunday = ISO8601DateFormatter().date(from: "2026-06-07T12:00:00Z")!
    let monday = ISO8601DateFormatter().date(from: "2026-06-08T12:00:00Z")!
    var state = AppState.empty(now: sunday, calendar: calendar)
    state.nextWeekDraft = ["Gym 0/7", "Publish blog"]

    RolloverEngine.apply(to: &state, now: monday, calendar: calendar)

    #expect(state.currentWeekGoals.map(\.text) == ["Gym", "Publish blog"])
    #expect(state.nextWeekDraft.isEmpty)
}

@Test
func tomorrowRollsIntoToday() {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(secondsFromGMT: 0)!
    let monday = ISO8601DateFormatter().date(from: "2026-06-08T12:00:00Z")!
    var state = AppState.empty(now: monday, calendar: calendar)
    state.tomorrowDraft = ["Finish homepage"]

    RolloverEngine.apply(to: &state, now: monday, calendar: calendar)

    #expect(state.days["2026-06-08"]?.plannedTasks.map(\.text) == ["Finish homepage"])
    #expect(state.tomorrowDraft.isEmpty)
}

@Test
func goalCanOnlyBeCreditedOncePerDay() {
    let goal = WeeklyGoal(text: "Gym", current: 0, target: 7)
    let first = ProgressMatcher.detect(
        reflection: "Went to the gym",
        tasks: [],
        goals: [goal],
        alreadyCredited: []
    )
    let second = ProgressMatcher.detect(
        reflection: "Went to the gym",
        tasks: [],
        goals: [goal],
        alreadyCredited: [goal.id]
    )

    #expect(first.goalIDs == [goal.id])
    #expect(second.goalIDs.isEmpty)
}
