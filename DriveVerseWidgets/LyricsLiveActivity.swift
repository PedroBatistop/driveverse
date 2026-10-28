#if canImport(ActivityKit) && canImport(WidgetKit)
import WidgetKit
import SwiftUI
import ActivityKit

@main
struct DriveVerseWidgetsBundle: WidgetBundle {
    var body: some Widget {
        LyricsLiveActivity()
    }
}

struct LyricsLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: LyricsAttributes.self) { context in
            // Lock screen — on iOS 26 this same presentation is shown on the
            // CarPlay screen, so it stays high-contrast and sparse:
            // one small meta row, two text rows, a progress bar.
            LockScreenLyricsView(context: context)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Image(systemName: context.state.isPlaying ? "music.note" : "pause.fill")
                        .font(.title3)
                        .foregroundStyle(.tint)
                        .padding(.leading, 4)
                }
                DynamicIslandExpandedRegion(.center) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(context.state.currentLine)
                            .font(.headline)
                            .lineLimit(2)
                            .minimumScaleFactor(0.8)
                        Text(context.state.nextLine)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }
                DynamicIslandExpandedRegion(.bottom) {
                    ProgressView(value: context.state.progress)
                        .tint(.white.opacity(0.85))
                        .padding(.horizontal, 4)
                }
            } compactLeading: {
                Image(systemName: context.state.isPlaying ? "music.note" : "pause.fill")
                    .foregroundStyle(.tint)
            } compactTrailing: {
                Text(context.state.currentLine)
                    .font(.caption2)
                    .lineLimit(1)
                    .frame(maxWidth: 72)
            } minimal: {
                Image(systemName: "music.note")
                    .foregroundStyle(.tint)
            }
        }
        // CarPlay (and the Watch Smart Stack) render the .small family;
        // without this opt-in they fall back to the compact Dynamic Island
        // views, which truncate the lyric to one short marquee.
        .supplementalActivityFamilies([.small])
    }
}

struct LockScreenLyricsView: View {
    let context: ActivityViewContext<LyricsAttributes>
    @Environment(\.activityFamily) private var family

    var body: some View {
        Group {
            if family == .small {
                smallBody
            } else {
                mediumBody
            }
        }
        .activityBackgroundTint(Color.black.opacity(0.75))
        .activitySystemActionForegroundColor(.white)
    }

    /// CarPlay tile / Watch Smart Stack: no room for meta chrome — the
    /// lyric IS the content. Two rows, high contrast. No progress bar:
    /// an observer app can't seek, so it would never be interactive and
    /// only steals space from the lyric.
    private var smallBody: some View {
        configurableLyrics
            .padding(8)
            .animation(.smooth(duration: 0.3), value: context.state.currentLine)
    }

    private var configurableLyrics: some View {
        let state = context.state
        let previous = Array(state.previousLines.suffix(max(0, state.previousCount)))
        let upcoming = Array(state.upcomingLines.prefix(max(0, state.upcomingCount)))
        return ViewThatFits(in: .vertical) {
            lyricsStack(previous: previous, upcoming: upcoming, fontSize: state.lyricFontSize)
            // Keep requested previous lines before dropping them for upcoming ones.
            lyricsStack(previous: previous, upcoming: [], fontSize: state.lyricFontSize)
            lyricsStack(previous: [], upcoming: upcoming, fontSize: state.lyricFontSize)
            lyricsStack(previous: [], upcoming: [], fontSize: state.lyricFontSize)
        }
    }

    private func lyricsStack(previous: [String], upcoming: [String], fontSize: Double) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            ForEach(Array(previous.enumerated()), id: \.offset) { _, line in
                Text(line)
                    .font(.system(size: max(9, fontSize * 0.65)))
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Text(context.state.currentLine)
                .font(.system(size: fontSize, weight: .bold))
                .foregroundStyle(.primary)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
            ForEach(Array(upcoming.enumerated()), id: \.offset) { _, line in
                Text(line)
                    .font(.system(size: max(9, fontSize * 0.7)))
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private var mediumBody: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Image(systemName: context.state.isPlaying ? "music.note" : "pause.fill")
                    .font(.caption2)
                Text(context.state.artist.isEmpty
                     ? context.state.title
                     : "\(context.state.title) — \(context.state.artist)")
                    .font(.caption)
                    .lineLimit(1)
                Spacer(minLength: 4)
                if !context.state.sourceName.isEmpty {
                    Text(context.state.sourceName)
                        .font(.caption2.bold())
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(.white.opacity(0.15), in: Capsule())
                }
            }
            .foregroundStyle(.secondary)

            Text(context.state.currentLine)
                .font(.title2.bold())
                .lineLimit(2)
                .minimumScaleFactor(0.75)

            Text(context.state.nextLine)
                .font(.callout)
                .foregroundStyle(.secondary)
                .lineLimit(1)

            ProgressView(value: context.state.progress)
                .tint(.white.opacity(0.85))
        }
        .padding(14)
    }
}
#endif
