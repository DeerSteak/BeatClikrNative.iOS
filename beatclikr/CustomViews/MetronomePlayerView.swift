//
//  MetronomePlayerView.swift
//  beatclikr
//
//  Created by Ben Funk on 8/5/23.
//

import SwiftUI

struct MetronomePlayerView: View {
    @EnvironmentObject var model: MetronomePlaybackViewModel
    var size: CGFloat = MetronomeConstants.playerViewDefaultSize
    
    var body: some View {
        Image(systemName: ImageConstants.rhythm)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(height: size * model.iconScale)
            .foregroundColor(Color.appPrimary)
            .accessibilityLabel(model.isPlaying ? "Metronome playing" : "Metronome stopped")
            .accessibilityAddTraits(.updatesFrequently)
    }
}

#Preview {
    MetronomePlayerView()
        .environmentObject(MetronomePlaybackViewModel())
}
