import SwiftUI

struct HistoryView: View {
    @ObservedObject var viewModel: SeatingViewModel
    @Binding var isPresented: Bool
    
    var body: some View {
        NavigationView {
            List {
                if viewModel.savedArrangements.isEmpty {
                    Text("No saved arrangements")
                        .foregroundColor(.secondary)
                } else {
                    ForEach(viewModel.savedArrangements) { arrangement in
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
                    .onDelete(perform: deleteArrangement)
                }
            }
            .navigationTitle("History")
            .navigationBarItems(trailing: Button("Done") {
                isPresented = false
            })
        }
    }
    
    private func deleteArrangement(at offsets: IndexSet) {
        viewModel.savedArrangements.remove(atOffsets: offsets)
        // Add persistence logic here
    }
} 