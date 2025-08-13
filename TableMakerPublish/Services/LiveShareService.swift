import Foundation
import UIKit
import MultipeerConnectivity

enum LiveShareError: LocalizedError {
    case notFound
    case pinMismatch
    case connectionFailed
    case invalidData
    
    var errorDescription: String? {
        switch self {
        case .notFound: return "Host unavailable."
        case .pinMismatch: return "PIN mismatch."
        case .connectionFailed: return "Unable to connect to host."
        case .invalidData: return "Received invalid data from host."
        }
    }
}

final class LiveShareService: NSObject {
    static let shared = LiveShareService()
    private override init() { super.init() }
    
    private let serviceType = "seatmaker-live"
    private var peerId = MCPeerID(displayName: UIDevice.current.name)
    private var session: MCSession?
    private var advertiser: MCNearbyServiceAdvertiser?
    private var browser: MCNearbyServiceBrowser?
    
    private var hostPIN: String?
    private var joinPIN: String?
    private var hostArrangementProvider: (() -> SeatingArrangement)?
    private var joinCompletion: ((Result<SeatingArrangement, Error>) -> Void)?
    private var targetSessionID: String?
    private var heartbeatTimer: Timer?
    private var joinTimeoutTimer: Timer?
    
    func host(sessionID: String, requiresPIN pin: String, arrangementProvider: @escaping () -> SeatingArrangement) {
        hostPIN = pin
        hostArrangementProvider = arrangementProvider
        session = MCSession(peer: peerId, securityIdentity: nil, encryptionPreference: .required)
        session?.delegate = self
        advertiser = MCNearbyServiceAdvertiser(peer: peerId, discoveryInfo: ["sessionID": sessionID, "requiresPIN": "true"], serviceType: serviceType)
        advertiser?.delegate = self
        advertiser?.startAdvertisingPeer()
        // Start heartbeat to periodically rebroadcast full doc for resync
        heartbeatTimer?.invalidate()
        heartbeatTimer = Timer.scheduledTimer(withTimeInterval: 10.0, repeats: true) { [weak self] _ in
            guard let self, let session = self.session, let provider = self.hostArrangementProvider else { return }
            let arrangement = provider()
            if let data = try? JSONEncoder().encode(arrangement), !session.connectedPeers.isEmpty {
                try? session.send(data, toPeers: session.connectedPeers, with: .reliable)
            }
        }
    }
    
    func stopHostingOrBrowsing() {
        advertiser?.stopAdvertisingPeer()
        browser?.stopBrowsingForPeers()
        advertiser = nil
        browser = nil
        session?.disconnect()
        session = nil
        hostPIN = nil
        joinPIN = nil
        targetSessionID = nil
        hostArrangementProvider = nil
        joinCompletion = nil
        heartbeatTimer?.invalidate()
        heartbeatTimer = nil
        joinTimeoutTimer?.invalidate()
        joinTimeoutTimer = nil
    }
    
    func join(sessionID: String, pin: String, completion: @escaping (Result<SeatingArrangement, Error>) -> Void) {
        joinPIN = pin
        targetSessionID = sessionID
        joinCompletion = completion
        session = MCSession(peer: peerId, securityIdentity: nil, encryptionPreference: .required)
        session?.delegate = self
        browser = MCNearbyServiceBrowser(peer: peerId, serviceType: serviceType)
        browser?.delegate = self
        browser?.startBrowsingForPeers()
        // We'll filter by discoveryInfo in foundPeer delegate
        joinTimeoutTimer?.invalidate()
        joinTimeoutTimer = Timer.scheduledTimer(withTimeInterval: 8.0, repeats: false) { [weak self] _ in
            guard let self else { return }
            if (self.session?.connectedPeers.isEmpty ?? true) {
                self.joinCompletion?(.failure(LiveShareError.notFound))
                self.joinCompletion = nil
                self.stopHostingOrBrowsing()
            }
        }
    }
}

extension LiveShareService: MCNearbyServiceAdvertiserDelegate {
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: Data?, invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        // Expect 6-digit pin in context
        if let context = context, let providedPIN = String(data: context, encoding: .utf8), let hostPIN = hostPIN, providedPIN == hostPIN {
            invitationHandler(true, session)
        } else {
            invitationHandler(false, nil)
        }
    }
}

extension LiveShareService: MCNearbyServiceBrowserDelegate {
    func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String : String]?) {
        guard let myPIN = joinPIN else { return }
        // Only connect to matching sessionID
        // Note: The sessionID can be embedded in the service's discoveryInfo; we match here.
        // If matches, invite with PIN as context
        if let advertisedSession = info?["sessionID"], let target = targetSessionID, advertisedSession == target {
            browser.invitePeer(peerID, to: session!, withContext: myPIN.data(using: .utf8), timeout: 15)
        }
    }
    func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) { }
    func browser(_ browser: MCNearbyServiceBrowser, didNotStartBrowsingForPeers error: Error) { }
}

extension LiveShareService: MCSessionDelegate {
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        if state == .connected {
            // If we are host, send full document
            if advertiser != nil, let provider = hostArrangementProvider {
                let arrangement = provider()
                if let data = try? JSONEncoder().encode(arrangement) {
                    try? session.send(data, toPeers: session.connectedPeers, with: .reliable)
                }
            }
        }
    }
    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        // Joiner receives full document first
        if advertiser == nil {
            if let arrangement = try? JSONDecoder().decode(SeatingArrangement.self, from: data) {
                joinCompletion?(.success(arrangement))
                joinCompletion = nil
            } else {
                joinCompletion?(.failure(LiveShareError.invalidData))
                joinCompletion = nil
            }
        }
    }
    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {}
    func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {}
    func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {}
    #if !os(macOS)
    func session(_ session: MCSession, didReceiveCertificate certificate: [Any]?, fromPeer peerID: MCPeerID, certificateHandler: @escaping (Bool) -> Void) {
        certificateHandler(true)
    }
    #endif
}


