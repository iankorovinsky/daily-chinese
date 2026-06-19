import Foundation
import WidgetKit

enum SharedSentenceState {
    private static let manualOffsetKey = "dailyChinese.sentence.manualOffset"
    private static let lastRefreshKey = "dailyChinese.sentence.lastRefresh"

    static var defaults: UserDefaults {
        SharedWordState.defaults
    }

    static func currentSentence(from sentences: [ChineseSentence], now: Date = Date()) -> ChineseSentence {
        guard !sentences.isEmpty else {
            return ChineseSentence(
                id: 0,
                simplified: "我在学习中文。",
                traditional: "我在學習中文。",
                pinyin: "wǒ zài xué xí zhōng wén",
                english: "I am studying Chinese.",
                notes: nil
            )
        }

        let slot = currentSlot(now: now)
        let manualOffset = defaults.integer(forKey: manualOffsetKey)
        let index = positiveModulo(slot + manualOffset, sentences.count)
        return sentences[index]
    }

    @discardableResult
    static func advance(sentences: [ChineseSentence]) -> ChineseSentence {
        let nextOffset = defaults.integer(forKey: manualOffsetKey) + 1
        defaults.set(nextOffset, forKey: manualOffsetKey)
        defaults.set(Date().timeIntervalSince1970, forKey: lastRefreshKey)
        WidgetCenter.shared.reloadAllTimelines()
        return currentSentence(from: sentences)
    }

    static func lastRefreshDate() -> Date? {
        let value = defaults.double(forKey: lastRefreshKey)
        guard value > 0 else { return nil }
        return Date(timeIntervalSince1970: value)
    }

    private static func currentSlot(now: Date) -> Int {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: now)
        let dayIndex = Int(floor(startOfDay.timeIntervalSince1970 / (24 * 60 * 60)))

        switch SharedWordState.cadence() {
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
