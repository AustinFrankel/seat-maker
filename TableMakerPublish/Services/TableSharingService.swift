import Foundation
import SwiftUI

@MainActor
class TableSharingService: ObservableObject {
    @Published var isLoading = false
    @Published var error: Error?
    
    private let baseURL = "https://www.seatmakerapp.com/api"
    
    func shareTable(_ arrangement: SeatingArrangement) async throws -> SharedTable {
        isLoading = true
        defer { isLoading = false }
        
        // Deprecated cloud share in favor of on-device universal link builder
        return SharedTable(arrangement: arrangement)
    }
    
    func fetchSharedTable(id: String) async throws -> SharedTable {
        isLoading = true
        defer { isLoading = false }
        
        // In a real implementation, this would fetch from a server
        // For now, we'll throw an error
        throw NSError(domain: "TableSharingService", code: 1, userInfo: [NSLocalizedDescriptionKey: "Not implemented"])
    }
    
    func shareTableLink(_ sharedTable: SharedTable) {
        // No-op for universal link migration
    }
    
    // Generate HTML template for web display of table arrangements
    static func generateTableHTML(from data: String) -> String {
        guard let decodedData = data.removingPercentEncoding,
              let jsonData = decodedData.data(using: .utf8),
              let tableData = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any],
              let title = tableData["title"] as? String,
              let shape = tableData["shape"] as? String,
              let people = tableData["people"] as? [[String: Any]] else {
            return generateErrorHTML()
        }
        
        let peopleHTML = people.map { person in
            let name = person["name"] as? String ?? "Unknown"
            let seat = person["seat"] as? Int ?? 0
            let locked = person["locked"] as? Bool ?? false
            let lockIcon = locked ? " 🔒" : ""
            return "<div class='person-item'><span class='seat-number'>\(seat)</span><span class='person-name'>\(name)\(lockIcon)</span></div>"
        }.joined()
        
        let shapeDisplay = getShapeDisplay(shape)
        
        return """
        <!DOCTYPE html>
        <html lang="en">
        <head>
            <meta charset="UTF-8">
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <title>Table Arrangement - \(title)</title>
            <style>
                body { 
                    font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; 
                    margin: 0; 
                    padding: 20px; 
                    background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
                    min-height: 100vh;
                    color: #333;
                }
                .container { 
                    max-width: 400px; 
                    margin: 0 auto; 
                    background: white; 
                    border-radius: 20px; 
                    padding: 30px; 
                    box-shadow: 0 20px 40px rgba(0,0,0,0.1);
                    text-align: center;
                }
                .title { 
                    font-size: 28px; 
                    font-weight: bold; 
                    margin-bottom: 10px; 
                    color: #2d3748;
                }
                .subtitle { 
                    color: #718096; 
                    margin-bottom: 30px; 
                    font-size: 16px;
                }
                .table-visual { 
                    width: 200px; 
                    height: 150px; 
                    margin: 20px auto; 
                    border: 3px solid #4299e1; 
                    background: rgba(66, 153, 225, 0.1);
                    display: flex;
                    align-items: center;
                    justify-content: center;
                    font-size: 18px;
                    color: #4299e1;
                    font-weight: bold;
                    \(shape == "round" ? "border-radius: 50%;" : shape == "square" ? "border-radius: 10px;" : "border-radius: 10px;")
                }
                .people-list { 
                    margin-top: 30px; 
                    text-align: left;
                }
                .people-title { 
                    font-size: 20px; 
                    font-weight: bold; 
                    margin-bottom: 15px; 
                    text-align: center;
                    color: #2d3748;
                }
                .person-item { 
                    display: flex; 
                    align-items: center; 
                    padding: 12px; 
                    margin: 8px 0; 
                    background: #f7fafc; 
                    border-radius: 10px;
                    border-left: 4px solid #4299e1;
                }
                .seat-number { 
                    background: #4299e1; 
                    color: white; 
                    border-radius: 50%; 
                    width: 30px; 
                    height: 30px; 
                    display: flex; 
                    align-items: center; 
                    justify-content: center; 
                    font-weight: bold; 
                    margin-right: 15px;
                    font-size: 14px;
                }
                .person-name { 
                    font-size: 16px; 
                    font-weight: 500;
                }
                .footer { 
                    margin-top: 30px; 
                    padding-top: 20px; 
                    border-top: 1px solid #e2e8f0; 
                    color: #718096; 
                    font-size: 14px;
                }
                .app-link {
                    display: inline-block;
                    background: #4299e1;
                    color: white;
                    text-decoration: none;
                    padding: 12px 24px;
                    border-radius: 25px;
                    margin-top: 15px;
                    font-weight: bold;
                    transition: background 0.3s;
                }
                .app-link:hover {
                    background: #3182ce;
                }
            </style>
        </head>
        <body>
            <div class="container">
                <div class="title">\(title)</div>
                <div class="subtitle">\(shapeDisplay) • \(people.count) \(people.count == 1 ? "person" : "people")</div>
                
                <div class="table-visual">
                    \(getTableIcon(shape)) Table
                </div>
                
                <div class="people-list">
                    <div class="people-title">Seating Arrangement</div>
                    \(peopleHTML)
                </div>
                
                <div class="footer">
                    Created with Seat Maker
                    <br>
                    <a href="https://apps.apple.com/app/seat-maker" class="app-link">Download Seat Maker</a>
                </div>
            </div>
        </body>
        </html>
        """
    }
    
    private static func getShapeDisplay(_ shape: String) -> String {
        switch shape.lowercased() {
        case "round": return "Round Table"
        case "square": return "Square Table"
        case "rectangle": return "Rectangle Table"
        default: return "Table"
        }
    }
    
    private static func getTableIcon(_ shape: String) -> String {
        switch shape.lowercased() {
        case "round": return "◯"
        case "square": return "□"
        case "rectangle": return "▭"
        default: return "◯"
        }
    }
    
    private static func generateErrorHTML() -> String {
        return """
        <!DOCTYPE html>
        <html>
        <head>
            <meta charset="UTF-8">
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <title>Table Arrangement - Error</title>
            <style>
                body { font-family: -apple-system, BlinkMacSystemFont, sans-serif; text-align: center; padding: 50px; }
                .error { color: #e53e3e; }
            </style>
        </head>
        <body>
            <h1 class="error">Invalid Table Data</h1>
            <p>Sorry, this table arrangement could not be loaded.</p>
            <a href="https://apps.apple.com/app/seat-maker">Download Seat Maker</a>
        </body>
        </html>
        """
    }
} 