//
//  SongListItemView.swift
//  beatclikr
//
//  Created by Ben Funk on 8/7/23.
//

import SwiftUI

protocol SongDisplayable {
    var title: String? { get }
    var artist: String? { get }
    var beatsPerMinute: Double? { get }
}

struct SongPresentation {
    let title: String
    let artist: String
    let beatsPerMinute: Double

    init(_ song: some SongDisplayable) {
        let normalizedTitle = song.title?.trimmingCharacters(in: .whitespacesAndNewlines)
        let normalizedArtist = song.artist?.trimmingCharacters(in: .whitespacesAndNewlines)
        title = normalizedTitle.flatMap { $0.isEmpty ? nil : $0 } ?? String(localized: "Untitled")
        artist = normalizedArtist.flatMap { $0.isEmpty ? nil : $0 } ?? String(localized: "Unknown")
        let candidateBPM = song.beatsPerMinute ?? 60
        beatsPerMinute = candidateBPM.isFinite && candidateBPM > 0 ? candidateBPM : 60
    }
}

struct SongListItemView<S: SongDisplayable>: View {
    var song: S

    var body: some View {
        let presentation = SongPresentation(song)
        VStack(alignment: .leading) {
            Text(presentation.title)
                .bold()
                .font(.title3)
                .truncationMode(.tail)
                .lineLimit(1)
            Text("\(presentation.artist) /  \(FormatterHelper.formatDouble(presentation.beatsPerMinute)) BPM")
        }
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    SongListItemView(song: Song(title: "Jump", artist: "Van Halen", beatsPerMinute: 129, beatsPerMeasure: 4, groove: .eighth))
}
