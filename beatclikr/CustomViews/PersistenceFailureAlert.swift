//
//  PersistenceFailureAlert.swift
//  beatclikr
//
//  Created by Ben Funk on 7/26/26.
//

import SwiftUI

private struct PersistenceFailureAlertModifier: ViewModifier {
    let failure: PersistenceFailure?
    let onDismiss: () -> Void

    func body(content: Content) -> some View {
        content.alert(
            "Changes Couldn't Be Saved",
            isPresented: Binding(
                get: { failure != nil },
                set: { if !$0 { onDismiss() } },
            ),
        ) {
            Button("OK", role: .cancel, action: onDismiss)
        } message: {
            if let failure {
                Text(
                    [failure.errorDescription, failure.recoverySuggestion]
                        .compactMap(\.self)
                        .joined(separator: " "),
                )
            }
        }
    }
}

extension View {
    func persistenceFailureAlert(
        _ failure: PersistenceFailure?,
        onDismiss: @escaping () -> Void,
    ) -> some View {
        modifier(PersistenceFailureAlertModifier(failure: failure, onDismiss: onDismiss))
    }
}
