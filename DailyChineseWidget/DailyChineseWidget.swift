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
        let entry = makeEntry()
        completion(Timeline(entries: [entry], policy: .after(entry.nextRefreshDate)))
    }

    private func makeEntry(now: Date = Date()) -> WordEntry {
        let words = WordDataset.load()
        return WordEntry(
            date: now,
            word: SharedWordState.currentWord(from: words, now: now),
            nextRefreshDate: SharedWordState.nextRefreshDate(after: now)
        )
    }
}

struct SentenceProvider: TimelineProvider {
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
        let entry = makeEntry()
        completion(Timeline(entries: [entry], policy: .after(entry.nextRefreshDate)))
    }

    private func makeEntry(now: Date = Date()) -> SentenceEntry {
        let sentences = SentenceDataset.load()
        return SentenceEntry(
            date: now,
            sentence: SharedSentenceState.currentSentence(from: sentences, now: now),
            nextRefreshDate: SharedWordState.nextRefreshDate(after: now)
        )
    }
}

struct WordWidgetView: View {
    let entry: WordEntry
    @Environment(\.widgetFamily) private var family

    var body: some View {
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
        .containerBackground(.background, for: .widget)
        .widgetURL(URL(string: "dailychinese://word/\(entry.word.id)"))
    }
}

struct SentenceWidgetView: View {
    let entry: SentenceEntry
    @Environment(\.widgetFamily) private var family

    var body: some View {
        VStack(spacing: family == .systemSmall ? 8 : 18) {
            Spacer(minLength: 0)

            Text(entry.sentence.simplified)
                .font(.system(size: family == .systemSmall ? 24 : 42, weight: .semibold, design: .rounded))
                .multilineTextAlignment(.center)
                .lineLimit(family == .systemSmall ? 3 : 4)
                .minimumScaleFactor(0.55)

            VStack(spacing: 5) {
                Text(entry.sentence.pinyin)
                    .font(family == .systemSmall ? .caption : .title3)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(family == .systemSmall ? 2 : 3)
                    .minimumScaleFactor(0.65)

                Text(entry.sentence.english)
                    .font(family == .systemSmall ? .caption2 : .body)
                    .multilineTextAlignment(.center)
                    .lineLimit(family == .systemSmall ? 2 : 3)
                    .minimumScaleFactor(0.7)
            }

            Spacer(minLength: 0)
        }
        .padding(family == .systemSmall ? 12 : 28)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .containerBackground(.background, for: .widget)
        .widgetURL(URL(string: "dailychinese://sentence/\(entry.sentence.id)"))
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
        .supportedFamilies([.systemSmall, .systemLarge])
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
        .supportedFamilies([.systemSmall, .systemLarge])
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
