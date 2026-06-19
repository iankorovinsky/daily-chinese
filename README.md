# Daily Chinese

Daily Chinese is a widget-first iOS app for learning one Chinese word at a time.

## Current behavior

- The app and widget use bundled local data in `Shared/words.json`.
- Sentence data is bundled in `Shared/sentences.json`.
- The default cadence changes the displayed word every 4 hours.
- The app supports switching between 4-hour and daily cadence.
- The widget extension exposes separate word and sentence widgets.
- Widgets only support small and large families.
- The app uses local iOS Mandarin speech synthesis for word and sentence playback.

## Local run

1. Open `DailyChinese.xcodeproj` in Xcode.
2. Select the `DailyChinese` scheme.
3. Choose an iOS 17+ simulator.
4. Set your development team/signing if Xcode asks.
5. Run the app, then add the **Daily Chinese** widget to the simulator home screen.

## Notes

- WidgetKit refresh timing is requested, not guaranteed. iOS may delay background refreshes.
- Manual refresh calls `WidgetCenter.reloadAllTimelines()` and is the fastest path for local verification.
- Pronunciation currently uses `AVSpeechSynthesizer`, so no audio files are bundled yet.
- The App Group is currently `group.com.iankorovinsky.dailychinese`; update the entitlements and `SharedWordState.appGroupID` if you change bundle identifiers.

## Expanding the word list

Download CC-CEDICT as `cedict_ts.u8`, then run:

```bash
python3 Tools/build_words_from_cedict.py --cedict /path/to/cedict_ts.u8 --out Shared/words.json --limit 500
```

For a hand-curated order, pass `--terms /path/to/terms.txt` where each line is one simplified character.
