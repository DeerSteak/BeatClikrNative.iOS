//
//  PlaylistTransportView.swift
//  beatclikr
//
//  Created by Ben Funk on 8/5/23.
//

import SwiftUI

struct PlaylistTransportView: View {
    @EnvironmentObject var metronome: MetronomePlaybackViewModel

    var currentTitle: String? = nil
    var onPlay: (() -> Void)? = nil
    var canGoPrevious: Bool = false
    var onPrevious: (() -> Void)? = nil
    var canGoNext: Bool = false
    var onNext: (() -> Void)? = nil

    var body: some View {
        VStack(spacing: 12) {
            if onPrevious != nil || onNext != nil {
                HStack(spacing: 16) {
                    Button { onPrevious?() } label: {
                        HStack {
                            Image(systemName: ImageConstants.chevronLeft)
                                .font(.title2)
                                .fontWeight(.semibold)
                            Text("Previous")
                                .font(.headline)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(canGoPrevious ? Color.accent : Color.secondary.opacity(0.3))
                        )
                        .foregroundStyle(.white)
                    }
                    .disabled(!canGoPrevious)
                    .accessibilityLabel("Previous Song")

                    playPauseButton

                    Button { onNext?() } label: {
                        HStack {
                            Text("Next")
                                .font(.headline)
                            Image(systemName: ImageConstants.chevronRight)
                                .font(.title2)
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(canGoNext ? Color.accent : Color.secondary.opacity(0.3))
                        )
                        .foregroundStyle(.white)
                    }
                    .disabled(!canGoNext)
                    .accessibilityLabel("Next Song")
                }
                .padding(.horizontal, 16)

                nowPlayingLabel
            } else {
                HStack(spacing: 12) {
                    nowPlayingLabel
                        .frame(maxWidth: .infinity, alignment: .leading)
                    playPauseButton
                }
                .padding(.horizontal, 16)
            }
        }
        .padding(.vertical, 12)
        .background(.regularMaterial)
        .overlay {
            Color.accent
                .opacity(metronome.isPlaying ? metronome.beatPulse * 0.35 : 0)
                .allowsHitTesting(false)
        }
    }

    private var playPauseButton: some View {
        Button {
            if metronome.isPlaying {
                metronome.stop()
            } else {
                onPlay?()
            }
        } label: {
            Image(systemName: metronome.isPlaying ? ImageConstants.pause : ImageConstants.play)
                .font(.title2)
                .fontWeight(.semibold)
                .frame(width: 56, height: 56)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.accent)
                )
                .foregroundStyle(.white)
        }
        .accessibilityLabel(metronome.isPlaying ? "Pause" : "Play")
    }

    private var nowPlayingLabel: some View {
        VStack(spacing: 4) {
            if let title = currentTitle {
                Text("Now Playing")
                    .font(.headline)
                    .foregroundStyle(.primary)
                Text(title)
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
    }
}
