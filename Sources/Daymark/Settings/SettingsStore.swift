import Foundation

@MainActor
final class SettingsStore {
    typealias Observer = (AppSettings) -> Void

    private(set) var settings: AppSettings
    private var observers: [UUID: Observer] = [:]
    private let fileURL: URL

    init(fileURL: URL = SettingsStore.defaultFileURL()) {
        self.fileURL = fileURL
        self.settings = Self.load(from: fileURL) ?? .defaults
        self.settings.normalize()
        save()
    }

    @discardableResult
    func observe(_ observer: @escaping Observer) -> UUID {
        let id = UUID()
        observers[id] = observer
        observer(settings)
        return id
    }

    func update(_ mutation: (inout AppSettings) -> Void) {
        mutation(&settings)
        settings.normalize()
        save()
        observers.values.forEach { $0(settings) }
    }

    func saveNow() {
        save()
    }

    static func defaultFileURL() -> URL {
        let base = FileManager.default.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        )[0]
        return base.appendingPathComponent("Daymark/settings.json")
    }

    private static func load(from url: URL) -> AppSettings? {
        guard let data = try? Data(contentsOf: url) else { return nil }
        return try? JSONDecoder().decode(AppSettings.self, from: data)
    }

    private func save() {
        do {
            try FileManager.default.createDirectory(
                at: fileURL.deletingLastPathComponent(),
                withIntermediateDirectories: true
            )
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            try encoder.encode(settings).write(to: fileURL, options: .atomic)
        } catch {
            let message = "Daymark could not save settings: \(error)\n"
            FileHandle.standardError.write(Data(message.utf8))
        }
    }
}
