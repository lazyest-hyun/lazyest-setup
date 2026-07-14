import Foundation
@testable import MacBootstrapSetupCore
import XCTest

final class KarabinerMappingStateTests: XCTestCase {
    func testExactOwnedComplexRuleIsApplied() throws {
        let data = try fixture(selectedRules: [ownedRule()])
        XCTAssertTrue(KarabinerMappingState.isApplied(data: data))
    }

    func testSimpleMappingAloneIsNotApplied() throws {
        let data = try fixture(simpleMappings: [mapping()])
        XCTAssertFalse(KarabinerMappingState.isApplied(data: data))
    }

    func testLegacyProfileSimpleMappingMakesStateNotApplied() throws {
        let data = try fixture(selectedRules: [ownedRule()], simpleMappings: [mapping()])
        XCTAssertFalse(KarabinerMappingState.isApplied(data: data))
    }

    func testLegacyDeviceSimpleMappingMakesStateNotApplied() throws {
        let data = try fixture(selectedRules: [ownedRule()], deviceSimpleMappings: [mapping()])
        XCTAssertFalse(KarabinerMappingState.isApplied(data: data))
    }

    func testUnrelatedMentionsDoNotProduceFalsePositive() throws {
        let unrelatedRule: [String: Any] = [
            "description": "right_command note for an unrelated F18 rule",
            "manipulators": [[
                "type": "basic",
                "from": ["key_code": "left_command"],
                "to": [["key_code": "f18"]],
            ]],
        ]
        let data = try fixture(selectedRules: [unrelatedRule])
        XCTAssertFalse(KarabinerMappingState.isApplied(data: data))
    }

    func testOnlySelectedProfileIsInspected() throws {
        let root: [String: Any] = [
            "profiles": [
                profile(selected: false, rules: [ownedRule()]),
                profile(selected: true, rules: []),
            ],
        ]
        let data = try JSONSerialization.data(withJSONObject: root)
        XCTAssertFalse(KarabinerMappingState.isApplied(data: data))
    }

    func testMalformedJSONIsNotApplied() {
        XCTAssertFalse(KarabinerMappingState.isApplied(data: Data("{".utf8)))
    }

    private func fixture(
        selectedRules: [[String: Any]] = [],
        simpleMappings: [[String: Any]] = [],
        deviceSimpleMappings: [[String: Any]] = []
    ) throws -> Data {
        var selectedProfile = profile(selected: true, rules: selectedRules)
        selectedProfile["simple_modifications"] = simpleMappings
        selectedProfile["devices"] = [["simple_modifications": deviceSimpleMappings]]
        return try JSONSerialization.data(withJSONObject: ["profiles": [selectedProfile]])
    }

    private func profile(selected: Bool, rules: [[String: Any]]) -> [String: Any] {
        [
            "name": selected ? "Selected" : "Other",
            "selected": selected,
            "complex_modifications": ["rules": rules],
        ]
    }

    private func ownedRule() -> [String: Any] {
        [
            "description": KarabinerMappingState.ownedRuleDescription,
            "manipulators": [mapping(type: "basic")],
        ]
    }

    private func mapping(type: String? = nil) -> [String: Any] {
        var value: [String: Any] = [
            "from": ["key_code": "right_command"],
            "to": [["key_code": "f18"]],
        ]
        if let type {
            value["type"] = type
        }
        return value
    }
}
