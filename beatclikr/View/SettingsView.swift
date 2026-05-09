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
                    // Appearance card
                    SettingsCard("AppearanceTitle") {
                        Toggle(LocalizedStringKey("AlwaysUseDarkTheme"), isOn: alwaysUseDarkThemeBinding)
                            .padding(12)
                    }

                    // Practice Reminders card
                    SettingsCard("PracticeRemindersTitle") {
                        Toggle(LocalizedStringKey("PracticeRemindersLabel"), isOn: $model.sendReminders)
                            .padding(12)
                        if model.sendReminders {
                            Divider().padding(.leading, 12)
                            DatePicker("Reminder Time", selection: $model.reminderTime, displayedComponents: .hourAndMinute)
                                .padding(12)
                        }
                    } footer: {
                        Text("PracticeRemindersDescription")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 4)
                        if model.sendReminders {
                            if model.notificationsBlockedLocally {
                                HStack(spacing: 6) {
                                    Image(systemName: "exclamationmark.triangle.fill")
                                        .foregroundStyle(.orange)
                                    Text("Notifications are blocked on this device. You may still receive them on other devices.")
                                        .font(.footnote)
                                        .foregroundStyle(.secondary)
                                    Spacer()
                                    Button("Open Settings") {
                                        model.openNotificationSettings()
                                    }
                                    .font(.footnote)
                                }
                                .padding(.horizontal, 4)
                            } else if model.notificationsDeferredLocally {
                                HStack(spacing: 6) {
                                    Image(systemName: "bell.slash")
                                        .foregroundStyle(.secondary)
                                    Text("Reminders aren't enabled on this device.")
                                        .font(.footnote)
                                        .foregroundStyle(.secondary)
                                    Spacer()
                                    Button("Enable") {
                                        model.allowRemindersFromOtherDevice()
                                    }
                                    .font(.footnote)
                                }
                                .padding(.horizontal, 4)
                            }
                        }
                    }

                    // Metronome Playback card
                    SettingsCard("MetronomePlaybackTitle") {
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
                    } footer: {
                        Text("MetronomePlaybackDescription")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 4)
                    }

                    // Metronome instruments card
                    SettingsCard("PlaybackInstrumentsMetronomeTitle") {
                        menuRow(label: "Beat") {
                            Menu {
                                Picker("Beat", selection: $model.metronomeBeat) {
                                    ForEach(InstrumentLists.beat) { option in
                                        Text(String(describing: option))
                                    }
                                }
                                .pickerStyle(.inline)
                                .labelsHidden()
                            } label: {
                                menuLabel(model.metronomeBeat.description)
                            }
                        }
                        Divider().padding(.leading, 12)
                        menuRow(label: "Rhythm") {
                            Menu {
                                Picker("Rhythm", selection: $model.metronomeRhythm) {
                                    ForEach(InstrumentLists.rhythm) { option in
                                        Text(String(describing: option))
                                    }
                                }
                                .pickerStyle(.inline)
                                .labelsHidden()
                            } label: {
                                menuLabel(model.metronomeRhythm.description)
                            }
                        }
                    }

                    // Playlist instruments card
                    SettingsCard("PlaybackInstrumentsPlaylistTitle") {
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
                    } footer: {
                        Text("PlaybackInstrumentsDescription")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 4)
                        Rectangle()
                            .foregroundColor(Color(.clear))
                            .frame(height: 5)
                    }

                    // Polyrhythm instruments card
                    SettingsCard("PlaybackInstrumentsPolyrhythmTitle") {
                        menuRow(label: "Beat") {
                            Menu {
                                Picker("Beat", selection: $model.polyrhythmBeat) {
                                    ForEach(InstrumentLists.beat) { option in
                                        Text(String(describing: option))
                                    }
                                }
                                .pickerStyle(.inline)
                                .labelsHidden()
                            } label: {
                                menuLabel(model.polyrhythmBeat.description)
                            }
                        }
                        Divider().padding(.leading, 12)
                        menuRow(label: "Rhythm") {
                            Menu {
                                Picker("Rhythm", selection: $model.polyrhythmRhythm) {
                                    ForEach(InstrumentLists.rhythm) { option in
                                        Text(String(describing: option))
                                    }
                                }
                                .pickerStyle(.inline)
                                .labelsHidden()
                            } label: {
                                menuLabel(model.polyrhythmRhythm.description)
                            }
                        }
                    }

                    // About card
                    SettingsCard("About") {
                        if let buildStr = Bundle.main.infoDictionary?["CFBundleVersion"] as? String,
                           let verStr = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
                        {
                            HStack {
                                Text("Version")
                                    .foregroundStyle(.primary)
                                Spacer()
                                Text("\(verStr) (\(buildStr))")
                                    .foregroundStyle(.secondary)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 10)
                            Divider().padding(.leading, 12)
                            HStack {
                                Text("Copyright")
                                    .foregroundStyle(.primary)
                                Spacer()
                                Text("© \(String(Calendar.current.component(.year, from: Date.now))) Benjamin Funk")
                                    .foregroundStyle(.secondary)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 10)
                        }
                    }
                }
                .padding()
            }
            .background(Color(UIColor.systemGroupedBackground))
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.automatic)
        }
    }

    private var alwaysUseDarkThemeBinding: Binding<Bool> {
        Binding(
            get: { model.alwaysUseDarkTheme },
            set: { newValue in
                var transaction = Transaction()
                transaction.disablesAnimations = true
                withTransaction(transaction) {
                    model.alwaysUseDarkTheme = newValue
                }
            },
        )
    }

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
    SettingsView()
        .environmentObject(SettingsViewModel())
}
