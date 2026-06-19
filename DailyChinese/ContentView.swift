import AVFoundation
import SwiftUI
import WidgetKit

private enum StudyMode: String, CaseIterable, Identifiable {
    case word
    case sentence

    var id: String { rawValue }

    var title: String {
        switch self {
        case .word: "Word"
        case .sentence: "Sentence"
        }
    }
}

struct ContentView: View {
    private let words = WordDataset.load()
    private let sentences = SentenceDataset.load()

    @State private var mode: StudyMode = .word
    @State private var currentWord: ChineseWord
    @State private var currentSentence: ChineseSentence
    @State private var cadence: RefreshCadence
    @State private var lastWordRefreshDate: Date?
    @State private var lastSentenceRefreshDate: Date?
    @State private var speechSynthesizer = AVSpeechSynthesizer()

    init() {
        let loadedWords = WordDataset.load()
        let loadedSentences = SentenceDataset.load()
        _currentWord = State(initialValue: SharedWordState.currentWord(from: loadedWords))
        _currentSentence = State(initialValue: SharedSentenceState.currentSentence(from: loadedSentences))
        _cadence = State(initialValue: SharedWordState.cadence())
        _lastWordRefreshDate = State(initialValue: SharedWordState.lastRefreshDate())
        _lastSentenceRefreshDate = State(initialValue: SharedSentenceState.lastRefreshDate())
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Picker("Study mode", selection: $mode) {
                    ForEach(StudyMode.allCases) { mode in
                        Text(mode.title).tag(mode)
                    }
                }
                .pickerStyle(.segmented)

                Spacer(minLength: 8)

                if mode == .word {
                    wordView
                } else {
                    sentenceView
                }

                Spacer(minLength: 8)

                controlsView
                statusView
            }
            .padding(24)
            .navigationTitle("Daily Chinese")
            .background(Color(.systemGroupedBackground))
        }
        .onAppear(perform: refreshFromState)
        .onOpenURL(perform: handleWidgetURL)
    }

    private var wordView: some View {
        VStack(spacing: 12) {
            Text(currentWord.displayCharacter)
                .font(.system(size: 112, weight: .semibold, design: .rounded))
                .minimumScaleFactor(0.6)

            Text(currentWord.pinyin)
                .font(.title2)
                .foregroundStyle(.secondary)

            Text(currentWord.english)
                .font(.title3)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            playbackButton {
                speak(currentWord.displayCharacter)
            }
        }
        .frame(maxWidth: .infinity)
    }

    private var sentenceView: some View {
        VStack(spacing: 14) {
            Text(currentSentence.simplified)
                .font(.system(size: 44, weight: .semibold, design: .rounded))
                .multilineTextAlignment(.center)
                .minimumScaleFactor(0.55)

            Text(currentSentence.pinyin)
                .font(.title3)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)

            Text(currentSentence.english)
                .font(.title3)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            playbackButton {
                speak(currentSentence.simplified)
            }
        }
        .frame(maxWidth: .infinity)
    }

    private var controlsView: some View {
        VStack(spacing: 16) {
            Picker("Refresh cadence", selection: $cadence) {
                ForEach(RefreshCadence.allCases) { cadence in
                    Text(cadence.title).tag(cadence)
                }
            }
            .pickerStyle(.segmented)
            .onChange(of: cadence) { _, newValue in
                SharedWordState.setCadence(newValue)
                refreshFromState()
                WidgetCenter.shared.reloadAllTimelines()
            }

            Button {
                refreshCurrentMode()
            } label: {
                Label("Refresh \(mode.title.lowercased()) now", systemImage: "arrow.clockwise")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
    }

    private var statusView: some View {
        VStack(spacing: 8) {
            Text("Widgets refresh \(cadence.shortTitle). iOS may delay background updates.")
                .font(.footnote)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)

            Text(statusText)
                .font(.caption)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
        }
    }

    private var statusText: String {
        let next = SharedWordState.nextRefreshDate().formatted(date: .omitted, time: .shortened)
        let lastRefreshDate = mode == .word ? lastWordRefreshDate : lastSentenceRefreshDate

        if let lastRefreshDate {
            return "Last manual refresh \(lastRefreshDate.formatted(date: .abbreviated, time: .shortened)) · next automatic slot \(next)"
        }

        return "Next automatic slot \(next)"
    }

    private func playbackButton(action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Label("Hear pronunciation", systemImage: "play.circle.fill")
                .font(.headline)
        }
        .buttonStyle(.borderless)
        .padding(.top, 8)
    }

    private func refreshCurrentMode() {
        switch mode {
        case .word:
            currentWord = SharedWordState.advance(words: words)
            lastWordRefreshDate = SharedWordState.lastRefreshDate()
        case .sentence:
            currentSentence = SharedSentenceState.advance(sentences: sentences)
            lastSentenceRefreshDate = SharedSentenceState.lastRefreshDate()
        }
    }

    private func refreshFromState() {
        currentWord = SharedWordState.currentWord(from: words)
        currentSentence = SharedSentenceState.currentSentence(from: sentences)
        cadence = SharedWordState.cadence()
        lastWordRefreshDate = SharedWordState.lastRefreshDate()
        lastSentenceRefreshDate = SharedSentenceState.lastRefreshDate()
    }

    private func handleWidgetURL(_ url: URL) {
        if url.host == "sentence" {
            mode = .sentence
        } else {
            mode = .word
        }
        refreshFromState()
    }

    private func speak(_ text: String) {
        if speechSynthesizer.isSpeaking {
            speechSynthesizer.stopSpeaking(at: .immediate)
        }

        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: "zh-CN")
        utterance.rate = AVSpeechUtteranceDefaultSpeechRate * 0.82
        utterance.pitchMultiplier = 1.0
        speechSynthesizer.speak(utterance)
    }
}

#Preview {
    ContentView()
}
