//
//  MetronomePlayerView.swift
//  beatclikr
//
//  Created by Ben Funk on 8/5/23.
//

import SwiftUI


struct MetronomePlayerView: View {
    @EnvironmentObject var model: MetronomePlaybackViewModel
    var size: CGFloat = 100

    var body: some View {
        Image(systemName: "circle.fill")
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(height: size * model.iconScale)
    }
}

#Preview {
    MetronomePlayerView()
        .environmentObject(MetronomePlaybackViewModel())
}
