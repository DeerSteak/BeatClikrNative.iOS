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

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                HStack(spacing: 0) {
                    StreakStatView(value: model.currentStreak, label: "Current Streak", icon: ImageConstants.streak, iconColor: .orange, subtitle: model.currentStreakSubtitle)
                    Divider().frame(height: 44)
                    StreakStatView(value: model.longestStreak, label: "Longest Streak", icon: ImageConstants.trophy, iconColor: Color(red: 0.95, green: 0.73, blue: 0.1), subtitle: model.longestStreakSubtitle)
                }
                .padding(.horizontal, 12)
                .padding(.top, 12)
                .padding(.bottom, 8)
                .background(Color(UIColor.systemGroupedBackground))

                if model.reminderNeeded {
                    HStack(spacing: 6) {
                        Image(systemName: ImageConstants.streak)
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

                CalendarView(markedDates: model.practiceDates, selectedDate: $selectedDate)
                    .padding(.horizontal, 12)
                    .padding(.bottom, 12)
                    .background(Color(UIColor.systemGroupedBackground))

                if let selectedDate {
                    List {
                        Section("Practice History for " + selectedDate.formatted(date: .long, time: .omitted)) {
                            if model.selectedDateSongs.isEmpty {
                                Text("No practice recorded")
                                    .foregroundStyle(.secondary)
                            } else {
                                ForEach(model.selectedDateSongs) { song in
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
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    if let image = makeShareImage() {
                        ShareLink(
                            item: Image(uiImage: image),
                            subject: Text("My Practice Streak"),
                            message: Text(model.shareText),
                            preview: SharePreview("Practice Streak", image: Image(uiImage: image))
                        ) {
                            Label("Share", systemImage: ImageConstants.share)
                        }
                    }
                }
            }
        }
        .onAppear {
            model.loadPracticeDates(context: modelContext)
            model.loadSongs(for: selectedDate, context: modelContext)
        }
        .onChange(of: selectedDate) { _, newDate in
            model.loadSongs(for: newDate, context: modelContext)
        }
    }

    @MainActor
    func makeShareImage() -> UIImage? {
        let card = SharableStreakCard(streakDays: String(model.longestStreak))
        let renderer = ImageRenderer(content: card)
        renderer.proposedSize = .init(width: 360, height: 360)
        renderer.scale = min(UIScreen.main.scale * 2, 3)
        renderer.isOpaque = false
        return renderer.uiImage
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
