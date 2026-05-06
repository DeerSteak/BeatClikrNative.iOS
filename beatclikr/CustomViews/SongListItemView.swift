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

struct SongListItemView<S: SongDisplayable>: View {
    var song: S

    var body: some View {
        VStack(alignment: .leading) {
            Text(song.title ?? String(localized: "Untitled"))
                .bold()
                .font(.title3)
                .truncationMode(.tail)
                .lineLimit(1)
            Text("\(song.artist ?? String(localized: "Unknown")) /  \(FormatterHelper.formatDouble(song.beatsPerMinute ?? 60)) BPM")
        }
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    SongListItemView(song: Song(title: "Jump", artist: "Van Halen", beatsPerMinute: 129, beatsPerMeasure: 4, groove: .eighth))
}
