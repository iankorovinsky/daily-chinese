import SwiftUI
import WidgetKit

struct WordEntry: TimelineEntry {
    let date: Date
    let word: ChineseWord
    let nextRefreshDate: Date
}

struct SentenceEntry: TimelineEntry {
    let date: Date
    let sentence: ChineseSentence
    let nextRefreshDate: Date
}

struct WordProvider: TimelineProvider {
    private let scheduledEntryCount = 12

    func placeholder(in context: Context) -> WordEntry {
        WordEntry(
            date: Date(),
            word: ChineseWord(id: 1, simplified: "人", traditional: "人", pinyin: "rén", english: "person; people", notes: nil),
            nextRefreshDate: Date().addingTimeInterval(4 * 60 * 60)
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (WordEntry) -> Void) {
        completion(makeEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<WordEntry>) -> Void) {
        let entries = makeTimelineEntries()
        completion(Timeline(entries: entries, policy: .atEnd))
    }

    private func makeEntry(now: Date = Date()) -> WordEntry {
        let words = WordDataset.load()
        return WordEntry(
            date: now,
            word: SharedWordState.currentWord(from: words, now: now),
            nextRefreshDate: SharedWordState.nextRefreshDate(after: now)
        )
    }

    private func makeTimelineEntries(startingAt startDate: Date = Date()) -> [WordEntry] {
        var entries: [WordEntry] = []
        var date = startDate

        for _ in 0..<scheduledEntryCount {
            let entry = makeEntry(now: date)
            entries.append(entry)
            date = entry.nextRefreshDate
        }

        return entries
    }
}

struct SentenceProvider: TimelineProvider {
    private let scheduledEntryCount = 12

    func placeholder(in context: Context) -> SentenceEntry {
        SentenceEntry(
            date: Date(),
            sentence: ChineseSentence(
                id: 1,
                simplified: "你好。",
                traditional: "你好。",
                pinyin: "nǐ hǎo",
                english: "Hello.",
                notes: nil
            ),
            nextRefreshDate: Date().addingTimeInterval(4 * 60 * 60)
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (SentenceEntry) -> Void) {
        completion(makeEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<SentenceEntry>) -> Void) {
        let entries = makeTimelineEntries()
        completion(Timeline(entries: entries, policy: .atEnd))
    }

    private func makeEntry(now: Date = Date()) -> SentenceEntry {
        let sentences = SentenceDataset.load()
        return SentenceEntry(
            date: now,
            sentence: SharedSentenceState.currentSentence(from: sentences, now: now),
            nextRefreshDate: SharedSentenceState.nextRefreshDate(after: now)
        )
    }

    private func makeTimelineEntries(startingAt startDate: Date = Date()) -> [SentenceEntry] {
        var entries: [SentenceEntry] = []
        var date = startDate

        for _ in 0..<scheduledEntryCount {
            let entry = makeEntry(now: date)
            entries.append(entry)
            date = entry.nextRefreshDate
        }

        return entries
    }
}

struct WordWidgetView: View {
    let entry: WordEntry
    @Environment(\.widgetFamily) private var family
    
    var body: some View {
        Group {
            switch family {
            case .accessoryInline:
                Text("\(entry.word.displayCharacter) \(entry.word.pinyin)")
                    .lineLimit(1)
            case .accessoryCircular:
                Text(entry.word.displayCharacter)
                    .font(.system(size: 28, weight: .semibold, design: .rounded))
                    .minimumScaleFactor(0.5)
                    .lineLimit(1)
            case .accessoryRectangular:
                VStack(alignment: .leading, spacing: 2) {
                    Text(entry.word.displayCharacter)
                        .font(.headline.weight(.semibold))
                        .lineLimit(1)
                    Text(entry.word.pinyin)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                    Text(entry.word.english)
                        .font(.caption2)
                        .lineLimit(1)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
            default:
                VStack(spacing: family == .systemSmall ? 8 : 16) {
                    Spacer(minLength: 0)

                    Text(entry.word.displayCharacter)
                        .font(.system(size: family == .systemSmall ? 68 : 132, weight: .semibold, design: .rounded))
                        .minimumScaleFactor(0.45)
                        .lineLimit(1)

                    VStack(spacing: 4) {
                        Text(entry.word.pinyin)
                            .font(family == .systemSmall ? .subheadline : .title2)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)

                        Text(entry.word.english)
                            .font(family == .systemSmall ? .caption : .title3)
                            .multilineTextAlignment(.center)
                            .lineLimit(family == .systemSmall ? 2 : 3)
                            .minimumScaleFactor(0.75)
                    }

                    Spacer(minLength: 0)
                }
                .padding(family == .systemSmall ? 14 : 28)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .containerBackground(.background, for: .widget)
        .widgetURL(URL(string: "dailychinese://word/\(entry.word.id)"))
    }
}

struct SentenceWidgetView: View {
    let entry: SentenceEntry
    @Environment(\.widgetFamily) private var family

    var body: some View {
        Group {
            switch family {
            case .accessoryRectangular:
                accessorySentenceLayout
            default:
                mediumSentenceLayout
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .containerBackground(.background, for: .widget)
        .widgetURL(URL(string: "dailychinese://sentence/\(entry.sentence.id)"))
    }

    private var mediumSentenceLayout: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(entry.sentence.simplified)
                .font(.system(size: 24, weight: .semibold, design: .rounded))
                .lineLimit(1)
                .minimumScaleFactor(0.45)
                .frame(maxWidth: .infinity, alignment: .leading)

            Text(entry.sentence.pinyin)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.55)
                .frame(maxWidth: .infinity, alignment: .leading)

            Text(entry.sentence.english)
                .font(.body)
                .multilineTextAlignment(.leading)
                .lineLimit(1)
                .minimumScaleFactor(0.55)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }

    private var accessorySentenceLayout: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(entry.sentence.simplified)
                .font(.headline.weight(.semibold))
                .lineLimit(1)
                .minimumScaleFactor(0.5)

            Text(entry.sentence.pinyin)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.6)

            Text(entry.sentence.english)
                .font(.caption2)
                .lineLimit(1)
                .minimumScaleFactor(0.65)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    }
}

struct DailyChineseWordWidget: Widget {
    let kind = "DailyChineseWordWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: WordProvider()) { entry in
            WordWidgetView(entry: entry)
        }
        .configurationDisplayName("Chinese Word")
        .description("A refreshed Chinese word.")
        .supportedFamilies([.systemSmall, .systemLarge, .accessoryInline, .accessoryCircular, .accessoryRectangular])
    }
}

struct DailyChineseSentenceWidget: Widget {
    let kind = "DailyChineseSentenceWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: SentenceProvider()) { entry in
            SentenceWidgetView(entry: entry)
        }
        .configurationDisplayName("Chinese Sentence")
        .description("A refreshed Chinese sentence.")
        .supportedFamilies([.systemMedium, .accessoryRectangular])
    }
}

@main
struct DailyChineseWidgets: WidgetBundle {
    var body: some Widget {
        DailyChineseWordWidget()
        DailyChineseSentenceWidget()
    }
}

#Preview(as: .systemSmall) {
    DailyChineseWordWidget()
} timeline: {
    WordEntry(
        date: Date(),
        word: ChineseWord(id: 1, simplified: "人", traditional: "人", pinyin: "rén", english: "person; people", notes: nil),
        nextRefreshDate: Date().addingTimeInterval(4 * 60 * 60)
    )
}
