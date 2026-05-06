//
//  SettingsCard.swift
//  beatclikr
//
//  Created by Ben Funk on 5/6/26.
//

import SwiftUI

struct SettingsCard<Content: View, Footer: View>: View {
    private let title: LocalizedStringKey
    private let content: Content
    private let footer: Footer

    init(_ title: LocalizedStringKey, @ViewBuilder content: () -> Content, @ViewBuilder footer: () -> Footer) {
        self.title = title
        self.content = content()
        self.footer = footer()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.footnote)
                .foregroundStyle(.secondary)
                .tracking(1)
                .textCase(.uppercase)
                .padding(.horizontal, 4)
            VStack(spacing: 0) {
                content
            }
            .background(Color(UIColor.secondarySystemGroupedBackground))
            .cornerRadius(16)
            footer
        }
    }
}

extension SettingsCard where Footer == EmptyView {
    init(_ title: LocalizedStringKey, @ViewBuilder content: () -> Content) {
        self.init(title, content: content, footer: { EmptyView() })
    }
}
