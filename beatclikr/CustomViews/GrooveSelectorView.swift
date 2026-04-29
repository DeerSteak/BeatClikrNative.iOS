import SwiftUI

struct GrooveSelectorView: View {
    @Binding var selection: Groove

    var body: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
            ForEach(Groove.allCases) { groove in
                Button {
                    selection = groove
                } label: {
                    Text(String(describing: groove))
                        .font(.subheadline.bold())
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(selection == groove ? Color.accentColor : Color(.tertiarySystemFill))
                        .foregroundStyle(selection == groove ? Color.white : Color.primary)
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(selection == groove ? .isSelected : [])
            }
        }
    }
}
