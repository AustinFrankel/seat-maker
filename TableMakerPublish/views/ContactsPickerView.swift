import SwiftUI
import ContactsUI

struct ContactsPickerView: UIViewControllerRepresentable {
    @Binding var selectedContacts: Set<String>
    @Environment(\.presentationMode) var presentationMode
    
    func makeUIViewController(context: Context) -> CNContactPickerViewController {
        let picker = CNContactPickerViewController()
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: CNContactPickerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, CNContactPickerDelegate {
        var parent: ContactsPickerView
        
        init(_ parent: ContactsPickerView) {
            self.parent = parent
        }
        
        func contactPicker(_ picker: CNContactPickerViewController, didSelect contacts: [CNContact]) {
            let names = contacts.map { "\($0.givenName) \($0.familyName)".trimmingCharacters(in: .whitespaces) }
            parent.selectedContacts = Set(names)
            parent.presentationMode.wrappedValue.dismiss()
        }
    }
} 