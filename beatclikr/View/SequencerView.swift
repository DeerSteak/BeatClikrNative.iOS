//
//  SequencerView.swift
//  beatclikr
//
//  Created by Ben Funk on 6/10/26.
//

import SwiftData
import SwiftUI

struct SequencerView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var viewModel: SequencerViewModel
    @State private var showConfig = false
    @State private var showSaveDialog = false
    @State private var showLoadSheet = false
    @State private var sequenceName = ""

    init(viewModel: SequencerViewModel? = nil) {
        _viewModel = StateObject(wrappedValue: viewModel ?? SequencerViewModel())
    }

    var body: some View {
        VStack(spacing: 0) {
            controlBar
            SequencerGridView(viewModel: viewModel)
        }
        .toolbar {
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                saveLoadMenu
            }
        }
        .sheet(isPresented: $showConfig) {
            NavigationStack {
                SequencerConfigView(viewModel: viewModel)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button("Done") { showConfig = false }
                        }
                    }
            }
        }
        .alert("Save Sequence", isPresented: $showSaveDialog) {
            TextField("Name", text: $sequenceName)
            Button("Save") {
                try? viewModel.saveSequence(name: sequenceName, context: modelContext)
                sequenceName = ""
            }
            Button("Cancel", role: .cancel) { sequenceName = "" }
        }
        .sheet(isPresented: $showLoadSheet) {
            SequenceLoadSheet(
                sequences: viewModel.savedSequences,
                onLoad: { sequence in
                    viewModel.loadSequence(sequence)
                    showLoadSheet = false
                },
                onDelete: { sequence in
                    viewModel.deleteSequence(sequence, context: modelContext)
                },
            )
        }
        .onAppear {
            viewModel.fetchSavedSequences(context: modelContext)
        }
        .onDisappear {
            viewModel.stop()
        }
    }

    private var controlBar: some View {
        HStack {
            Button {
                viewModel.isPlaying ? viewModel.stop() : viewModel.play()
            } label: {
                Image(systemName: viewModel.isPlaying ? "stop.fill" : "play.fill")
                    .font(.title2)
                    .frame(width: 44, height: 44)
            }

            Spacer()

            Button { showConfig = true } label: {
                Image(systemName: "slider.horizontal.3")
                    .font(.title2)
                    .frame(width: 44, height: 44)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Color(UIColor.systemGroupedBackground))
    }

    private var saveLoadMenu: some View {
        Menu {
            Button { showSaveDialog = true } label: {
                Label("Save Sequence", systemImage: "square.and.arrow.down")
            }
            Button { showLoadSheet = true } label: {
                Label("Load Sequence", systemImage: "folder")
            }
            .disabled(viewModel.savedSequences.isEmpty)
        } label: {
            Image(systemName: "ellipsis.circle")
        }
    }
}
