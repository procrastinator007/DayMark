import Foundation

@MainActor
final class DaymarkStore {
    typealias Observer = (AppState) -> Void

    private(set) var state: AppState
    private var observers: [UUID: Observer] = [:]
    private let fileURL: URL
    private let calendar: Calendar

    init(
        fileURL: URL = DaymarkStore.defaultFileURL(),
        now: Date = Date(),
        calendar: Calendar = .current
    ) {
        self.fileURL = fileURL
        self.calendar = calendar
        self.state = Self.load(from: fileURL) ?? .empty(now: now, calendar: calendar)
        RolloverEngine.apply(to: &state, now: now, calendar: calendar)
        save()
    }

    @discardableResult
    func observe(_ observer: @escaping Observer) -> UUID {
        let id = UUID()
        observers[id] = observer
        observer(state)
        return id
    }

    func update(_ mutation: (inout AppState) -> Void) {
        mutation(&state)
        save()
        notifyObservers()
    }

    func refreshForCurrentDate(now: Date = Date()) {
        RolloverEngine.apply(to: &state, now: now, calendar: calendar)
        save()
        notifyObservers()
    }

    func recordReflection(_ text: String, now: Date = Date()) {
        let key = DateRules.dateKey(now, calendar: calendar)
        update { state in
            guard var day = state.days[key] else { return }
            day.reflection = text
            state.days[key] = day
        }
    }

    func commitToday(now: Date = Date()) -> Int {
        let key = DateRules.dateKey(now, calendar: calendar)
        var changed = 0
        update { state in
            guard var day = state.days[key] else { return }
            let matches = ProgressMatcher.detect(
                reflection: day.reflection,
                tasks: day.plannedTasks,
                goals: state.currentWeekGoals,
                alreadyCredited: day.creditedGoalIDs
            )

            for index in day.plannedTasks.indices where matches.taskIDs.contains(day.plannedTasks[index].id) {
                day.plannedTasks[index].completed = true
                day.plannedTasks[index].completedAt = now
                changed += 1
            }
            for index in state.currentWeekGoals.indices where matches.goalIDs.contains(state.currentWeekGoals[index].id) {
                if let target = state.currentWeekGoals[index].target {
                    state.currentWeekGoals[index].current = min(
                        target,
                        (state.currentWeekGoals[index].current ?? 0) + 1
                    )
                } else {
                    state.currentWeekGoals[index].completed = true
                }
                day.creditedGoalIDs.insert(state.currentWeekGoals[index].id)
                changed += 1
            }
            day.loggedAt = now
            state.days[key] = day
        }
        return changed
    }

    func exportSnapshot(to url: URL) throws {
        let data = try JSONEncoder.daymark.encode(state)
        try data.write(to: url, options: .atomic)
    }

    static func defaultFileURL() -> URL {
        let base = FileManager.default.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        )[0]
        return base.appendingPathComponent("Daymark/daymark.json")
    }

    private static func load(from url: URL) -> AppState? {
        guard let data = try? Data(contentsOf: url) else { return nil }
        return try? JSONDecoder.daymark.decode(AppState.self, from: data)
    }

    private func save() {
        do {
            try FileManager.default.createDirectory(
                at: fileURL.deletingLastPathComponent(),
                withIntermediateDirectories: true
            )
            try JSONEncoder.daymark.encode(state).write(to: fileURL, options: .atomic)
        } catch {
            let message = "Daymark could not save: \(error)\n"
            FileHandle.standardError.write(Data(message.utf8))
        }
    }

    private func notifyObservers() {
        observers.values.forEach { $0(state) }
    }
}

extension JSONEncoder {
    static var daymark: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }
}

extension JSONDecoder {
    static var daymark: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }
}
