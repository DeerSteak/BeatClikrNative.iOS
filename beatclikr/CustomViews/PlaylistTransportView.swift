//
//  PlaylistTransportView.swift
//  beatclikr
//

import SwiftUI
import SwiftData

struct PlaylistTransportView: View {

    @EnvironmentObject var model: PlaylistModeViewModel
    @EnvironmentObject var metronome: MetronomePlaybackViewModel
    let entries: [PlaylistEntry]

    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 16) {
                Button {
                    model.playPrevious(entries: entries, metronome: metronome)
                } label: {
                    HStack {
                        Image(systemName: "chevron.left")
                            .font(.title2)
                            .fontWeight(.semibold)
                        Text("Previous")
                            .font(.headline)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(model.canGoPrevious(entries: entries) ? Color.accentColor : Color.secondary.opacity(0.3))
                    )
                    .foregroundStyle(.white)
                }
                .disabled(!model.canGoPrevious(entries: entries))
                .accessibilityLabel("Previous Song")

                Button(action: metronome.stop) {
                    Image(systemName: "pause.fill")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .frame(width: 56, height: 56)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(metronome.isPlaying ? Color.accentColor : Color.secondary.opacity(0.3))
                        )
                        .foregroundStyle(.white)
                }
                .accessibilityLabel("Stop Metronome")
                .disabled(!metronome.isPlaying)

                Button {
                    model.playNext(entries: entries, metronome: metronome)
                } label: {
                    HStack {
                        Text("Next")
                            .font(.headline)
                        Image(systemName: "chevron.right")
                            .font(.title2)
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(model.canGoNext(entries: entries) ? Color.accentColor : Color.secondary.opacity(0.3))
                    )
                    .foregroundStyle(.white)
                }
                .disabled(!model.canGoNext(entries: entries))
                .accessibilityLabel("Next Song")
            }
            .padding(.horizontal, 16)

            // Current song indicator
            VStack(spacing: 4) {
                if let currentIndex = model.currentSongIndex,
                   currentIndex < entries.count,
                   let currentSong = entries[currentIndex].song {
                    Text("Now Playing")
                        .font(.headline)
                        .foregroundStyle(.primary)
                    Text(currentSong.title ?? "Untitled")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .lineLimit(1)
                } else {
                    Text("Tap a song to begin")
                        .font(.headline)
                        .foregroundStyle(.primary)
                    Text("--")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .lineLimit(1)
                }
            }
            .padding(.vertical, 8)
        }
        .padding(.vertical, 12)
        .background(.regularMaterial)
        .overlay {
            Color.accentColor
                .opacity(metronome.isPlaying ? metronome.beatPulse * 0.35 : 0)
                .allowsHitTesting(false)
        }
    }
}
