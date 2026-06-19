//
//  SequenceLoadSheet.swift
//  beatclikr
//
//  Created by Ben Funk on 6/14/26.
//

import SwiftUI

struct SequenceLoadSheet: View {
    let sequences: [SavedSequence]
    let onLoad: (SavedSequence) -> Void
    let onDelete: (SavedSequence) -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                ForEach(sequences) { sequence in
                    Button {
                        onLoad(sequence)
                    } label: {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(sequence.name ?? "Untitled")
                                .font(.headline)
                                .foregroundColor(.primary)
                            Text("\(Int(sequence.tempo ?? 120)) BPM · \(sequence.beatsPerMeasure ?? 4) beats · \(sequence.measuresCount ?? 4) measures · \(sequence.subdivisionsPerBeat ?? 4) subdivisions")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .onDelete { indexSet in
                    indexSet.forEach { onDelete(sequences[$0]) }
                }
            }
            .navigationTitle("Load Sequence")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}
