//
//  CalendarView.swift
//  beatclikr
//
//  Created by Ben Funk on 5/1/26.
//

import SwiftUI

struct CalendarView: View {
    let markedDates: Set<Date>
    @Binding var selectedDate: Date?

    @State private var displayedMonth: Date = {
        let cal = Calendar.current
        return cal.date(from: cal.dateComponents([.year, .month], from: .now))!
    }()

    private let calendar = Calendar.current
    private let gridColumns = Array(repeating: GridItem(.flexible()), count: 7)

    private var firstOfMonth: Date {
        calendar.date(from: calendar.dateComponents([.year, .month], from: displayedMonth))!
    }

    private var daysGrid: [Date?] {
        let leadingBlanks = calendar.component(.weekday, from: firstOfMonth) - 1
        let daysInMonth = calendar.range(of: .day, in: .month, for: firstOfMonth)!.count
        var days: [Date?] = Array(repeating: nil, count: leadingBlanks)
        for i in 0..<daysInMonth {
            days.append(calendar.date(byAdding: .day, value: i, to: firstOfMonth))
        }
        while days.count % 7 != 0 { days.append(nil) }
        return days
    }

    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Button {
                    displayedMonth = calendar.date(byAdding: .month, value: -1, to: displayedMonth)!
                    selectedDate = nil
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.title3)
                        .foregroundStyle(Color.appPrimary)
                }

                Spacer()

                Text(displayedMonth.formatted(.dateTime.month(.wide).year()))
                    .font(.title3.weight(.semibold))

                Spacer()

                Button {
                    displayedMonth = calendar.date(byAdding: .month, value: 1, to: displayedMonth)!
                    selectedDate = nil
                } label: {
                    Image(systemName: "chevron.right")
                        .font(.title3)
                        .foregroundStyle(Color.appPrimary)
                }
            }
            .padding(.horizontal, 4)
            .padding(.bottom, 4)

            LazyVGrid(columns: gridColumns, spacing: 0) {
                ForEach(Array(calendar.veryShortWeekdaySymbols.enumerated()), id: \.offset) { _, symbol in
                    Text(symbol)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                        .padding(.bottom, 4)
                }
            }

            LazyVGrid(columns: gridColumns, spacing: 0) {
                ForEach(Array(daysGrid.enumerated()), id: \.offset) { _, day in
                    if let day {
                        let dayKey = calendar.startOfDay(for: day)
                        CalendarDayCell(
                            day: day,
                            isMarked: markedDates.contains(dayKey),
                            isToday: calendar.isDateInToday(day),
                            isSelected: selectedDate.map { calendar.isDate($0, inSameDayAs: day) } ?? false
                        )
                        .onTapGesture {
                            selectedDate = dayKey
                        }
                    } else {
                        Color.clear.frame(height: 44)
                    }
                }
            }
        }
        .padding(12)
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(16)
        .frame(maxWidth: 400)
        .frame(maxWidth: .infinity)
    }
}

private struct CalendarDayCell: View {
    let day: Date
    let isMarked: Bool
    let isToday: Bool
    let isSelected: Bool

    private var circleBackground: Color {
        if isSelected { return Color.appPrimary }
        if isToday { return Color.accent.opacity(0.18) }
        return .clear
    }

    private var textColor: Color {
        if isSelected { return .white }
        if isToday { return Color.accentColor }
        return .primary
    }

    private var dotColor: Color {
        isMarked ? Color.appPrimary : .clear
    }

    var body: some View {
        VStack(spacing: 2) {
            ZStack {
                Circle()
                    .fill(circleBackground)
                    .frame(width: 32, height: 32)
                Text(day.formatted(.dateTime.day()))
                    .font(isToday ? .callout.bold() : .callout)
                    .foregroundStyle(textColor)
            }
            Circle()
                .fill(dotColor)
                .frame(width: 5, height: 5)
        }
        .frame(maxWidth: .infinity, minHeight: 44)
        .contentShape(Rectangle())
    }
}

#Preview {
    @Previewable @State var selectedDate: Date? = nil

    let cal = Calendar.current
    let today = cal.startOfDay(for: .now)
    let marked: Set<Date> = [
        today,
        cal.date(byAdding: .day, value: -2, to: today)!,
        cal.date(byAdding: .day, value: -5, to: today)!,
        cal.date(byAdding: .day, value: -10, to: today)!
    ]
    
    return CalendarView(markedDates: marked, selectedDate: $selectedDate)
        .padding()
        .background(Color(UIColor.systemGroupedBackground))
}
