//
//  MetronomeContainerView.swift
//  beatclikr
//

import SwiftUI

/// iPhone-only container that presents Instant and Polyrhythm as top tabs
/// inside a single NavigationStack, so both metronome modes share one bottom tab.
struct MetronomeContainerView: View {
    private enum Mode: Hashable { case instant, polyrhythm }

    @State private var selectedMode: Mode = .instant
    @EnvironmentObject private var polyrhythmModel: PolyrhythmViewModel

    var body: some View {
        NavigationStack {
            Group {
                if selectedMode == .instant {
                    InstantMetronomeView()
                } else {
                    PolyrhythmView()
                }
            }
            .navigationBarTitleDisplayMode(.inline)
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
