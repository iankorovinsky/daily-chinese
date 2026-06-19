import Foundation

enum WordDataset {
    static func load() -> [ChineseWord] {
        guard let url = Bundle.main.url(forResource: "words", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let words = try? JSONDecoder().decode([ChineseWord].self, from: data),
              !words.isEmpty else {
            return fallbackWords
        }

        return words
    }

    private static let fallbackWords: [ChineseWord] = [
        ChineseWord(id: 1, simplified: "人", traditional: "人", pinyin: "rén", english: "person; people", notes: nil),
        ChineseWord(id: 2, simplified: "日", traditional: "日", pinyin: "rì", english: "sun; day", notes: nil),
        ChineseWord(id: 3, simplified: "水", traditional: "水", pinyin: "shuǐ", english: "water", notes: nil)
    ]
}
