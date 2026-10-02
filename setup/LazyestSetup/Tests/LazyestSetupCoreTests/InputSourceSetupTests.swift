import XCTest
@testable import LazyestSetupCore

final class InputSourceSetupTests: XCTestCase {
    private final class Backend: InputSourceBackend {
        let apple = EnabledInputSource(id: "com.apple.inputmethod.Korean.2SetKorean", bundleID: "com.apple.inputmethod.Korean")
        let gureum = EnabledInputSource(id: "org.youknowone.inputmethod.Gureum.han2", bundleID: "org.youknowone.inputmethod.Gureum")
        let abc = EnabledInputSource(id: "com.apple.keylayout.ABC", bundleID: "com.apple.KeyboardLayouts")
        var registered = true
        var activationWorks = true
        var selectionWorks = true
        var cleanupWorks = true
        var enabled: [EnabledInputSource] = []
        var events: [String] = []

        init() { enabled = [apple, abc] }
        func registerGureum() -> Bool { events.append("register"); return registered }
        func sources(includeDisabled: Bool) -> [EnabledInputSource]? {
            includeDisabled ? [apple, gureum, abc] : enabled
        }
        func enable(_ id: String) -> Bool {
            events.append("enable:" + id)
            guard activationWorks else { return false }
            if !enabled.contains(where: { $0.id == id }) {
                enabled.append(id == gureum.id ? gureum : apple)
            }
            return true
        }
        func select(_ id: String) -> Bool { events.append("select:" + id); return selectionWorks }
        func disable(_ id: String) -> Bool {
            events.append("disable:" + id)
            guard cleanupWorks else { return false }
            enabled.removeAll { $0.id == id }
            return true
        }
    }

    func testSettingRegistersEnablesAndSelectsBeforeRemovingFallback() {
        let backend = Backend()
        XCTAssertEqual(InputSourceSetup.apply(using: backend), .applied)
        XCTAssertEqual(backend.events, ["register", "enable:" + backend.gureum.id,
                                        "select:" + backend.gureum.id, "disable:" + backend.apple.id])
        XCTAssertTrue(backend.enabled.contains { $0.id == backend.abc.id })
        XCTAssertFalse(InputSourceState.appleKoreanEnabled(backend.enabled))
    }

    func testRegistrationFailurePreservesFallback() {
        let backend = Backend(); backend.registered = false
        XCTAssertEqual(InputSourceSetup.apply(using: backend), .registrationFailed)
        XCTAssertTrue(InputSourceState.appleKoreanEnabled(backend.enabled))
        XCTAssertEqual(backend.events, ["register"])
    }

    func testActivationAndSelectionFailuresPreserveFallback() {
        for failSelection in [false, true] {
            let backend = Backend()
            backend.activationWorks = failSelection
            backend.selectionWorks = false
            XCTAssertEqual(InputSourceSetup.apply(using: backend), .activationFailed)
            XCTAssertTrue(InputSourceState.appleKoreanEnabled(backend.enabled))
            XCTAssertFalse(backend.events.contains { $0.hasPrefix("disable:") })
        }
    }

    func testRemovalFailureIsNotReportedAsApplied() {
        let backend = Backend(); backend.cleanupWorks = false
        XCTAssertEqual(InputSourceSetup.apply(using: backend), .cleanupFailed)
        XCTAssertTrue(InputSourceState.gureumEnabled(backend.enabled))
        XCTAssertTrue(InputSourceState.appleKoreanEnabled(backend.enabled))
    }

    func testResetActivatesAppleBeforeDisablingGureum() {
        let backend = Backend(); backend.enabled = [backend.gureum, backend.abc]
        XCTAssertEqual(InputSourceSetup.reset(using: backend), .applied)
        XCTAssertEqual(backend.events, ["enable:" + backend.apple.id, "select:" + backend.apple.id,
                                        "disable:" + backend.gureum.id])
        XCTAssertTrue(InputSourceState.appleKoreanEnabled(backend.enabled))
        XCTAssertFalse(InputSourceState.gureumEnabled(backend.enabled))
    }

    func testResetSelectionFailureKeepsGureum() {
        let backend = Backend(); backend.enabled = [backend.gureum, backend.abc]; backend.selectionWorks = false
        XCTAssertEqual(InputSourceSetup.reset(using: backend), .activationFailed)
        XCTAssertTrue(InputSourceState.gureumEnabled(backend.enabled))
        XCTAssertFalse(backend.events.contains { $0.hasPrefix("disable:") })
    }
}
