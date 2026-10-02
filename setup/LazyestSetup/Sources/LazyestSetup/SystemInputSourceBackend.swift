import AppKit
import Carbon
import Foundation
import LazyestSetupCore

/// Calls macOS directly; users do not need Swift or Command Line Tools installed.
final class SystemInputSourceBackend: InputSourceBackend {
    private(set) var lastError = ""

    private func succeeded(_ status: OSStatus, action: String) -> Bool {
        if status != noErr { lastError = "\(action): \(status)" }
        return status == noErr
    }

    func backupPreferences() -> Bool {
        let manager = FileManager.default
        let preferences = URL(fileURLWithPath: NSHomeDirectory())
            .appendingPathComponent("Library/Preferences/com.apple.HIToolbox.plist")
        guard manager.fileExists(atPath: preferences.path) else { return true }
        let directory = URL(fileURLWithPath: NSHomeDirectory())
            .appendingPathComponent("Library/Application Support/Lazyest Setup/Backups", isDirectory: true)
        do {
            try manager.createDirectory(at: directory, withIntermediateDirectories: true)
            let name = "com.apple.HIToolbox.\(Int(Date().timeIntervalSince1970))-\(UUID().uuidString).plist"
            try manager.copyItem(at: preferences, to: directory.appendingPathComponent(name))
            return true
        } catch {
            return false
        }
    }

    func registerGureum() -> Bool {
        let paths = ["/Library/Input Methods/Gureum.app", NSHomeDirectory() + "/Library/Input Methods/Gureum.app"]
        guard let path = paths.first(where: { FileManager.default.fileExists(atPath: $0) }) else { return false }
        return succeeded(TISRegisterInputSource(URL(fileURLWithPath: path) as CFURL), action: "register")
    }

    private func string(_ source: TISInputSource, _ key: CFString) -> String {
        guard let raw = TISGetInputSourceProperty(source, key) else { return "" }
        return Unmanaged<CFString>.fromOpaque(raw).takeUnretainedValue() as String
    }

    private func rawSources(_ includeDisabled: Bool) -> [TISInputSource]? {
        TISCreateInputSourceList(nil, includeDisabled)?.takeRetainedValue() as? [TISInputSource]
    }

    func sources(includeDisabled: Bool) -> [EnabledInputSource]? {
        guard let all = rawSources(true) else { return nil }
        let disabledMethods = Set(all.filter {
            string($0, kTISPropertyInputSourceType) == (kTISTypeKeyboardInputMethodModeEnabled as String) && !isEnabled($0)
        }.map { string($0, kTISPropertyBundleID) })
        return all.filter {
            includeDisabled || (isEnabled($0) && !disabledMethods.contains(string($0, kTISPropertyBundleID)))
        }.map {
            EnabledInputSource(id: string($0, kTISPropertyInputSourceID), bundleID: string($0, kTISPropertyBundleID))
        }
    }

    private func isEnabled(_ source: TISInputSource) -> Bool {
        guard let raw = TISGetInputSourceProperty(source, kTISPropertyInputSourceIsEnabled) else { return false }
        return CFBooleanGetValue(Unmanaged<CFBoolean>.fromOpaque(raw).takeUnretainedValue())
    }

    private func source(_ id: String) -> TISInputSource? {
        rawSources(true)?.first { string($0, kTISPropertyInputSourceID) == id }
    }

    func enable(_ id: String) -> Bool {
        guard let source = source(id) else { return false }
        return succeeded(TISEnableInputSource(source), action: "enable \(id)")
    }

    func select(_ id: String) -> Bool {
        guard let source = source(id) else { return false }
        return succeeded(TISSelectInputSource(source), action: "select \(id)")
    }

    func disable(_ id: String) -> Bool {
        guard let source = source(id) else { return false }
        return succeeded(TISDisableInputSource(source), action: "disable \(id)")
    }
}
