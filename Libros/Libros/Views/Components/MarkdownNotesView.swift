import SwiftUI

/// A notes editor that toggles between edit mode and markdown preview
struct MarkdownNotesView: View {
    @Binding var text: String
    @State private var isEditing = true

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Spacer()

                Button {
                    isEditing.toggle()
                } label: {
                    Label(
                        isEditing ? "Preview" : "Edit",
                        systemImage: isEditing ? "eye" : "pencil"
                    )
                    .font(.caption)
                }
            }

            if isEditing {
                TextEditor(text: $text)
                    .frame(minHeight: 80)
            } else {
                if text.isEmpty {
                    Text("No notes")
                        .foregroundStyle(.secondary)
                        .italic()
                } else {
                    Text(LocalizedStringKey(text))
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
    }
}
