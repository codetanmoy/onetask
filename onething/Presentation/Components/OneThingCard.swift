import SwiftUI

struct OneThingCard<Content: View>: View {
    private let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color(.secondarySystemGroupedBackground))
            )
            .overlay {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(Color(.separator).opacity(0.25), lineWidth: 1)
            }
    }
}

#Preview {
    OneThingCard {
        VStack(alignment: .leading, spacing: 8) {
            Text("One thing").font(.caption).foregroundStyle(.secondary)
            Text("Ship a calm iOS-native UI").font(.title3).fontWeight(.semibold)
        }
    }
    .padding()
    .background(Color(.systemGroupedBackground))
}

