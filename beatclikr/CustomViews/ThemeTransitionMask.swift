//
//  ThemeTransitionMask.swift
//  beatclikr
//
//  Created by Ben Funk on 5/9/26.
//

import SwiftUI

private struct ThemeTransitionMask: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject private var settings: SettingsViewModel

    @State private var lastColorScheme: ColorScheme?
    @State private var overlayColor: Color = .clear
    @State private var overlayOpacity: Double = 0

    func body(content: Content) -> some View {
        content
            .overlay {
                overlayColor
                    .opacity(overlayOpacity)
                    .ignoresSafeArea()
                    .allowsHitTesting(false)
            }
            .onAppear {
                lastColorScheme = colorScheme
            }
            .onChange(of: settings.alwaysUseDarkTheme) { _, _ in
                animateThemeTransition(from: lastColorScheme ?? colorScheme)
                lastColorScheme = colorScheme
            }
            .onChange(of: colorScheme) { _, newValue in
                guard overlayOpacity == 0 else { return }
                lastColorScheme = newValue
            }
    }

    private func animateThemeTransition(from oldColorScheme: ColorScheme) {
        overlayColor = oldColorScheme == .dark ? .black : .white
        overlayOpacity = 1
        withAnimation(.easeInOut(duration: 0.35)) {
            overlayOpacity = 0
        }
    }
}

extension View {
    func themeTransitionMask() -> some View {
        modifier(ThemeTransitionMask())
    }
}
