import SwiftUI
import Foundation

public struct PersonNameView: View {
    public let person: Person
    public let onUpdate: (String) -> Void
    public var showDoneButtonOnRight: Bool = false
    @State private var isEditing = false
    @State private var editedName: String = ""
    @State private var keyboardHeight: CGFloat = 0
    public init(person: Person, onUpdate: @escaping (String) -> Void, showDoneButtonOnRight: Bool = false) {
        self.person = person
        self.onUpdate = onUpdate
        self.showDoneButtonOnRight = showDoneButtonOnRight
    }
    public var body: some View {
        if isEditing {
            HStack(spacing: 8) {
                TextField("Name", text: $editedName, onCommit: {
                    finishEditing()
                })
                .font(.headline)
                .padding(10)
                .background(Color(.systemBackground))
                .cornerRadius(16)
                .shadow(color: Color.black.opacity(0.12), radius: 6)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.blue, lineWidth: 1.5)
                )
                .frame(width: 120)
                .zIndex(100)
                if showDoneButtonOnRight {
                    Button(action: finishEditing) {
                        Text("Done")
                            .font(.headline)
                            .foregroundColor(.blue)
                            .padding(.horizontal, 18)
                            .padding(.vertical, 6)
                            .background(Color.blue.opacity(0.08))
                            .cornerRadius(8)
                    }
                }
            }
        } else {
            Text(person.name)
                .font(.headline)
                .lineLimit(1)
                .minimumScaleFactor(0.9)
                .frame(width: 120)
                .onTapGesture {
                    isEditing = true
                    editedName = person.name
                }
        }
    }
    private func finishEditing() {
        if !editedName.isEmpty {
            onUpdate(editedName)
        }
        isEditing = false
    }
} 