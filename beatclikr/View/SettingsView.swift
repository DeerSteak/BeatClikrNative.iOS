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
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    
                    // Practice Reminders card
                    VStack(alignment: .leading, spacing: 6) {
                        Text("PracticeRemindersTitle")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .tracking(1)
                            .textCase(.uppercase)
                            .padding(.horizontal, 4)
                        
                        VStack(spacing: 0) {
                            Toggle(LocalizedStringKey("PracticeRemindersLabel"), isOn: $model.sendReminders)
                                .padding(12)
                            if model.sendReminders {
                                Divider().padding(.leading, 12)
                                DatePicker("Reminder Time", selection: $model.reminderTime, displayedComponents: .hourAndMinute)
                                    .padding(12)
                            }
                        }
                        .background(Color(UIColor.secondarySystemGroupedBackground))
                        .cornerRadius(16)
                        
                        Text("PracticeRemindersDescription")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 4)
                    }
                    
                    // Metronome Playback card
                    VStack(alignment: .leading, spacing: 6) {
                        Text("MetronomePlaybackTitle")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .tracking(1)
                            .textCase(.uppercase)
                            .padding(.horizontal, 4)
                        
                        VStack(spacing: 0) {
                            Toggle(LocalizedStringKey("MetronomePlaybackFlashlight"), isOn: $model.useFlashlight)
                                .padding(12)
                            Divider().padding(.leading, 12)
                            Toggle(LocalizedStringKey("MetronomePlaybackVibration"), isOn: $model.useVibration)
                                .padding(12)
                            Divider().padding(.leading, 12)
                            Toggle(LocalizedStringKey("MetronomePlaybackAlwaysMute"), isOn: $model.muteMetronome)
                                .padding(12)
                            Divider().padding(.leading, 12)
                            Toggle(LocalizedStringKey("KeepAwake"), isOn: $model.keepAwake)
                                .padding(12)
                            Divider().padding(.leading, 12)
                            Toggle(LocalizedStringKey("SixteenthAlternate"), isOn: $model.sixteenthAlternate)
                                .padding(12)
                        }
                        .background(Color(UIColor.secondarySystemGroupedBackground))
                        .cornerRadius(16)
                        
                        Text("MetronomePlaybackDescription")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 4)
                    }
                    
                    // Instant instruments card
                    VStack(alignment: .leading, spacing: 6) {
                        Text("PlaybackInstrumentsInstantTitle")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .tracking(1)
                            .textCase(.uppercase)
                            .padding(.horizontal, 4)
                        
                        VStack(spacing: 0) {
                            menuRow(label: "Beat") {
                                Menu {
                                    Picker("Beat", selection: $model.instantBeat) {
                                        ForEach(InstrumentLists.beat) { option in
                                            Text(String(describing: option))
                                        }
                                    }
                                    .pickerStyle(.inline)
                                    .labelsHidden()
                                } label: {
                                    menuLabel(model.instantBeat.description)
                                }
                            }
                            Divider().padding(.leading, 12)
                            menuRow(label: "Rhythm") {
                                Menu {
                                    Picker("Rhythm", selection: $model.instantRhythm) {
                                        ForEach(InstrumentLists.rhythm) { option in
                                            Text(String(describing: option))
                                        }
                                    }
                                    .pickerStyle(.inline)
                                    .labelsHidden()
                                } label: {
                                    menuLabel(model.instantRhythm.description)
                                }
                            }
                        }
                        .background(Color(UIColor.secondarySystemGroupedBackground))
                        .cornerRadius(16)
                    }
                    
                    // Playlist instruments card
                    VStack(alignment: .leading, spacing: 6) {
                        Text("PlaybackInstrumentsPlaylistTitle")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .tracking(1)
                            .textCase(.uppercase)
                            .padding(.horizontal, 4)
                        
                        VStack(spacing: 0) {
                            menuRow(label: "Beat") {
                                Menu {
                                    Picker("Beat", selection: $model.playlistBeat) {
                                        ForEach(InstrumentLists.beat) { option in
                                            Text(String(describing: option))
                                        }
                                    }
                                    .pickerStyle(.inline)
                                    .labelsHidden()
                                } label: {
                                    menuLabel(model.playlistBeat.description)
                                }
                            }
                            Divider().padding(.leading, 12)
                            menuRow(label: "Rhythm") {
                                Menu {
                                    Picker("Rhythm", selection: $model.playlistRhythm) {
                                        ForEach(InstrumentLists.rhythm) { option in
                                            Text(String(describing: option))
                                        }
                                    }
                                    .pickerStyle(.inline)
                                    .labelsHidden()
                                } label: {
                                    menuLabel(model.playlistRhythm.description)
                                }
                            }
                        }
                        .background(Color(UIColor.secondarySystemGroupedBackground))
                        .cornerRadius(16)
                        
                        Text("PlaybackInstrumentsDescription")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 4)
                    }
                }
                .padding()
            }
            .background(Color(UIColor.systemGroupedBackground))
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.automatic)
        }
        .alert("Notifications Disabled", isPresented: $model.showPermissionDeniedAlert) {
            Button("Open Settings") {
                #if targetEnvironment(macCatalyst)
                if let url = URL(string: "x-apple.systempreferences:com.apple.preference.notifications") {
                    UIApplication.shared.open(url)
                }
                #else
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
                #endif
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Practice reminders require notification permissions. Please enable them in Settings.")
        }
    }
    
    @ViewBuilder
    private func menuRow(label: LocalizedStringKey, @ViewBuilder content: () -> some View) -> some View {
        HStack {
            Text(label)
                .foregroundStyle(.primary)
            Spacer()
            content()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
    }
    
    private func menuLabel(_ text: String) -> some View {
        HStack(spacing: 4) {
            Text(text)
            Image(systemName: ImageConstants.chevronUpDown)
                .font(.caption2)
        }
        .foregroundStyle(Color.accentColor)
    }
}

#Preview {
    return SettingsView()
        .environmentObject(SettingsViewModel())
}
