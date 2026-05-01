//
//  TapTempoButton.swift
//  beatclikr
//

import SwiftUI

struct TapTempoButton: View {
    @Binding var bpm: Double
    var size: CGFloat = MetronomeConstants.playerViewDefaultSize

    @State private var tapTimestamps: [Date] = []

    var body: some View {
        Button(action: recordTap) {
            ZStack {
                Circle()
                    .fill(Color.accent.opacity(0.15))
                    .frame(width: size, height: size)
                Text("TAP\nTEMPO")
                    .font(.caption.bold())
                    .multilineTextAlignment(.center)
                    .foregroundStyle(Color.accent)
                    .tracking(1)
                    .textCase(.uppercase)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Tap Tempo")
    }

    private func recordTap() {
        let now = Date()
        if let last = tapTimestamps.last, now.timeIntervalSince(last) > 2.0 {
            tapTimestamps = []
        }
        tapTimestamps.append(now)
        if tapTimestamps.count > 8 {
            tapTimestamps.removeFirst()
        }
        guard tapTimestamps.count >= 2 else { return }
        let intervals = zip(tapTimestamps, tapTimestamps.dropFirst()).map { $1.timeIntervalSince($0) }
        let avgInterval = intervals.reduce(0, +) / Double(intervals.count)
        let computed = (60.0 / avgInterval).rounded()
        withAnimation {
            bpm = min(MetronomeConstants.maxBPM, max(MetronomeConstants.minBPM, computed))
        }
    }
}

#Preview {
    @Previewable @State var bpm: Double = 120
    TapTempoButton(bpm: $bpm)
}
