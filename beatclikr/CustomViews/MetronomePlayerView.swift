//
//  MetronomePlayerView.swift
//  beatclikr
//
//  Created by Ben Funk on 8/5/23.
//

import SwiftUI
import Awesome


struct MetronomePlayerView: View {
    @EnvironmentObject var model: MetronomePlaybackViewModel
    
    var body: some View {
        if (model.isBeat) {
            AwesomePro.Solid.lightbulbOn.image
                .size(80)
                .foregroundColor(.orange)
        } else {
            AwesomePro.Regular.lightbulb.image
                .size(80)
                .foregroundColor(.black)
        }            
    }
}

#Preview {
    MetronomePlayerView()
        .environmentObject(MetronomePlaybackViewModel())
}
