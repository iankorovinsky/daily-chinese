import AVFoundation
import SwiftUI

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
    @State private var speechSynthesizer = AVSpeechSynthesizer()

    init() {
        let loadedWords = WordDataset.load()
        let loadedSentences = SentenceDataset.load()
        _currentWord = State(initialValue: SharedWordState.currentWord(from: loadedWords))
        _currentSentence = State(initialValue: SharedSentenceState.currentSentence(from: loadedSentences))
    }

    var body: some View {
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

            Button {
                refreshCurrentMode()
            } label: {
                Label("Refresh", systemImage: "arrow.clockwise")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground))
        .onAppear(perform: refreshFromState)
        .onOpenURL(perform: handleWidgetURL)
    }

    private var wordView: some View {
        Button {
            speak(currentWord.displayCharacter)
        } label: {
            studyCard {
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
                }
            }
        }
        .buttonStyle(.plain)
        .frame(maxWidth: .infinity)
    }

    private var sentenceView: some View {
        Button {
            speak(currentSentence.simplified)
        } label: {
            studyCard {
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
                }
            }
        }
        .buttonStyle(.plain)
        .frame(maxWidth: .infinity)
    }

    private func studyCard<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        VStack(spacing: 18) {
            content()

            HStack(spacing: 8) {
                Image(systemName: "speaker.wave.2.fill")
                    .font(.subheadline.weight(.semibold))

                Text("Tap to hear pronunciation")
                    .font(.subheadline.weight(.medium))
            }
            .foregroundStyle(Color.accentColor)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 24)
        .background(.background, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(Color.accentColor, lineWidth: 2)
        )
        .shadow(color: Color.accentColor.opacity(0.08), radius: 12, y: 6)
    }

    private func refreshCurrentMode() {
        switch mode {
        case .word:
            currentWord = SharedWordState.advance(words: words)
        case .sentence:
            currentSentence = SharedSentenceState.advance(sentences: sentences)
        }
    }

    private func refreshFromState() {
        currentWord = SharedWordState.currentWord(from: words)
        currentSentence = SharedSentenceState.currentSentence(from: sentences)
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
