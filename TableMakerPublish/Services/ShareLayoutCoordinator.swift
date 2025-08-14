import Foundation
import SwiftUI

/// Coordinator responsible for building compact public snapshots, creating viewer links,
/// generating QR codes, and importing snapshots back into local models.
@MainActor
final class ShareLayoutCoordinator: ObservableObject {
    static let shared = ShareLayoutCoordinator()
    private init() {}

    struct ShareResult {
        let viewerURL: URL
        let slug: String?
        let usedServerless: Bool
    }

    // MARK: - Public API

    func buildSnapshotJSON(arrangement: SeatingArrangement, eventTitle: String?) -> Data {
        // Canonical canvas size for pixel parity across app/web
        let canvasWidth: CGFloat = 2000
        let canvasHeight: CGFloat = 1200
        let iconSize: CGFloat = 64
        let tableCenter = CGPoint(x: canvasWidth/2, y: canvasHeight/2)

        // Table geometry
        let table: [String: Any]
        switch arrangement.tableShape {
        case .round:
            table = [
                "id": "t1",
                "kind": "round",
                "cx": Int(tableCenter.x.rounded()),
                "cy": Int(tableCenter.y.rounded()),
                "r": 300,
                "rot": 0,
                "label": arrangement.title
            ]
        case .rectangle:
            table = [
                "id": "t1",
                "kind": "rect",
                "x": Int((tableCenter.x - 360).rounded()),
                "y": Int((tableCenter.y - 240).rounded()),
                "w": 720,
                "h": 480,
                "rot": 0,
                "label": arrangement.title
            ]
        case .square:
            table = [
                "id": "t1",
                "kind": "rect",
                "x": Int((tableCenter.x - 320).rounded()),
                "y": Int((tableCenter.y - 320).rounded()),
                "w": 640,
                "h": 640,
                "rot": 0,
                "label": arrangement.title
            ]
        }

        // Compute seat coordinates identically to in-app layout
        let calculator = SeatPositionCalculator()
        let positions = calculator.calculatePositions(
            for: arrangement.tableShape,
            in: CGSize(width: canvasWidth, height: canvasHeight),
            totalSeats: arrangement.people.count,
            iconSize: iconSize
        )

        // Map people -> seats using current seatAssignments order
        let ordered: [(person: Person, seat: Int)] = arrangement.people.compactMap { person in
            guard let seat = arrangement.seatAssignments[person.id] else { return nil }
            return (person, seat)
        }.sorted { $0.seat < $1.seat }

        var seatsArray: [[String: Any]] = []
        for (index, item) in ordered.enumerated() {
            let pos = positions.indices.contains(item.seat) ? positions[item.seat] : CGPoint(x: tableCenter.x, y: tableCenter.y)
            seatsArray.append([
                "tid": "t1",
                "sid": "s\(index + 1)",
                "x": Int(pos.x.rounded()),
                "y": Int(pos.y.rounded()),
                "n": Self.sanitizedPublicName(item.person.name),
                "locked": item.person.isLocked
            ])
        }

        let snapshot: [String: Any] = [
            "v": 1,
            "event": ["title": (eventTitle ?? arrangement.eventTitle ?? "").trimmingCharacters(in: .whitespacesAndNewlines)],
            "canvas": ["w": Int(canvasWidth), "h": Int(canvasHeight), "bg": "#FFFFFF"],
            "tables": [table],
            "seats": seatsArray,
            "style": ["tableStroke": "#222", "seatFill": "#eeeeee", "font": "-apple-system"]
        ]

        // Serialize compactly
        let json = try! JSONSerialization.data(withJSONObject: snapshot, options: [])
        return json
    }

    func generateShareLink(arrangement: SeatingArrangement, preferServerless: Bool = true) async -> ShareResult {
        let snapshot = buildSnapshotJSON(arrangement: arrangement, eventTitle: arrangement.eventTitle)
        if preferServerless, let server = await tryServerlessPublish(snapshot: snapshot) {
            return server
        }
        let fragment = Self.buildFragmentURL(from: snapshot)
        return ShareResult(viewerURL: fragment, slug: nil, usedServerless: false)
    }

    func importFrom(url: URL, completion: @escaping (Result<SeatingArrangement, Error>) -> Void) {
        // /t/[slug] or /t#v=1&d=...
        if url.path.hasPrefix("/t"), let fragment = url.fragment, fragment.contains("d=") {
            do {
                let data = try Self.decodeFragment(fragment)
                let arrangement = try Self.arrangement(fromSnapshot: data)
                completion(.success(arrangement))
            } catch {
                completion(.failure(error))
            }
            return
        }
        if url.path.hasPrefix("/t/") {
            let slug = url.lastPathComponent
            Task {
                do {
                    let data = try await Self.fetchSnapshot(slug: slug, base: url)
                    let arrangement = try Self.arrangement(fromSnapshot: data)
                    completion(.success(arrangement))
                } catch { completion(.failure(error)) }
            }
            return
        }
        completion(.failure(NSError(domain: "ShareLayout", code: -1, userInfo: [NSLocalizedDescriptionKey: "Unsupported link"])) )
    }

    // MARK: - Private helpers

    private func tryServerlessPublish(snapshot: Data) async -> ShareResult? {
        guard let endpoint = URL(string: "https://www.seatmakerapp.com/api/share") else { return nil }
        var req = URLRequest(url: endpoint)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = snapshot
        do {
            let (data, resp) = try await URLSession.shared.data(for: req)
            guard let http = resp as? HTTPURLResponse, (200..<300).contains(http.statusCode) else { return nil }
            if let obj = try JSONSerialization.jsonObject(with: data) as? [String: Any], let urlStr = obj["viewerUrl"] as? String, let url = URL(string: urlStr) {
                return ShareResult(viewerURL: url, slug: obj["slug"] as? String, usedServerless: true)
            }
        } catch { return nil }
        return nil
    }

    private static func buildFragmentURL(from snapshot: Data) -> URL {
        // Prefer deflate for web compatibility
        let compressed = (try? DeflateCompression.compress(snapshot)) ?? snapshot
        let b64 = compressed.base64URLEncodedString()
        var comps = URLComponents()
        comps.scheme = "https"
        comps.host = "www.seatmakerapp.com"
        comps.path = "/t"
        comps.fragment = "v=1&d=\(b64)"
        return comps.url!
    }

    nonisolated static func decodeFragment(_ fragment: String) throws -> Data {
        // Parse v and d
        let pairs = fragment.split(separator: "&").map { $0.split(separator: "=", maxSplits: 1).map(String.init) }
        var dict: [String: String] = [:]
        for pair in pairs { if pair.count == 2 { dict[pair[0]] = pair[1] } }
        guard let d = dict["d"] else { throw RouterError.malformed }
        let raw = try Data(base64URLEncoded: d)
        // Try deflate first; fallback to LZFSE
        if let deflated = try? DeflateCompression.decompress(raw) { return deflated }
        if let lzfse = try? LZFSECompression.decompress(raw) { return lzfse }
        return raw
    }

    nonisolated static func fetchSnapshot(slug: String, base: URL) async throws -> Data {
        var comps = URLComponents()
        comps.scheme = base.scheme
        comps.host = base.host
        comps.port = base.port
        comps.path = "/api/tables/\(slug)"
        guard let url = comps.url else { throw RouterError.malformed }
        let (data, resp) = try await URLSession.shared.data(from: url)
        guard let http = resp as? HTTPURLResponse else { throw RouterError.malformed }
        if http.statusCode == 410 { throw RouterError.expired }
        guard (200..<300).contains(http.statusCode) else { throw RouterError.malformed }
        return data
    }

    nonisolated static func arrangement(fromSnapshot data: Data) throws -> SeatingArrangement {
        guard let obj = try JSONSerialization.jsonObject(with: data) as? [String: Any] else { throw RouterError.malformed }
        let event = (obj["event"] as? [String: Any])?["title"] as? String
        let tables = (obj["tables"] as? [[String: Any]]) ?? []
        let seats = (obj["seats"] as? [[String: Any]]) ?? []
        // Build arrangement from seats order (sid ascending)
        let sortedSeats = seats.sorted { a, b in
            let sa = (a["sid"] as? String)?.replacingOccurrences(of: "s", with: "") ?? "0"
            let sb = (b["sid"] as? String)?.replacingOccurrences(of: "s", with: "") ?? "0"
            return (Int(sa) ?? 0) < (Int(sb) ?? 0)
        }
        var people: [Person] = []
        var seatAssignments: [UUID: Int] = [:]
        for (idx, seat) in sortedSeats.enumerated() {
            let name = (seat["n"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines)
            let locked = (seat["locked"] as? Bool) ?? false
            let person = Person(name: name?.isEmpty == false ? name! : "Guest \(idx + 1)", isLocked: locked)
            people.append(person)
            seatAssignments[person.id] = idx
        }
        let title: String = {
            if let table = tables.first, let label = table["label"] as? String, !label.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { return label }
            return "Imported Table"
        }()
        let shape: TableShape = {
            if let k = (tables.first)?["kind"] as? String, k == "rect" {
                // Distinguish square vs rectangle by w/h
                if let w = (tables.first)?["w"] as? Int, let h = (tables.first)?["h"] as? Int, w == h { return .square }
                return .rectangle
            }
            return .round
        }()
        return SeatingArrangement(
            id: UUID(),
            title: title,
            eventTitle: event,
            date: Date(),
            people: people,
            tableShape: shape,
            seatAssignments: seatAssignments
        )
    }

    private static func sanitizedPublicName(_ name: String) -> String {
        // Drop emails/phone-like tokens, keep first name + last initial
        let components = name.split(separator: " ").map(String.init).filter { part in
            if part.contains("@") { return false }
            let digits = part.filter { $0.isNumber }
            return digits.count < 5
        }
        guard let first = components.first else { return "Guest" }
        let lastInitial = components.dropFirst().first?.first
        let result = lastInitial != nil ? "\(first) \(lastInitial!)." : first
        return String(result.prefix(24))
    }
}


