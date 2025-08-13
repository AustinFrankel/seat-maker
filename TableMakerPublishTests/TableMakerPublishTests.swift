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
        let pin = "123456"
        let ttl = 600
        let url = try ShareLinkBuilder.buildSnapshotLink(arrangement: arrangement, ttlSeconds: ttl, pin: pin, hostDisplayName: "Host")
        let payload = try ShareLinkRouterTestShim.parse(url: url)
        XCTAssertEqual(payload.mode.rawValue, "snapshot")
        XCTAssertEqual(payload.pin, pin)
        XCTAssertTrue(payload.expiresAtEpoch > Int(Date().timeIntervalSince1970))
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
}
