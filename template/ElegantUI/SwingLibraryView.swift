import SwiftUI

struct SwingLibraryView: View {
    @EnvironmentObject private var services: PenduloraServices
    @State private var sets: [SwingSet] = []
    @State private var records: [SwingRecord] = []
    @State private var editingSet: SwingSet?
    @State private var showEditor = false

    var body: some View {
        NavigationStack {
            List {
                Section {
                    ForEach(sets) { set in
                        Button {
                            editingSet = set
                            showEditor = true
                        } label: {
                            HStack {
                                Image(systemName: set.category.icon)
                                    .foregroundStyle(LuxPalette.secondary)
                                VStack(alignment: .leading) {
                                    Text(set.name).luxCormorant(18)
                                    Text("\(set.segments.count) sectors")
                                        .font(.caption)
                                        .foregroundStyle(LuxPalette.textMuted)
                                }
                                Spacer()
                                if services.preferences.defaultDailySetId == set.id {
                                    Image(systemName: "star.fill")
                                        .foregroundStyle(LuxPalette.secondary)
                                }
                            }
                        }
                        .swipeActions {
                            if !set.isBuiltIn {
                                Button(role: .destructive) {
                                    try? services.setRepository.delete(set)
                                    reload()
                                } label: { Label("Delete", systemImage: "trash") }
                            }
                            Button {
                                services.preferences.defaultDailySetId = set.id
                            } label: { Label("Daily", systemImage: "star") }
                            .tint(LuxPalette.secondary)
                        }
                    }
                } header: {
                    Text("Swing Sets").luxCormorant(16)
                }

                Section {
                    ForEach(records.prefix(20)) { record in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(record.landedTitle).font(.subheadline.weight(.medium))
                            HStack {
                                Text(record.swingSetName)
                                Spacer()
                                Text(record.swungAt, style: .date)
                            }
                            .font(.caption)
                            .foregroundStyle(LuxPalette.textMuted)
                        }
                        .padding(.vertical, 4)
                    }
                } header: {
                    Text("Recent Swings").luxCormorant(16)
                }
            }
            .scrollContentBackground(.hidden)
            .luxScreen()
            .navigationTitle("Library")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        editingSet = nil
                        showEditor = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .onAppear { reload() }
            .sheet(isPresented: $showEditor) {
                SwingEditorView(existing: editingSet) { reload() }
            }
        }
    }

    private func reload() {
        sets = (try? services.setRepository.fetchAll()) ?? []
        records = (try? services.recordRepository.fetchAll()) ?? []
    }
}

extension SwingRecord: @retroactive Identifiable {}
