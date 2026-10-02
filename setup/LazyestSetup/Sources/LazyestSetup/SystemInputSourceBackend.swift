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

    // TIS retains default mode flags after a mode is removed. Check the saved
    // enabled list as well so Roman/default modes do not falsely count as active.
    func persistedEnabledSources() -> [EnabledInputSource]? {
        guard let sources = sources(includeDisabled: false) else { return nil }
        let domain = "com.apple.HIToolbox" as CFString
        CFPreferencesSynchronize(domain, kCFPreferencesCurrentUser, kCFPreferencesAnyHost)
        guard let items = CFPreferencesCopyAppValue("AppleEnabledInputSources" as CFString, domain) as? [[String: Any]] else { return nil }
        return sources.filter { source in
            if source.bundleID != "org.youknowone.inputmethod.Gureum" && source.bundleID != "com.apple.inputmethod.Korean" { return true }
            return items.contains { item in
                guard item["Bundle ID"] as? String == source.bundleID else { return false }
                if source.id == "org.youknowone.inputmethod.Korean" || source.id == "com.apple.inputmethod.Korean" {
                    return item["InputSourceKind"] as? String == "Keyboard Input Method"
                }
                return item["Input Mode"] as? String == source.id
            }
        }
    }

    func persistConfiguredSources() -> Bool {
        let domain = "com.apple.HIToolbox" as CFString
        let key = "AppleEnabledInputSources" as CFString
        CFPreferencesSynchronize(domain, kCFPreferencesCurrentUser, kCFPreferencesAnyHost)
        guard var items = CFPreferencesCopyAppValue(key, domain) as? [[String: Any]] else { return false }
        // Preserve layouts and palettes while replacing only Korean/Gureum entries.
        items.removeAll { item in
            let bundle = item["Bundle ID"] as? String
            return bundle == "com.apple.inputmethod.Korean" || bundle == "org.youknowone.inputmethod.Gureum"
        }
        items += [
            ["InputSourceKind": "Keyboard Input Method", "Bundle ID": "org.youknowone.inputmethod.Gureum"],
            ["InputSourceKind": "Input Mode", "Bundle ID": "org.youknowone.inputmethod.Gureum", "Input Mode": "org.youknowone.inputmethod.Gureum.han2"]
        ]
        CFPreferencesSetAppValue(key, items as CFArray, domain)
        return CFPreferencesAppSynchronize(domain)
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
