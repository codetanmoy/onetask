import SwiftUI

struct UndoToastContainer: View {
    let isPresented: Bool
    let undo: () -> Void

    var body: some View {
        if isPresented {
            HStack(spacing: 12) {
                Text("Marked done")
                    .font(.footnote)
                    .foregroundStyle(.primary)

                Spacer(minLength: 0)

                Button("Undo", action: undo)
                    .font(.footnote.weight(.semibold))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(.thinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .padding(.horizontal, 16)
            .padding(.bottom, 8)
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Marked done. Undo.")
            .transition(.move(edge: .bottom).combined(with: .opacity))
        } else {
            EmptyView()
        }
    }
}

