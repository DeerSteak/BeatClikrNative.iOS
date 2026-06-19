//
//  BeatCellView.swift
//  beatclikr
//
//  Created by Ben Funk on 6/11/26.
//

import SwiftUI

struct BeatCellView: View {
    let velocity: UInt8 // 0=off, 1=on (v1 binary; 2-3 reserved for velocity in v4.2)
    let isCurrentStep: Bool
    let isMeasureBoundary: Bool
    let isBeatBoundary: Bool
    let onTap: () -> Void

    private let cellSize: CGFloat = 40

    var body: some View {
        Button(action: onTap) {
            Rectangle()
                .fill(fillColor)
                .frame(width: cellSize, height: cellSize)
                .overlay(Rectangle().stroke(borderColor, lineWidth: borderWidth))
                .overlay(
                    isCurrentStep
                        ? Rectangle().strokeBorder(Color.yellow, lineWidth: 3)
                        : nil,
                )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(velocity > 0 ? "active" : "inactive")
        .accessibilityHint("Tap to toggle")
    }

    private var fillColor: Color {
        velocity > 0 ? Color.appPrimary : Color(UIColor.systemBackground)
    }

    private var borderColor: Color {
        if isMeasureBoundary { return Color.primary }
        if isBeatBoundary { return Color.secondary }
        return Color(UIColor.separator)
    }

    private var borderWidth: CGFloat {
        if isMeasureBoundary { return 2.0 }
        if isBeatBoundary { return 1.5 }
        return 1.0
    }
}
