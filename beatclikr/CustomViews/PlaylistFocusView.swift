//
//  PlaylistFocusView.swift
//  beatclikr
//
//  Created by Ben Funk on 5/6/26.
//

import SwiftUI

struct PlaylistFocusView: View {
    @EnvironmentObject var metronome: MetronomePlaybackViewModel
    @ObservedObject var model: SongNavigationViewModel

    var entries: [PlaylistEntry]
    var onDismiss: () -> Void

    var body: some View {
        ZStack {
            Color.black
                .ignoresSafeArea()

            GeometryReader { geometry in
                let circleSize = min(geometry.size.width, geometry.size.height) * 0.8
                ScrollView {
                    VStack(spacing: 0) {
                        closeButtonRow
                        Spacer()
                        pulsingCircle(size: circleSize)
                        Spacer()
                        nowPlayingLabel
                        transportRow
                    }
                    .frame(minWidth: geometry.size.width, minHeight: geometry.size.height)
                }
            }
        }
        .preferredColorScheme(.dark) // force light text/icons against the always-black background
    }

    private var closeButtonRow: some View {
        HStack {
            Spacer()
            Button { onDismiss() } label: {
                Image(systemName: "xmark")
                    .font(.body)
                    .fontWeight(.semibold)
                    .foregroundStyle(.secondary)
                    .frame(width: 36, height: 36)
                    .background(Color.secondary.opacity(0.2), in: Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Close")
            .padding(.trailing, 20)
        }
        .padding(.top, 16)
    }

    private func pulsingCircle(size: CGFloat) -> some View {
        ZStack {
            Circle()
                .fill(Color.white.opacity(metronome.beatPulse * 0.1))
                .frame(width: size * 1.25, height: size * 1.25)
                .scaleEffect(0.75 + metronome.beatPulse * 0.25)

            Circle()
                .fill(Color.white.opacity(0.08 + metronome.beatPulse * 0.62))
                .frame(width: size, height: size)
                .scaleEffect(0.7 + metronome.beatPulse * 0.3)
        }
    }

    private var nowPlayingLabel: some View {
        VStack(spacing: 6) {
            if let title = model.currentSongTitle(in: entries) {
                Text("Now Playing")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Text(title)
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
        }
        .padding(.bottom, 28)
    }

    private var transportRow: some View {
        HStack(spacing: 16) {
            Button { model.playPrevious(items: entries, metronome: metronome) } label: {
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
                        .fill(model.canGoPrevious(items: entries) ? Color.white.opacity(0.18) : Color.white.opacity(0.06)),
                )
                .foregroundStyle(model.canGoPrevious(items: entries) ? Color.white : Color.white.opacity(0.35))
            }
            .buttonStyle(.plain)
            .disabled(!model.canGoPrevious(items: entries))
            .accessibilityLabel("Previous Song")

            Button {
                if metronome.isPlaying {
                    metronome.stop()
                } else {
                    model.playOrResume(items: entries, metronome: metronome)
                }
            } label: {
                Image(systemName: metronome.isPlaying ? ImageConstants.pause : ImageConstants.play)
                    .font(.title2)
                    .fontWeight(.semibold)
                    .frame(width: 56, height: 56)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.white.opacity(0.18)),
                    )
                    .foregroundStyle(Color.white)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(metronome.isPlaying ? "Pause" : "Play")

            Button { model.playNext(items: entries, metronome: metronome) } label: {
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
                        .fill(model.canGoNext(items: entries) ? Color.white.opacity(0.18) : Color.white.opacity(0.06)),
                )
                .foregroundStyle(model.canGoNext(items: entries) ? Color.white : Color.white.opacity(0.35))
            }
            .buttonStyle(.plain)
            .disabled(!model.canGoNext(items: entries))
            .accessibilityLabel("Next Song")
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 40)
    }
}
