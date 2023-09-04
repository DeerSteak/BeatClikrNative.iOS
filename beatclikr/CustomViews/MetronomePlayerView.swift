//
//  MetronomePlayerView.swift
//  beatclikr
//
//  Created by Ben Funk on 8/5/23.
//

import SwiftUI


struct MetronomePlayerView: View {
    @EnvironmentObject var model: MetronomePlaybackViewModel
    
    var body: some View {
        Image(systemName: model.imageName)
            .resizable()
            .frame(width: 100, height: 100)
            .aspectRatio(contentMode: .fit)
    }
}

#Preview {
    MetronomePlayerView()
        .environmentObject(MetronomePlaybackViewModel())
}
