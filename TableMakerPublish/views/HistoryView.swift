import SwiftUI

struct HistoryView: View {
    @ObservedObject var viewModel: SeatingViewModel
    let dismissAction: () -> Void
    @State private var isSelecting: Bool = false
    @State private var selectedIds: Set<UUID> = []

    var body: some View {
        // This standalone file is retained for compatibility but the inlined
        // HistoryView inside ContentView is the one shown via sheet with
        // richer UI and interactive selection. Keep this as a fallback.
        NavigationView {
            List(viewModel.savedArrangements) { arrangement in
                HStack {
                    if isSelecting {
                        Button(action: {
                            if selectedIds.contains(arrangement.id) { selectedIds.remove(arrangement.id) } else { selectedIds.insert(arrangement.id) }
                        }) {
                            Image(systemName: selectedIds.contains(arrangement.id) ? "checkmark.circle.fill" : "circle")
                                .foregroundColor(selectedIds.contains(arrangement.id) ? .blue : .secondary)
                        }
                    }
                    Button(action: {
                        guard !isSelecting else { return }
                        let copy = SeatingArrangement(
                            id: arrangement.id,
                            title: arrangement.title,
                            date: arrangement.date,
                            people: arrangement.people,
                            tableShape: arrangement.tableShape,
                            seatAssignments: arrangement.seatAssignments
                        )
                        viewModel.isViewingHistory = true
                        viewModel.loadArrangement(copy)
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { dismissAction() }
                    }) {
                        VStack(alignment: .leading) {
                            Text(arrangement.title).font(.headline)
                            Text("\(arrangement.people.count) people").font(.subheadline).foregroundColor(.secondary)
                            Text(arrangement.date, style: .date).font(.caption).foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .disabled(isSelecting)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: dismissAction) { Text("Back") }
                }
                ToolbarItem(placement: .principal) {
                    Text("History").font(.headline)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack(spacing: 12) {
                        if isSelecting {
                            Button("Delete") {
                                let idsToDelete = selectedIds
                                selectedIds.removeAll()
                                isSelecting = false
                                // Delete by matching IDs in savedArrangements order
                                let indices = viewModel.savedArrangements.enumerated().compactMap { idx, item in idsToDelete.contains(item.id) ? idx : nil }
                                viewModel.deleteSavedArrangements(at: IndexSet(indices))
                            }
                            .disabled(selectedIds.isEmpty)
                        }
                        Button(isSelecting ? "Cancel" : "Select") {
                            if isSelecting { selectedIds.removeAll() }
                            isSelecting.toggle()
                        }
                    }
                }
            }
        }
    }
}