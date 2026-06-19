import Foundation

enum SentenceDataset {
    static func load() -> [ChineseSentence] {
        guard let url = Bundle.main.url(forResource: "sentences", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let sentences = try? JSONDecoder().decode([ChineseSentence].self, from: data),
              !sentences.isEmpty else {
            return fallbackSentences
        }

        return sentences
    }

    private static let fallbackSentences: [ChineseSentence] = [
        ChineseSentence(id: 1, simplified: "你好。", traditional: "你好。", pinyin: "nǐ hǎo", english: "Hello.", notes: nil),
        ChineseSentence(id: 2, simplified: "我爱学习中文。", traditional: "我愛學習中文。", pinyin: "wǒ ài xué xí zhōng wén", english: "I love learning Chinese.", notes: nil)
    ]
}
