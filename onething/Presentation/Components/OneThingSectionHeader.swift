import SwiftUI

struct OneThingSectionHeader: View {
    let title: String

    var body: some View {
        Text(title)
            .font(.caption)
            .foregroundStyle(.secondary)
            .textCase(nil)
    }
}

