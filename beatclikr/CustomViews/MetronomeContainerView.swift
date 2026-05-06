//
//  MetronomeContainerView.swift
//  beatclikr
//
//  Created by Ben Funk on 5/5/26.
//

import SwiftUI

struct MetronomeContainerView: View {
    private enum Mode: Hashable { case instant, polyrhythm }

    @State private var selectedMode: Mode = .instant
    @EnvironmentObject private var metronomeModel: MetronomePlaybackViewModel
    @EnvironmentObject private var polyrhythmModel: PolyrhythmViewModel

    var body: some View {
        NavigationStack {
            GeometryReader { geo in
                HStack(spacing: 0) {
                    InstantMetronomeView()
                        .frame(width: geo.size.width)
                    PolyrhythmView()
                        .frame(width: geo.size.width)
                }
                .offset(x: selectedMode == .instant ? 0 : -geo.size.width)
                .animation(.easeInOut(duration: 0.3), value: selectedMode)
            }
            .clipped()
            .onChange(of: selectedMode) { _, newMode in
                switch newMode {
                case .instant:  polyrhythmModel.stop()
                case .polyrhythm: metronomeModel.stop()
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color(UIColor.systemGroupedBackground), for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Picker("Mode", selection: $selectedMode) {
                        Text("Instant").tag(Mode.instant)
                        Text("Polyrhythm").tag(Mode.polyrhythm)
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 220)
                }
            }
        }
    }
}

#Preview {
    MetronomeContainerView()
        .environmentObject(MetronomePlaybackViewModel())
        .environmentObject(PolyrhythmViewModel())
}
