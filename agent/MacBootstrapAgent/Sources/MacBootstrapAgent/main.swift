import AppKit
import ApplicationServices
import Carbon
import Darwin
import Foundation
import ImageIO
import IOKit.pwr_mgt

let dockAnchorStatusNotification = Notification.Name("MacBootstrapDockAnchorStatusChanged")

enum AgentLanguage: String {
    case automatic = "auto"
    case english = "en"
    case korean = "ko"
}

func agentSharedLanguageConfigPath() -> URL {
    let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
        ?? URL(fileURLWithPath: NSHomeDirectory()).appendingPathComponent("Library/Application Support", isDirectory: true)
    return base.appendingPathComponent("MacBootstrapAgent", isDirectory: true).appendingPathComponent("language.conf")
}

func agentSavedLanguageCode() -> String {
    let path = agentSharedLanguageConfigPath()
    if let value = try? String(contentsOf: path, encoding: .utf8).trimmingCharacters(in: .whitespacesAndNewlines),
       !value.isEmpty {
        return value
    }
    return UserDefaults.standard.string(forKey: "MacBootstrapLanguage") ?? AgentLanguage.automatic.rawValue
}

func saveAgentLanguageCode(_ code: String) throws {
    guard AgentLanguage(rawValue: code) != nil else { return }
    let path = agentSharedLanguageConfigPath()
    try FileManager.default.createDirectory(at: path.deletingLastPathComponent(), withIntermediateDirectories: true)
    try code.write(to: path, atomically: true, encoding: .utf8)
    UserDefaults.standard.set(code, forKey: "MacBootstrapLanguage")
}

func agentLanguage() -> AgentLanguage {
    let selected = AgentLanguage(rawValue: agentSavedLanguageCode()) ?? .automatic
    if selected != .automatic {
        return selected
    }
    let preferred = Locale.preferredLanguages.first?.lowercased() ?? ""
    return preferred.hasPrefix("ko") ? .korean : .english
}

func agentText(_ key: String) -> String {
    let ko: [String: String] = [
        "title": "MacBootstrapAgent",
        "tab.apps": "앱 단축키",
        "tab.screenshots": "스크린샷",
        "tab.keepAwake": "슬립모드 방지",
        "tab.dockAnchor": "Dock 고정",
        "apps.hint": "단축키로 앱을 숨기거나 다시 표시합니다. 실행 중이 아니면 앱을 엽니다.",
        "apps.enabled": "앱 단축키 사용",
        "apps.countSuffix": "개 앱",
        "apps.name": "이름",
        "apps.bundle": "번들 ID",
        "apps.shortcut": "단축키",
        "apps.add": "앱 추가",
        "apps.addRunning": "앱 추가",
        "apps.editTitle": "앱 단축키 추가",
        "apps.editRow": "변경",
        "apps.applyRow": "적용",
        "apps.editName": "이름",
        "apps.editBundle": "번들 ID",
        "apps.editShortcut": "단축키",
        "apps.editShortcutHint": "단축키를 직접 누르세요",
        "apps.capturing": "단축키 입력 중",
        "apps.captured": "캡처됨",
        "apps.cancel": "취소",
        "apps.remove": "삭제",
        "screenshots.title": "스크린샷",
        "screenshots.detail": "기본 스크린샷 단축키는 그대로 사용합니다. 파일은 현재 macOS 저장 위치에 남고 같은 이미지가 클립보드에도 복사됩니다.",
        "screenshots.folder": "저장 폴더",
        "screenshots.choose": "변경",
        "screenshots.open": "폴더 열기",
        "screenshots.copy": "파일 저장 + 클립보드 복사",
        "screenshots.immediate": "캡처 직후 바로 복사",
        "screenshots.immediateDetail": "떠 있는 썸네일을 끄고 캡처 파일을 즉시 저장합니다.",
        "state.on": "켜짐",
        "state.off": "꺼짐",
        "keep.title": "슬립모드 방지",
        "keep.detail": "잠금 화면이나 디스플레이가 꺼져도 Mac은 깨어 있어 원격 작업을 계속합니다.",
        "keep.prevent": "슬립모드 방지 사용",
        "keep.policy": "화면 잠금과 디스플레이 꺼짐은 그대로 허용하고 시스템 잠자기만 막습니다. MacBook 덮개를 닫으면 전원 및 외부 디스플레이 상태에 따라 macOS가 잠들 수 있습니다.",
        "keep.display": "디스플레이 계속 켜두기",
        "dock.title": "Dock 고정",
        "dock.detail": "Dock을 선택한 모니터로 옮기고 다른 모니터로 이동하지 않게 유지합니다.",
        "dock.checkbox": "Dock 고정 사용",
        "dock.display": "고정할 모니터",
        "dock.permission": "권한 설정",
        "dock.status.off": "꺼짐",
        "dock.status.active": "실행 중",
        "dock.status.needsPermission": "Accessibility 권한 미적용",
        "dock.status.failed": "이벤트 감시 시작 실패",
        "dock.status.agentOff": "Agent 개입 없음",
        "dock.status.nativeOnly": "macOS 기본 Dock 이동만 사용",
        "dock.status.onDisplay": "현재 Dock",
        "dock.status.unknownDisplay": "현재 Dock 위치 감지 불가",
        "dock.status.layoutLimited": "디스플레이 하단 높이가 달라 macOS 기본 Dock이 가장 아래 모니터에 머물 수 있음",
        "dock.status.targetLimited": "선택 모니터 하단이 전체 데스크톱 하단이 아니라 macOS 기본 Dock 이동이 제한될 수 있음",
        "dock.status.targetReady": "선택 모니터 하단에서 Dock 사용 가능",
        "footer.reload": "설정 다시 불러오기",
        "language.label": "언어",
        "language.auto": "자동",
        "language.korean": "한국어",
        "language.english": "English",
        "footer.save": "저장",
        "status.saved": "자동 저장됨",
        "status.loaded": "설정 불러옴",
        "status.failed": "저장 실패",
        "menu.settings": "설정 열기",
        "menu.keepAwake": "슬립모드 방지",
        "menu.reload": "다시 불러오기",
        "menu.quit": "종료"
    ]
    if agentLanguage() == .korean, let value = ko[key] {
        return value
    }
    let en: [String: String] = [
        "title": "MacBootstrapAgent",
        "tab.apps": "App Hotkeys",
        "tab.screenshots": "Screenshots",
        "tab.keepAwake": "Prevent Sleep",
        "tab.dockAnchor": "Dock Anchor",
        "apps.hint": "Use a hotkey to hide or restore an app. The app opens when it is not running.",
        "apps.enabled": "Enable app hotkeys",
        "apps.countSuffix": " apps",
        "apps.name": "Name",
        "apps.bundle": "Bundle ID",
        "apps.shortcut": "Shortcut",
        "apps.add": "Add App",
        "apps.addRunning": "Add App",
        "apps.editTitle": "Add App Hotkey",
        "apps.editRow": "Change",
        "apps.applyRow": "Apply",
        "apps.editName": "Name",
        "apps.editBundle": "Bundle ID",
        "apps.editShortcut": "Shortcut",
        "apps.editShortcutHint": "Press the shortcut",
        "apps.capturing": "Capturing shortcut",
        "apps.captured": "Captured",
        "apps.cancel": "Cancel",
        "apps.remove": "Remove",
        "screenshots.title": "Screenshots",
        "screenshots.detail": "Keep using the standard screenshot shortcuts. The file stays in the current macOS save location and the same image is copied to the clipboard.",
        "screenshots.folder": "Save folder",
        "screenshots.choose": "Change",
        "screenshots.open": "Open folder",
        "screenshots.copy": "Save file + copy to clipboard",
        "screenshots.immediate": "Copy immediately after capture",
        "screenshots.immediateDetail": "Disables the floating thumbnail so the capture file is saved immediately.",
        "state.on": "On",
        "state.off": "Off",
        "keep.title": "Prevent Sleep",
        "keep.detail": "Keeps the Mac awake for remote work while the screen is locked or the display is off.",
        "keep.prevent": "Prevent Sleep",
        "keep.policy": "Screen locking and display sleep remain available; only system sleep is prevented. Closing a MacBook may still sleep it depending on power and external display state.",
        "keep.display": "Keep display awake",
        "dock.title": "Dock Anchor",
        "dock.detail": "Moves the Dock to the selected display and keeps it from moving to another display.",
        "dock.checkbox": "Keep Dock on display",
        "dock.display": "Pinned display",
        "dock.permission": "Permission Settings",
        "dock.status.off": "Off",
        "dock.status.active": "Active",
        "dock.status.needsPermission": "Accessibility permission not applied",
        "dock.status.failed": "Failed to start event monitor",
        "dock.status.agentOff": "Agent not intercepting",
        "dock.status.nativeOnly": "Using native macOS Dock movement only",
        "dock.status.onDisplay": "Current Dock",
        "dock.status.unknownDisplay": "Current Dock display unknown",
        "dock.status.layoutLimited": "Display bottom edges are not aligned, so native macOS Dock can stay on the lowest display",
        "dock.status.targetLimited": "The selected display is not on the bottom edge of the full desktop, so native Dock movement can be limited",
        "dock.status.targetReady": "Dock can be used on the selected display edge",
        "footer.reload": "Reload Settings",
        "language.label": "Language",
        "language.auto": "Automatic",
        "language.korean": "한국어",
        "language.english": "English",
        "footer.save": "Save",
        "status.saved": "Saved automatically",
        "status.loaded": "Settings loaded",
        "status.failed": "Save failed",
        "menu.settings": "Open Settings",
        "menu.keepAwake": "Prevent Sleep",
        "menu.reload": "Reload",
        "menu.quit": "Quit"
    ]
    return en[key] ?? key
}

struct AppBinding {
    var shortcut: String
    var bundleID: String
    var label: String
    var isEnabled: Bool
}

struct TextBinding {
    var shortcut: String
    var text: String
    var label: String
}

enum HotkeyAction {
    case toggleApp(AppBinding)
    case insertText(TextBinding)
}

struct ParsedShortcut {
    let keyCode: UInt32
    let modifiers: UInt32
}

final class Config {
    let hotkeyPath: String
    let bootstrapPath: String
    private(set) var appHotkeysEnabled: Bool
    private(set) var screenshotDir: String
    private(set) var screenshotClipboardWatch: Bool
    private(set) var keepAwakeEnabled: Bool
    private(set) var keepDisplayAwake: Bool
    private(set) var dockAnchorEnabled: Bool
    private(set) var dockAnchorDisplayID: UInt32?

    init(hotkeyPath: String, bootstrapPath: String) {
        self.hotkeyPath = hotkeyPath
        self.bootstrapPath = bootstrapPath
        self.appHotkeysEnabled = false
        self.screenshotDir = currentMacOSScreenshotDir()
        self.screenshotClipboardWatch = false
        self.keepAwakeEnabled = false
        self.keepDisplayAwake = false
        self.dockAnchorEnabled = false
        self.dockAnchorDisplayID = currentDisplayID()
        ensureConfigFiles()
        loadBootstrap()
        syncScreenshotDirFromSystem()
    }

    func loadBindings() throws -> [AppBinding] {
        let content = try String(contentsOfFile: hotkeyPath, encoding: .utf8)
        return content.split(separator: "\n").compactMap { rawLine in
            let line = rawLine.trimmingCharacters(in: .whitespaces)
            guard !line.isEmpty, !line.hasPrefix("#") else { return nil }
            let parts = line.split(separator: "|", omittingEmptySubsequences: false).map(String.init)
            guard parts.count >= 4, parts[0] == "toggle-app" else { return nil }
            return AppBinding(
                shortcut: parts[1].trimmingCharacters(in: .whitespaces),
                bundleID: parts[2].trimmingCharacters(in: .whitespaces),
                label: parts[3].trimmingCharacters(in: .whitespaces),
                isEnabled: parts.count < 5 || parts[4] == "1" || parts[4].lowercased() == "true"
            )
        }
    }

    func loadTextBindings() throws -> [TextBinding] {
        let content = try String(contentsOfFile: hotkeyPath, encoding: .utf8)
        return content.split(separator: "\n").compactMap { rawLine in
            let line = rawLine.trimmingCharacters(in: .whitespaces)
            guard !line.isEmpty, !line.hasPrefix("#") else { return nil }
            let parts = line.split(separator: "|", omittingEmptySubsequences: false).map(String.init)
            guard parts.count >= 4, parts[0] == "insert-text" else { return nil }
            return TextBinding(
                shortcut: parts[1].trimmingCharacters(in: .whitespaces),
                text: parts[2],
                label: parts[3].trimmingCharacters(in: .whitespaces)
            )
        }
    }

    func saveBindings(_ bindings: [AppBinding]) throws {
        try saveHotkeys(appBindings: bindings)
    }

    func saveTextBindings(_ bindings: [TextBinding]) throws {
        let appBindings = (try? loadBindings()) ?? []
        try saveHotkeys(appBindings: appBindings)
    }

    func saveHotkeys(appBindings: [AppBinding]) throws {
        let header = """
        # MacBootstrapAgent app hotkeys.
        # Format: toggle-app|shortcut|bundle-id|label|enabled
        # Add, remove, or edit rows from the Agent UI.

        """
        let appBody = appBindings.map { "toggle-app|\($0.shortcut)|\($0.bundleID)|\($0.label)|\($0.isEnabled ? "1" : "0")" }
        let body = appBody.joined(separator: "\n")
        try (header + body + (body.isEmpty ? "" : "\n")).write(toFile: hotkeyPath, atomically: true, encoding: .utf8)
    }

    func saveBootstrap(
        appHotkeysEnabled: Bool,
        screenshotDir: String,
        screenshotClipboardWatch: Bool,
        keepAwakeEnabled: Bool,
        keepDisplayAwake: Bool,
        dockAnchorEnabled: Bool,
        dockAnchorDisplayID: UInt32?
    ) throws {
        self.appHotkeysEnabled = appHotkeysEnabled
        self.screenshotDir = resolveScreenshotDir(screenshotDir)
        self.screenshotClipboardWatch = screenshotClipboardWatch
        self.keepAwakeEnabled = keepAwakeEnabled
        self.keepDisplayAwake = keepDisplayAwake
        self.dockAnchorEnabled = dockAnchorEnabled
        self.dockAnchorDisplayID = dockAnchorDisplayID
        let content = """
        APP_HOTKEYS_ENABLED=\(appHotkeysEnabled ? "1" : "0")
        SCREENSHOT_DIR="\(screenshotDir)"
        SCREENSHOT_CLIPBOARD_WATCH=\(screenshotClipboardWatch ? "1" : "0")
        KEEP_AWAKE_ENABLED=\(keepAwakeEnabled ? "1" : "0")
        KEEP_DISPLAY_AWAKE=\(keepDisplayAwake ? "1" : "0")
        DOCK_ANCHOR_ENABLED=\(dockAnchorEnabled ? "1" : "0")
        DOCK_ANCHOR_DISPLAY_ID=\(dockAnchorDisplayID.map(String.init) ?? "auto")
        AGENT_REGISTERED_BUNDLE_IDS=()
        """
        try content.write(toFile: bootstrapPath, atomically: true, encoding: .utf8)
    }

    func setKeepAwakeEnabled(_ enabled: Bool) throws {
        try saveBootstrap(
            appHotkeysEnabled: appHotkeysEnabled,
            screenshotDir: screenshotDir,
            screenshotClipboardWatch: screenshotClipboardWatch,
            keepAwakeEnabled: enabled,
            keepDisplayAwake: keepDisplayAwake,
            dockAnchorEnabled: dockAnchorEnabled,
            dockAnchorDisplayID: dockAnchorDisplayID
        )
    }

    func reloadBootstrap() {
        appHotkeysEnabled = false
        screenshotDir = currentMacOSScreenshotDir()
        screenshotClipboardWatch = false
        keepAwakeEnabled = false
        keepDisplayAwake = false
        dockAnchorEnabled = false
        dockAnchorDisplayID = currentDisplayID()
        loadBootstrap()
        syncScreenshotDirFromSystem()
    }

    func syncScreenshotDirFromSystem() {
        screenshotDir = currentMacOSScreenshotDir()
    }

    private func ensureConfigFiles() {
        let dir = URL(fileURLWithPath: hotkeyPath).deletingLastPathComponent().path
        try? FileManager.default.createDirectory(atPath: dir, withIntermediateDirectories: true)
        if !FileManager.default.fileExists(atPath: hotkeyPath) {
            try? defaultHotkeys().write(toFile: hotkeyPath, atomically: true, encoding: .utf8)
        }
        if !FileManager.default.fileExists(atPath: bootstrapPath) {
            try? defaultBootstrap().write(toFile: bootstrapPath, atomically: true, encoding: .utf8)
        }
    }

    private func loadBootstrap() {
        guard let content = try? String(contentsOfFile: bootstrapPath, encoding: .utf8) else { return }
        for rawLine in content.split(separator: "\n") {
            let line = rawLine.trimmingCharacters(in: .whitespaces)
            if line.hasPrefix("APP_HOTKEYS_ENABLED="), let value = shellValue(line) {
                appHotkeysEnabled = value == "1" || value.lowercased() == "true"
            } else if line.hasPrefix("SCREENSHOT_DIR="), let value = shellValue(line) {
                screenshotDir = resolveScreenshotDir(value)
            } else if line.hasPrefix("SCREENSHOT_CLIPBOARD_WATCH="), let value = shellValue(line) {
                screenshotClipboardWatch = value == "1" || value.lowercased() == "true"
            } else if line.hasPrefix("KEEP_AWAKE_ENABLED="), let value = shellValue(line) {
                keepAwakeEnabled = value == "1" || value.lowercased() == "true"
            } else if line.hasPrefix("KEEP_DISPLAY_AWAKE="), let value = shellValue(line) {
                keepDisplayAwake = value == "1" || value.lowercased() == "true"
            } else if line.hasPrefix("DOCK_ANCHOR_ENABLED="), let value = shellValue(line) {
                dockAnchorEnabled = value == "1" || value.lowercased() == "true"
            } else if line.hasPrefix("DOCK_ANCHOR_DISPLAY_ID="), let value = shellValue(line) {
                dockAnchorDisplayID = UInt32(value)
            }
        }
    }

    private func shellValue(_ line: String) -> String? {
        guard let equals = line.firstIndex(of: "=") else { return nil }
        let raw = String(line[line.index(after: equals)...])
        return unquote(raw).replacingOccurrences(of: "$HOME", with: NSHomeDirectory())
    }

    private func resolveScreenshotDir(_ value: String) -> String {
        if value.lowercased() == "auto" || value.isEmpty {
            return currentMacOSScreenshotDir()
        }
        return NSString(string: value).expandingTildeInPath
    }

    private func unquote(_ raw: String) -> String {
        let trimmed = raw.trimmingCharacters(in: .whitespaces)
        if trimmed.hasPrefix("\""), trimmed.hasSuffix("\""), trimmed.count >= 2 {
            return String(trimmed.dropFirst().dropLast())
        }
        return trimmed
    }
}

final class BindingRow {
    var binding: AppBinding
    var draftShortcut = ""
    let iconView: NSImageView
    let label: NSTextField
    let bundleID: NSTextField
    let shortcutField: ShortcutCaptureField
    let enabledSwitch: NSSwitch
    let editButton: NSButton
    let removeButton: NSButton
    var isEditing = false

    init(binding: AppBinding) {
        self.binding = binding
        self.draftShortcut = binding.shortcut
        self.iconView = NSImageView()
        self.label = NSTextField(labelWithString: binding.label)
        self.bundleID = NSTextField(labelWithString: binding.bundleID)
        self.shortcutField = ShortcutCaptureField(string: binding.shortcut)
        self.shortcutField.lastCompleteShortcut = binding.shortcut
        self.enabledSwitch = NSSwitch(frame: .zero)
        self.editButton = NSButton(title: agentText("apps.editRow"), target: nil, action: nil)
        self.removeButton = NSButton(title: "", target: nil, action: nil)
        if let appURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: binding.bundleID) {
            self.iconView.image = NSWorkspace.shared.icon(forFile: appURL.path)
        } else {
            self.iconView.image = NSImage(systemSymbolName: "app", accessibilityDescription: binding.label)
        }
        self.iconView.imageScaling = .scaleProportionallyUpOrDown
        self.iconView.setContentHuggingPriority(.required, for: .horizontal)
        self.label.font = NSFont.systemFont(ofSize: 13, weight: .medium)
        self.label.lineBreakMode = .byTruncatingTail
        self.bundleID.font = NSFont.systemFont(ofSize: 11)
        self.bundleID.textColor = .secondaryLabelColor
        self.bundleID.lineBreakMode = .byTruncatingMiddle
        self.enabledSwitch.state = binding.isEnabled ? .on : .off
        self.enabledSwitch.toolTip = agentText("apps.enabled")
        self.enabledSwitch.setAccessibilityLabel("\(binding.label) \(agentText("apps.enabled"))")
        setEditing(false)
    }

    func update(_ binding: AppBinding) {
        self.binding = binding
        self.draftShortcut = binding.shortcut
        label.stringValue = binding.label
        bundleID.stringValue = binding.bundleID
        shortcutField.stringValue = binding.shortcut
        shortcutField.lastCompleteShortcut = binding.shortcut
        enabledSwitch.state = binding.isEnabled ? .on : .off
        refreshEnabledAppearance()
    }

    func setEditing(_ editing: Bool) {
        isEditing = editing
        shortcutField.isEditable = false
        shortcutField.isSelectable = false
        shortcutField.isBordered = editing
        shortcutField.drawsBackground = editing
        shortcutField.backgroundColor = editing ? .textBackgroundColor : .clear
        editButton.title = editing ? agentText("apps.applyRow") : agentText("apps.editRow")
        if editing {
            draftShortcut = binding.shortcut
            shortcutField.lastCompleteShortcut = binding.shortcut
            shortcutField.placeholderString = agentText("apps.editShortcutHint")
        } else {
            removeButton.title = ""
            removeButton.image = NSImage(systemSymbolName: "trash", accessibilityDescription: agentText("apps.remove"))
            removeButton.imagePosition = .imageOnly
            removeButton.contentTintColor = .systemRed
            removeButton.toolTip = agentText("apps.remove")
        }
        refreshEnabledAppearance()
    }

    func cancelEditing() {
        shortcutField.stringValue = binding.shortcut
        shortcutField.lastCompleteShortcut = binding.shortcut
        setEditing(false)
    }

    func refreshEnabledAppearance() {
        let enabled = enabledSwitch.state == .on
        iconView.alphaValue = enabled ? 1 : 0.5
        label.textColor = enabled ? .labelColor : .secondaryLabelColor
        bundleID.textColor = enabled ? .secondaryLabelColor : .tertiaryLabelColor
        shortcutField.textColor = enabled ? .labelColor : .tertiaryLabelColor
    }
}

final class TextShortcutRow {
    var binding: TextBinding
    let labelField: NSTextField
    let textField: NSTextField
    let shortcutField: ShortcutCaptureField
    let editButton: NSButton
    var isEditing = false

    init(binding: TextBinding) {
        self.binding = binding
        self.labelField = NSTextField(string: binding.label)
        self.textField = NSTextField(string: binding.text)
        self.shortcutField = ShortcutCaptureField(string: binding.shortcut)
        self.shortcutField.lastCompleteShortcut = binding.shortcut
        self.editButton = NSButton(title: agentText("apps.editRow"), target: nil, action: nil)
        setEditing(false)
    }

    func updateFromFields() {
        binding = TextBinding(
            shortcut: shortcutField.lastCompleteShortcut.trimmingCharacters(in: .whitespaces),
            text: textField.stringValue,
            label: labelField.stringValue.trimmingCharacters(in: .whitespaces)
        )
    }

    func setEditing(_ editing: Bool) {
        isEditing = editing
        for field in [labelField, textField, shortcutField] {
            field.isEditable = editing
            field.isSelectable = true
            field.isBordered = editing
            field.drawsBackground = editing
            field.backgroundColor = editing ? .textBackgroundColor : .clear
        }
        editButton.title = editing ? agentText("apps.applyRow") : agentText("apps.editRow")
    }
}

final class FlippedDocumentView: NSView {
    override var isFlipped: Bool { true }
}

final class ShortcutCaptureField: NSTextField {
    var onShortcutCaptured: ((String) -> Void)?
    var onCancelCapture: (() -> Void)?
    var onFocus: (() -> Void)?
    var lastCompleteShortcut = ""
    var isCapturingShortcut = false

    override var acceptsFirstResponder: Bool { true }
    override var needsPanelToBecomeKey: Bool { true }

    override func becomeFirstResponder() -> Bool {
        if stringValue.isEmpty {
            placeholderString = agentText("apps.editShortcutHint")
        }
        onFocus?()
        return true
    }

    override func mouseDown(with event: NSEvent) {
        window?.makeFirstResponder(self)
    }

    override func performKeyEquivalent(with event: NSEvent) -> Bool {
        guard isCapturingShortcut else { return false }
        return capture(event)
    }

    override func keyDown(with event: NSEvent) {
        guard isCapturingShortcut else {
            super.keyDown(with: event)
            return
        }
        _ = capture(event)
    }

    override func flagsChanged(with event: NSEvent) {
        guard isCapturingShortcut else {
            super.flagsChanged(with: event)
            return
        }
        guard let modifiers = modifierString(from: event), !modifiers.isEmpty else {
            return
        }
        stringValue = modifiers
        needsDisplay = true
    }

    @discardableResult
    private func capture(_ event: NSEvent) -> Bool {
        if event.keyCode == 53 {
            onCancelCapture?()
            return true
        }
        guard let shortcut = shortcutString(from: event) else {
            return true
        }
        stringValue = shortcut
        lastCompleteShortcut = shortcut
        needsDisplay = true
        onShortcutCaptured?(shortcut)
        return true
    }
}

final class SettingsTabButton: NSButton {
    private let tabLabel: NSTextField
    private let tabIcon: NSImageView

    var isSelectedTab = false {
        didSet { updateAppearance() }
    }

    init(title: String, symbolName: String) {
        tabLabel = NSTextField(labelWithString: title)
        tabIcon = NSImageView(image: NSImage(systemSymbolName: symbolName, accessibilityDescription: title) ?? NSImage())
        super.init(frame: .zero)

        self.title = ""
        isBordered = false
        setButtonType(.momentaryPushIn)
        wantsLayer = true
        layer?.cornerRadius = 6
        setAccessibilityLabel(title)

        tabLabel.font = NSFont.systemFont(ofSize: 12, weight: .medium)
        tabLabel.alignment = .center
        tabLabel.lineBreakMode = .byTruncatingTail
        tabIcon.symbolConfiguration = NSImage.SymbolConfiguration(pointSize: 12, weight: .medium)
        tabIcon.setContentHuggingPriority(.required, for: .horizontal)

        let content = NSStackView(views: [tabIcon, tabLabel])
        content.orientation = .horizontal
        content.alignment = .centerY
        content.spacing = 7
        content.translatesAutoresizingMaskIntoConstraints = false
        addSubview(content)
        NSLayoutConstraint.activate([
            content.centerXAnchor.constraint(equalTo: centerXAnchor),
            content.centerYAnchor.constraint(equalTo: centerYAnchor),
            content.leadingAnchor.constraint(greaterThanOrEqualTo: leadingAnchor, constant: 8),
            content.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -8),
            heightAnchor.constraint(equalToConstant: 32)
        ])
        updateAppearance()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func updateLayer() {
        super.updateLayer()
        updateAppearance()
    }

    private func updateAppearance() {
        guard let layer else { return }
        layer.backgroundColor = (isSelectedTab
            ? NSColor.controlAccentColor.withAlphaComponent(0.2)
            : NSColor.controlBackgroundColor.withAlphaComponent(0.55)).cgColor
        layer.borderWidth = 1
        layer.borderColor = (isSelectedTab
            ? NSColor.controlAccentColor.withAlphaComponent(0.45)
            : NSColor.separatorColor.withAlphaComponent(0.4)).cgColor
        tabLabel.textColor = isSelectedTab ? .labelColor : .secondaryLabelColor
        tabIcon.contentTintColor = isSelectedTab ? .controlAccentColor : .secondaryLabelColor
    }
}

final class SettingsWindowController: NSWindowController {
    private let config: Config
    private var rows: [BindingRow] = []
    private var textRows: [TextShortcutRow] = []
    private let bindingsStack = NSStackView()
    private let textBindingsStack = NSStackView()
    private let appsHintLabel = NSTextField(labelWithString: agentText("apps.hint"))
    private let textHintLabel = NSTextField(labelWithString: agentText("text.hint"))
    private var screenshotDirectoryPath = ""
    private var shortcutCaptureMonitor: Any?
    private weak var activeShortcutField: ShortcutCaptureField?
    private var activeShortcutLabel = ""
    private weak var activeEditingRow: BindingRow?
    private lazy var appHotkeysSwitch = settingSwitch(action: #selector(toggleAppHotkeys))
    private lazy var screenshotFolderButton = pathButton(action: #selector(openScreenshotDirectory))
    private lazy var screenshotWatchSwitch = settingSwitch(action: #selector(toggleScreenshotWatch))
    private lazy var screenshotImmediateSwitch = settingSwitch(action: #selector(toggleScreenshotImmediateCopy))
    private lazy var keepAwakeSwitch = settingSwitch(action: #selector(toggleKeepAwake))
    private lazy var dockAnchorSwitch = settingSwitch(action: #selector(toggleDockAnchor))
    private lazy var dockPermissionButton = actionButton(title: agentText("dock.permission"), action: #selector(openAccessibilitySettings))
    private lazy var appAddButton = actionButton(title: agentText("apps.addRunning"), action: #selector(addRunningApp))
    private lazy var footerReloadButton = iconButton(symbolName: "arrow.clockwise", tooltip: agentText("footer.reload"), action: #selector(reloadPressed))
    private let languagePopup = NSPopUpButton()
    private let settingsTabs = NSTabView()
    private var tabButtons: [SettingsTabButton] = []
    private let dockDisplayPopup = NSPopUpButton()
    private let dockAnchorStatusLabel = NSTextField(labelWithString: "")
    private let statusLabel = NSTextField(labelWithString: "")
    var onSave: (() -> Void)?
    var onShortcutCaptureStart: (() -> Void)?
    var onShortcutCaptureEnd: (() -> Void)?
    var onLanguageChange: (() -> Void)?

    init(config: Config) {
        self.config = config
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 820, height: 540),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.title = agentText("title")
        window.isReleasedWhenClosed = false
        window.minSize = NSSize(width: 760, height: 500)
        super.init(window: window)
        buildUI()
        NotificationCenter.default.addObserver(forName: dockAnchorStatusNotification, object: nil, queue: .main) { [weak self] note in
            self?.refreshDockAnchorUI(status: note.object as? String)
        }
        NotificationCenter.default.addObserver(forName: NSWindow.didResignKeyNotification, object: window, queue: .main) { [weak self] _ in
            self?.stopShortcutCaptureMonitor(reloadHotkeys: true)
        }
        loadFromDisk()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func buildUI() {
        guard let contentView = window?.contentView else { return }
        let root = NSStackView()
        root.orientation = .vertical
        root.alignment = .width
        root.spacing = 10
        root.edgeInsets = NSEdgeInsets(top: 14, left: 14, bottom: 12, right: 14)
        root.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(root)
        NSLayoutConstraint.activate([
            root.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            root.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            root.topAnchor.constraint(equalTo: contentView.topAnchor),
            root.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ])

        let tabBarRow = NSStackView()
        tabBarRow.orientation = .horizontal
        let tabBar = NSStackView()
        tabBar.orientation = .horizontal
        tabBar.distribution = .fillEqually
        tabBar.spacing = 4
        let tabDefinitions = [
            (agentText("tab.apps"), "keyboard"),
            (agentText("tab.screenshots"), "camera.viewfinder"),
            (agentText("tab.keepAwake"), "moon.zzz"),
            (agentText("tab.dockAnchor"), "dock.rectangle")
        ]
        for (index, definition) in tabDefinitions.enumerated() {
            let button = SettingsTabButton(title: definition.0, symbolName: definition.1)
            button.target = self
            button.action = #selector(selectSettingsTab(_:))
            button.tag = index
            button.isSelectedTab = index == 0
            tabButtons.append(button)
            tabBar.addArrangedSubview(button)
        }
        tabBar.widthAnchor.constraint(equalToConstant: 560).isActive = true
        tabBarRow.addArrangedSubview(NSView())
        tabBarRow.addArrangedSubview(tabBar)
        tabBarRow.addArrangedSubview(NSView())
        root.addArrangedSubview(tabBarRow)

        settingsTabs.tabViewType = .noTabsNoBorder
        settingsTabs.frame = NSRect(x: 0, y: 0, width: 792, height: 400)
        settingsTabs.translatesAutoresizingMaskIntoConstraints = false
        settingsTabs.addTabViewItem(appBindingsTab())
        settingsTabs.addTabViewItem(screenshotsTab())
        settingsTabs.addTabViewItem(keepAwakeTab())
        settingsTabs.addTabViewItem(dockAnchorTab())
        root.addArrangedSubview(settingsTabs)
        settingsTabs.widthAnchor.constraint(equalTo: contentView.widthAnchor, constant: -28).isActive = true
        settingsTabs.heightAnchor.constraint(greaterThanOrEqualToConstant: 400).isActive = true

        let footer = NSStackView()
        footer.orientation = .horizontal
        footer.spacing = 8
        statusLabel.textColor = .secondaryLabelColor
        statusLabel.font = NSFont.systemFont(ofSize: 11)
        footer.addArrangedSubview(statusLabel)
        footer.addArrangedSubview(NSView())
        let languageLabel = NSTextField(labelWithString: agentText("language.label"))
        languageLabel.textColor = .secondaryLabelColor
        languageLabel.font = NSFont.systemFont(ofSize: 11)
        footer.addArrangedSubview(languageLabel)
        configureLanguagePopup()
        languagePopup.target = self
        languagePopup.action = #selector(changeLanguage)
        languagePopup.widthAnchor.constraint(equalToConstant: 118).isActive = true
        footer.addArrangedSubview(languagePopup)
        footer.addArrangedSubview(footerReloadButton)
        root.addArrangedSubview(footer)
    }

    private func configureLanguagePopup() {
        languagePopup.removeAllItems()
        let options: [(String, String)] = [
            (agentText("language.auto"), AgentLanguage.automatic.rawValue),
            (agentText("language.korean"), AgentLanguage.korean.rawValue),
            (agentText("language.english"), AgentLanguage.english.rawValue)
        ]
        for option in options {
            languagePopup.addItem(withTitle: option.0)
            languagePopup.lastItem?.representedObject = option.1
        }
        let savedCode = agentSavedLanguageCode()
        if let index = languagePopup.itemArray.firstIndex(where: { ($0.representedObject as? String) == savedCode }) {
            languagePopup.selectItem(at: index)
        } else {
            languagePopup.selectItem(at: 0)
        }
    }

    @objc private func changeLanguage() {
        guard let code = languagePopup.selectedItem?.representedObject as? String else { return }
        do {
            try saveAgentLanguageCode(code)
            onLanguageChange?()
        } catch {
            statusLabel.stringValue = "\(agentText("status.failed")): \(error.localizedDescription)"
        }
    }

    @objc private func selectSettingsTab(_ sender: SettingsTabButton) {
        for button in tabButtons {
            button.isSelectedTab = button === sender
        }
        settingsTabs.selectTabViewItem(at: sender.tag)
    }

    private func settingSwitch(action: Selector) -> NSSwitch {
        let toggle = NSSwitch(frame: .zero)
        toggle.target = self
        toggle.action = action
        toggle.setContentHuggingPriority(.required, for: .horizontal)
        return toggle
    }

    private func actionButton(title: String, action: Selector) -> NSButton {
        let button = NSButton(title: title, target: self, action: action)
        button.bezelStyle = .rounded
        button.controlSize = .regular
        button.heightAnchor.constraint(equalToConstant: 32).isActive = true
        return button
    }

    private func iconButton(symbolName: String, tooltip: String, action: Selector) -> NSButton {
        let button = NSButton(title: "", target: self, action: action)
        button.bezelStyle = .rounded
        button.controlSize = .regular
        button.toolTip = tooltip
        button.image = NSImage(systemSymbolName: symbolName, accessibilityDescription: tooltip)
        button.imagePosition = .imageOnly
        button.heightAnchor.constraint(equalToConstant: 32).isActive = true
        button.widthAnchor.constraint(equalToConstant: 40).isActive = true
        return button
    }

    private func pathButton(action: Selector) -> NSButton {
        let button = NSButton(title: "", target: self, action: action)
        button.isBordered = false
        button.alignment = .right
        button.contentTintColor = .linkColor
        button.font = NSFont.systemFont(ofSize: 12)
        button.lineBreakMode = .byTruncatingMiddle
        button.toolTip = agentText("screenshots.open")
        return button
    }

    private func pageHeader(title: String, detail: String) -> NSStackView {
        let stack = NSStackView()
        stack.orientation = .vertical
        stack.alignment = .leading
        stack.spacing = 4
        let titleLabel = NSTextField(labelWithString: title)
        titleLabel.font = NSFont.systemFont(ofSize: 17, weight: .semibold)
        stack.addArrangedSubview(titleLabel)
        if !detail.isEmpty {
            let detailLabel = NSTextField(wrappingLabelWithString: detail)
            detailLabel.textColor = .secondaryLabelColor
            detailLabel.font = NSFont.systemFont(ofSize: 12)
            stack.addArrangedSubview(detailLabel)
        }
        return stack
    }

    private func settingRow(title: String, detail: String = "", control: NSView) -> NSStackView {
        let row = NSStackView()
        row.orientation = .horizontal
        row.alignment = .centerY
        row.spacing = 12
        row.edgeInsets = NSEdgeInsets(top: 10, left: 2, bottom: 10, right: 2)

        let labels = NSStackView()
        labels.orientation = .vertical
        labels.alignment = .leading
        labels.spacing = 2
        let titleLabel = NSTextField(labelWithString: title)
        titleLabel.font = NSFont.systemFont(ofSize: 13, weight: .medium)
        labels.addArrangedSubview(titleLabel)
        if !detail.isEmpty {
            let detailLabel = NSTextField(wrappingLabelWithString: detail)
            detailLabel.textColor = .secondaryLabelColor
            detailLabel.font = NSFont.systemFont(ofSize: 11)
            labels.addArrangedSubview(detailLabel)
        }
        labels.setContentHuggingPriority(.defaultLow, for: .horizontal)
        row.addArrangedSubview(labels)
        row.addArrangedSubview(NSView())
        control.setContentHuggingPriority(.required, for: .horizontal)
        row.addArrangedSubview(control)
        row.heightAnchor.constraint(greaterThanOrEqualToConstant: 58).isActive = true
        return row
    }

    private func compactSettingRow(title: String, control: NSView) -> NSStackView {
        let row = NSStackView()
        row.orientation = .horizontal
        row.alignment = .centerY
        row.spacing = 10
        row.edgeInsets = NSEdgeInsets(top: 2, left: 2, bottom: 2, right: 2)
        let titleLabel = NSTextField(labelWithString: title)
        titleLabel.font = NSFont.systemFont(ofSize: 12, weight: .medium)
        row.addArrangedSubview(titleLabel)
        row.addArrangedSubview(NSView())
        control.setContentHuggingPriority(.required, for: .horizontal)
        row.addArrangedSubview(control)
        return row
    }

    private func separator() -> NSBox {
        let box = NSBox()
        box.boxType = .separator
        return box
    }

    private func rowContainer(compact: Bool = false) -> NSStackView {
        let view = NSStackView()
        view.orientation = .horizontal
        view.spacing = 8
        let verticalInset: CGFloat = compact ? 5 : 7
        view.edgeInsets = NSEdgeInsets(top: verticalInset, left: 10, bottom: verticalInset, right: 10)
        view.wantsLayer = true
        view.layer?.cornerRadius = 8
        view.layer?.backgroundColor = NSColor.controlBackgroundColor.withAlphaComponent(0.35).cgColor
        view.layer?.borderWidth = 1
        view.layer?.borderColor = NSColor.separatorColor.withAlphaComponent(0.28).cgColor
        return view
    }

    private func updateDockAnchorControls(isEnabled: Bool, status: String? = nil) {
        let currentStatus = status ?? dockAnchorStatusLabel.stringValue
        dockAnchorSwitch.state = isEnabled ? .on : .off
        let warning = currentStatus.contains(agentText("dock.status.needsPermission"))
            || currentStatus.contains(agentText("dock.status.failed"))
            || currentStatus.contains(agentText("dock.status.targetLimited"))
        dockPermissionButton.isHidden = !isEnabled || !warning
        dockDisplayPopup.isEnabled = !isEnabled
    }

    private func refreshDockAnchorUI(status: String? = nil) {
        let enabled = dockAnchorSwitch.state == .on
        let resolvedStatus = dockAnchorResolvedStatus(isEnabled: enabled, baseStatus: status)
        dockAnchorStatusLabel.stringValue = resolvedStatus
        let isActive = resolvedStatus.contains(agentText("dock.status.active"))
        let isOff = resolvedStatus == agentText("dock.status.off")
        let tint: NSColor = isActive ? .systemGreen : (isOff ? .secondaryLabelColor : .systemOrange)
        dockAnchorStatusLabel.textColor = tint
        dockAnchorStatusLabel.layer?.backgroundColor = tint.withAlphaComponent(isOff ? 0.08 : 0.13).cgColor
        updateDockAnchorControls(isEnabled: enabled, status: resolvedStatus)
    }

    private func dockAnchorResolvedStatus(isEnabled: Bool, baseStatus override: String? = nil) -> String {
        let baseStatus: String
        if isEnabled {
            baseStatus = override ?? (AXIsProcessTrusted() ? agentText("dock.status.active") : agentText("dock.status.needsPermission"))
        } else {
            baseStatus = override ?? agentText("dock.status.off")
        }
        return baseStatus
    }

    private func appBindingsTab() -> NSTabViewItem {
        let item = NSTabViewItem(identifier: "apps")
        item.label = agentText("tab.apps")
        let root = NSStackView()
        root.frame = NSRect(x: 0, y: 0, width: 760, height: 400)
        root.orientation = .vertical
        root.alignment = .width
        root.spacing = 8
        root.edgeInsets = NSEdgeInsets(top: 14, left: 18, bottom: 12, right: 18)

        let header = NSStackView()
        header.orientation = .horizontal
        header.alignment = .centerY
        header.spacing = 8
        appsHintLabel.textColor = .secondaryLabelColor
        appsHintLabel.font = NSFont.systemFont(ofSize: 12)
        let heading = NSStackView()
        heading.orientation = .vertical
        heading.alignment = .leading
        heading.spacing = 4
        let headingTitle = NSTextField(labelWithString: agentText("tab.apps"))
        headingTitle.font = NSFont.systemFont(ofSize: 17, weight: .semibold)
        heading.addArrangedSubview(headingTitle)
        heading.addArrangedSubview(appsHintLabel)
        header.addArrangedSubview(heading)
        header.addArrangedSubview(NSView())
        appAddButton.image = NSImage(systemSymbolName: "plus", accessibilityDescription: agentText("apps.addRunning"))
        appAddButton.imagePosition = .imageLeading
        header.addArrangedSubview(appAddButton)
        root.addArrangedSubview(header)
        header.widthAnchor.constraint(equalTo: root.widthAnchor).isActive = true
        root.addArrangedSubview(separator())
        root.addArrangedSubview(compactSettingRow(title: agentText("apps.enabled"), control: appHotkeysSwitch))
        let listSeparator = separator()
        root.addArrangedSubview(listSeparator)

        bindingsStack.orientation = .vertical
        bindingsStack.alignment = .width
        bindingsStack.spacing = 6
        let scrollView = NSScrollView()
        scrollView.hasVerticalScroller = true
        scrollView.drawsBackground = false
        let documentView = FlippedDocumentView()
        documentView.translatesAutoresizingMaskIntoConstraints = false
        bindingsStack.translatesAutoresizingMaskIntoConstraints = false
        documentView.addSubview(bindingsStack)
        NSLayoutConstraint.activate([
            bindingsStack.leadingAnchor.constraint(equalTo: documentView.leadingAnchor),
            bindingsStack.trailingAnchor.constraint(equalTo: documentView.trailingAnchor),
            bindingsStack.topAnchor.constraint(equalTo: documentView.topAnchor),
            bindingsStack.bottomAnchor.constraint(lessThanOrEqualTo: documentView.bottomAnchor),
            bindingsStack.widthAnchor.constraint(equalTo: documentView.widthAnchor)
        ])
        scrollView.documentView = documentView
        NSLayoutConstraint.activate([
            documentView.leadingAnchor.constraint(equalTo: scrollView.contentView.leadingAnchor),
            documentView.topAnchor.constraint(equalTo: scrollView.contentView.topAnchor),
            documentView.widthAnchor.constraint(equalTo: scrollView.contentView.widthAnchor)
        ])
        let scrollContainer = NSView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollContainer.addSubview(scrollView)
        root.addArrangedSubview(scrollContainer)
        NSLayoutConstraint.activate([
            listSeparator.leadingAnchor.constraint(equalTo: root.leadingAnchor, constant: 18),
            listSeparator.trailingAnchor.constraint(equalTo: root.trailingAnchor, constant: -18),
            scrollContainer.leadingAnchor.constraint(equalTo: root.leadingAnchor, constant: 18),
            scrollContainer.trailingAnchor.constraint(equalTo: root.trailingAnchor, constant: -18),
            scrollView.leadingAnchor.constraint(equalTo: scrollContainer.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: scrollContainer.trailingAnchor),
            scrollView.topAnchor.constraint(equalTo: scrollContainer.topAnchor),
            scrollView.bottomAnchor.constraint(equalTo: scrollContainer.bottomAnchor)
        ])
        item.view = root
        return item
    }

    private func keepAwakeTab() -> NSTabViewItem {
        let item = NSTabViewItem(identifier: "keep-awake")
        item.label = agentText("tab.keepAwake")
        let root = NSStackView()
        root.orientation = .vertical
        root.alignment = .width
        root.spacing = 14
        root.edgeInsets = NSEdgeInsets(top: 18, left: 18, bottom: 18, right: 18)

        let header = pageHeader(title: agentText("keep.title"), detail: agentText("keep.detail"))
        root.addArrangedSubview(header)
        header.widthAnchor.constraint(equalTo: root.widthAnchor).isActive = true
        root.addArrangedSubview(separator())
        root.addArrangedSubview(settingRow(title: agentText("keep.prevent"), control: keepAwakeSwitch))
        root.addArrangedSubview(separator())
        let policy = NSTextField(wrappingLabelWithString: agentText("keep.policy"))
        policy.font = NSFont.systemFont(ofSize: 12)
        policy.textColor = .secondaryLabelColor
        policy.maximumNumberOfLines = 3
        root.addArrangedSubview(policy)
        root.addArrangedSubview(NSView())
        item.view = root
        return item
    }

    private func dockAnchorTab() -> NSTabViewItem {
        let item = NSTabViewItem(identifier: "dock-anchor")
        item.label = agentText("tab.dockAnchor")
        let root = NSStackView()
        root.orientation = .vertical
        root.alignment = .width
        root.spacing = 14
        root.edgeInsets = NSEdgeInsets(top: 18, left: 18, bottom: 18, right: 18)

        let header = pageHeader(title: agentText("dock.title"), detail: agentText("dock.detail"))
        root.addArrangedSubview(header)
        header.widthAnchor.constraint(equalTo: root.widthAnchor).isActive = true
        root.addArrangedSubview(separator())

        dockAnchorStatusLabel.alignment = .center
        dockAnchorStatusLabel.font = NSFont.systemFont(ofSize: 11, weight: .medium)
        dockAnchorStatusLabel.wantsLayer = true
        dockAnchorStatusLabel.layer?.cornerRadius = 7
        dockAnchorStatusLabel.layer?.masksToBounds = true
        dockAnchorStatusLabel.widthAnchor.constraint(greaterThanOrEqualToConstant: 76).isActive = true
        let anchorControls = NSStackView()
        anchorControls.orientation = .horizontal
        anchorControls.spacing = 8
        anchorControls.addArrangedSubview(dockAnchorStatusLabel)
        anchorControls.addArrangedSubview(dockPermissionButton)
        anchorControls.addArrangedSubview(dockAnchorSwitch)
        root.addArrangedSubview(settingRow(title: agentText("dock.checkbox"), control: anchorControls))
        root.addArrangedSubview(separator())

        dockDisplayPopup.target = self
        dockDisplayPopup.action = #selector(saveRuntimeSettings)
        dockDisplayPopup.widthAnchor.constraint(equalToConstant: 440).isActive = true
        root.addArrangedSubview(settingRow(title: agentText("dock.display"), control: dockDisplayPopup))
        root.addArrangedSubview(NSView())
        item.view = root
        return item
    }

    private func textShortcutsTab() -> NSTabViewItem {
        let item = NSTabViewItem(identifier: "text")
        item.label = agentText("tab.text")
        let root = NSStackView()
        root.orientation = .vertical
        root.alignment = .width
        root.spacing = 12
        root.edgeInsets = NSEdgeInsets(top: 14, left: 14, bottom: 14, right: 14)

        textHintLabel.textColor = .secondaryLabelColor
        root.addArrangedSubview(textHintLabel)
        root.addArrangedSubview(textHeaderRow())

        textBindingsStack.orientation = .vertical
        textBindingsStack.spacing = 8
        let scrollView = NSScrollView()
        scrollView.hasVerticalScroller = true
        let documentView = FlippedDocumentView()
        documentView.translatesAutoresizingMaskIntoConstraints = false
        textBindingsStack.translatesAutoresizingMaskIntoConstraints = false
        documentView.addSubview(textBindingsStack)
        NSLayoutConstraint.activate([
            textBindingsStack.leadingAnchor.constraint(equalTo: documentView.leadingAnchor),
            textBindingsStack.trailingAnchor.constraint(equalTo: documentView.trailingAnchor),
            textBindingsStack.topAnchor.constraint(equalTo: documentView.topAnchor),
            textBindingsStack.bottomAnchor.constraint(lessThanOrEqualTo: documentView.bottomAnchor),
            textBindingsStack.widthAnchor.constraint(equalTo: documentView.widthAnchor)
        ])
        scrollView.documentView = documentView
        root.addArrangedSubview(scrollView)

        let controls = NSStackView()
        controls.orientation = .horizontal
        controls.spacing = 10
        controls.addArrangedSubview(NSView())
        controls.addArrangedSubview(actionButton(title: agentText("text.add"), action: #selector(addTextShortcut)))
        root.addArrangedSubview(controls)
        item.view = root
        return item
    }

    private func screenshotsTab() -> NSTabViewItem {
        let item = NSTabViewItem(identifier: "screenshots")
        item.label = agentText("tab.screenshots")
        let root = NSStackView()
        root.orientation = .vertical
        root.alignment = .width
        root.spacing = 14
        root.edgeInsets = NSEdgeInsets(top: 18, left: 18, bottom: 18, right: 18)

        let header = pageHeader(title: agentText("screenshots.title"), detail: agentText("screenshots.detail"))
        root.addArrangedSubview(header)
        header.widthAnchor.constraint(equalTo: root.widthAnchor).isActive = true
        root.addArrangedSubview(separator())

        let pathControls = NSStackView()
        pathControls.orientation = .horizontal
        pathControls.spacing = 8
        screenshotFolderButton.widthAnchor.constraint(equalToConstant: 390).isActive = true
        pathControls.addArrangedSubview(screenshotFolderButton)
        pathControls.addArrangedSubview(actionButton(title: agentText("screenshots.choose"), action: #selector(chooseScreenshotDirectory)))
        root.addArrangedSubview(settingRow(title: agentText("screenshots.folder"), control: pathControls))
        root.addArrangedSubview(separator())
        root.addArrangedSubview(settingRow(title: agentText("screenshots.copy"), control: screenshotWatchSwitch))
        root.addArrangedSubview(separator())
        root.addArrangedSubview(settingRow(
            title: agentText("screenshots.immediate"),
            detail: agentText("screenshots.immediateDetail"),
            control: screenshotImmediateSwitch
        ))
        root.addArrangedSubview(NSView())
        item.view = root
        return item
    }

    private func textHeaderRow() -> NSView {
        let row = NSStackView()
        row.orientation = .horizontal
        row.spacing = 8
        for (title, width) in [(agentText("text.name"), 180), (agentText("text.value"), 320), (agentText("apps.shortcut"), 120), ("", 168)] {
            let label = NSTextField(labelWithString: title)
            label.font = NSFont.boldSystemFont(ofSize: 12)
            label.widthAnchor.constraint(equalToConstant: CGFloat(width)).isActive = true
            row.addArrangedSubview(label)
        }
        return row
    }

    private func loadFromDisk() {
        config.reloadBootstrap()
        screenshotDirectoryPath = config.screenshotDir
        updateScreenshotFolderButton()
        appHotkeysSwitch.state = config.appHotkeysEnabled ? .on : .off
        screenshotWatchSwitch.state = config.screenshotClipboardWatch ? .on : .off
        screenshotImmediateSwitch.state = macOSScreenshotFloatingThumbnailEnabled() ? .off : .on
        keepAwakeSwitch.state = config.keepAwakeEnabled ? .on : .off
        dockAnchorSwitch.state = config.dockAnchorEnabled ? .on : .off
        populateDockDisplayPopup(selectedID: config.dockAnchorDisplayID)
        refreshDockAnchorUI()
        clearRows()
        let bindings = (try? config.loadBindings()) ?? []
        for binding in bindings {
            appendRow(binding)
        }
        setAppShortcutEditingMode(activeRow: nil)
        updateAppHotkeyControls()
        updateAppsHint(count: bindings.count)
        statusLabel.stringValue = ""
    }

    private func clearRows() {
        rows.removeAll()
        for view in bindingsStack.arrangedSubviews {
            bindingsStack.removeArrangedSubview(view)
            view.removeFromSuperview()
        }
    }

    private func clearTextRows() {
        textRows.removeAll()
        for view in textBindingsStack.arrangedSubviews {
            textBindingsStack.removeArrangedSubview(view)
            view.removeFromSuperview()
        }
    }

    private func appendRow(_ binding: AppBinding) {
        let row = BindingRow(binding: binding)

        let view = rowContainer(compact: true)
        view.heightAnchor.constraint(greaterThanOrEqualToConstant: 48).isActive = true
        row.iconView.widthAnchor.constraint(equalToConstant: 30).isActive = true
        row.iconView.heightAnchor.constraint(equalToConstant: 30).isActive = true

        let identity = NSStackView()
        identity.orientation = .vertical
        identity.alignment = .leading
        identity.spacing = 2
        identity.addArrangedSubview(row.label)
        identity.addArrangedSubview(row.bundleID)
        identity.widthAnchor.constraint(greaterThanOrEqualToConstant: 330).isActive = true
        identity.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        let appInfo = NSStackView()
        appInfo.orientation = .horizontal
        appInfo.alignment = .centerY
        appInfo.spacing = 9
        appInfo.addArrangedSubview(row.iconView)
        appInfo.addArrangedSubview(identity)
        appInfo.setContentHuggingPriority(.defaultLow, for: .horizontal)

        row.shortcutField.widthAnchor.constraint(equalToConstant: 110).isActive = true
        row.shortcutField.alignment = .center
        row.shortcutField.placeholderString = agentText("apps.editShortcutHint")
        row.shortcutField.lineBreakMode = .byTruncatingMiddle
        row.enabledSwitch.target = self
        row.enabledSwitch.action = #selector(toggleRowEnabled(_:))
        row.enabledSwitch.setContentHuggingPriority(.required, for: .horizontal)
        row.editButton.target = self
        row.editButton.action = #selector(editRow(_:))
        row.editButton.bezelStyle = .rounded
        row.editButton.controlSize = .regular
        row.editButton.heightAnchor.constraint(equalToConstant: 32).isActive = true
        row.editButton.widthAnchor.constraint(equalToConstant: 72).isActive = true
        row.removeButton.target = self
        row.removeButton.action = #selector(removeRow(_:))
        row.removeButton.bezelStyle = .rounded
        row.removeButton.controlSize = .regular
        row.removeButton.toolTip = agentText("apps.remove")
        row.removeButton.image = NSImage(systemSymbolName: "trash", accessibilityDescription: agentText("apps.remove"))
        row.removeButton.imagePosition = .imageOnly
        row.removeButton.contentTintColor = .systemRed
        row.removeButton.heightAnchor.constraint(equalToConstant: 32).isActive = true
        row.removeButton.widthAnchor.constraint(equalToConstant: 40).isActive = true
        for control in [appInfo, row.shortcutField, row.editButton, row.removeButton, row.enabledSwitch] as [NSView] {
            view.addArrangedSubview(control)
        }
        rows.append(row)
        bindingsStack.addArrangedSubview(view)
        row.enabledSwitch.isEnabled = appHotkeysSwitch.state == .on && activeEditingRow == nil
        updateAppsHint(count: rows.count)
    }

    private func appendTextRow(_ binding: TextBinding) {
        let row = TextShortcutRow(binding: binding)
        let view = rowContainer()
        row.labelField.widthAnchor.constraint(equalToConstant: 180).isActive = true
        row.textField.widthAnchor.constraint(equalToConstant: 320).isActive = true
        row.shortcutField.widthAnchor.constraint(equalToConstant: 120).isActive = true
        row.shortcutField.alignment = .center
        row.shortcutField.placeholderString = agentText("apps.editShortcutHint")
        row.editButton.target = self
        row.editButton.action = #selector(editTextRow(_:))
        row.editButton.bezelStyle = .rounded
        row.editButton.controlSize = .regular
        row.editButton.heightAnchor.constraint(equalToConstant: 32).isActive = true
        row.editButton.widthAnchor.constraint(equalToConstant: 80).isActive = true
        let remove = iconButton(symbolName: "trash", tooltip: agentText("apps.remove"), action: #selector(removeTextRow(_:)))
        remove.contentTintColor = .systemRed
        for control in [row.labelField, row.textField, row.shortcutField, row.editButton, remove] as [NSView] {
            view.addArrangedSubview(control)
        }
        textRows.append(row)
        textBindingsStack.addArrangedSubview(view)
    }

    @objc private func addTextShortcut() {
        appendTextRow(TextBinding(shortcut: "", text: "", label: ""))
        if let row = textRows.last {
            row.setEditing(true)
            beginShortcutCapture(for: row.shortcutField, label: row.binding.label)
            window?.makeFirstResponder(row.textField)
        }
    }

    @objc private func addRunningApp() {
        let apps = visibleRunningApplications()
        let alert = NSAlert()
        alert.messageText = agentText("apps.addRunning")
        alert.informativeText = agentLanguage() == .korean ? "현재 화면에 창이 보이는 앱만 표시합니다. 앱을 선택한 뒤 단축키를 지정합니다." : "Only apps with visible windows are listed. Choose an app, then set its shortcut."
        let popup = NSPopUpButton(frame: NSRect(x: 0, y: 0, width: 420, height: 28))
        for app in apps {
            let title = "\(app.localizedName ?? "Unknown") — \(app.bundleIdentifier ?? "")"
            popup.addItem(withTitle: title)
        }
        alert.accessoryView = popup
        alert.addButton(withTitle: agentText("apps.add"))
        alert.addButton(withTitle: agentText("apps.cancel"))
        guard alert.runModal() == .alertFirstButtonReturn,
              popup.indexOfSelectedItem >= 0,
              apps.indices.contains(popup.indexOfSelectedItem) else { return }
        let app = apps[popup.indexOfSelectedItem]
        appendRow(AppBinding(shortcut: "", bundleID: app.bundleIdentifier ?? "", label: app.localizedName ?? "App", isEnabled: true))
        if let row = rows.last, let rowView = bindingsStack.arrangedSubviews.last {
            row.setEditing(true)
            beginShortcutCapture(for: row.shortcutField, label: row.binding.label)
            window?.makeFirstResponder(row.shortcutField)
            rowView.needsDisplay = true
        }
    }

    private func visibleRunningApplications() -> [NSRunningApplication] {
        let visiblePIDs = visibleWindowProcessIDs()
        var seen = Set<String>()
        return NSWorkspace.shared.runningApplications
            .filter { app in
                guard let bundleID = app.bundleIdentifier, !bundleID.isEmpty else { return false }
                guard bundleID != Bundle.main.bundleIdentifier else { return false }
                guard app.activationPolicy == .regular else { return false }
                guard visiblePIDs.contains(app.processIdentifier) else { return false }
                if seen.contains(bundleID) { return false }
                seen.insert(bundleID)
                return true
            }
            .sorted {
                let left = ($0.localizedName?.isEmpty == false ? $0.localizedName! : $0.bundleIdentifier ?? "")
                let right = ($1.localizedName?.isEmpty == false ? $1.localizedName! : $1.bundleIdentifier ?? "")
                return left.localizedCaseInsensitiveCompare(right) == .orderedAscending
            }
    }

    private func visibleWindowProcessIDs() -> Set<pid_t> {
        let windows = CGWindowListCopyWindowInfo([.optionOnScreenOnly, .excludeDesktopElements], kCGNullWindowID) as? [[String: Any]] ?? []
        var pids = Set<pid_t>()
        for window in windows {
            guard (window[kCGWindowLayer as String] as? Int) == 0 else { continue }
            let rawPID = window[kCGWindowOwnerPID as String]
            let pid: pid_t
            if let value = rawPID as? pid_t {
                pid = value
            } else if let value = rawPID as? NSNumber {
                pid = value.int32Value
            } else {
                continue
            }
            guard let bounds = window[kCGWindowBounds as String] as? [String: Any],
                  let width = bounds["Width"] as? CGFloat,
                  let height = bounds["Height"] as? CGFloat,
                  width > 0, height > 0 else { continue }
            pids.insert(pid)
        }
        return pids
    }

    private func editBinding(_ initial: AppBinding) -> AppBinding? {
        let nameField = NSTextField(string: initial.label)
        let bundleField = NSTextField(string: initial.bundleID)
        let shortcutField = ShortcutCaptureField(string: initial.shortcut)
        shortcutField.placeholderString = agentText("apps.editShortcutHint")

        let grid = NSGridView(views: [
            [NSTextField(labelWithString: agentText("apps.editName")), nameField],
            [NSTextField(labelWithString: agentText("apps.editBundle")), bundleField],
            [NSTextField(labelWithString: agentText("apps.editShortcut")), shortcutField]
        ])
        grid.column(at: 0).xPlacement = .trailing
        grid.column(at: 1).width = 360
        grid.rowSpacing = 8
        grid.columnSpacing = 10

        let alert = NSAlert()
        alert.messageText = agentText("apps.editTitle")
        alert.accessoryView = grid
        alert.addButton(withTitle: agentText("apps.add"))
        alert.addButton(withTitle: agentText("apps.cancel"))
        onShortcutCaptureStart?()
        let result = alert.runModal()
        onShortcutCaptureEnd?()
        guard result == .alertFirstButtonReturn else { return nil }

        let label = nameField.stringValue.trimmingCharacters(in: .whitespaces)
        let bundleID = bundleField.stringValue.trimmingCharacters(in: .whitespaces)
        let shortcut = shortcutField.stringValue.trimmingCharacters(in: .whitespaces)
        guard !label.isEmpty, !bundleID.isEmpty, !shortcut.isEmpty else { return nil }
        return AppBinding(shortcut: shortcut, bundleID: bundleID, label: label, isEnabled: initial.isEnabled)
    }

    private func populateDockDisplayPopup(selectedID: UInt32?) {
        dockDisplayPopup.removeAllItems()
        let screens = sortedScreens()
        for (index, screen) in screens.enumerated() {
            let id = displayID(for: screen)
            let frame = screen.frame
            let title = "\(screen.localizedName) · Display \(index + 1) · \(Int(frame.width))x\(Int(frame.height)) · ID \(id)"
            dockDisplayPopup.addItem(withTitle: title)
            dockDisplayPopup.lastItem?.representedObject = id
        }
        let targetID = selectedID ?? currentDisplayID()
        if let index = dockDisplayPopup.itemArray.firstIndex(where: { ($0.representedObject as? UInt32) == targetID }) {
            dockDisplayPopup.selectItem(at: index)
        } else if dockDisplayPopup.numberOfItems > 0 {
            dockDisplayPopup.selectItem(at: 0)
        }
    }

    private func selectedDockDisplayID() -> UInt32? {
        dockDisplayPopup.selectedItem?.representedObject as? UInt32
    }

    @objc private func removeRow(_ sender: NSButton) {
        if let activeEditingRow, activeEditingRow.removeButton === sender {
            activeEditingRow.cancelEditing()
            endShortcutCapture()
            setAppShortcutEditingMode(activeRow: nil)
            updateAppsHint(count: rows.count)
            statusLabel.stringValue = ""
            return
        }
        guard let index = rows.firstIndex(where: { $0.removeButton === sender }),
              rows.indices.contains(index),
              bindingsStack.arrangedSubviews.indices.contains(index) else { return }
        let rowView = bindingsStack.arrangedSubviews[index]
        if rows[index].isEditing {
            endShortcutCapture()
        }
        rows.remove(at: index)
        bindingsStack.removeArrangedSubview(rowView)
        rowView.removeFromSuperview()
        updateAppsHint(count: rows.count)
        savePressed()
    }

    @objc private func toggleRowEnabled(_ sender: NSSwitch) {
        guard let row = rows.first(where: { $0.enabledSwitch === sender }) else { return }
        row.binding.isEnabled = sender.state == .on
        row.refreshEnabledAppearance()
        savePressed()
    }

    @objc private func removeTextRow(_ sender: NSButton) {
        guard let rowView = sender.superview else { return }
        if let index = textBindingsStack.arrangedSubviews.firstIndex(of: rowView), textRows.indices.contains(index) {
            textRows.remove(at: index)
        }
        textBindingsStack.removeArrangedSubview(rowView)
        rowView.removeFromSuperview()
        savePressed()
    }

    @objc private func editRow(_ sender: NSButton) {
        guard let index = rows.firstIndex(where: { $0.editButton === sender }),
              rows.indices.contains(index) else { return }
        let row = rows[index]
        if row.isEditing {
            let shortcut = row.shortcutField.lastCompleteShortcut.trimmingCharacters(in: .whitespaces)
            guard parseShortcut(shortcut) != nil else { return }
            row.update(AppBinding(shortcut: shortcut, bundleID: row.binding.bundleID, label: row.binding.label, isEnabled: row.binding.isEnabled))
            row.setEditing(false)
            endShortcutCapture()
            setAppShortcutEditingMode(activeRow: nil)
            savePressed()
        } else {
            for otherRow in rows where otherRow !== row && otherRow.isEditing {
                otherRow.setEditing(false)
            }
            row.setEditing(true)
            setAppShortcutEditingMode(activeRow: row)
            beginShortcutCapture(for: row.shortcutField, label: row.binding.label)
            window?.makeFirstResponder(row.shortcutField)
        }
    }

    @objc private func editTextRow(_ sender: NSButton) {
        guard let rowView = sender.superview,
              let index = textBindingsStack.arrangedSubviews.firstIndex(of: rowView),
              textRows.indices.contains(index) else { return }
        let row = textRows[index]
        if row.isEditing {
            row.updateFromFields()
            guard parseShortcut(row.binding.shortcut) != nil, !row.binding.text.isEmpty else { return }
            row.setEditing(false)
            endShortcutCapture()
            savePressed()
        } else {
            row.setEditing(true)
            beginShortcutCapture(for: row.shortcutField, label: row.binding.label)
            window?.makeFirstResponder(row.shortcutField)
        }
    }

    private func beginShortcutCapture(for field: ShortcutCaptureField, label: String) {
        endShortcutCapture()
        activeShortcutField = field
        activeShortcutLabel = label
        field.onShortcutCaptured = { [weak field] shortcut in
            field?.stringValue = shortcut
            field?.lastCompleteShortcut = shortcut
            field?.needsDisplay = true
        }
        field.onCancelCapture = { [weak self] in
            self?.activeEditingRow?.cancelEditing()
            self?.endShortcutCapture()
            self?.setAppShortcutEditingMode(activeRow: nil)
        }
        field.onFocus = { [weak self, weak field] in
            guard let self, let field else { return }
            guard self.activeEditingRow != nil else { return }
            if self.activeShortcutField !== field {
                self.beginShortcutCapture(for: field, label: self.activeEditingRow?.binding.label ?? label)
            }
        }
        onShortcutCaptureStart?()
        shortcutCaptureMonitor = NSEvent.addLocalMonitorForEvents(matching: [.keyDown, .flagsChanged]) { [weak self] event in
            guard let self, let field = self.activeShortcutField else { return event }
            guard self.window?.isKeyWindow == true, field.window?.firstResponder === field else {
                return event
            }
            if event.type == .flagsChanged {
                if let modifiers = modifierString(from: event), !modifiers.isEmpty {
                    field.stringValue = modifiers
                    field.needsDisplay = true
                }
                return nil
            }
            if event.keyCode == 53 {
                self.activeEditingRow?.cancelEditing()
                self.endShortcutCapture()
                self.setAppShortcutEditingMode(activeRow: nil)
                return nil
            }
            guard let shortcut = shortcutString(from: event) else { return nil }
            field.stringValue = shortcut
            field.lastCompleteShortcut = shortcut
            field.needsDisplay = true
            return nil
        }
    }

    private func setAppShortcutEditingMode(activeRow: BindingRow?) {
        activeEditingRow = activeRow
        let editing = activeRow != nil
        for row in rows {
            row.enabledSwitch.isEnabled = appHotkeysSwitch.state == .on && !editing
            if row === activeRow {
                row.shortcutField.isCapturingShortcut = true
                row.editButton.isEnabled = true
                row.removeButton.isEnabled = true
                row.removeButton.title = agentText("apps.cancel")
                row.removeButton.image = NSImage(systemSymbolName: "xmark", accessibilityDescription: agentText("apps.cancel"))
                row.removeButton.imagePosition = .imageLeading
                row.removeButton.contentTintColor = .controlAccentColor
                row.removeButton.toolTip = agentText("apps.cancel")
                row.shortcutField.textColor = .labelColor
            } else {
                row.editButton.isEnabled = !editing
                row.removeButton.isEnabled = !editing
                if row.isEditing {
                    row.setEditing(false)
                }
                row.shortcutField.isCapturingShortcut = false
            }
        }
        if activeRow == nil {
            for row in rows {
                row.shortcutField.isCapturingShortcut = false
                row.shortcutField.onShortcutCaptured = nil
                row.shortcutField.onCancelCapture = nil
                row.shortcutField.onFocus = nil
            }
        }
        appAddButton.isEnabled = !editing
        appHotkeysSwitch.isEnabled = !editing
        languagePopup.isEnabled = !editing
        footerReloadButton.isEnabled = !editing
    }

    private func endShortcutCapture() {
        stopShortcutCaptureMonitor(reloadHotkeys: true)
    }

    private func stopShortcutCaptureMonitor(reloadHotkeys: Bool) {
        if let shortcutCaptureMonitor {
            NSEvent.removeMonitor(shortcutCaptureMonitor)
            self.shortcutCaptureMonitor = nil
        }
        activeShortcutField?.onShortcutCaptured = nil
        activeShortcutField?.onCancelCapture = nil
        activeShortcutField?.isCapturingShortcut = false
        activeShortcutField = nil
        activeShortcutLabel = ""
        if reloadHotkeys {
            onShortcutCaptureEnd?()
        }
    }

    private func updateAppsHint(count: Int) {
        appsHintLabel.stringValue = count == 0
            ? agentText("apps.hint")
            : "\(count)\(agentText("apps.countSuffix")) · \(agentText("apps.hint"))"
    }

    @objc private func chooseScreenshotDirectory() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.directoryURL = URL(fileURLWithPath: screenshotDirectoryPath, isDirectory: true)
        guard panel.runModal() == .OK, let url = panel.url else { return }
        guard setMacOSScreenshotLocation(url.path) else {
            statusLabel.stringValue = agentText("status.failed")
            return
        }
        screenshotDirectoryPath = url.path
        updateScreenshotFolderButton()
        saveRuntimeSettings()
    }

    @objc private func openScreenshotDirectory() {
        guard !screenshotDirectoryPath.isEmpty else { return }
        NSWorkspace.shared.open(URL(fileURLWithPath: screenshotDirectoryPath, isDirectory: true))
    }

    private func updateScreenshotFolderButton() {
        screenshotFolderButton.title = screenshotDirectoryPath
        screenshotFolderButton.toolTip = screenshotDirectoryPath
    }

    @objc private func toggleScreenshotWatch() {
        saveRuntimeSettings()
    }

    @objc private func toggleScreenshotImmediateCopy() {
        let immediateCopyEnabled = screenshotImmediateSwitch.state == .on
        guard setMacOSScreenshotFloatingThumbnailEnabled(!immediateCopyEnabled) else {
            screenshotImmediateSwitch.state = macOSScreenshotFloatingThumbnailEnabled() ? .off : .on
            statusLabel.stringValue = agentText("status.failed")
            return
        }
        screenshotImmediateSwitch.state = macOSScreenshotFloatingThumbnailEnabled() ? .off : .on
        statusLabel.stringValue = agentText("status.saved")
    }

    @objc private func toggleAppHotkeys() {
        let enabled = appHotkeysSwitch.state == .on
        for row in rows {
            row.enabledSwitch.state = enabled ? .on : .off
            row.binding.isEnabled = enabled
            row.refreshEnabledAppearance()
        }
        updateAppHotkeyControls()
        savePressed()
    }

    private func updateAppHotkeyControls() {
        let masterEnabled = appHotkeysSwitch.state == .on
        let individuallyEditable = masterEnabled && activeEditingRow == nil
        for row in rows {
            if !masterEnabled {
                row.enabledSwitch.state = .off
                row.binding.isEnabled = false
                row.refreshEnabledAppearance()
            }
            row.enabledSwitch.isEnabled = individuallyEditable
        }
    }

    @objc private func toggleKeepAwake() {
        saveRuntimeSettings()
    }

    @objc private func toggleDockAnchor() {
        refreshDockAnchorUI()
        saveRuntimeSettings()
    }

    @objc private func openAccessibilitySettings() {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
        AXIsProcessTrustedWithOptions(options)
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
            NSWorkspace.shared.open(url)
        }
        refreshDockAnchorUI(status: AXIsProcessTrusted() ? nil : agentText("dock.status.needsPermission"))
    }

    @objc func reloadPressed() {
        loadFromDisk()
    }

    @objc private func savePressed() {
        let bindings = rows.compactMap { row -> AppBinding? in
            let shortcut = row.shortcutField.lastCompleteShortcut.trimmingCharacters(in: .whitespaces)
            guard parseShortcut(shortcut) != nil else { return nil }
            return AppBinding(
                shortcut: shortcut,
                bundleID: row.binding.bundleID,
                label: row.binding.label,
                isEnabled: row.enabledSwitch.state == .on
            )
        }
        do {
            try config.saveBindings(bindings)
            try config.saveBootstrap(
                appHotkeysEnabled: appHotkeysSwitch.state == .on,
                screenshotDir: screenshotDirectoryPath,
                screenshotClipboardWatch: screenshotWatchSwitch.state == .on,
                keepAwakeEnabled: keepAwakeSwitch.state == .on,
                keepDisplayAwake: false,
                dockAnchorEnabled: dockAnchorSwitch.state == .on,
                dockAnchorDisplayID: selectedDockDisplayID()
            )
            statusLabel.stringValue = agentText("status.saved")
            onSave?()
        } catch {
            statusLabel.stringValue = "\(agentText("status.failed")): \(error.localizedDescription)"
        }
    }

    @objc private func saveRuntimeSettings() {
        do {
            try config.saveBootstrap(
                appHotkeysEnabled: appHotkeysSwitch.state == .on,
                screenshotDir: screenshotDirectoryPath,
                screenshotClipboardWatch: screenshotWatchSwitch.state == .on,
                keepAwakeEnabled: keepAwakeSwitch.state == .on,
                keepDisplayAwake: false,
                dockAnchorEnabled: dockAnchorSwitch.state == .on,
                dockAnchorDisplayID: selectedDockDisplayID()
            )
            statusLabel.stringValue = agentText("status.saved")
            onSave?()
        } catch {
            statusLabel.stringValue = "\(agentText("status.failed")): \(error.localizedDescription)"
        }
    }
}

final class KeepAwakeController {
    private let config: Config
    private var assertionID = IOPMAssertionID(0)
    private var assertionActive = false

    init(config: Config) {
        self.config = config
    }

    func reload() {
        config.reloadBootstrap()
        if config.keepAwakeEnabled {
            start()
        } else {
            stop()
        }
    }

    func stop() {
        if assertionActive {
            let result = IOPMAssertionRelease(assertionID)
            if result != kIOReturnSuccess {
                NSLog("Failed to release sleep assertion: \(result)")
            }
            assertionID = 0
            assertionActive = false
        }
    }

    private func start() {
        if assertionActive {
            return
        }
        var id = IOPMAssertionID(0)
        let result = IOPMAssertionCreateWithName(
            kIOPMAssertionTypeNoIdleSleep as CFString,
            IOPMAssertionLevel(kIOPMAssertionLevelOn),
            "MacBootstrapAgent sleep mode prevention" as CFString,
            &id
        )
        if result == kIOReturnSuccess {
            assertionID = id
            assertionActive = true
        } else {
            NSLog("Failed to create sleep assertion: \(result)")
        }
    }
}

final class DockAnchorController {
    private let config: Config
    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    private var observers: [NSObjectProtocol] = []
    private var isRelocating = false
    private var currentlyInCorner = false
    private var cachedDockOrientation = "bottom"
    private var permissionTimer: Timer?
    private var pendingRelocationWork: DispatchWorkItem?
    private let syntheticEventMarker: Int64 = 0xD0C4A5C4
    private let dockTriggerSize: CGFloat = 10
    private let cornerZoneSize: CGFloat = 1

    init(config: Config) {
        self.config = config
    }

    func reload() {
        config.reloadBootstrap()
        if config.dockAnchorEnabled {
            start()
        } else {
            stop()
            postStatus(agentText("dock.status.off"))
        }
    }

    func stop(keepPermissionMonitoring: Bool = false) {
        isRelocating = false
        currentlyInCorner = false
        NSCursor.unhide()
        if let eventTap {
            CGEvent.tapEnable(tap: eventTap, enable: false)
            self.eventTap = nil
        }
        if let runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetMain(), runLoopSource, .commonModes)
            self.runLoopSource = nil
        }
        for observer in observers {
            NotificationCenter.default.removeObserver(observer)
            NSWorkspace.shared.notificationCenter.removeObserver(observer)
            DistributedNotificationCenter.default().removeObserver(observer)
        }
        observers.removeAll()
        if !keepPermissionMonitoring {
            permissionTimer?.invalidate()
            permissionTimer = nil
        }
        pendingRelocationWork?.cancel()
        pendingRelocationWork = nil
    }

    private func start() {
        stop()
        guard AXIsProcessTrusted() else {
            let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
            AXIsProcessTrustedWithOptions(options)
            NSLog("Dock anchor needs Accessibility permission")
            postStatus(agentText("dock.status.needsPermission"))
            startPermissionMonitoring()
            return
        }
        guard targetDisplayID() != nil else {
            NSLog("Dock anchor has no valid target display")
            postStatus(agentText("dock.status.failed"))
            return
        }
        cachedDockOrientation = dockOrientation()
        guard startEventTap() else { return }
        addLifecycleObservers()
        startPermissionMonitoring()
        scheduleRelocation(after: 0.1)
    }

    private func startEventTap() -> Bool {
        let eventMask = CGEventMask(
            (1 << CGEventType.mouseMoved.rawValue) |
            (1 << CGEventType.tapDisabledByTimeout.rawValue) |
            (1 << CGEventType.tapDisabledByUserInput.rawValue)
        )
        eventTap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: eventMask,
            callback: { _, type, event, refcon in
                let controller = Unmanaged<DockAnchorController>.fromOpaque(refcon!).takeUnretainedValue()
                if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
                    if let eventTap = controller.eventTap {
                        CGEvent.tapEnable(tap: eventTap, enable: true)
                    }
                    return Unmanaged.passUnretained(event)
                }
                return controller.handleMouseEvent(type: type, event: event)
            },
            userInfo: Unmanaged.passUnretained(self).toOpaque()
        )
        guard let eventTap else {
            NSLog("Failed to create Dock anchor event tap")
            postStatus(agentText("dock.status.failed"))
            return false
        }
        runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, eventTap, 0)
        if let runLoopSource {
            CFRunLoopAddSource(CFRunLoopGetMain(), runLoopSource, .commonModes)
        }
        CGEvent.tapEnable(tap: eventTap, enable: true)
        NSLog("Dock anchor event tap active")
        postStatus(agentText("dock.status.active"))
        return true
    }

    private func startPermissionMonitoring() {
        permissionTimer?.invalidate()
        permissionTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            self?.verifyPermissionsAndTapValidity()
        }
    }

    private func verifyPermissionsAndTapValidity() {
        guard config.dockAnchorEnabled else { return }
        guard AXIsProcessTrusted() else {
            stop(keepPermissionMonitoring: true)
            postStatus(agentText("dock.status.needsPermission"))
            return
        }
        if eventTap == nil {
            start()
            return
        }
        if let eventTap, !CFMachPortIsValid(eventTap) {
            stop(keepPermissionMonitoring: true)
            postStatus(agentText("dock.status.failed"))
        }
    }

    private func postStatus(_ value: String) {
        NotificationCenter.default.post(name: dockAnchorStatusNotification, object: value)
    }

    private func addLifecycleObservers() {
        let displayObserver = NotificationCenter.default.addObserver(
            forName: NSApplication.didChangeScreenParametersNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.config.reloadBootstrap()
            self?.scheduleRelocation(after: 1.0)
        }
        let wakeObserver = NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didWakeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.scheduleRelocation(after: 3.0)
            DispatchQueue.main.asyncAfter(deadline: .now() + 8.0) { [weak self] in
                self?.relocateDockIfNeeded()
            }
        }
        let unlockObserver = DistributedNotificationCenter.default().addObserver(
            forName: Notification.Name("com.apple.screenIsUnlocked"),
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.scheduleRelocation(after: 1.0)
        }
        observers = [displayObserver, wakeObserver, unlockObserver]
    }

    private func handleMouseEvent(type: CGEventType, event: CGEvent) -> Unmanaged<CGEvent>? {
        guard type == .mouseMoved else { return Unmanaged.passUnretained(event) }
        if isRelocating {
            return event.getIntegerValueField(.eventSourceUserData) == syntheticEventMarker
                ? Unmanaged.passUnretained(event)
                : nil
        }
        guard config.dockAnchorEnabled, shouldBlockDockTrigger(at: event.location) else {
            return Unmanaged.passUnretained(event)
        }
        return nil
    }

    private func shouldBlockDockTrigger(at location: CGPoint) -> Bool {
        if NSApplication.shared.isActive {
            return false
        }
        guard let targetID = targetDisplayID() else { return false }
        for screen in NSScreen.screens {
            let id = displayID(for: screen)
            if id == targetID { continue }
            let frame = CGDisplayBounds(id)
            if isCorner(location, in: frame) {
                if !currentlyInCorner {
                    currentlyInCorner = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) { [weak self] in
                        self?.warpCursorAwayFromEdge(from: location, frame: frame)
                    }
                    return false
                }
                return true
            }
            if dockTriggerZone(for: frame).contains(location) {
                currentlyInCorner = false
                return true
            }
        }
        currentlyInCorner = false
        return false
    }

    private func dockTriggerZone(for frame: CGRect) -> CGRect {
        switch cachedDockOrientation {
        case "left":
            return CGRect(x: frame.minX, y: frame.minY, width: dockTriggerSize, height: frame.height)
        case "right":
            return CGRect(x: frame.maxX - dockTriggerSize, y: frame.minY, width: dockTriggerSize, height: frame.height)
        default:
            return CGRect(x: frame.minX, y: frame.maxY - dockTriggerSize, width: frame.width, height: dockTriggerSize)
        }
    }

    private func isCorner(_ location: CGPoint, in frame: CGRect) -> Bool {
        let size = cornerZoneSize
        let corners: [CGRect]
        switch cachedDockOrientation {
        case "left":
            corners = [
                CGRect(x: frame.minX, y: frame.minY, width: size, height: size),
                CGRect(x: frame.minX, y: frame.maxY - size, width: size, height: size)
            ]
        case "right":
            corners = [
                CGRect(x: frame.maxX - size, y: frame.minY, width: size, height: size),
                CGRect(x: frame.maxX - size, y: frame.maxY - size, width: size, height: size)
            ]
        default:
            corners = [
                CGRect(x: frame.minX, y: frame.maxY - size, width: size, height: size),
                CGRect(x: frame.maxX - size, y: frame.maxY - size, width: size, height: size)
            ]
        }
        return corners.contains { $0.contains(location) }
    }

    private func warpCursorAwayFromEdge(from location: CGPoint, frame: CGRect) {
        let offset: CGFloat = 15
        var newLocation = location
        switch cachedDockOrientation {
        case "left":
            newLocation.x = frame.minX + offset
        case "right":
            newLocation.x = frame.maxX - offset
        default:
            newLocation.y = frame.maxY - offset
        }
        CGWarpMouseCursorPosition(newLocation)
    }

    private func scheduleRelocation(after delay: TimeInterval) {
        pendingRelocationWork?.cancel()
        let work = DispatchWorkItem { [weak self] in
            self?.pendingRelocationWork = nil
            self?.relocateDockIfNeeded()
        }
        pendingRelocationWork = work
        DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: work)
    }

    private func relocateDockIfNeeded() {
        guard config.dockAnchorEnabled, let targetID = targetDisplayID() else { return }
        if NSScreen.screens.count <= 1 { return }
        if let currentDockID = currentDockDisplayID(), currentDockID == targetID {
            return
        }
        relocateDock()
    }

    private func relocateDock() {
        guard let targetID = targetDisplayID(), !isRelocating else { return }
        let frame = CGDisplayBounds(targetID)
        guard frame.width > 0, frame.height > 0 else { return }
        let source = CGEventSource(stateID: .hidSystemState)
        let original = CGEvent(source: nil)?.location ?? .zero
        let approach = approachPoint(for: frame)
        let edge = triggerPoint(for: frame)

        isRelocating = true
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self else { return }
            var cursorHidden = false
            defer {
                CGWarpMouseCursorPosition(original)
                self.isRelocating = false
                self.currentlyInCorner = false
                if cursorHidden {
                    DispatchQueue.main.sync { NSCursor.unhide() }
                }
            }
            DispatchQueue.main.sync {
                NSCursor.hide()
                cursorHidden = true
            }
            self.postSyntheticMove(approach, source: source)
            Thread.sleep(forTimeInterval: 0.03)
            for step in 0..<8 {
                let progress = CGFloat(step) / 7.0
                let point = CGPoint(
                    x: approach.x + (edge.x - approach.x) * progress,
                    y: approach.y + (edge.y - approach.y) * progress
                )
                self.postSyntheticMove(point, source: source)
                Thread.sleep(forTimeInterval: 0.015)
            }
            for _ in 0..<6 {
                self.postSyntheticMove(edge, source: source)
                Thread.sleep(forTimeInterval: 0.025)
            }
        }
    }

    private func approachPoint(for frame: CGRect) -> CGPoint {
        switch cachedDockOrientation {
        case "left":
            return CGPoint(x: frame.minX + 50, y: frame.midY)
        case "right":
            return CGPoint(x: frame.maxX - 50, y: frame.midY)
        default:
            return CGPoint(x: frame.midX, y: frame.maxY - 50)
        }
    }

    private func triggerPoint(for frame: CGRect) -> CGPoint {
        switch cachedDockOrientation {
        case "left":
            return CGPoint(x: frame.minX + 1, y: frame.midY)
        case "right":
            return CGPoint(x: frame.maxX - 1, y: frame.midY)
        default:
            return CGPoint(x: frame.midX, y: frame.maxY - 1)
        }
    }

    private func postSyntheticMove(_ point: CGPoint, source: CGEventSource?) {
        CGWarpMouseCursorPosition(point)
        guard let event = CGEvent(
            mouseEventSource: source,
            mouseType: .mouseMoved,
            mouseCursorPosition: point,
            mouseButton: .left
        ) else { return }
        event.setIntegerValueField(.eventSourceUserData, value: syntheticEventMarker)
        event.post(tap: .cghidEventTap)
    }

    private func currentDockDisplayID() -> UInt32? {
        if let id = currentDockDisplayIDFromWindowServer() {
            return id
        }
        guard let dockApp = NSRunningApplication.runningApplications(withBundleIdentifier: "com.apple.dock").first else {
            return nil
        }
        let dockElement = AXUIElementCreateApplication(dockApp.processIdentifier)
        var windowsValue: CFTypeRef?
        guard AXUIElementCopyAttributeValue(dockElement, kAXWindowsAttribute as CFString, &windowsValue) == .success,
              let windows = windowsValue as? [AXUIElement],
              let window = windows.first else {
            return nil
        }
        var positionValue: CFTypeRef?
        guard AXUIElementCopyAttributeValue(window, kAXPositionAttribute as CFString, &positionValue) == .success,
              let axValue = positionValue,
              CFGetTypeID(axValue) == AXValueGetTypeID() else {
            return nil
        }
        var position = CGPoint.zero
        guard AXValueGetValue(axValue as! AXValue, .cgPoint, &position) else {
            return nil
        }
        for screen in NSScreen.screens {
            let id = displayID(for: screen)
            if CGDisplayBounds(id).contains(position) {
                return id
            }
        }
        return nil
    }

    private func targetDisplayID() -> UInt32? {
        let ids = Set(NSScreen.screens.map(displayID(for:)))
        if let configured = config.dockAnchorDisplayID, ids.contains(configured) {
            return configured
        }
        return currentDisplayID()
    }

    private func dockOrientation() -> String {
        let process = Process()
        let pipe = Pipe()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/defaults")
        process.arguments = ["read", "com.apple.dock", "orientation"]
        process.standardOutput = pipe
        process.standardError = Pipe()
        do {
            try process.run()
            process.waitUntilExit()
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            let value = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            return value.isEmpty ? "bottom" : value
        } catch {
            return "bottom"
        }
    }
}

final class ScreenshotWatcher {
    private struct ImageFile {
        let path: String
        let modificationDate: Date
    }

    private let config: Config
    private var timer: Timer?
    private var directorySource: DispatchSourceFileSystemObject?
    private var scheduledScan: DispatchWorkItem?
    private var seenPaths: Set<String> = []
    private var pendingPaths: [String: Date] = [:]
    private var isScanning = false
    private var isRunning = false
    private let imageExtensions = Set(["png", "jpg", "jpeg", "tif", "tiff", "heic"])

    init(config: Config) {
        self.config = config
    }

    func start() {
        stop()
        isRunning = true
        DispatchQueue.global(qos: .utility).async { [weak self] in
            let files = self?.currentImageFiles() ?? []
            DispatchQueue.main.async {
                guard let self, self.isRunning else { return }
                self.seenPaths = Set(files.map(\.path))
                self.startDirectoryMonitor()
                self.scan()

                let timer = Timer(timeInterval: 2.0, repeats: true) { [weak self] _ in
                    self?.scan()
                }
                self.timer = timer
                RunLoop.main.add(timer, forMode: .common)
            }
        }
    }

    func stop() {
        isRunning = false
        timer?.invalidate()
        timer = nil
        scheduledScan?.cancel()
        scheduledScan = nil
        directorySource?.cancel()
        directorySource = nil
        pendingPaths.removeAll()
    }

    func reload() {
        config.reloadBootstrap()
        if config.screenshotClipboardWatch {
            start()
        } else {
            stop()
        }
    }

    private func scan() {
        guard isRunning, config.screenshotClipboardWatch else { return }
        guard !isScanning else { return }
        isScanning = true
        DispatchQueue.global(qos: .utility).async { [weak self] in
            guard let self else { return }
            let files = self.currentImageFiles()
            DispatchQueue.main.async {
                guard self.isRunning else {
                    self.isScanning = false
                    return
                }
                let currentPaths = Set(files.map(\.path))
                self.seenPaths.formIntersection(currentPaths)
                self.pendingPaths = self.pendingPaths.filter { currentPaths.contains($0.key) }

                let unseenFiles = files.filter { !self.seenPaths.contains($0.path) }
                guard let newestFile = unseenFiles.last else {
                    self.isScanning = false
                    return
                }

                for olderFile in unseenFiles.dropLast() {
                    self.seenPaths.insert(olderFile.path)
                    self.pendingPaths.removeValue(forKey: olderFile.path)
                }

                let now = Date()
                if let retryAt = self.pendingPaths[newestFile.path], retryAt > now {
                    self.isScanning = false
                    self.scheduleScan(after: retryAt.timeIntervalSince(now))
                    return
                }

                if self.copyImageToClipboard(path: newestFile.path) {
                    self.seenPaths.insert(newestFile.path)
                    self.pendingPaths.removeValue(forKey: newestFile.path)
                } else {
                    self.pendingPaths = [newestFile.path: now.addingTimeInterval(0.02)]
                    self.scheduleScan(after: 0.02)
                }
                self.isScanning = false
            }
        }
    }

    private func startDirectoryMonitor() {
        let descriptor = Darwin.open(config.screenshotDir, O_EVTONLY)
        guard descriptor >= 0 else { return }
        let source = DispatchSource.makeFileSystemObjectSource(
            fileDescriptor: descriptor,
            eventMask: [.write, .extend, .rename, .delete],
            queue: DispatchQueue.global(qos: .utility)
        )
        source.setEventHandler { [weak self] in
            DispatchQueue.main.async {
                self?.scheduleScan(after: 0.01)
            }
        }
        source.setCancelHandler {
            Darwin.close(descriptor)
        }
        directorySource = source
        source.resume()
    }

    private func scheduleScan(after delay: TimeInterval) {
        guard isRunning else { return }
        scheduledScan?.cancel()
        let workItem = DispatchWorkItem { [weak self] in
            self?.scheduledScan = nil
            self?.scan()
        }
        scheduledScan = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + max(0.01, delay), execute: workItem)
    }

    private func currentImageFiles() -> [ImageFile] {
        let dir = config.screenshotDir
        guard let urls = try? FileManager.default.contentsOfDirectory(
            at: URL(fileURLWithPath: dir),
            includingPropertiesForKeys: [.isRegularFileKey, .contentModificationDateKey],
            options: [.skipsHiddenFiles]
        ) else { return [] }
        return urls
            .compactMap { url -> ImageFile? in
                guard imageExtensions.contains(url.pathExtension.lowercased()),
                      let values = try? url.resourceValues(forKeys: [.isRegularFileKey, .contentModificationDateKey]),
                      values.isRegularFile == true else { return nil }
                return ImageFile(path: url.path, modificationDate: values.contentModificationDate ?? .distantPast)
            }
            .sorted {
                if $0.modificationDate == $1.modificationDate {
                    return $0.path < $1.path
                }
                return $0.modificationDate < $1.modificationDate
            }
    }

    @discardableResult
    private func copyImageToClipboard(path: String) -> Bool {
        let url = URL(fileURLWithPath: path)
        let fileExtension = url.pathExtension.lowercased()
        guard let data = try? Data(contentsOf: url),
              hasCompleteFileTrailer(data, fileExtension: fileExtension),
              let source = CGImageSourceCreateWithData(data as CFData, nil),
              CGImageSourceGetStatus(source) == .statusComplete,
              CGImageSourceGetCount(source) > 0,
              let cgImage = CGImageSourceCreateImageAtIndex(source, 0, nil) else {
            return false
        }

        let item = NSPasteboardItem()
        let sourceType: NSPasteboard.PasteboardType
        switch fileExtension {
        case "png":
            sourceType = .png
        case "jpg", "jpeg":
            sourceType = NSPasteboard.PasteboardType("public.jpeg")
        case "tif", "tiff":
            sourceType = .tiff
        case "heic":
            sourceType = NSPasteboard.PasteboardType("public.heic")
        default:
            return false
        }
        item.setData(data, forType: sourceType)

        if sourceType != .png {
            let representation = NSBitmapImageRep(cgImage: cgImage)
            if let pngData = representation.representation(using: .png, properties: [:]) {
                item.setData(pngData, forType: .png)
            }
        }

        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        return pasteboard.writeObjects([item])
    }

    private func hasCompleteFileTrailer(_ data: Data, fileExtension: String) -> Bool {
        switch fileExtension {
        case "png":
            let iend = Data([0x00, 0x00, 0x00, 0x00, 0x49, 0x45, 0x4e, 0x44, 0xae, 0x42, 0x60, 0x82])
            return data.count >= iend.count && data.suffix(iend.count).elementsEqual(iend)
        case "jpg", "jpeg":
            return data.count >= 2 && data.suffix(2).elementsEqual([0xff, 0xd9])
        default:
            return true
        }
    }
}

func displayID(for screen: NSScreen) -> UInt32 {
    screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? UInt32 ?? 0
}

func currentDisplayID() -> UInt32? {
    NSScreen.main.map(displayID(for:))
}

func displayTitle(for targetID: UInt32) -> String? {
    let screens = sortedScreens()
    guard let index = screens.firstIndex(where: { displayID(for: $0) == targetID }) else {
        return nil
    }
    let screen = screens[index]
    return "\(screen.localizedName) · Display \(index + 1) · ID \(targetID)"
}

func dockBottomEdgeIsAvailable(for targetID: UInt32) -> Bool {
    let selectedFrame = CGDisplayBounds(targetID)
    guard selectedFrame.width > 0, selectedFrame.height > 0 else { return false }
    let allFrames = NSScreen.screens.map { CGDisplayBounds(displayID(for: $0)) }
    guard let desktopMaxY = allFrames.map({ $0.maxY }).max() else { return true }
    return abs(selectedFrame.maxY - desktopMaxY) < 2
}

func dockBottomEdgesAreMisaligned() -> Bool {
    let bottoms = NSScreen.screens.map { CGDisplayBounds(displayID(for: $0)).maxY }
    guard let minY = bottoms.min(), let maxY = bottoms.max() else { return false }
    return abs(maxY - minY) >= 2
}

func currentDockDisplayIDFromWindowServer() -> UInt32? {
    dockDisplayIDFromWindowList([.optionOnScreenOnly, .excludeDesktopElements])
        ?? dockDisplayIDFromWindowList(.optionAll)
}

func appHasVisibleWindows(processIdentifier: pid_t) -> Bool {
    guard let windowInfo = CGWindowListCopyWindowInfo([.optionOnScreenOnly, .excludeDesktopElements], kCGNullWindowID) as? [[String: Any]] else {
        return false
    }
    return windowInfo.contains { window in
        guard (window[kCGWindowOwnerPID as String] as? pid_t) == processIdentifier else {
            return false
        }
        let layer = window[kCGWindowLayer as String] as? Int ?? 0
        guard layer == 0 else {
            return false
        }
        guard let boundsDictionary = window[kCGWindowBounds as String] as? NSDictionary,
              let bounds = CGRect(dictionaryRepresentation: boundsDictionary) else {
            return false
        }
        return bounds.width > 1 && bounds.height > 1
    }
}

private func dockDisplayIDFromWindowList(_ options: CGWindowListOption) -> UInt32? {
    guard let windowInfo = CGWindowListCopyWindowInfo(options, kCGNullWindowID) as? [[String: Any]] else {
        return nil
    }
    return windowInfo.compactMap(dockWindowDisplayID(from:)).first
}

private func dockWindowDisplayID(from window: [String: Any]) -> UInt32? {
    guard (window[kCGWindowOwnerName as String] as? String) == "Dock",
          let name = window[kCGWindowName as String] as? String,
          name == "Dock",
          let boundsDictionary = window[kCGWindowBounds as String] as? NSDictionary,
          let bounds = CGRect(dictionaryRepresentation: boundsDictionary) else {
        return nil
    }
    let midpoint = CGPoint(x: bounds.midX, y: bounds.midY)
    for screen in NSScreen.screens {
        let id = displayID(for: screen)
        if CGDisplayBounds(id).contains(midpoint) {
            return id
        }
    }
    return nil
}

func sortedScreens() -> [NSScreen] {
    NSScreen.screens.sorted {
        if $0.frame.minX == $1.frame.minX {
            return $0.frame.minY < $1.frame.minY
        }
        return $0.frame.minX < $1.frame.minX
    }
}

func agentMenuBarIcon() -> NSImage {
    let image = NSImage(size: NSSize(width: 18, height: 18))
    image.lockFocus()
    NSColor.black.setStroke()
    NSColor.black.setFill()

    let stroke = NSBezierPath()
    stroke.lineWidth = 1.8
    stroke.lineCapStyle = .round
    stroke.lineJoinStyle = .round
    stroke.move(to: NSPoint(x: 9, y: 3))
    stroke.line(to: NSPoint(x: 9, y: 15))
    stroke.move(to: NSPoint(x: 4.5, y: 6))
    stroke.curve(to: NSPoint(x: 9, y: 3.2), controlPoint1: NSPoint(x: 4.8, y: 3.8), controlPoint2: NSPoint(x: 7.1, y: 3.1))
    stroke.curve(to: NSPoint(x: 13.5, y: 6), controlPoint1: NSPoint(x: 10.9, y: 3.1), controlPoint2: NSPoint(x: 13.2, y: 3.8))
    stroke.stroke()

    let top = NSBezierPath(roundedRect: NSRect(x: 5.2, y: 11.2, width: 7.6, height: 3.6), xRadius: 1.8, yRadius: 1.8)
    top.lineWidth = 1.6
    top.stroke()

    let leftDot = NSBezierPath(ovalIn: NSRect(x: 4.0, y: 7.8, width: 2.4, height: 2.4))
    leftDot.fill()
    let rightDot = NSBezierPath(ovalIn: NSRect(x: 11.6, y: 7.8, width: 2.4, height: 2.4))
    rightDot.fill()

    image.unlockFocus()
    image.isTemplate = true
    image.accessibilityDescription = "MacBootstrapAgent"
    return image
}

final class Agent: NSObject, NSApplicationDelegate {
    private let config: Config
    private let screenshotWatcher: ScreenshotWatcher
    private let keepAwakeController: KeepAwakeController
    private let dockAnchorController: DockAnchorController
    private var entriesByID: [UInt32: HotkeyAction] = [:]
    private var hotKeyRefs: [EventHotKeyRef] = []
    private var nextID: UInt32 = 1
    private var eventHandler: EventHandlerRef?
    private var statusItem: NSStatusItem?
    private var keepAwakeMenuItem: NSMenuItem?
    private var settingsWindowController: SettingsWindowController?

    init(config: Config) {
        self.config = config
        self.screenshotWatcher = ScreenshotWatcher(config: config)
        self.keepAwakeController = KeepAwakeController(config: config)
        self.dockAnchorController = DockAnchorController(config: config)
        super.init()
    }

    func run() {
        NSApplication.shared.setActivationPolicy(.accessory)
        NSApplication.shared.delegate = self
        setupStatusItem()
        installEventHandler()
        reloadAll()
        NSApplication.shared.finishLaunching()
        openSettings()
        NSApplication.shared.run()
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        openSettings()
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        openSettings()
        return true
    }

    private func setupStatusItem() {
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        item.button?.image = agentMenuBarIcon()
        let menu = NSMenu()
        let settings = NSMenuItem(title: agentText("menu.settings"), action: #selector(openSettingsFromMenu), keyEquivalent: ",")
        let keepAwake = NSMenuItem(title: agentText("menu.keepAwake"), action: #selector(toggleKeepAwakeFromMenu), keyEquivalent: "k")
        let reload = NSMenuItem(title: agentText("menu.reload"), action: #selector(reloadFromMenu), keyEquivalent: "r")
        let quit = NSMenuItem(title: agentText("menu.quit"), action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        [settings, keepAwake, reload].forEach { $0.target = self }
        menu.addItem(settings)
        menu.addItem(keepAwake)
        menu.addItem(reload)
        menu.addItem(NSMenuItem.separator())
        menu.addItem(quit)
        item.menu = menu
        keepAwakeMenuItem = keepAwake
        statusItem = item
    }

    private func installEventHandler() {
        var eventType = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
        let callback: EventHandlerUPP = { _, eventRef, userData in
            var hotKeyID = EventHotKeyID()
            GetEventParameter(
                eventRef,
                EventParamName(kEventParamDirectObject),
                EventParamType(typeEventHotKeyID),
                nil,
                MemoryLayout<EventHotKeyID>.size,
                nil,
                &hotKeyID
            )
            guard let userData else { return noErr }
            let agent = Unmanaged<Agent>.fromOpaque(userData).takeUnretainedValue()
            agent.handle(id: hotKeyID.id)
            return noErr
        }

        InstallEventHandler(
            GetApplicationEventTarget(),
            callback,
            1,
            &eventType,
            Unmanaged.passUnretained(self).toOpaque(),
            &eventHandler
        )
    }

    @objc private func openSettingsFromMenu() {
        openSettings()
    }

    @objc private func reloadFromMenu() {
        reloadAll()
    }

    @objc private func toggleKeepAwakeFromMenu() {
        do {
            config.reloadBootstrap()
            try config.setKeepAwakeEnabled(!config.keepAwakeEnabled)
            reloadAll()
            settingsWindowController?.reloadPressed()
        } catch {
            NSLog("Failed to toggle keep awake: \(error)")
        }
    }

    private func openSettings() {
        if settingsWindowController == nil {
            let controller = SettingsWindowController(config: config)
            controller.onSave = { [weak self] in self?.reloadAll() }
            controller.onShortcutCaptureStart = { [weak self] in self?.pauseHotkeysForCapture() }
            controller.onShortcutCaptureEnd = { [weak self] in self?.reloadHotkeys() }
            controller.onLanguageChange = { [weak self] in
                DispatchQueue.main.async {
                    self?.rebuildLocalizedUI()
                }
            }
            settingsWindowController = controller
        }
        settingsWindowController?.showWindow(nil)
        settingsWindowController?.window?.center()
        settingsWindowController?.window?.makeKeyAndOrderFront(nil)
        settingsWindowController?.window?.orderFrontRegardless()
        NSApplication.shared.activate(ignoringOtherApps: true)
    }

    private func rebuildLocalizedUI() {
        settingsWindowController?.close()
        settingsWindowController = nil
        if let statusItem {
            NSStatusBar.system.removeStatusItem(statusItem)
            self.statusItem = nil
        }
        setupStatusItem()
        updateMenuState()
        openSettings()
    }

    private func reloadAll() {
        reloadHotkeys()
        screenshotWatcher.reload()
        keepAwakeController.reload()
        dockAnchorController.reload()
        updateMenuState()
    }

    private func updateMenuState() {
        keepAwakeMenuItem?.state = config.keepAwakeEnabled ? .on : .off
    }

    private func reloadHotkeys() {
        unregisterHotkeys()
        nextID = 1
        guard config.appHotkeysEnabled else { return }

        do {
            for binding in try config.loadBindings() where binding.isEnabled {
                register(shortcutText: binding.shortcut, label: binding.label, action: .toggleApp(binding))
            }
        } catch {
            NSLog("Failed to load hotkey bindings: \(error)")
        }
    }

    private func pauseHotkeysForCapture() {
        unregisterHotkeys()
    }

    private func unregisterHotkeys() {
        for ref in hotKeyRefs {
            UnregisterEventHotKey(ref)
        }
        hotKeyRefs.removeAll()
        entriesByID.removeAll()
    }

    private func register(shortcutText: String, label: String, action: HotkeyAction) {
        guard let shortcut = parseShortcut(shortcutText) else {
            NSLog("Skipping invalid shortcut: \(shortcutText)")
            return
        }
        var hotKeyRef: EventHotKeyRef?
        let id = nextID
        nextID += 1
        let hotKeyID = EventHotKeyID(signature: OSType(0x4D424148), id: id)
        let status = RegisterEventHotKey(shortcut.keyCode, shortcut.modifiers, hotKeyID, GetApplicationEventTarget(), 0, &hotKeyRef)
        if status == noErr, let hotKeyRef {
            entriesByID[id] = action
            hotKeyRefs.append(hotKeyRef)
        } else {
            NSLog("Failed to register \(shortcutText) for \(label): \(status)")
        }
    }

    private func handle(id: UInt32) {
        guard let action = entriesByID[id] else { return }
        switch action {
        case .toggleApp(let binding):
            toggleApp(bundleID: binding.bundleID)
        case .insertText(let binding):
            insertText(binding.text)
        }
    }

    private func toggleApp(bundleID: String) {
        let running = NSRunningApplication.runningApplications(withBundleIdentifier: bundleID)
        if let app = running.first {
            let hasVisibleWindows = appHasVisibleWindows(processIdentifier: app.processIdentifier)
            if hasVisibleWindows && (app.isActive || !app.isHidden) {
                app.hide()
            } else {
                reopenAndActivate(app: app, bundleID: bundleID)
            }
            return
        }

        if let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleID) {
            let configuration = NSWorkspace.OpenConfiguration()
            configuration.activates = true
            NSWorkspace.shared.openApplication(at: url, configuration: configuration)
        }
    }

    private func reopenAndActivate(app: NSRunningApplication, bundleID: String) {
        guard let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleID) else {
            app.unhide()
            app.activate(options: [.activateIgnoringOtherApps])
            return
        }
        let configuration = NSWorkspace.OpenConfiguration()
        configuration.activates = true
        NSWorkspace.shared.openApplication(at: url, configuration: configuration) { reopenedApp, _ in
            DispatchQueue.main.async {
                let target = reopenedApp ?? app
                target.unhide()
                target.activate(options: [.activateIgnoringOtherApps])
            }
        }
    }

    private func insertText(_ text: String) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
        let source = CGEventSource(stateID: .hidSystemState)
        let flags: CGEventFlags = [.maskCommand]
        let down = CGEvent(keyboardEventSource: source, virtualKey: 9, keyDown: true)
        down?.flags = flags
        let up = CGEvent(keyboardEventSource: source, virtualKey: 9, keyDown: false)
        up?.flags = flags
        down?.post(tap: .cghidEventTap)
        up?.post(tap: .cghidEventTap)
    }
}

func parseShortcut(_ value: String) -> ParsedShortcut? {
    let parts = value.lowercased().split(separator: "+").map(String.init)
    guard let key = parts.last else { return nil }
    var modifiers: UInt32 = 0
    for modifier in parts.dropLast() {
        switch modifier {
        case "ctrl", "control": modifiers |= UInt32(controlKey)
        case "opt", "option", "alt": modifiers |= UInt32(optionKey)
        case "cmd", "command": modifiers |= UInt32(cmdKey)
        case "shift": modifiers |= UInt32(shiftKey)
        default: return nil
        }
    }
    guard let keyCode = keyCode(for: key) else { return nil }
    return ParsedShortcut(keyCode: keyCode, modifiers: modifiers)
}

func shortcutString(from event: NSEvent) -> String? {
    guard let key = keyName(for: UInt32(event.keyCode)) else { return nil }
    var parts = modifierParts(from: event)
    guard !parts.isEmpty else { return nil }
    parts.append(key)
    return parts.joined(separator: "+")
}

func modifierString(from event: NSEvent) -> String? {
    let parts = modifierParts(from: event)
    return parts.isEmpty ? nil : parts.joined(separator: "+")
}

func modifierParts(from event: NSEvent) -> [String] {
    let flags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
    var parts: [String] = []
    if flags.contains(.control) { parts.append("ctrl") }
    if flags.contains(.option) { parts.append("opt") }
    if flags.contains(.shift) { parts.append("shift") }
    if flags.contains(.command) { parts.append("cmd") }
    return parts
}

func keyCode(for key: String) -> UInt32? {
    let map: [String: UInt32] = [
        "a": 0, "s": 1, "d": 2, "f": 3, "h": 4, "g": 5, "z": 6, "x": 7,
        "c": 8, "v": 9, "b": 11, "q": 12, "w": 13, "e": 14, "r": 15,
        "y": 16, "t": 17, "1": 18, "2": 19, "3": 20, "4": 21, "6": 22,
        "5": 23, "=": 24, "9": 25, "7": 26, "-": 27, "8": 28, "0": 29,
        "]": 30, "o": 31, "u": 32, "[": 33, "i": 34, "p": 35, "l": 37,
        "j": 38, "'": 39, "k": 40, ";": 41, "\\": 42, ",": 43, "/": 44,
        "n": 45, "m": 46, ".": 47, "`": 50, "space": 49, "escape": 53,
        "ㅁ": 0, "ㄴ": 1, "ㅇ": 2, "ㄹ": 3, "ㅗ": 4, "ㅎ": 5, "ㅋ": 6, "ㅌ": 7,
        "ㅊ": 8, "ㅍ": 9, "ㅠ": 11, "ㅂ": 12, "ㅈ": 13, "ㄷ": 14, "ㄱ": 15,
        "ㅛ": 16, "ㅅ": 17, "ㅕ": 31, "ㅜ": 32, "ㅔ": 33, "ㅑ": 34, "ㅐ": 35,
        "ㅣ": 37, "ㅓ": 38, "ㅏ": 40, "ㅡ": 45, "ㅢ": 46
    ]
    return map[key]
}

func keyName(for keyCode: UInt32) -> String? {
    let map: [UInt32: String] = [
        0: "a", 1: "s", 2: "d", 3: "f", 4: "h", 5: "g", 6: "z", 7: "x",
        8: "c", 9: "v", 11: "b", 12: "q", 13: "w", 14: "e", 15: "r",
        16: "y", 17: "t", 18: "1", 19: "2", 20: "3", 21: "4", 22: "6",
        23: "5", 24: "=", 25: "9", 26: "7", 27: "-", 28: "8", 29: "0",
        30: "]", 31: "o", 32: "u", 33: "[", 34: "i", 35: "p", 37: "l",
        38: "j", 39: "'", 40: "k", 41: ";", 42: "\\", 43: ",", 44: "/",
        45: "n", 46: "m", 47: ".", 49: "space", 50: "`", 53: "escape"
    ]
    return map[keyCode]
}

func argument(_ name: String) -> String? {
    let args = CommandLine.arguments
    guard let index = args.firstIndex(of: name), args.indices.contains(index + 1) else { return nil }
    return args[index + 1]
}

func applicationSupportPath(_ fileName: String) -> String {
    let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        .appendingPathComponent("MacBootstrapAgent", isDirectory: true)
    return base.appendingPathComponent(fileName).path
}

func defaultHotkeys() -> String {
    """
    # MacBootstrapAgent app hotkeys.
    # Format: toggle-app|shortcut|bundle-id|label|enabled
    # Add, remove, or edit rows from the Agent UI.
    """
}

func defaultBootstrap() -> String {
    """
    APP_HOTKEYS_ENABLED=0
    SCREENSHOT_DIR="auto"
    SCREENSHOT_CLIPBOARD_WATCH=0
    KEEP_AWAKE_ENABLED=0
    KEEP_DISPLAY_AWAKE=0
    DOCK_ANCHOR_ENABLED=0
    DOCK_ANCHOR_DISPLAY_ID=auto
    AGENT_REGISTERED_BUNDLE_IDS=()
    """
}

func currentMacOSScreenshotDir() -> String {
    let process = Process()
    let pipe = Pipe()
    process.executableURL = URL(fileURLWithPath: "/usr/bin/defaults")
    process.arguments = ["read", "com.apple.screencapture", "location"]
    process.standardOutput = pipe
    process.standardError = Pipe()
    do {
        try process.run()
        process.waitUntilExit()
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let value = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if process.terminationStatus == 0, !value.isEmpty {
            return NSString(string: value).expandingTildeInPath
        }
    } catch {
        return NSHomeDirectory() + "/Desktop"
    }
    return NSHomeDirectory() + "/Desktop"
}

func macOSScreenshotFloatingThumbnailEnabled() -> Bool {
    let process = Process()
    let pipe = Pipe()
    process.executableURL = URL(fileURLWithPath: "/usr/bin/defaults")
    process.arguments = ["read", "com.apple.screencapture", "show-thumbnail"]
    process.standardOutput = pipe
    process.standardError = Pipe()
    do {
        try process.run()
        process.waitUntilExit()
        guard process.terminationStatus == 0 else { return true }
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let value = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() ?? ""
        return !["0", "false", "no"].contains(value)
    } catch {
        return true
    }
}

func setMacOSScreenshotFloatingThumbnailEnabled(_ enabled: Bool) -> Bool {
    let defaults = Process()
    defaults.executableURL = URL(fileURLWithPath: "/usr/bin/defaults")
    defaults.arguments = ["write", "com.apple.screencapture", "show-thumbnail", "-bool", enabled ? "true" : "false"]
    defaults.standardOutput = Pipe()
    defaults.standardError = Pipe()
    do {
        try defaults.run()
        defaults.waitUntilExit()
    } catch {
        return false
    }
    guard defaults.terminationStatus == 0 else { return false }

    let refresh = Process()
    refresh.executableURL = URL(fileURLWithPath: "/usr/bin/killall")
    refresh.arguments = ["screencaptureui"]
    refresh.standardOutput = Pipe()
    refresh.standardError = Pipe()
    do {
        try refresh.run()
        refresh.waitUntilExit()
    } catch {
        // The preference is already written; no active UI process is also a valid state.
    }
    return true
}

func setMacOSScreenshotLocation(_ path: String) -> Bool {
    do {
        try FileManager.default.createDirectory(atPath: path, withIntermediateDirectories: true)
    } catch {
        return false
    }

    let defaults = Process()
    defaults.executableURL = URL(fileURLWithPath: "/usr/bin/defaults")
    defaults.arguments = ["write", "com.apple.screencapture", "location", "-string", path]
    defaults.standardOutput = Pipe()
    defaults.standardError = Pipe()
    do {
        try defaults.run()
        defaults.waitUntilExit()
    } catch {
        return false
    }
    guard defaults.terminationStatus == 0 else { return false }

    for processName in ["SystemUIServer", "screencaptureui"] {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/killall")
        process.arguments = [processName]
        process.standardOutput = Pipe()
        process.standardError = Pipe()
        try? process.run()
        process.waitUntilExit()
    }
    return true
}

let hotkeyPath = argument("--config") ?? applicationSupportPath("hotkeys.conf")
let bootstrapPath = argument("--bootstrap-config") ?? applicationSupportPath("bootstrap.conf")
let config = Config(hotkeyPath: hotkeyPath, bootstrapPath: bootstrapPath)
Agent(config: config).run()
