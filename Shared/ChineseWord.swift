import Foundation

struct ChineseWord: Codable, Equatable, Identifiable {
    let id: Int
    let simplified: String
    let traditional: String
    let pinyin: String
    let english: String
    let notes: String?

    var displayCharacter: String {
        simplified
    }
}

enum RefreshCadence: String, CaseIterable, Identifiable {
    case fourHours
    case daily

    var id: String { rawValue }

    var title: String {
        switch self {
        case .fourHours: "Every 4 hours"
        case .daily: "Daily"
        }
    }

    var shortTitle: String {
        switch self {
        case .fourHours: "4 hours"
        case .daily: "daily"
        }
    }

    var interval: TimeInterval {
        switch self {
        case .fourHours: 4 * 60 * 60
        case .daily: 24 * 60 * 60
        }
    }
}
