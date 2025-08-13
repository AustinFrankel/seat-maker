import SwiftUI

struct HistoryView: View {
    @ObservedObject var viewModel: SeatingViewModel
    let dismissAction: () -> Void

    var body: some View {
        // This standalone file is retained for compatibility but the inlined
        // HistoryView inside ContentView is the one shown via sheet with
        // richer UI and interactive selection. Keep this as a fallback.
        NavigationView {
            List(viewModel.savedArrangements) { arrangement in
                Button(action: {
                    // Open selected arrangement into main editor
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
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                        dismissAction()
                    }
                }) {
                    VStack(alignment: .leading) {
                        Text(arrangement.title)
                            .font(.headline)
                        Text("\(arrangement.people.count) people")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Text(arrangement.date, style: .date)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("History")
            .navigationBarItems(leading: Button(action: dismissAction) { Text("Back") })
        }
    }
}