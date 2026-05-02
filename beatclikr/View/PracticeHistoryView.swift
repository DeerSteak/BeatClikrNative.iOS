//
//  PracticeHistoryView.swift
//  beatclikr
//
//  Created by Ben Funk on 5/1/26.
//

import SwiftUI
import SwiftData

struct PracticeHistoryView: View {
    @EnvironmentObject private var model: PracticeHistoryViewModel
    @Environment(\.modelContext) private var modelContext
    @State private var selectedDate: Date? = Calendar.current.startOfDay(for: .now)
    @State private var markedDates: Set<Date> = []
    @State private var practicedSongs: [PracticedSong] = []

    private var currentStreak: Int { model.currentStreak(from: markedDates) }
    private var longestStreak: Int { model.longestStreak(from: markedDates) }

    private var currentStreakSubtitle: String {
        guard let start = model.currentStreakStartDate(from: markedDates) else { return String(localized: "Let's go!") }
        return String(format: String(localized: "Since %@"), start.formatted(.dateTime.month().day().year()))
    }

    private var longestStreakSubtitle: String {
        guard let range = model.longestStreakRange(from: markedDates) else { return String(localized: "Let's go!") }
        let fmt = Date.FormatStyle().month(.defaultDigits).day(.defaultDigits).year(.twoDigits)
        if Calendar.current.isDate(range.start, inSameDayAs: range.end) {
            return range.start.formatted(fmt)
        }
        return "\(range.start.formatted(fmt)) – \(range.end.formatted(fmt))"
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                HStack(spacing: 0) {
                    StreakStatView(value: currentStreak, label: "Current Streak", icon: "flame.fill", iconColor: .orange, subtitle: currentStreakSubtitle)
                    Divider().frame(height: 44)
                    StreakStatView(value: longestStreak, label: "Longest Streak", icon: "trophy.fill", iconColor: Color(red: 0.95, green: 0.73, blue: 0.1), subtitle: longestStreakSubtitle)
                }
                .padding(.horizontal, 12)
                .padding(.top, 12)
                .padding(.bottom, 8)
                .background(Color(UIColor.systemGroupedBackground))

                if model.practiceReminderNeeded(from: markedDates) {
                    HStack(spacing: 6) {
                        Image(systemName: "flame.fill")
                            .foregroundStyle(.orange)
                            .font(.subheadline)
                        Text("Practice today to keep your streak going!")
                            .font(.subheadline)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.orange.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .padding(.horizontal, 12)
                    .padding(.bottom, 8)
                    .background(Color(UIColor.systemGroupedBackground))
                }

                CalendarView(markedDates: markedDates, selectedDate: $selectedDate)
                    .padding(.horizontal, 12)
                    .padding(.bottom, 12)
                    .background(Color(UIColor.systemGroupedBackground))

                if let selectedDate {
                    List {
                        Section("Practiced History" + selectedDate.formatted(date: .long, time: .omitted)) {
                            if practicedSongs.isEmpty {
                                Text("No practice recorded")
                                    .foregroundStyle(.secondary)
                            } else {
                                ForEach(practicedSongs) { song in
                                    SongListItemView(song: song)
                                }
                            }
                        }
                    }
                    .scrollContentBackground(.hidden)
                    .background(Color(UIColor.systemGroupedBackground))
                } else {
                    Spacer()
                }
            }
            .background(Color(UIColor.systemGroupedBackground))
            .navigationTitle("Practice History")
            .navigationBarTitleDisplayMode(UIScreen.main.bounds.height < 700 ? .inline : .large)
        }
        .onAppear {
            markedDates = model.markedDates(context: modelContext)
        }
        .onChange(of: selectedDate) { _, newDate in
            guard let newDate else {
                practicedSongs = []
                return
            }
            practicedSongs = model.session(for: newDate, context: modelContext)?.songsPracticed ?? []
        }
    }
}

private struct StreakStatView: View {
    let value: Int
    let label: LocalizedStringKey
    let icon: String
    let iconColor: Color
    let subtitle: String

    var body: some View {
        VStack(spacing: 2) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .foregroundStyle(iconColor)
                    .font(.subheadline)
                Text("\(value) day\(value == 1 ? "" : "s")")
                    .font(.headline)
            }
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(subtitle)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    let preview = PreviewContainer([Song.self, PracticeSession.self, PracticedSong.self])
    preview.addMockPracticeHistory()

    return PracticeHistoryView()
        .modelContainer(preview.container)
        .environmentObject(PracticeHistoryViewModel())
}
