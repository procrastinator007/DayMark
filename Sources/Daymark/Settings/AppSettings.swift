import Foundation

enum StickyAlignment: String, Codable, CaseIterable {
    case right
    case left

    var title: String {
        switch self {
        case .right: "Right side"
        case .left: "Left side"
        }
    }
}

enum StickyFont: String, Codable, CaseIterable {
    case systemDefault = "System Default"
    case helveticaNeue = "Helvetica Neue"
    case menlo = "Menlo"
    case avenirNext = "Avenir Next"
    case georgia = "Georgia"
}

enum StickyFontSize: String, Codable, CaseIterable {
    case small
    case medium
    case large
    case extraLarge

    var title: String {
        switch self {
        case .small: "Small"
        case .medium: "Medium"
        case .large: "Large"
        case .extraLarge: "Extra Large"
        }
    }

    var bodyPointSize: Double {
        switch self {
        case .small: 13
        case .medium: 15.5
        case .large: 18
        case .extraLarge: 21
        }
    }
}

struct AppSettings: Codable, Equatable {
    var stickyAlignment: StickyAlignment = .right
    var alwaysOnTop = true
    var opacity = 0.78
    var fontName: StickyFont = .systemDefault
    var fontSize: StickyFontSize = .medium

    static let defaults = AppSettings()

    mutating func normalize() {
        opacity = min(1, max(0.4, opacity))
    }
}
