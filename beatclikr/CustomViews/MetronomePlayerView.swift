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
        Image(systemName: model.imageName)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(height: size)
    }
}

#Preview {
    MetronomePlayerView()
        .environmentObject(MetronomePlaybackViewModel())
}
