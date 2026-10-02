import XCTest
@testable import LazyestSetupCore

final class InputSourceStateTests: XCTestCase {
    private let gureum = EnabledInputSource(
        id: "org.youknowone.inputmethod.Gureum.han2",
        bundleID: "org.youknowone.inputmethod.Gureum"
    )
    private let apple = EnabledInputSource(
        id: "com.apple.inputmethod.Korean.2SetKorean",
        bundleID: "com.apple.inputmethod.Korean"
    )

    func testInstalledButNotAddedDoesNotCountAsEnabled() {
        XCTAssertFalse(InputSourceState.gureumEnabled([apple]))
        XCTAssertTrue(InputSourceState.appleKoreanEnabled([apple]))
    }

    func testManuallyAddedGureumAndRemovedApple() {
        XCTAssertTrue(InputSourceState.gureumEnabled([gureum]))
        XCTAssertFalse(InputSourceState.appleKoreanEnabled([gureum]))
    }

    func testBothSourcesRemainEnabledUntilAppleIsRemoved() {
        XCTAssertTrue(InputSourceState.gureumEnabled([gureum, apple]))
        XCTAssertTrue(InputSourceState.appleKoreanEnabled([gureum, apple]))
    }

    func testOtherGureumLayoutsDoNotCountAsTwoSet() {
        let other = EnabledInputSource(
            id: "org.youknowone.inputmethod.Gureum.han3final",
            bundleID: gureum.bundleID
        )
        XCTAssertFalse(InputSourceState.gureumEnabled([other]))
        XCTAssertFalse(InputSourceState.gureumEnabled([
            EnabledInputSource(id: gureum.id, bundleID: "com.example.other")
        ]))
    }

    func testNoEnabledSourcesDoesNotInventGureumRegistration() {
        XCTAssertFalse(InputSourceState.gureumEnabled([]))
    }
}
