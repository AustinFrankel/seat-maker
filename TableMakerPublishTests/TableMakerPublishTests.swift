//
//  TableMakerPublishTests.swift
//  TableMakerPublishTests
//
//  Created by Austin Frankel on 5/23/25.
//

import XCTest
@testable import TableMakerPublish

final class TableMakerPublishTests: XCTestCase {
    func testShareLinkSnapshotBuildAndParse() throws {
        let arrangement = SeatingArrangement(title: "Dinner at 8", people: [Person(name: "A")], tableShape: .round, seatAssignments: [:])
        let url = try ShareLinkBuilder.buildSnapshotLink(arrangement: arrangement, hostDisplayName: "Host")
        let payload = try ShareLinkRouterTestShim.parse(url: url)
        XCTAssertEqual(payload.mode.rawValue, "snapshot")
    }

    func testShareLinkExpired() throws {
        var comps = URLComponents(string: "https://share.seatmaker.app/sm/share")!
        comps.queryItems = [
            .init(name: "v", value: "1"),
            .init(name: "mode", value: "live"),
            .init(name: "ttl", value: String(1)),
            .init(name: "pin", value: "123456"),
            .init(name: "host", value: "H"),
            .init(name: "blob", value: Data("{}".utf8).base64URLEncodedString())
        ]
        let url = comps.url!
        XCTAssertThrowsError(try ShareLinkRouterTestShim.validateBasic(payload: ShareLinkRouterTestShim.parse(url: url)))
    }

    func testPINValidation() throws {
        var comps = URLComponents(string: "https://share.seatmaker.app/sm/share")!
        comps.queryItems = [
            .init(name: "v", value: "1"),
            .init(name: "mode", value: "snapshot"),
            .init(name: "ttl", value: String(Int(Date().timeIntervalSince1970) + 600)),
            .init(name: "pin", value: "12a456"),
            .init(name: "host", value: "H"),
            .init(name: "blob", value: Data("{}".utf8).base64URLEncodedString())
        ]
        let url = comps.url!
        XCTAssertThrowsError(try ShareLinkRouterTestShim.parse(url: url))
    }

    @MainActor
    func testFreeUserCannotNavigatePastTableFour() throws {
        let vm = SeatingViewModel()
        // Ensure user is non‑Pro
        RevenueCatManager.shared.state.hasPro = false
        vm.tableCollection.currentTableId = 3 // currently at table 4 (0-indexed)
        vm.saveCurrentTableState()
        vm.navigateToTable(direction: .right)
        // Should still be at table 4 for non‑Pro
        XCTAssertEqual(vm.tableCollection.currentTableId, 3)
    }

    @MainActor
    func testProUserCanNavigateToTableFive() throws {
        let vm = SeatingViewModel()
        // Grant Pro
        RevenueCatManager.shared.state.hasPro = true
        vm.tableCollection.currentTableId = 3 // table 4
        vm.saveCurrentTableState()
        vm.navigateToTable(direction: .right)
        // Now should be at table 5 (id 4)
        XCTAssertEqual(vm.tableCollection.currentTableId, 4)
    }
}
