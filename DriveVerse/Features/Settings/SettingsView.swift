import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var model: AppModel
    @AppStorage(AppModel.pollIntervalKey) private var pollInterval: Double = 5
    @State private var cacheCleared = false
    @AppStorage("lyricsPreviousCount") private var previousCount = 0
    @AppStorage("lyricsUpcomingCount") private var upcomingCount = 1
    @AppStorage("lyricsFontSize") private var lyricFontSize = 22.0

    var body: some View {
        Form {
            Section {
                Picker("Preferred source", selection: pinBinding) {
                    ForEach(SourcePin.allCases) { pin in
                        Text(pin.displayName).tag(pin)
                    }
                }
            } header: {
                Text("Source")
            } footer: {
                Text("Automatic prefers Apple Music whenever it's playing (local, exact position), otherwise Spotify. Pin a source to ignore the other.")
            }

            Section {
                VStack(alignment: .leading) {
                    HStack {
                        Text("Poll interval")
                        Spacer()
                        Text("\(Int(pollInterval)) s")
                            .foregroundStyle(.secondary)
                            .monospacedDigit()
                    }
                    Slider(value: $pollInterval, in: 3...10, step: 1)
                }
                if model.spotifyConnected {
                    Button("Disconnect Spotify", role: .destructive) {
                        model.disconnectSpotify()
                    }
                }
            } header: {
                Text("Spotify")
            } footer: {
                Text("How often DriveVerse asks Spotify what's playing. Lower is snappier; higher saves battery and API quota. Between reports, lyric timing is extrapolated locally.")
            }

            Section {
                Stepper("Previous lines: \(previousCount)", value: $previousCount, in: 0...10)
                Stepper("Upcoming lines: \(upcomingCount)", value: $upcomingCount, in: 0...10)
                VStack(alignment: .leading) {
                    HStack {
                        Text("Lyric font size")
                        Spacer()
                        Text("\(Int(lyricFontSize)) pt").foregroundStyle(.secondary)
                    }
                    Slider(value: $lyricFontSize, in: 10...42, step: 1)
                }
            } header: {
                Text("CarPlay lyrics")
            } footer: {
                Text("Set either line count to zero to hide those lines. Long lyrics wrap onto additional lines when space permits. CarPlay controls the tile's physical size, so extra content may not fit.")
            }
            .onChange(of: previousCount) { _, _ in model.refreshLyricsPreferences() }
            .onChange(of: upcomingCount) { _, _ in model.refreshLyricsPreferences() }
            .onChange(of: lyricFontSize) { _, _ in model.refreshLyricsPreferences() }

            Section {
                Button("Clear lyrics cache") {
                    model.clearLyricsCache()
                    cacheCleared = true
                }
                if cacheCleared {
                    Label("Cache cleared", systemImage: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                }
            } header: {
                Text("Lyrics")
            } footer: {
                Text("Lyrics come from LRCLIB and are cached on this device for at most 30 days.")
            }

            Section {
                EmptyView()
            } header: {
                Text("Drive Mode & battery")
            } footer: {
                Text("Drive Mode keeps DriveVerse awake in the background using a low-power location session, so lyrics keep updating on CarPlay and the lock screen while you drive. Locations are discarded immediately and never stored. It uses extra battery, so it's opt-in. This approach is fine for a personal sideloaded app but would not pass App Store review.")
            }

            Section {
                EmptyView()
            } header: {
                Text("About")
            } footer: {
                Text("DriveVerse is a personal-use app. Lyrics are fetched from the community-run LRCLIB API for private, non-commercial display. Do not distribute this app without a licensed lyrics provider.")
            }
        }
        .navigationTitle("Settings")
#if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
#endif
    }

    private var pinBinding: Binding<SourcePin> {
        Binding(get: { model.sourcePin }, set: { model.sourcePin = $0 })
    }
}
