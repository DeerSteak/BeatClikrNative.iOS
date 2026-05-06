//
//  CardContainer.swift
//  beatclikr
//
//  Created by Ben Funk on 5/6/26.
//

import SwiftUI

struct CardContainer<Content: View>: View {
    private let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .background(Color(UIColor.secondarySystemGroupedBackground))
            .cornerRadius(16)
    }
}
