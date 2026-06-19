//
//  MetronomeContainerView.swift
//  beatclikr
//
//  Created by Ben Funk on 5/5/26.
//

import SwiftUI

struct MetronomeContainerView: View {
    private enum Mode: Hashable { case metronome, polyrhythm, sequencer }

    @State private var selectedMode: Mode = .metronome
    @StateObject private var sequencerViewModel = SequencerViewModel()
    @EnvironmentObject private var metronomeModel: MetronomePlaybackViewModel
    @EnvironmentObject private var polyrhythmModel: PolyrhythmViewModel

    var body: some View {
        NavigationStack {
            Group {
                if selectedMode == .sequencer {
                    SequencerView(viewModel: sequencerViewModel)
                } else {
                    GeometryReader { geo in
                        HStack(spacing: 0) {
                            MetronomeView()
                                .frame(width: geo.size.width)
                            PolyrhythmView()
                                .frame(width: geo.size.width)
                        }
                        .offset(x: selectedMode == .metronome ? 0 : -geo.size.width)
                        .animation(.easeInOut(duration: 0.3), value: selectedMode)
                    }
                    .clipped()
                }
            }
            .onChange(of: selectedMode) { _, newMode in
                switch newMode {
                case .metronome:
                    polyrhythmModel.stop()
                    sequencerViewModel.stop()
                case .polyrhythm:
                    metronomeModel.stop()
                    sequencerViewModel.stop()
                case .sequencer:
                    metronomeModel.stop()
                    polyrhythmModel.stop()
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color(UIColor.systemGroupedBackground), for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Picker("Mode", selection: $selectedMode) {
                        Text("Metronome").tag(Mode.metronome)
                        Text("Polyrhythm").tag(Mode.polyrhythm)
                        Text("Sequencer").tag(Mode.sequencer)
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 310)
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
