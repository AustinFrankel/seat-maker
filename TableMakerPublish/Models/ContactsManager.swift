import Contacts
import Foundation

public class ContactsManager {
    public static let shared = ContactsManager()
    private let contactStore = CNContactStore()
    
    private init() {}
    
    public func requestAccess() async -> Bool {
        do {
            return try await contactStore.requestAccess(for: .contacts)
        } catch {
            print("Error requesting contacts access: \(error)")
            return false
        }
    }
    
    public func fetchContacts() async -> [String] {
        do {
            let keysToFetch = [CNContactGivenNameKey, CNContactFamilyNameKey] as [CNKeyDescriptor]
            let request = CNContactFetchRequest(keysToFetch: keysToFetch)
            var contacts: [String] = []
            
            try contactStore.enumerateContacts(with: request) { contact, _ in
                let fullName = [contact.givenName, contact.familyName]
                    .filter { !$0.isEmpty }
                    .joined(separator: " ")
                if !fullName.isEmpty {
                    contacts.append(fullName)
                }
            }
            
            return contacts.sorted()
        } catch {
            print("Error fetching contacts: \(error)")
            return []
        }
    }
}
