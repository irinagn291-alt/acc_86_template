import SwiftUI

struct SwingEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var services: PenduloraServices

    let existing: SwingSet?
    let onSave: () -> Void

    @State private var name = ""
    @State private var description = ""
    @State private var category: SwingCategory = .ritual
    @State private var segmentTitles: [String] = ["", "", ""]

    var body: some View {
        NavigationStack {
            Form {
                Section("Details") {
                    TextField("Set name", text: $name)
                    TextField("Description", text: $description)
                    Picker("Category", selection: $category) {
                        ForEach(SwingCategory.allCases) { cat in
                            Text(cat.rawValue).tag(cat)
                        }
                    }
                }
                Section("Arc Sectors") {
                    ForEach(segmentTitles.indices, id: \.self) { idx in
                        TextField("Sector \(idx + 1)", text: $segmentTitles[idx])
                    }
                    if segmentTitles.count < AppConstants.maxSegments {
                        Button("Add Sector") {
                            segmentTitles.append("")
                        }
                    }
                }
            }
            .navigationTitle(existing == nil ? "New Swing Set" : "Edit Set")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(!canSave)
                }
            }
            .onAppear { loadExisting() }
        }
    }

    private var canSave: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty &&
        segmentTitles.filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }.count >= AppConstants.minSegments
    }

    private func loadExisting() {
        guard let existing else { return }
        name = existing.name
        description = existing.setDescription
        category = existing.category
        segmentTitles = existing.sortedSegments.map(\.title)
    }

    private func save() {
        let titles = segmentTitles
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }

        if let existing {
            existing.name = String(name.prefix(AppConstants.maxSetNameLength))
            existing.setDescription = description
            existing.category = category
            existing.segments = titles.enumerated().map { idx, title in
                ArcSegment(title: String(title.prefix(AppConstants.maxSegmentTitleLength)), sortOrder: idx)
            }
            try? services.setRepository.update(existing)
        } else {
            let set = SwingSet(
                name: String(name.prefix(AppConstants.maxSetNameLength)),
                setDescription: description,
                category: category,
                sortOrder: 99
            )
            set.segments = titles.enumerated().map { idx, title in
                ArcSegment(title: String(title.prefix(AppConstants.maxSegmentTitleLength)), sortOrder: idx)
            }
            try? services.setRepository.insert(set)
        }
        onSave()
        dismiss()
    }
}
