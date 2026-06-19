import Foundation
import WidgetKit

enum SharedWordState {
    static let appGroupID = "group.com.iankorovinsky.dailychinese"

    private static let manualOffsetKey = "dailyChinese.manualOffset"
    private static let cadenceKey = "dailyChinese.cadence"
    private static let lastRefreshKey = "dailyChinese.lastRefresh"

    static var defaults: UserDefaults {
        UserDefaults(suiteName: appGroupID) ?? .standard
    }

    static func cadence() -> RefreshCadence {
        guard let rawValue = defaults.string(forKey: cadenceKey),
              let cadence = RefreshCadence(rawValue: rawValue) else {
            return .fourHours
        }
        return cadence
    }

    static func setCadence(_ cadence: RefreshCadence) {
        defaults.set(cadence.rawValue, forKey: cadenceKey)
        defaults.set(Date().timeIntervalSince1970, forKey: lastRefreshKey)
    }

    static func currentWord(from words: [ChineseWord], now: Date = Date()) -> ChineseWord {
        guard !words.isEmpty else {
            return ChineseWord(id: 0, simplified: "中", traditional: "中", pinyin: "zhōng", english: "middle; China", notes: nil)
        }

        let slot = currentSlot(now: now, cadence: cadence())
        let manualOffset = defaults.integer(forKey: manualOffsetKey)
        let index = positiveModulo(slot + manualOffset, words.count)
        return words[index]
    }

    @discardableResult
    static func advance(words: [ChineseWord]) -> ChineseWord {
        let nextOffset = defaults.integer(forKey: manualOffsetKey) + 1
        defaults.set(nextOffset, forKey: manualOffsetKey)
        defaults.set(Date().timeIntervalSince1970, forKey: lastRefreshKey)
        WidgetCenter.shared.reloadAllTimelines()
        return currentWord(from: words)
    }

    static func lastRefreshDate() -> Date? {
        let value = defaults.double(forKey: lastRefreshKey)
        guard value > 0 else { return nil }
        return Date(timeIntervalSince1970: value)
    }

    static func nextRefreshDate(after date: Date = Date()) -> Date {
        let calendar = Calendar.current

        switch cadence() {
        case .daily:
            let tomorrow = calendar.date(byAdding: .day, value: 1, to: date) ?? date.addingTimeInterval(24 * 60 * 60)
            return calendar.startOfDay(for: tomorrow)
        case .fourHours:
            let startOfDay = calendar.startOfDay(for: date)
            let hour = calendar.component(.hour, from: date)
            let nextHour = ((hour / 4) + 1) * 4

            if nextHour >= 24 {
                let tomorrow = calendar.date(byAdding: .day, value: 1, to: startOfDay) ?? date.addingTimeInterval(4 * 60 * 60)
                return calendar.startOfDay(for: tomorrow)
            }

            return calendar.date(byAdding: .hour, value: nextHour, to: startOfDay) ?? date.addingTimeInterval(4 * 60 * 60)
        }
    }

    private static func currentSlot(now: Date, cadence: RefreshCadence) -> Int {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: now)
        let dayIndex = Int(floor(startOfDay.timeIntervalSince1970 / (24 * 60 * 60)))

        switch cadence {
        case .daily:
            return dayIndex
        case .fourHours:
            return (dayIndex * 6) + (calendar.component(.hour, from: now) / 4)
        }
    }

    private static func positiveModulo(_ value: Int, _ divisor: Int) -> Int {
        let result = value % divisor
        return result >= 0 ? result : result + divisor
    }
}
