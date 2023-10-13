//
//  SettingsView.swift
//  beatclikr
//
//  Created by Ben Funk on 10/12/23.
//

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var model: SettingsViewModel
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading) {
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
            }
            .padding()
        }
        
    }
}

#Preview {
    return SettingsView()        
        .environmentObject(SettingsViewModel())
}
