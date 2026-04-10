//
//  SettingsView.swift
//  beatclikr
//
//  Created by Ben Funk on 10/12/23.
//

import SwiftUI
import SwiftData

struct SettingsView: View {
    @EnvironmentObject var model: SettingsViewModel
    @Environment(\.modelContext) private var modelContext
    @Query private var songs: [Song]
    @Query private var playlistEntries: [PlaylistEntry]
    
    var body: some View {
        NavigationStack {
        ScrollView {
            VStack(alignment: .leading) {
                Text("iCloud Backup")
                    .font(.title)
                Text("Back up your settings and songs to iCloud. You can restore them on any device.")
                    .font(.caption)
                    .foregroundColor(.secondary)

                if let lastBackup = model.lastBackupDate {
                    Text("Last backup: \(lastBackup.formatted(date: .abbreviated, time: .shortened))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                

                if let error = model.backupError {
                    Text(error)
                        .foregroundColor(.red)
                        .font(.caption)
                }

                if let success = model.backupSuccess {
                    Text(success)
                        .foregroundColor(.green)
                        .font(.caption)
                }

                if !model.checkiCloudAvailability() {
                    Text("iCloud is not available. Please enable iCloud Drive in Settings.")
                        .foregroundColor(.orange)
                        .font(.caption)
                }
                HStack {
                    Button(action: {
                        model.backupToiCloud(songs: songs, playlistEntries: playlistEntries)
                    }) {
                        HStack {
                            if model.isBackingUp {
                                ProgressView()
                                    .progressViewStyle(.circular)
                                    .scaleEffect(0.8)
                            } else {
                                Image(systemName: "icloud.and.arrow.up")
                            }
                            Text("Backup to iCloud")
                        }
                    }
                    .disabled(model.isBackingUp || model.isRestoring || !model.checkiCloudAvailability())

                    Spacer()

                    Button(action: {
                        model.restoreFromiCloud(modelContext: modelContext)
                    }) {
                        HStack {
                            if model.isRestoring {
                                ProgressView()
                                    .progressViewStyle(.circular)
                                    .scaleEffect(0.8)
                            } else {
                                Image(systemName: "icloud.and.arrow.down")
                            }
                            Text("Restore from iCloud")
                        }
                    }
                    .disabled(model.isBackingUp || model.isRestoring || !model.checkiCloudAvailability())
                }
                Text("PracticeRemindersTitle")
                    .font(.title)
                Text("PracticeRemindersDescription")
                Toggle(LocalizedStringKey("PracticeRemindersLabel"), isOn: $model.sendReminders)
                Divider()
                Text("MetronomePlaybackTitle")
                    .font(.title)
                Text("MetronomePlaybackDescription")
                Toggle(LocalizedStringKey("MetronomePlaybackFlashlight"), isOn: $model.useFlashlight)
                Toggle(LocalizedStringKey("MetronomePlaybackVibration"), isOn: $model.useVibration)
                Toggle(LocalizedStringKey("MetronomePlaybackAlwaysMute"), isOn: $model.muteMetronome)
                Divider()
                Text("PlaybackInstrumentsTitle")
                    .font(.title)
                Text("PlaybackInstrumentsDescription")
                Text("PlaybackInstrumentsInstantTitle")
                    .font(.title2)
                Grid(alignment: .leading) {
                    GridRow {
                        Text("Beat")
                        Menu(content: {
                            Picker("Beat", selection: $model.instantBeat) {
                                ForEach(InstrumentLists.beat) {
                                    option in
                                    Text(String(describing: option))
                                }
                            }
                            .pickerStyle(.inline)
                            .labelsHidden()
                        }, label: {
                            RectangleText("\(model.instantBeat.description)", backgroundColor: Color(UIColor.systemBackground), foregroundColor: .appPrimary)
                                
                        })
                    }
                    GridRow {
                        Text("Rhythm")
                        Menu(content: {
                            Picker("Rhythm", selection: $model.instantRhythm) {
                                ForEach(InstrumentLists.beat) {
                                    option in
                                    Text(String(describing: option))
                                }
                            }
                            .pickerStyle(.inline)
                            .labelsHidden()
                        }, label: {
                            RectangleText("\(model.instantRhythm.description)", backgroundColor: Color(UIColor.systemBackground), foregroundColor: .appPrimary)
                        })
                    }
                }
                Divider()
                Text("PlaybackInstrumentsPlaylistTitle")
                    .font(.title2)
                
                Grid(alignment: .leading) {
                    GridRow {
                        Text("Beat")
                        Menu(content: {
                            Picker("Beat", selection: $model.playlistBeat) {
                                ForEach(InstrumentLists.beat) {
                                    option in
                                    Text(String(describing: option))
                                }
                            }
                            .pickerStyle(.inline)
                            .labelsHidden()
                        }, label: {
                            RectangleText("\(model.playlistBeat.description)", backgroundColor: Color(UIColor.systemBackground), foregroundColor: .appPrimary)
                                
                        })
                    }
                    GridRow {
                        Text("Rhythm")
                        Menu(content: {
                            Picker("Rhythm", selection: $model.playlistRhythm) {
                                ForEach(InstrumentLists.beat) {
                                    option in
                                    Text(String(describing: option))
                                }
                            }
                            .pickerStyle(.inline)
                            .labelsHidden()
                        }, label: {
                            RectangleText("\(model.playlistRhythm.description)", backgroundColor: Color(UIColor.systemBackground), foregroundColor: .appPrimary)
                        })
                    }
                }
                Divider()

            }
            .padding()
        }
        .navigationTitle("Settings")
        }
    }
}

#Preview {
    return SettingsView()        
        .environmentObject(SettingsViewModel())
}
