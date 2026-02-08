import SwiftUI
import SwiftData

/// Form for creating or editing a tag
struct TagEditView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let tag: Tag?

    @State private var name = ""
    @State private var selectedColorHex: String = TagColors.defaultHex

    private var isNewTag: Bool { tag == nil }

    var body: some View {
        Form {
            Section("Tag Information") {
                TextField("Name", text: $name)
            }

            Section("Color") {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 44))], spacing: 12) {
                    ForEach(TagColors.presets, id: \.hex) { preset in
                        Button {
                            selectedColorHex = preset.hex
                        } label: {
                            ZStack {
                                Circle()
                                    .fill(Color(hex: preset.hex))
                                    .frame(width: 36, height: 36)

                                if selectedColorHex == preset.hex {
                                    Image(systemName: "checkmark")
                                        .font(.caption.bold())
                                        .foregroundStyle(.white)
                                }
                            }
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(preset.name)
                    }
                }
                .padding(.vertical, 8)
            }
        }
        .navigationTitle(isNewTag ? "Add Tag" : "Edit Tag")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") {
                    dismiss()
                }
            }

            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    saveTag()
                }
                .disabled(name.isEmpty)
            }
        }
        .onAppear {
            loadTagData()
        }
    }

    // MARK: - Data Methods

    private func loadTagData() {
        if let tag = tag {
            name = tag.name
            selectedColorHex = tag.colorHex ?? TagColors.defaultHex
        }
    }

    private func saveTag() {
        let targetTag: Tag
        if let existing = tag {
            targetTag = existing
        } else {
            targetTag = Tag(name: name, colorHex: selectedColorHex)
            modelContext.insert(targetTag)
        }

        targetTag.name = name
        targetTag.colorHex = selectedColorHex

        dismiss()
    }
}

#Preview {
    NavigationStack {
        TagEditView(tag: nil)
    }
    .modelContainer(.preview)
}
