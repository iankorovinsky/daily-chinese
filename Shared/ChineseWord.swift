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
