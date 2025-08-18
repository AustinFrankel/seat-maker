import SwiftUI

struct InlineGuestManagerView: View {
    @ObservedObject var viewModel: SeatingViewModel
    @Binding var isPresented: Bool
    // When invoked, this triggers the parent (ContentView) to show its existing add person sheet
    var onAddPerson: (() -> Void)? = nil
    @State private var editMode: EditMode = .active

    var body: some View {
        NavigationView {
            Group {
                if viewModel.currentArrangement.people.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "person.2.fill")
                            .font(.system(size: 40))
                            .foregroundColor(.secondary)
                        Text("No people yet")
                            .font(.headline)
                        Text("Add people to this table to manage.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                    .padding()
                } else {
                    List {
                        ForEach(Array(viewModel.currentArrangement.people.enumerated()), id: \.element.id) { index, person in
                            HStack(spacing: 12) {
                                // Remove drag grip inside row; use system edit handles only
                                Text("\(index + 1)")
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundColor(.accentColor)
                                    .frame(width: 28, alignment: .trailing)

                                Text(person.name)
                                    .font(.system(size: 16))
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.8)
                                Spacer()
                                Button(action: { viewModel.toggleLock(for: person.id) }) {
                                    Image(systemName: person.isLocked ? "lock.fill" : "lock.open")
                                        .foregroundColor(person.isLocked ? .accentColor : .gray)
                                        .font(.system(size: 18, weight: .semibold))
                                        .padding(7)
                                        .background(
                                            Circle()
                                                .fill(person.isLocked ? Color.accentColor.opacity(0.12) : Color.gray.opacity(0.08))
                                        )
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                            .padding(.vertical, 6)
                        }
                        .onDelete { indexSet in
                            if let index = indexSet.first {
                                withAnimation(.easeInOut(duration: 0.18)) {
                                    viewModel.removePerson(at: index)
                                }
                            }
                        }
                        .onMove { source, destination in
                            viewModel.movePerson(from: source, to: destination)
                        }
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("Manage Guests")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { onAddPerson?() }) {
                        Image(systemName: "plus.circle.fill")
                    }
                    .accessibilityLabel("Add person")
                    .accessibilityIdentifier("btn.managePeople")
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { isPresented = false }
                        .font(.headline)
                }
            }
            .environment(\.editMode, $editMode)
        }
        .onAppear {
            // Keep drag handles visible for easy reordering
            editMode = .active
        }
        .tint(.accentColor)
    }
}



