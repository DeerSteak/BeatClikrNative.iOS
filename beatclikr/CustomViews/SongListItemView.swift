//
//  SongListItemView.swift
//  beatclikr
//
//  Created by Ben Funk on 8/7/23.
//

import SwiftUI

struct SongListItemView: View {
    var song: Song
    
    var body: some View {
        VStack (alignment: .leading) {
            Text(song.title)
                .bold()
                .font(.title3)
                .truncationMode(.tail)
                .lineLimit(1)
            Text("\(song.artist) /  \(FormatterHelper.formatDouble(song.beatsPerMinute)) BPM")
        }
    }
}

#Preview {
    SongListItemView(song: Song(title: "Jump", artist: "Van Halen", beatsPerMinute: 129, beatsPerMeasure: 4, groove: .eighth))
}
