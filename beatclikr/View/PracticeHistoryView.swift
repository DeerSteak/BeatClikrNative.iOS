//
//  PracticeHistoryView.swift
//  beatclikr
//
//  Created by Ben Funk on 5/1/26.
//

import SwiftUI

struct PracticeHistoryView: View {
    @EnvironmentObject private var model: PracticeHistoryViewModel
    @State private var selectedDate: Date? = .now

    var body: some View {
        VStack {
            CalendarView(markedDates:[], selectedDate: $selectedDate)
            Text("Hello, World!")
        }
    }
}

#Preview {
    PracticeHistoryView()
        .environmentObject(PracticeHistoryViewModel())
}
