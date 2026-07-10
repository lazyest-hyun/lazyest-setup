import AppKit
import Carbon
import Foundation

enum SetupLanguage: String {
    case automatic = "auto"
    case english = "en"
    case korean = "ko"
}

func sharedLanguageConfigPath() -> URL {
    let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
        ?? URL(fileURLWithPath: NSHomeDirectory()).appendingPathComponent("Library/Application Support", isDirectory: true)
    return base.appendingPathComponent("MacBootstrapSetup", isDirectory: true).appendingPathComponent("language.conf")
}

func savedLanguageCode() -> String {
    let path = sharedLanguageConfigPath()
    if let value = try? String(contentsOf: path, encoding: .utf8).trimmingCharacters(in: .whitespacesAndNewlines),
       !value.isEmpty {
        return value
    }
    return UserDefaults.standard.string(forKey: "MacBootstrapLanguage") ?? SetupLanguage.automatic.rawValue
}

func saveLanguageCode(_ code: String) {
    let path = sharedLanguageConfigPath()
    try? FileManager.default.createDirectory(at: path.deletingLastPathComponent(), withIntermediateDirectories: true)
    try? code.write(to: path, atomically: true, encoding: .utf8)
    UserDefaults.standard.set(code, forKey: "MacBootstrapLanguage")
}

func effectiveLanguage() -> SetupLanguage {
    let selected = SetupLanguage(rawValue: savedLanguageCode()) ?? .automatic
    if selected != .automatic {
        return selected
    }
    let preferred = Locale.preferredLanguages.first?.lowercased() ?? ""
    return preferred.hasPrefix("ko") ? .korean : .english
}

func localized(_ key: String) -> String {
    let korean: [String: String] = [
        "app.title": "Mac 초기 설정",
        "tab.install": "설치",
        "tab.text": "텍스트/키보드",
        "tab.desktop": "데스크톱",
        "tab.dock": "Dock",
        "tab.runtime": "Agent",
        "language.auto": "자동",
        "language.ko": "한국어",
        "language.en": "English",
        "section.base": "기본",
        "section.browser": "브라우저/런처",
        "section.developer": "개발/AI",
        "section.editor": "에디터",
        "section.communication": "커뮤니케이션",
        "section.utility": "편의",
        "row.homebrew.title": "Homebrew",
        "row.homebrew.detail": "앱 설치에 필요합니다.",
        "row.chrome.title": "Google Chrome",
        "row.chrome.detail": "기본 웹 브라우저.",
        "row.arc.title": "Arc",
        "row.arc.detail": "공간/프로필 중심 브라우저.",
        "row.aside.title": "Aside",
        "row.aside.detail": "AI 브라우저.",
        "row.codex.title": "Codex",
        "row.codex.detail": "코딩 에이전트 앱.",
        "row.cursor.title": "Cursor",
        "row.cursor.detail": "AI 코드 에디터.",
        "row.vscode.title": "Visual Studio Code",
        "row.vscode.detail": "범용 코드 에디터.",
        "row.zed.title": "Zed",
        "row.zed.detail": "빠른 협업 코드 에디터.",
        "row.devin.title": "Devin Desktop",
        "row.devin.detail": "AI 개발 에이전트 데스크톱 앱.",
        "row.docker.title": "Docker Desktop",
        "row.docker.detail": "컨테이너 개발 환경.",
        "row.iterm.title": "iTerm2",
        "row.iterm.detail": "터미널 대체 앱.",
        "row.linearmouse.title": "LinearMouse",
        "row.linearmouse.detail": "마우스 스크롤 방향.",
        "row.raycast.title": "Raycast",
        "row.raycast.detail": "선택 런처.",
        "row.claude.title": "Claude",
        "row.claude.detail": "데스크톱 앱.",
        "row.teams.title": "Microsoft Teams",
        "row.teams.detail": "팀 채팅.",
        "row.slack.title": "Slack",
        "row.slack.detail": "팀 채팅.",
        "row.amphetamine.title": "Amphetamine",
        "row.amphetamine.detail": "선택 App Store 대안.",
        "row.gureum.title": "구름 입력기",
        "row.gureum.detail": "설치 후 로그아웃해야 입력 소스에 나타납니다.",
        "row.gureumOption.title": "구름 Option 키",
        "row.gureumOption.detail": "한글 입력 중에도 Option 조합 특수문자를 사용합니다.",
        "row.karabiner.title": "Karabiner-Elements",
        "row.karabiner.detail": "오른쪽 Command를 F18로.",
        "row.inputSource.title": "입력 소스 설정",
        "row.inputSource.detail": "Gureum / Han 2set 등록 후 Apple 두벌식을 제거합니다.",
        "row.inputShortcut.title": "입력 소스 단축키",
        "row.inputShortcut.detail": "이전 입력 소스는 끄고 다음 입력 소스는 F18로 설정합니다.",
        "row.keyRepeat.title": "키 반복 속도",
        "row.keyRepeat.detail": "반복 속도는 제일 빠르게, 반복 지연 시간은 제일 짧게 설정합니다.",
        "row.pressAndHold.title": "길게 눌러 악센트",
        "row.pressAndHold.detail": "키를 길게 눌렀을 때 악센트 선택 대신 반복 입력되게 합니다.",
        "row.functionKeys.title": "기능 키",
        "row.functionKeys.detail": "F1, F2 등의 키를 표준 기능 키로 사용.",
        "row.globeKey.title": "지구본 키",
        "row.globeKey.detail": "지구본/Fn 키를 눌러도 아무 동작 없음.",
        "row.spelling.title": "맞춤법 자동 수정",
        "row.spelling.detail": "자동 텍스트 변경.",
        "row.period.title": "스페이스 두 번 마침표",
        "row.period.detail": "Space Space로 마침표 입력.",
        "row.inline.title": "인라인 자동 완성",
        "row.inline.detail": "인라인 완성 텍스트.",
        "row.click.title": "데스크톱 보기 방지",
        "row.click.detail": "배경화면을 클릭해도 창이 사라지지 않게 합니다.",
        "row.wallpaper.title": "검정 배경화면",
        "row.wallpaper.detail": "macOS 내장 검은색 배경.",
        "row.dockAutohide.title": "Dock 자동 숨김",
        "row.dockAutohide.detail": "Dock을 평소에는 숨기고 가장자리에서만 표시합니다.",
        "row.dock.title": "Dock 정리",
        "row.dock.detail": "체크한 기본 앱만 Dock에 유지합니다.",
        "dock.hint": "Finder는 macOS 고정 항목이라 따로 관리하지 않습니다. 체크를 켜면 Dock에 추가하고, 끄면 Dock에서 제거합니다.",
        "dock.apply": "선택 적용",
        "dock.selected": "선택됨",
        "dock.current": "현재 Dock",
        "row.agent.title": "MacBootstrapAgent",
        "row.agent.detail": "별도 프로젝트로 설치되는 메뉴 막대 앱.",
        "button.install": "설치",
        "button.open": "열기",
        "button.done": "완료",
        "button.reset": "초기화",
        "button.enable": "켜기",
        "button.disable": "끄기",
        "button.apply": "적용",
        "button.applySettings": "설정 적용",
        "button.check": "확인",
        "button.appstore": "App Store",
        "button.refresh": "새로고침",
        "button.removeSetup": "Setup 제거",
        "button.remove": "제거",
        "button.logout": "로그아웃",
        "status.ready": "준비됨",
        "status.refreshed": "상태만 확인됨",
        "status.done": "완료",
        "status.installed": "설치됨",
        "status.registered": "등록됨",
        "status.missing": "없음",
        "status.notApplied": "미적용",
        "status.partiallyApplied": "부분 적용",
        "status.systemColor": "시스템 색상",
        "status.homebrewFirst": "Homebrew 먼저",
        "status.gureumFirst": "구름 먼저",
        "status.appstore": "App Store",
        "status.off": "꺼짐",
        "status.on": "켜짐",
        "status.applied": "적용됨",
        "status.default": "기본값",
        "status.running": "실행 중",
        "status.needsOpen": "열기 필요",
        "status.needsPermission": "권한 필요",
        "status.needsRelogin": "반영 대기",
        "status.needsLogout": "로그아웃 필요",
        "status.manualCheck": "수동 확인",
        "status.agentInstalled": "Agent 설치됨",
        "status.agentFailed": "Agent 설치 실패",
        "status.agentInstalling": "Agent 다운로드 및 설치 중",
        "status.opened": "열림",
        "status.applying": "적용 중",
        "status.failed": "실패",
        "status.dockApplied": "Dock 정리 완료",
        "status.dockBlocked": "Dock 정리 실패",
        "status.startedTerminal": "Terminal에서 설치 시작",
        "status.installHomebrewFirst": "Homebrew를 먼저 설치하세요",
        "status.settingsApplied": "설정 적용됨",
        "alert.logout.title": "지금 로그아웃할까요?",
        "alert.logout.gureum": "구름 입력기는 설치 후 로그아웃해야 입력 소스 목록에 나타납니다. 저장하지 않은 작업을 먼저 정리하세요.",
        "alert.logout.now": "지금 로그아웃",
        "alert.logout.later": "나중에"
    ]
    if effectiveLanguage() == .korean, let value = korean[key] {
        return value
    }
    let english: [String: String] = [
        "app.title": "One-Time Mac Setup",
        "tab.install": "Install",
        "tab.text": "Text & Keyboard",
        "tab.desktop": "Desktop",
        "tab.dock": "Dock",
        "tab.runtime": "Agent",
        "language.auto": "Auto",
        "language.ko": "한국어",
        "language.en": "English",
        "section.base": "Base",
        "section.browser": "Browser / Launcher",
        "section.developer": "Developer / AI",
        "section.editor": "Editors",
        "section.communication": "Communication",
        "section.utility": "Utilities",
        "row.homebrew.title": "Homebrew",
        "row.homebrew.detail": "Required for cask installs.",
        "row.chrome.title": "Google Chrome",
        "row.chrome.detail": "Primary web browser.",
        "row.arc.title": "Arc",
        "row.arc.detail": "Spaces/profile-focused browser.",
        "row.aside.title": "Aside",
        "row.aside.detail": "AI browser.",
        "row.codex.title": "Codex",
        "row.codex.detail": "Coding agent app.",
        "row.cursor.title": "Cursor",
        "row.cursor.detail": "AI code editor.",
        "row.vscode.title": "Visual Studio Code",
        "row.vscode.detail": "General-purpose code editor.",
        "row.zed.title": "Zed",
        "row.zed.detail": "Fast collaborative code editor.",
        "row.devin.title": "Devin Desktop",
        "row.devin.detail": "AI development agent desktop app.",
        "row.docker.title": "Docker Desktop",
        "row.docker.detail": "Container development environment.",
        "row.iterm.title": "iTerm2",
        "row.iterm.detail": "Terminal replacement.",
        "row.linearmouse.title": "LinearMouse",
        "row.linearmouse.detail": "Mouse scroll direction.",
        "row.raycast.title": "Raycast",
        "row.raycast.detail": "Optional launcher.",
        "row.claude.title": "Claude",
        "row.claude.detail": "Desktop app.",
        "row.teams.title": "Microsoft Teams",
        "row.teams.detail": "Team chat.",
        "row.slack.title": "Slack",
        "row.slack.detail": "Team chat.",
        "row.amphetamine.title": "Amphetamine",
        "row.amphetamine.detail": "Optional App Store alternative.",
        "row.gureum.title": "Gureum Input Method",
        "row.gureum.detail": "Log out after install so it appears in Input Sources.",
        "row.gureumOption.title": "Gureum Option Key",
        "row.gureumOption.detail": "Use Option-key special characters while typing Korean.",
        "row.karabiner.title": "Karabiner-Elements",
        "row.karabiner.detail": "Right Command to F18.",
        "row.inputSource.title": "Input Source Settings",
        "row.inputSource.detail": "Register Gureum / Han 2set, then remove Apple 2-set Korean.",
        "row.inputShortcut.title": "Input Source Shortcuts",
        "row.inputShortcut.detail": "Disable previous input source and set next input source to F18.",
        "row.keyRepeat.title": "Key Repeat",
        "row.keyRepeat.detail": "Set key repeat to fastest and repeat delay to shortest.",
        "row.pressAndHold.title": "Press-and-hold accents",
        "row.pressAndHold.detail": "Make long key presses repeat instead of opening accent pickers.",
        "row.functionKeys.title": "Function Keys",
        "row.functionKeys.detail": "Use F1, F2, etc. as standard function keys.",
        "row.globeKey.title": "Globe Key",
        "row.globeKey.detail": "Pressing Globe/Fn key does nothing.",
        "row.spelling.title": "Spelling correction",
        "row.spelling.detail": "Automatic text change.",
        "row.period.title": "Double-space period",
        "row.period.detail": "Space Space inserts period.",
        "row.inline.title": "Inline prediction",
        "row.inline.detail": "Inline completion text.",
        "row.click.title": "Disable Click-to-Show Desktop",
        "row.click.detail": "Keep windows visible when clicking the wallpaper.",
        "row.wallpaper.title": "Black wallpaper",
        "row.wallpaper.detail": "Built-in macOS black wallpaper.",
        "row.dockAutohide.title": "Automatically hide Dock",
        "row.dockAutohide.detail": "Hide the Dock until the pointer reaches the screen edge.",
        "row.dock.title": "Dock cleanup",
        "row.dock.detail": "Keep only the checked default apps in the Dock.",
        "dock.hint": "Finder is a fixed macOS Dock item and is not managed here. Checked apps are added to the Dock; unchecked apps are removed.",
        "dock.apply": "Apply Selection",
        "dock.selected": "selected",
        "dock.current": "in Dock",
        "row.agent.title": "MacBootstrapAgent",
        "row.agent.detail": "Menu bar app installed from its separate project.",
        "button.install": "Install",
        "button.open": "Open",
        "button.done": "Done",
        "button.reset": "Reset",
        "button.enable": "Enable",
        "button.disable": "Disable",
        "button.apply": "Apply",
        "button.applySettings": "Apply Settings",
        "button.check": "Check",
        "button.appstore": "App Store",
        "button.refresh": "Refresh",
        "button.removeSetup": "Remove Setup App",
        "button.remove": "Remove",
        "button.logout": "Log Out",
        "status.ready": "Ready",
        "status.refreshed": "Status checked only",
        "status.done": "Done",
        "status.installed": "Installed",
        "status.registered": "Registered",
        "status.missing": "Missing",
        "status.notApplied": "Not applied",
        "status.partiallyApplied": "Partially applied",
        "status.systemColor": "System color",
        "status.homebrewFirst": "Homebrew first",
        "status.gureumFirst": "Gureum first",
        "status.appstore": "App Store",
        "status.off": "Off",
        "status.on": "On",
        "status.applied": "Applied",
        "status.default": "Default",
        "status.running": "Running",
        "status.needsOpen": "Needs open",
        "status.needsPermission": "Needs permission",
        "status.needsRelogin": "Pending refresh",
        "status.needsLogout": "Needs logout",
        "status.manualCheck": "Manual check",
        "status.agentInstalled": "Agent installed",
        "status.agentFailed": "Agent install failed",
        "status.agentInstalling": "Downloading and installing Agent",
        "status.opened": "Opened",
        "status.applying": "Applying",
        "status.failed": "Failed",
        "status.dockApplied": "Dock cleanup applied",
        "status.dockBlocked": "Dock cleanup blocked",
        "status.startedTerminal": "Started install in Terminal",
        "status.installHomebrewFirst": "Install Homebrew first",
        "status.settingsApplied": "Settings applied",
        "alert.logout.title": "Log out now?",
        "alert.logout.gureum": "Gureum appears in Input Sources only after logging out after install. Save your work first.",
        "alert.logout.now": "Log Out Now",
        "alert.logout.later": "Later"
    ]
    return english[key] ?? key
}

struct DockChoice {
    let title: String
    let aliases: [String]
    let path: String
}

let dockChoices: [DockChoice] = [
    DockChoice(title: "앱 / Apps", aliases: ["앱", "Apps", "Launchpad"], path: "/System/Applications/Apps.app"),
    DockChoice(title: "Safari", aliases: ["Safari"], path: "/Applications/Safari.app"),
    DockChoice(title: "메모 / Notes", aliases: ["메모", "Notes"], path: "/System/Applications/Notes.app"),
    DockChoice(title: "시스템 설정 / System Settings", aliases: ["시스템 설정", "System Settings"], path: "/System/Applications/System Settings.app"),
    DockChoice(title: "캘린더 / Calendar", aliases: ["캘린더", "Calendar"], path: "/System/Applications/Calendar.app"),
    DockChoice(title: "메시지 / Messages", aliases: ["메시지", "Messages"], path: "/System/Applications/Messages.app"),
    DockChoice(title: "메일 / Mail", aliases: ["메일", "Mail"], path: "/System/Applications/Mail.app"),
    DockChoice(title: "지도 / Maps", aliases: ["지도", "Maps"], path: "/System/Applications/Maps.app"),
    DockChoice(title: "사진 / Photos", aliases: ["사진", "Photos"], path: "/System/Applications/Photos.app"),
    DockChoice(title: "FaceTime", aliases: ["FaceTime"], path: "/System/Applications/FaceTime.app"),
    DockChoice(title: "전화 / Phone", aliases: ["전화", "Phone"], path: "/System/Applications/Phone.app"),
    DockChoice(title: "연락처 / Contacts", aliases: ["연락처", "Contacts"], path: "/System/Applications/Contacts.app"),
    DockChoice(title: "미리 알림 / Reminders", aliases: ["미리 알림", "Reminders"], path: "/System/Applications/Reminders.app"),
    DockChoice(title: "TV", aliases: ["TV"], path: "/System/Applications/TV.app"),
    DockChoice(title: "음악 / Music", aliases: ["음악", "Music"], path: "/System/Applications/Music.app"),
    DockChoice(title: "Freeform", aliases: ["Freeform", "무한 캔버스"], path: "/System/Applications/Freeform.app"),
    DockChoice(title: "App Store", aliases: ["App Store"], path: "/System/Applications/App Store.app"),
    DockChoice(title: "iPhone 미러링 / iPhone Mirroring", aliases: ["iPhone 미러링", "iPhone Mirroring"], path: "/System/Applications/iPhone Mirroring.app"),
]

final class FlippedView: NSView {
    override var isFlipped: Bool { true }
}

private enum RowVisualState {
    case success
    case attention
    case info
    case neutral
}

private enum BooleanPreferenceState: Equatable {
    case enabled
    case disabled
    case inherited
}

final class SetupWindowController: NSWindowController {
    private var statusPills: [NSTextField] = []
    private var statusRows: [(status: NSTextField, box: NSBox)] = []
    private var dockCheckboxes: [String: NSButton] = [:]
    private var activationObserver: NSObjectProtocol?
    private var spellingPreferenceState: BooleanPreferenceState = .inherited
    private var periodPreferenceState: BooleanPreferenceState = .inherited
    private var inlinePreferenceState: BooleanPreferenceState = .inherited
    private var clickDesktopPreferenceState: BooleanPreferenceState = .inherited
    private var dockAutohidePreferenceState: BooleanPreferenceState = .inherited
    private let statusLabel = NSTextField(labelWithString: localized("status.ready"))
    private let languagePopup = NSPopUpButton()
    private let spellingStatus = NSTextField(labelWithString: "")
    private let periodStatus = NSTextField(labelWithString: "")
    private let inlineStatus = NSTextField(labelWithString: "")
    private let clickDesktopStatus = NSTextField(labelWithString: "")
    private let wallpaperStatus = NSTextField(labelWithString: "")
    private let dockAutohideStatus = NSTextField(labelWithString: "")
    private let dockStatus = NSTextField(labelWithString: "")
    private let homebrewStatus = NSTextField(labelWithString: "")
    private let chromeStatus = NSTextField(labelWithString: "")
    private let arcStatus = NSTextField(labelWithString: "")
    private let asideStatus = NSTextField(labelWithString: "")
    private let raycastStatus = NSTextField(labelWithString: "")
    private let codexStatus = NSTextField(labelWithString: "")
    private let claudeStatus = NSTextField(labelWithString: "")
    private let cursorStatus = NSTextField(labelWithString: "")
    private let vscodeStatus = NSTextField(labelWithString: "")
    private let zedStatus = NSTextField(labelWithString: "")
    private let devinStatus = NSTextField(labelWithString: "")
    private let dockerStatus = NSTextField(labelWithString: "")
    private let itermStatus = NSTextField(labelWithString: "")
    private let teamsStatus = NSTextField(labelWithString: "")
    private let slackStatus = NSTextField(labelWithString: "")
    private let karabinerStatus = NSTextField(labelWithString: "")
    private let gureumStatus = NSTextField(labelWithString: "")
    private let gureumOptionStatus = NSTextField(labelWithString: "")
    private let inputSourceStatus = NSTextField(labelWithString: "")
    private let inputShortcutStatus = NSTextField(labelWithString: "")
    private let keyRepeatStatus = NSTextField(labelWithString: "")
    private let pressAndHoldStatus = NSTextField(labelWithString: "")
    private let functionKeysStatus = NSTextField(labelWithString: "")
    private let globeKeyStatus = NSTextField(labelWithString: "")
    private let linearMouseStatus = NSTextField(labelWithString: "")
    private let amphetamineStatus = NSTextField(labelWithString: "")
    private let agentStatus = NSTextField(labelWithString: "")
    private lazy var spellingPrimaryButton = button("Disable", #selector(toggleSpelling))
    private lazy var periodPrimaryButton = button("Disable", #selector(togglePeriod))
    private lazy var inlinePrimaryButton = button("Disable", #selector(toggleInline))
    private lazy var clickDesktopPrimaryButton = button("Apply", #selector(toggleClickDesktop))
    private lazy var wallpaperPrimaryButton = button("Apply", #selector(applyWallpaper))
    private lazy var dockAutohidePrimaryButton = button("Enable", #selector(toggleDockAutohide))
    private lazy var dockPrimaryButton = button("Apply Selection", #selector(applyDockSelection))
    private lazy var homebrewPrimaryButton = button("Install", #selector(installHomebrew))
    private lazy var chromePrimaryButton = button("Open", #selector(primaryChrome))
    private lazy var arcPrimaryButton = button("Install", #selector(primaryArc))
    private lazy var asidePrimaryButton = button("Install", #selector(primaryAside))
    private lazy var gureumPrimaryButton = button("Install", #selector(primaryGureum))
    private lazy var gureumOptionPrimaryButton = button("Apply Settings", #selector(applyGureumOptionSettings))
    private lazy var karabinerPrimaryButton = button("Install", #selector(primaryKarabiner))
    private lazy var inputSourcePrimaryButton = button("Apply Settings", #selector(applyInputSourceSettings))
    private lazy var inputShortcutPrimaryButton = button("Apply Settings", #selector(applyInputShortcutSettings))
    private lazy var keyRepeatPrimaryButton = button("Apply Settings", #selector(applyKeyRepeatSettings))
    private lazy var pressAndHoldPrimaryButton = button("Apply Settings", #selector(applyPressAndHoldSettings))
    private lazy var functionKeysPrimaryButton = button("Apply Settings", #selector(applyFunctionKeysSettings))
    private lazy var globeKeyPrimaryButton = button("Apply Settings", #selector(applyGlobeKeySettings))
    private lazy var linearMousePrimaryButton = button("Install", #selector(primaryLinearMouse))
    private lazy var raycastPrimaryButton = button("Install", #selector(primaryRaycast))
    private lazy var codexPrimaryButton = button("Open", #selector(primaryCodex))
    private lazy var claudePrimaryButton = button("Install", #selector(primaryClaude))
    private lazy var cursorPrimaryButton = button("Install", #selector(primaryCursor))
    private lazy var vscodePrimaryButton = button("Install", #selector(primaryVSCode))
    private lazy var zedPrimaryButton = button("Install", #selector(primaryZed))
    private lazy var devinPrimaryButton = button("Download", #selector(primaryDevin))
    private lazy var dockerPrimaryButton = button("Install", #selector(primaryDocker))
    private lazy var itermPrimaryButton = button("Install", #selector(primaryITerm))
    private lazy var teamsPrimaryButton = button("Install", #selector(primaryTeams))
    private lazy var slackPrimaryButton = button("Install", #selector(primarySlack))
    private lazy var amphetaminePrimaryButton = button("App Store", #selector(primaryAmphetamine))
    private lazy var agentPrimaryButton = button("Install", #selector(primaryAgent))
    private lazy var agentRemoveButton = button("Remove", #selector(removeAgent))

    init() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 900, height: 620),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.title = localized("app.title")
        window.isReleasedWhenClosed = false
        super.init(window: window)
        buildUI()
        refresh()
        activationObserver = NotificationCenter.default.addObserver(
            forName: NSApplication.didBecomeActiveNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.refresh()
        }
    }

    deinit {
        if let activationObserver {
            NotificationCenter.default.removeObserver(activationObserver)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func buildUI() {
        guard let contentView = window?.contentView else { return }
        statusPills.removeAll()
        statusRows.removeAll()
        contentView.subviews.forEach { $0.removeFromSuperview() }
        window?.title = localized("app.title")
        let root = NSStackView()
        root.orientation = .vertical
        root.spacing = 14
        root.edgeInsets = NSEdgeInsets(top: 18, left: 18, bottom: 18, right: 18)
        root.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(root)
        NSLayoutConstraint.activate([
            root.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            root.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            root.topAnchor.constraint(equalTo: contentView.topAnchor),
            root.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ])

        let header = NSStackView()
        header.orientation = .horizontal
        header.spacing = 12
        let title = NSTextField(labelWithString: localized("app.title"))
        title.font = NSFont.boldSystemFont(ofSize: 22)
        title.alignment = .left
        header.addArrangedSubview(title)
        header.addArrangedSubview(NSView())
        configureLanguagePopup()
        header.addArrangedSubview(languagePopup)
        root.addArrangedSubview(header)

        let tabs = NSTabView()
        tabs.translatesAutoresizingMaskIntoConstraints = false
        tabs.addTabViewItem(appsTab())
        tabs.addTabViewItem(textKeyboardTab())
        tabs.addTabViewItem(desktopTab())
        tabs.addTabViewItem(dockTab())
        tabs.addTabViewItem(runtimeTab())
        root.addArrangedSubview(tabs)
        tabs.widthAnchor.constraint(equalTo: root.widthAnchor).isActive = true
        tabs.heightAnchor.constraint(greaterThanOrEqualToConstant: 470).isActive = true

        let footer = NSStackView()
        footer.orientation = .horizontal
        footer.spacing = 10
        statusLabel.textColor = .secondaryLabelColor
        footer.addArrangedSubview(statusLabel)
        footer.addArrangedSubview(NSView())
        footer.addArrangedSubview(NSButton(title: localized("button.refresh"), target: self, action: #selector(refreshPressed)))
        footer.addArrangedSubview(NSButton(title: localized("button.removeSetup"), target: self, action: #selector(removeSetupApp)))
        root.addArrangedSubview(footer)
    }

    private func configureLanguagePopup() {
        languagePopup.removeAllItems()
        languagePopup.addItem(withTitle: localized("language.auto"))
        languagePopup.addItem(withTitle: localized("language.ko"))
        languagePopup.addItem(withTitle: localized("language.en"))
        languagePopup.target = self
        languagePopup.action = #selector(languageChanged)
        switch savedLanguageCode() {
        case SetupLanguage.korean.rawValue:
            languagePopup.selectItem(at: 1)
        case SetupLanguage.english.rawValue:
            languagePopup.selectItem(at: 2)
        default:
            languagePopup.selectItem(at: 0)
        }
    }

    @objc private func languageChanged() {
        let values = [SetupLanguage.automatic.rawValue, SetupLanguage.korean.rawValue, SetupLanguage.english.rawValue]
        let index = max(0, min(languagePopup.indexOfSelectedItem, values.count - 1))
        saveLanguageCode(values[index])
        buildUI()
        refresh()
    }

    private func textKeyboardTab() -> NSTabViewItem {
        tab(localized("tab.text"), [
            row(title: localized("row.gureum.title"), detail: localized("row.gureum.detail"), status: gureumStatus, buttons: [
                gureumPrimaryButton
            ]),
            row(title: localized("row.gureumOption.title"), detail: localized("row.gureumOption.detail"), status: gureumOptionStatus, buttons: [
                gureumOptionPrimaryButton
            ]),
            row(title: localized("row.karabiner.title"), detail: localized("row.karabiner.detail"), status: karabinerStatus, buttons: [
                karabinerPrimaryButton
            ]),
            row(title: localized("row.inputSource.title"), detail: localized("row.inputSource.detail"), status: inputSourceStatus, buttons: [
                inputSourcePrimaryButton
            ]),
            row(title: localized("row.inputShortcut.title"), detail: localized("row.inputShortcut.detail"), status: inputShortcutStatus, buttons: [
                inputShortcutPrimaryButton
            ]),
            row(title: localized("row.keyRepeat.title"), detail: localized("row.keyRepeat.detail"), status: keyRepeatStatus, buttons: [
                keyRepeatPrimaryButton
            ]),
            row(title: localized("row.pressAndHold.title"), detail: localized("row.pressAndHold.detail"), status: pressAndHoldStatus, buttons: [
                pressAndHoldPrimaryButton
            ]),
            row(title: localized("row.functionKeys.title"), detail: localized("row.functionKeys.detail"), status: functionKeysStatus, buttons: [
                functionKeysPrimaryButton
            ]),
            row(title: localized("row.globeKey.title"), detail: localized("row.globeKey.detail"), status: globeKeyStatus, buttons: [
                globeKeyPrimaryButton
            ]),
            row(title: localized("row.spelling.title"), detail: localized("row.spelling.detail"), status: spellingStatus, buttons: [
                spellingPrimaryButton
            ]),
            row(title: localized("row.period.title"), detail: localized("row.period.detail"), status: periodStatus, buttons: [
                periodPrimaryButton
            ]),
            row(title: localized("row.inline.title"), detail: localized("row.inline.detail"), status: inlineStatus, buttons: [
                inlinePrimaryButton
            ])
        ])
    }

    private func desktopTab() -> NSTabViewItem {
        tab(localized("tab.desktop"), [
            row(title: localized("row.click.title"), detail: localized("row.click.detail"), status: clickDesktopStatus, buttons: [
                clickDesktopPrimaryButton
            ]),
            row(title: localized("row.wallpaper.title"), detail: localized("row.wallpaper.detail"), status: wallpaperStatus, buttons: [
                wallpaperPrimaryButton
            ])
        ])
    }

    private func dockTab() -> NSTabViewItem {
        let item = NSTabViewItem(identifier: localized("tab.dock"))
        item.label = localized("tab.dock")
        dockCheckboxes.removeAll()

        let container = NSView()
        let root = NSStackView()
        root.orientation = .vertical
        root.spacing = 12
        root.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(root)

        let autohideRow = row(title: localized("row.dockAutohide.title"), detail: localized("row.dockAutohide.detail"), status: dockAutohideStatus, buttons: [
            dockAutohidePrimaryButton
        ])
        root.addArrangedSubview(autohideRow)
        autohideRow.widthAnchor.constraint(equalTo: root.widthAnchor).isActive = true

        let header = NSStackView()
        header.orientation = .horizontal
        header.spacing = 12
        header.alignment = .centerY

        let text = NSStackView()
        text.orientation = .vertical
        text.spacing = 4
        let title = NSTextField(labelWithString: localized("row.dock.title"))
        title.font = NSFont.boldSystemFont(ofSize: 16)
        let detail = NSTextField(labelWithString: localized("row.dock.detail"))
        detail.textColor = .secondaryLabelColor
        text.addArrangedSubview(title)
        text.addArrangedSubview(detail)

        styleStatusPill(dockStatus)
        header.addArrangedSubview(text)
        header.addArrangedSubview(NSView())
        header.addArrangedSubview(dockStatus)
        root.addArrangedSubview(header)

        let hint = NSTextField(wrappingLabelWithString: localized("dock.hint"))
        hint.textColor = .secondaryLabelColor
        hint.font = NSFont.systemFont(ofSize: 12)
        root.addArrangedSubview(hint)

        let scrollView = NSScrollView()
        scrollView.hasVerticalScroller = true
        scrollView.drawsBackground = false
        scrollView.borderType = .noBorder
        let documentHeight = CGFloat(dockChoices.count * 42)
        let document = FlippedView(frame: NSRect(x: 0, y: 0, width: 760, height: documentHeight))
        let list = NSStackView()
        list.orientation = .vertical
        list.spacing = 8
        list.translatesAutoresizingMaskIntoConstraints = false
        document.addSubview(list)

        for choice in dockChoices {
            let checkbox = NSButton(checkboxWithTitle: choice.title, target: nil, action: nil)
            checkbox.font = NSFont.systemFont(ofSize: 13)
            checkbox.isEnabled = FileManager.default.fileExists(atPath: choice.path)
            dockCheckboxes[choice.title] = checkbox

            let row = NSBox()
            row.boxType = .custom
            row.cornerRadius = 7
            row.borderColor = NSColor.separatorColor
            row.borderWidth = 1
            row.fillColor = NSColor.clear
            row.contentViewMargins = NSSize(width: 12, height: 8)
            row.heightAnchor.constraint(equalToConstant: 34).isActive = true
            let rowStack = NSStackView()
            rowStack.orientation = .horizontal
            rowStack.alignment = .centerY
            rowStack.translatesAutoresizingMaskIntoConstraints = false
            rowStack.addArrangedSubview(checkbox)
            rowStack.addArrangedSubview(NSView())
            row.contentView?.addSubview(rowStack)
            NSLayoutConstraint.activate([
                rowStack.leadingAnchor.constraint(equalTo: row.contentView!.leadingAnchor),
                rowStack.trailingAnchor.constraint(equalTo: row.contentView!.trailingAnchor),
                rowStack.topAnchor.constraint(equalTo: row.contentView!.topAnchor),
                rowStack.bottomAnchor.constraint(equalTo: row.contentView!.bottomAnchor)
            ])
            list.addArrangedSubview(row)
            row.widthAnchor.constraint(equalTo: list.widthAnchor).isActive = true
        }

        scrollView.documentView = document
        root.addArrangedSubview(scrollView)
        scrollView.heightAnchor.constraint(greaterThanOrEqualToConstant: 330).isActive = true

        let actions = NSStackView()
        actions.orientation = .horizontal
        actions.spacing = 8
        actions.addArrangedSubview(NSView())
        dockPrimaryButton.title = localized("dock.apply")
        actions.addArrangedSubview(dockPrimaryButton)
        root.addArrangedSubview(actions)

        NSLayoutConstraint.activate([
            root.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 18),
            root.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -18),
            root.topAnchor.constraint(equalTo: container.topAnchor, constant: 18),
            root.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -18),
            list.leadingAnchor.constraint(equalTo: document.leadingAnchor),
            list.trailingAnchor.constraint(equalTo: document.trailingAnchor),
            list.topAnchor.constraint(equalTo: document.topAnchor),
            list.widthAnchor.constraint(equalTo: scrollView.contentView.widthAnchor),
            document.heightAnchor.constraint(equalToConstant: documentHeight)
        ])
        statusPills.append(dockStatus)
        item.view = container
        return item
    }

    private func appsTab() -> NSTabViewItem {
        tab(localized("tab.install"), [
            sectionHeader(localized("section.base")),
            row(title: localized("row.homebrew.title"), detail: localized("row.homebrew.detail"), status: homebrewStatus, buttons: [
                homebrewPrimaryButton
            ]),
            sectionHeader(localized("section.browser")),
            row(title: localized("row.chrome.title"), detail: localized("row.chrome.detail"), status: chromeStatus, buttons: [
                chromePrimaryButton
            ]),
            row(title: localized("row.arc.title"), detail: localized("row.arc.detail"), status: arcStatus, buttons: [
                arcPrimaryButton
            ]),
            row(title: localized("row.aside.title"), detail: localized("row.aside.detail"), status: asideStatus, buttons: [
                asidePrimaryButton
            ]),
            row(title: localized("row.raycast.title"), detail: localized("row.raycast.detail"), status: raycastStatus, buttons: [
                raycastPrimaryButton
            ]),
            sectionHeader(localized("section.developer")),
            row(title: localized("row.codex.title"), detail: localized("row.codex.detail"), status: codexStatus, buttons: [
                codexPrimaryButton
            ]),
            row(title: localized("row.claude.title"), detail: localized("row.claude.detail"), status: claudeStatus, buttons: [
                claudePrimaryButton
            ]),
            row(title: localized("row.devin.title"), detail: localized("row.devin.detail"), status: devinStatus, buttons: [
                devinPrimaryButton
            ]),
            row(title: localized("row.docker.title"), detail: localized("row.docker.detail"), status: dockerStatus, buttons: [
                dockerPrimaryButton
            ]),
            sectionHeader(localized("section.editor")),
            row(title: localized("row.cursor.title"), detail: localized("row.cursor.detail"), status: cursorStatus, buttons: [
                cursorPrimaryButton
            ]),
            row(title: localized("row.vscode.title"), detail: localized("row.vscode.detail"), status: vscodeStatus, buttons: [
                vscodePrimaryButton
            ]),
            row(title: localized("row.zed.title"), detail: localized("row.zed.detail"), status: zedStatus, buttons: [
                zedPrimaryButton
            ]),
            row(title: localized("row.iterm.title"), detail: localized("row.iterm.detail"), status: itermStatus, buttons: [
                itermPrimaryButton
            ]),
            sectionHeader(localized("section.communication")),
            row(title: localized("row.teams.title"), detail: localized("row.teams.detail"), status: teamsStatus, buttons: [
                teamsPrimaryButton
            ]),
            row(title: localized("row.slack.title"), detail: localized("row.slack.detail"), status: slackStatus, buttons: [
                slackPrimaryButton
            ]),
            sectionHeader(localized("section.utility")),
            row(title: localized("row.linearmouse.title"), detail: localized("row.linearmouse.detail"), status: linearMouseStatus, buttons: [
                linearMousePrimaryButton
            ]),
            row(title: localized("row.amphetamine.title"), detail: localized("row.amphetamine.detail"), status: amphetamineStatus, buttons: [
                amphetaminePrimaryButton
            ]),
        ])
    }

    private func sectionHeader(_ title: String) -> NSView {
        let label = NSTextField(labelWithString: title)
        label.font = NSFont.systemFont(ofSize: 11, weight: .semibold)
        label.textColor = .secondaryLabelColor
        label.alignment = .left
        label.translatesAutoresizingMaskIntoConstraints = false
        label.heightAnchor.constraint(equalToConstant: 20).isActive = true
        return label
    }

    private func runtimeTab() -> NSTabViewItem {
        tab(localized("tab.runtime"), [
            row(title: localized("row.agent.title"), detail: localized("row.agent.detail"), status: agentStatus, buttons: [
                agentPrimaryButton,
                agentRemoveButton
            ])
        ])
    }

    private func tab(_ title: String, _ rows: [NSView]) -> NSTabViewItem {
        let item = NSTabViewItem(identifier: title)
        item.label = title
        let container = NSView()
        let scrollView = NSScrollView()
        scrollView.hasVerticalScroller = true
        scrollView.drawsBackground = false
        scrollView.borderType = .noBorder
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        let document = FlippedView()
        document.translatesAutoresizingMaskIntoConstraints = false
        scrollView.documentView = document
        container.addSubview(scrollView)

        let stack = NSStackView()
        stack.orientation = .vertical
        stack.spacing = 8
        stack.alignment = .leading
        stack.translatesAutoresizingMaskIntoConstraints = false
        document.addSubview(stack)
        for row in rows {
            stack.addArrangedSubview(row)
            row.widthAnchor.constraint(equalTo: stack.widthAnchor).isActive = true
        }
        NSLayoutConstraint.activate([
            scrollView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            scrollView.topAnchor.constraint(equalTo: container.topAnchor),
            scrollView.bottomAnchor.constraint(equalTo: container.bottomAnchor),
            document.leadingAnchor.constraint(equalTo: scrollView.contentView.leadingAnchor),
            document.trailingAnchor.constraint(equalTo: scrollView.contentView.trailingAnchor),
            document.topAnchor.constraint(equalTo: scrollView.contentView.topAnchor),
            document.widthAnchor.constraint(equalTo: scrollView.contentView.widthAnchor),
            stack.leadingAnchor.constraint(equalTo: document.leadingAnchor, constant: 18),
            stack.trailingAnchor.constraint(equalTo: document.trailingAnchor, constant: -18),
            stack.topAnchor.constraint(equalTo: document.topAnchor, constant: 10),
            stack.bottomAnchor.constraint(equalTo: document.bottomAnchor, constant: -10)
        ])
        item.view = container
        return item
    }

    private func row(title: String, detail: String, status: NSTextField, buttons: [NSButton]) -> NSView {
        let box = NSBox()
        box.boxType = .custom
        box.cornerRadius = 8
        box.borderColor = NSColor.separatorColor
        box.borderWidth = 1
        box.fillColor = NSColor.clear
        box.contentViewMargins = NSSize(width: 12, height: 6)
        box.translatesAutoresizingMaskIntoConstraints = false
        box.heightAnchor.constraint(equalToConstant: 52).isActive = true

        let root = NSStackView()
        root.orientation = .horizontal
        root.spacing = 10
        root.alignment = .centerY
        root.translatesAutoresizingMaskIntoConstraints = false

        let text = NSStackView()
        text.orientation = .vertical
        text.spacing = 2
        text.alignment = .leading
        let titleLabel = NSTextField(labelWithString: title)
        titleLabel.font = NSFont.boldSystemFont(ofSize: 13)
        titleLabel.alignment = .left
        let detailLabel = NSTextField(labelWithString: detail)
        detailLabel.textColor = .secondaryLabelColor
        detailLabel.lineBreakMode = .byTruncatingTail
        detailLabel.maximumNumberOfLines = 1
        detailLabel.alignment = .left
        detailLabel.font = NSFont.systemFont(ofSize: 11)
        status.isBezeled = false
        status.isBordered = false
        status.drawsBackground = false
        status.wantsLayer = true
        status.layer?.cornerRadius = 7
        status.layer?.masksToBounds = true
        status.textColor = .secondaryLabelColor
        status.lineBreakMode = .byWordWrapping
        status.maximumNumberOfLines = 1
        status.alignment = .center
        status.font = NSFont.systemFont(ofSize: 11, weight: .medium)
        status.setContentHuggingPriority(.required, for: .horizontal)
        status.setContentCompressionResistancePriority(.required, for: .horizontal)
        status.widthAnchor.constraint(greaterThanOrEqualToConstant: 72).isActive = true
        text.addArrangedSubview(titleLabel)
        text.addArrangedSubview(detailLabel)

        let actions = NSStackView()
        actions.orientation = .horizontal
        actions.spacing = 8
        actions.alignment = .centerY
        actions.distribution = .fillEqually
        for button in buttons {
            actions.addArrangedSubview(button)
        }
        actions.widthAnchor.constraint(equalToConstant: 228).isActive = true

        root.addArrangedSubview(text)
        let flexibleGap = NSView()
        root.addArrangedSubview(flexibleGap)
        root.addArrangedSubview(status)
        root.addArrangedSubview(actions)
        text.setContentHuggingPriority(.defaultLow, for: .horizontal)
        flexibleGap.setContentHuggingPriority(.defaultLow, for: .horizontal)
        actions.setContentHuggingPriority(.required, for: .horizontal)
        actions.setContentCompressionResistancePriority(.required, for: .horizontal)
        box.contentView?.addSubview(root)
        NSLayoutConstraint.activate([
            root.leadingAnchor.constraint(equalTo: box.contentView!.leadingAnchor),
            root.trailingAnchor.constraint(equalTo: box.contentView!.trailingAnchor),
            root.topAnchor.constraint(equalTo: box.contentView!.topAnchor),
            root.bottomAnchor.constraint(equalTo: box.contentView!.bottomAnchor)
        ])
        statusPills.append(status)
        statusRows.append((status, box))
        return box
    }

    private func styleStatusPill(_ status: NSTextField) {
        status.isBezeled = false
        status.isBordered = false
        status.drawsBackground = false
        status.wantsLayer = true
        status.layer?.cornerRadius = 7
        status.layer?.masksToBounds = true
        status.textColor = .secondaryLabelColor
        status.lineBreakMode = .byWordWrapping
        status.maximumNumberOfLines = 1
        status.alignment = .center
        status.font = NSFont.systemFont(ofSize: 11, weight: .medium)
        status.setContentHuggingPriority(.required, for: .horizontal)
        status.setContentCompressionResistancePriority(.required, for: .horizontal)
        status.widthAnchor.constraint(greaterThanOrEqualToConstant: 72).isActive = true
    }

    private func button(_ title: String, _ action: Selector) -> NSButton {
        let button = NSButton(title: title, target: self, action: action)
        button.bezelStyle = .rounded
        return button
    }

    @objc private func refreshPressed() { refresh() }

    private func refresh() {
        spellingPreferenceState = booleanPreferenceState("-g", "NSAutomaticSpellingCorrectionEnabled")
        periodPreferenceState = booleanPreferenceState("-g", "NSAutomaticPeriodSubstitutionEnabled")
        inlinePreferenceState = booleanPreferenceState("-g", "NSAutomaticInlinePredictionEnabled")
        clickDesktopPreferenceState = booleanPreferenceState("com.apple.WindowManager", "EnableStandardClickToShowDesktop")
        dockAutohidePreferenceState = booleanPreferenceState("com.apple.dock", "autohide")
        let brewInstalled = brewPath() != nil

        spellingStatus.stringValue = spellingPreferenceState == .disabled ? localized("status.off") : localized("status.on")
        spellingPrimaryButton.title = spellingPreferenceState == .disabled ? localized("button.reset") : localized("button.disable")
        spellingPrimaryButton.isEnabled = true
        periodStatus.stringValue = periodPreferenceState == .disabled ? localized("status.off") : localized("status.on")
        periodPrimaryButton.title = periodPreferenceState == .disabled ? localized("button.reset") : localized("button.disable")
        periodPrimaryButton.isEnabled = true
        inlineStatus.stringValue = inlinePreferenceState == .disabled ? localized("status.off") : localized("status.on")
        inlinePrimaryButton.title = inlinePreferenceState == .disabled ? localized("button.reset") : localized("button.disable")
        inlinePrimaryButton.isEnabled = true
        clickDesktopStatus.stringValue = clickDesktopPreferenceState == .disabled ? localized("status.applied") : localized("status.default")
        clickDesktopPrimaryButton.title = clickDesktopPreferenceState == .disabled ? localized("button.reset") : localized("button.apply")
        clickDesktopPrimaryButton.isEnabled = true
        dockAutohideStatus.stringValue = dockAutohidePreferenceState == .enabled ? localized("status.on") : localized("status.off")
        dockAutohidePrimaryButton.title = dockAutohidePreferenceState == .enabled ? localized("button.disable") : localized("button.enable")
        dockAutohidePrimaryButton.isEnabled = true
        if blackWallpaperApplied() {
            wallpaperStatus.stringValue = localized("status.applied")
        } else if currentDesktopPictures().isEmpty {
            wallpaperStatus.stringValue = localized("status.systemColor")
        } else if FileManager.default.fileExists(atPath: blackWallpaperPath()) {
            wallpaperStatus.stringValue = localized("status.notApplied")
        } else {
            wallpaperStatus.stringValue = localized("status.missing")
        }
        wallpaperPrimaryButton.title = localized("button.apply")
        wallpaperPrimaryButton.isEnabled = true
        refreshDockState()
        setHomebrewState(installed: brewInstalled)
        setInstallableAppState(status: chromeStatus, button: chromePrimaryButton, appName: "Google Chrome", brewInstalled: brewInstalled)
        setInstallableAppState(status: arcStatus, button: arcPrimaryButton, appName: "Arc", brewInstalled: brewInstalled)
        setInstallableAppState(status: asideStatus, button: asidePrimaryButton, appName: "Aside", brewInstalled: brewInstalled)
        setInstallableAppState(status: raycastStatus, button: raycastPrimaryButton, appName: "Raycast", brewInstalled: brewInstalled)
        setInstallableAppState(status: codexStatus, button: codexPrimaryButton, appName: "Codex", brewInstalled: brewInstalled)
        setInstallableAppState(status: claudeStatus, button: claudePrimaryButton, appName: "Claude", brewInstalled: brewInstalled)
        setInstallableAppState(status: cursorStatus, button: cursorPrimaryButton, appName: "Cursor", brewInstalled: brewInstalled)
        setInstallableAppState(status: vscodeStatus, button: vscodePrimaryButton, appName: "Visual Studio Code", brewInstalled: brewInstalled)
        setInstallableAppState(status: zedStatus, button: zedPrimaryButton, appName: "Zed", brewInstalled: brewInstalled)
        setDirectDownloadState(status: devinStatus, button: devinPrimaryButton, appName: "Devin")
        if !appExists("Devin") {
            devinPrimaryButton.title = effectiveLanguage() == .korean ? "다운로드" : "Download"
        }
        setInstallableAppState(status: dockerStatus, button: dockerPrimaryButton, appName: "Docker", brewInstalled: brewInstalled)
        setInstallableAppState(status: itermStatus, button: itermPrimaryButton, appName: "iTerm", brewInstalled: brewInstalled)
        setInstallableAppState(status: teamsStatus, button: teamsPrimaryButton, appName: "Microsoft Teams", brewInstalled: brewInstalled)
        setInstallableAppState(status: slackStatus, button: slackPrimaryButton, appName: "Slack", brewInstalled: brewInstalled)
        setKarabinerState(brewInstalled: brewInstalled)
        setGureumState(brewInstalled: brewInstalled)
        setGureumOptionState()
        setInputSourceSettingsState()
        setInputShortcutSettingsState()
        setKeyRepeatState()
        setPressAndHoldState()
        setFunctionKeysState()
        setGlobeKeyState()
        setInstallableAppState(status: linearMouseStatus, button: linearMousePrimaryButton, appName: "LinearMouse", brewInstalled: brewInstalled)
        setAppStoreState(status: amphetamineStatus, button: amphetaminePrimaryButton, appName: "Amphetamine")
        refreshAgentState()
        updateRowStyles()
        statusLabel.stringValue = localized("status.refreshed")
        window?.contentView?.layoutSubtreeIfNeeded()
        window?.displayIfNeeded()
    }

    @objc private func toggleSpelling() {
        applyBooleanPreference(
            domain: "-g",
            key: "NSAutomaticSpellingCorrectionEnabled",
            value: spellingPreferenceState == .disabled ? nil : false,
            status: spellingStatus,
            button: spellingPrimaryButton
        )
    }
    @objc private func togglePeriod() {
        applyBooleanPreference(
            domain: "-g",
            key: "NSAutomaticPeriodSubstitutionEnabled",
            value: periodPreferenceState == .disabled ? nil : false,
            status: periodStatus,
            button: periodPrimaryButton
        )
    }
    @objc private func toggleInline() {
        applyBooleanPreference(
            domain: "-g",
            key: "NSAutomaticInlinePredictionEnabled",
            value: inlinePreferenceState == .disabled ? nil : false,
            status: inlineStatus,
            button: inlinePrimaryButton
        )
    }

    @objc private func openKeyboardSettings() {
        NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.Keyboard-Settings.extension")!)
    }

    @objc private func toggleClickDesktop() {
        applyBooleanPreference(
            domain: "com.apple.WindowManager",
            key: "EnableStandardClickToShowDesktop",
            value: clickDesktopPreferenceState == .disabled ? nil : false,
            status: clickDesktopStatus,
            button: clickDesktopPrimaryButton
        )
    }

    @objc private func applyWallpaper() {
        let path = blackWallpaperPath()
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
        process.arguments = ["-e", "tell application \"System Events\" to tell every desktop to set picture to POSIX file \"\(path)\""]
        try? process.run()
        process.waitUntilExit()
        refresh()
    }

    @objc private func openWallpaperFolder() {
        NSWorkspace.shared.open(URL(fileURLWithPath: NSHomeDirectory() + "/Pictures/Wallpapers"))
    }

    @objc private func applyDockSelection() {
        let output = runScript(["dock-apply"], extraEnv: ["MAC_BOOTSTRAP_DOCK_KEEP_LABELS": selectedDockAliases().joined(separator: "\n")])
        statusLabel.stringValue = output.contains("blocked:") ? localized("status.dockBlocked") : localized("status.dockApplied")
        refreshDockState()
    }

    @objc private func toggleDockAutohide() {
        applyBooleanPreference(
            domain: "com.apple.dock",
            key: "autohide",
            value: dockAutohidePreferenceState != .enabled,
            status: dockAutohideStatus,
            button: dockAutohidePrimaryButton,
            restartDock: true
        )
    }
    @objc private func openHomebrew() { openURL("https://brew.sh/") }
    @objc private func openGureum() { openURL("https://gureum.io/") }
    @objc private func openKarabiner() { openURL("https://karabiner-elements.pqrs.org/") }
    @objc private func openLinearMouse() { openURL("https://linearmouse.app/") }
    @objc private func openRaycast() { openURL("https://www.raycast.com/download") }
    @objc private func openClaude() { openURL("https://claude.ai/download") }
    @objc private func openTeams() { openURL("https://www.microsoft.com/microsoft-teams/download-app") }
    @objc private func openSlack() { openURL("https://slack.com/downloads/mac") }
    @objc private func openAmphetamine() { openURL("https://apps.apple.com/app/amphetamine/id937984704") }
    @objc private func installHomebrew() {
        runInstallInTerminal(#"/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)""#)
    }
    @objc private func primaryGureum() {
        if inputMethodStatus("Gureum") != "Installed" {
            installGureum()
        } else if !gureumInputSourceRegistered() {
            confirmLogoutForGureum()
        } else {
            openKeyboardSettings()
        }
    }
    @objc private func primaryKarabiner() {
        if appStatus("Karabiner-Elements") != "Installed" {
            installKarabiner()
        } else if !karabinerDriverReady() {
            openApp("Karabiner-Elements")
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
                self?.refresh()
            }
        } else if karabinerMappingApplied() {
            resetKarabinerSettings()
        } else {
            applyKarabinerSettings()
        }
    }
    @objc private func primaryLinearMouse() { appStatus("LinearMouse") == "Installed" ? openApp("LinearMouse") : installLinearMouse() }
    @objc private func primaryChrome() { appStatus("Google Chrome") == "Installed" ? openApp("Google Chrome") : installChrome() }
    @objc private func primaryArc() { appStatus("Arc") == "Installed" ? openApp("Arc") : installArc() }
    @objc private func primaryAside() { appStatus("Aside") == "Installed" ? openApp("Aside") : installAside() }
    @objc private func primaryRaycast() { appStatus("Raycast") == "Installed" ? openApp("Raycast") : installRaycast() }
    @objc private func primaryCodex() { appStatus("Codex") == "Installed" ? openApp("Codex") : openURL("https://openai.com/codex/") }
    @objc private func primaryClaude() { appStatus("Claude") == "Installed" ? openApp("Claude") : installClaude() }
    @objc private func primaryCursor() { appStatus("Cursor") == "Installed" ? openApp("Cursor") : installCursor() }
    @objc private func primaryVSCode() { appStatus("Visual Studio Code") == "Installed" ? openApp("Visual Studio Code") : installVSCode() }
    @objc private func primaryZed() { appStatus("Zed") == "Installed" ? openApp("Zed") : installZed() }
    @objc private func primaryDevin() { appStatus("Devin") == "Installed" ? openApp("Devin") : openURL("https://devin.ai/download/") }
    @objc private func primaryDocker() { appStatus("Docker") == "Installed" ? openApp("Docker") : installDocker() }
    @objc private func primaryITerm() { appStatus("iTerm") == "Installed" ? openApp("iTerm") : installITerm() }
    @objc private func primaryTeams() { appStatus("Microsoft Teams") == "Installed" ? openApp("Microsoft Teams") : installTeams() }
    @objc private func primarySlack() { appStatus("Slack") == "Installed" ? openApp("Slack") : installSlack() }
    @objc private func primaryAmphetamine() { appStatus("Amphetamine") == "Installed" ? openApp("Amphetamine") : openAmphetamine() }
    @objc private func installGureum() {
        installBrewCask(
            "gureumkim",
            afterInstallCommand: """
            /usr/bin/osascript -e 'display dialog "\(terminalLogoutPrompt())" buttons {"\(localized("alert.logout.later"))", "\(localized("alert.logout.now"))"} default button "\(localized("alert.logout.now"))" cancel button "\(localized("alert.logout.later"))"' >/tmp/mac-bootstrap-gureum-logout-choice 2>/dev/null && /usr/bin/osascript -e 'tell application "System Events" to log out'
            """
        )
    }
    @objc private func installKarabiner() { installBrewCask("karabiner-elements") }
    @objc private func installLinearMouse() { installBrewCask("linearmouse") }
    @objc private func installChrome() { installBrewCask("google-chrome") }
    @objc private func installArc() { installBrewCask("arc") }
    @objc private func installAside() { installBrewCask("aside") }
    @objc private func installRaycast() { installBrewCask("raycast") }
    @objc private func installClaude() { installBrewCask("claude") }
    @objc private func installCursor() { installBrewCask("cursor") }
    @objc private func installVSCode() { installBrewCask("visual-studio-code") }
    @objc private func installZed() { installBrewCask("zed") }
    @objc private func installDocker() { installBrewCask("docker-desktop") }
    @objc private func installITerm() { installBrewCask("iterm2") }
    @objc private func installTeams() { installBrewCask("microsoft-teams") }
    @objc private func installSlack() { installBrewCask("slack") }
    @objc private func applyInputSourceSettings() {
        if inputSourcesApplied() {
            resetInputSourceSettings()
            return
        }
        if inputMethodStatus("Gureum") == "Installed" && !gureumInputSourceRegistered() {
            confirmLogoutForGureum()
            return
        }
        let output = runScript(["apply-input-sources"])
        if output.contains("blocked:") {
            statusLabel.stringValue = output.components(separatedBy: .newlines).last ?? localized("status.dockBlocked")
        } else {
            statusLabel.stringValue = localized("status.settingsApplied")
        }
        refresh()
    }
    private func resetInputSourceSettings() {
        let output = runScript(["reset-input-sources"])
        refresh()
        statusLabel.stringValue = output.contains("blocked:") ? output.components(separatedBy: .newlines).last ?? localized("status.dockBlocked") : localized("status.settingsApplied")
        window?.displayIfNeeded()
    }
    @objc private func applyGureumOptionSettings() {
        let targetEnabled = !gureumOptionSpecialCharactersApplied()
        setGureumOptionSpecialCharacters(targetEnabled)
        statusLabel.stringValue = gureumOptionSpecialCharactersApplied() == targetEnabled
            ? localized("status.settingsApplied")
            : localized("status.failed")
        refresh()
    }
    @objc private func applyInputShortcutSettings() {
        inputSourceShortcutApplied() ? resetInputShortcutSettings() : applyInputShortcut()
    }
    @objc private func applyKeyRepeatSettings() {
        keyRepeatApplied() ? resetKeyRepeatSettings() : applyKeyRepeat()
    }
    @objc private func applyPressAndHoldSettings() {
        pressAndHoldDisabled() ? resetPressAndHoldSettings() : disablePressAndHold()
    }
    @objc private func applyFunctionKeysSettings() {
        functionKeysApplied() ? resetFunctionKeysSettings() : applyFunctionKeys()
    }
    @objc private func applyGlobeKeySettings() {
        globeKeyApplied() ? resetGlobeKeySettings() : applyGlobeKey()
    }
    private func openKeyboardShortcuts() {
        openKeyboardSettings()
        statusLabel.stringValue = localized("status.manualCheck")
    }
    private func applyFunctionKeys() {
        let output = runScript(["apply-function-keys"])
        statusLabel.stringValue = output.contains("blocked:") ? output.components(separatedBy: .newlines).last ?? localized("status.dockBlocked") : localized("status.settingsApplied")
        refresh()
    }
    private func applyInputShortcut() {
        let output = runScript(["apply-input-shortcuts"])
        statusLabel.stringValue = output.contains("blocked:") ? output.components(separatedBy: .newlines).last ?? localized("status.dockBlocked") : localized("status.settingsApplied")
        refresh()
    }
    private func resetInputShortcutSettings() {
        let output = runScript(["reset-input-shortcuts"])
        statusLabel.stringValue = output.contains("blocked:") ? output.components(separatedBy: .newlines).last ?? localized("status.dockBlocked") : localized("status.settingsApplied")
        refresh()
    }
    private func applyKeyRepeat() {
        let output = runScript(["apply-key-repeat"])
        refresh()
        statusLabel.stringValue = output.contains("blocked:") ? output.components(separatedBy: .newlines).last ?? localized("status.dockBlocked") : localized("status.settingsApplied")
        window?.displayIfNeeded()
    }
    private func resetKeyRepeatSettings() {
        runDefaults(["delete", "NSGlobalDomain", "KeyRepeat"])
        runDefaults(["delete", "NSGlobalDomain", "InitialKeyRepeat"])
        refresh()
    }
    private func disablePressAndHold() {
        let output = runScript(["apply-press-and-hold"])
        refresh()
        statusLabel.stringValue = output.contains("blocked:") ? output.components(separatedBy: .newlines).last ?? localized("status.dockBlocked") : localized("status.settingsApplied")
        window?.displayIfNeeded()
    }
    private func resetPressAndHoldSettings() {
        runDefaults(["delete", "NSGlobalDomain", "ApplePressAndHoldEnabled"])
        refresh()
    }
    private func resetFunctionKeysSettings() {
        runDefaults(["delete", "NSGlobalDomain", "com.apple.keyboard.fnState"])
        refresh()
    }
    private func applyGlobeKey() {
        let output = runScript(["apply-globe-key"])
        statusLabel.stringValue = output.contains("blocked:") ? output.components(separatedBy: .newlines).last ?? localized("status.dockBlocked") : localized("status.settingsApplied")
        refresh()
    }
    private func resetGlobeKeySettings() {
        runDefaults(["delete", "com.apple.HIToolbox", "AppleFnUsageType"])
        refresh()
    }
    @objc private func applyGureumSettings() { confirmLogoutForGureum() }
    @objc private func applyKarabinerSettings() {
        let output = runScript(["apply-karabiner"])
        statusLabel.stringValue = output.contains("blocked:") ? output.components(separatedBy: .newlines).last ?? localized("status.dockBlocked") : localized("status.settingsApplied")
        refresh()
    }
    private func resetKarabinerSettings() {
        let output = runScript(["reset-karabiner"])
        statusLabel.stringValue = output.contains("blocked:") ? output.components(separatedBy: .newlines).last ?? localized("status.dockBlocked") : localized("status.settingsApplied")
        refresh()
    }
    @objc private func openDockSettings() {
        NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.Desktop-Settings.extension")!)
    }
    @objc private func openAccessibilitySettings() {
        NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!)
    }
    @objc private func openProjectFolder() { NSWorkspace.shared.open(URL(fileURLWithPath: projectRoot())) }
    @objc private func primaryAgent() {
        if appExists("MacBootstrapAgent") {
            openAgent()
        } else {
            installAgent()
        }
    }

    private func installAgent() {
        statusLabel.stringValue = localized("status.agentInstalling")
        agentPrimaryButton.isEnabled = false
        agentRemoveButton.isEnabled = false
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self else { return }
            let output = self.runScript(["install-agent"])
            DispatchQueue.main.async {
                self.statusLabel.stringValue = output.contains("INSTALL_AGENT_OK")
                    ? localized("status.agentInstalled")
                    : localized("status.agentFailed")
                self.refreshAgentState()
                self.updateRowStyles()
            }
        }
    }

    private func openAgent() {
        let opened = NSWorkspace.shared.open(URL(fileURLWithPath: "/Applications/MacBootstrapAgent.app"))
        statusLabel.stringValue = opened ? localized("status.opened") : localized("status.failed")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.refreshAgentState()
            self?.updateRowStyles()
        }
    }
    @objc private func removeAgent() {
        _ = runScript(["uninstall-agent"])
        refreshAgentState()
        updateRowStyles()
    }

    @objc private func removeSetupApp() {
        let alert = NSAlert()
        alert.messageText = effectiveLanguage() == .korean ? "MacBootstrapSetup.app을 제거할까요?" : "Remove MacBootstrapSetup.app?"
        alert.informativeText = effectiveLanguage() == .korean
            ? "일회성 Setup 앱만 제거합니다. MacBootstrapAgent.app은 유지됩니다."
            : "This removes only the one-time setup app. MacBootstrapAgent.app remains installed."
        alert.addButton(withTitle: localized("button.remove"))
        alert.addButton(withTitle: effectiveLanguage() == .korean ? "취소" : "Cancel")
        guard alert.runModal() == .alertFirstButtonReturn else { return }
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/sh")
        process.arguments = ["-c", "sleep 1; rm -rf /Applications/MacBootstrapSetup.app"]
        try? process.run()
        NSApplication.shared.terminate(nil)
    }

    private func terminalLogoutPrompt() -> String {
        localized("alert.logout.gureum")
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
    }

    private func confirmLogoutForGureum() {
        let alert = NSAlert()
        alert.messageText = localized("alert.logout.title")
        alert.informativeText = localized("alert.logout.gureum")
        alert.addButton(withTitle: localized("alert.logout.now"))
        alert.addButton(withTitle: localized("alert.logout.later"))
        guard alert.runModal() == .alertFirstButtonReturn else {
            openKeyboardSettings()
            return
        }
        performLogout()
    }

    private func performLogout() {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
        process.arguments = ["-e", "tell application \"System Events\" to log out"]
        try? process.run()
    }

    private func applyBooleanPreference(
        domain: String,
        key: String,
        value: Bool?,
        status: NSTextField,
        button: NSButton,
        restartDock: Bool = false
    ) {
        status.stringValue = localized("status.applying")
        button.isEnabled = false
        updateRowStyles()
        window?.displayIfNeeded()

        let commandSucceeded: Bool
        if let value {
            commandSucceeded = runDefaults(["write", domain, key, "-bool", value ? "true" : "false"])
        } else {
            commandSucceeded = runDefaults(["delete", domain, key])
        }

        let expectedState: BooleanPreferenceState = value.map { $0 ? .enabled : .disabled } ?? .inherited
        let valueVerified = booleanPreferenceState(domain, key) == expectedState
        if restartDock && commandSucceeded && valueVerified {
            _ = runProcess("/usr/bin/killall", ["Dock"])
        }

        refresh()
        statusLabel.stringValue = commandSucceeded && valueVerified
            ? localized("status.settingsApplied")
            : localized("status.failed")
        window?.displayIfNeeded()
    }

    @discardableResult
    private func runDefaults(_ args: [String]) -> Bool {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/defaults")
        process.arguments = args
        process.standardOutput = Pipe()
        process.standardError = Pipe()
        do {
            try process.run()
            process.waitUntilExit()
            return process.terminationStatus == 0
        } catch {
            return false
        }
    }

    @discardableResult
    private func runProcess(_ executable: String, _ arguments: [String]) -> Bool {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: executable)
        process.arguments = arguments
        process.standardOutput = Pipe()
        process.standardError = Pipe()
        do {
            try process.run()
            process.waitUntilExit()
            return process.terminationStatus == 0
        } catch {
            return false
        }
    }

    private func booleanPreferenceState(_ domain: String, _ key: String) -> BooleanPreferenceState {
        switch defaultValue(domain, key).lowercased() {
        case "1", "true", "yes":
            return .enabled
        case "0", "false", "no":
            return .disabled
        default:
            return .inherited
        }
    }

    private func defaultValue(_ domain: String, _ key: String) -> String {
        let process = Process()
        let pipe = Pipe()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/defaults")
        process.arguments = ["read", domain, key]
        process.standardOutput = pipe
        process.standardError = Pipe()
        do {
            try process.run()
            process.waitUntilExit()
            let value = String(data: pipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8)?
                .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            return value.isEmpty ? "<unset>" : value
        } catch {
            return "<unset>"
        }
    }

    private func appStatus(_ name: String) -> String {
        FileManager.default.fileExists(atPath: "/Applications/\(name).app") ? "Installed" : "Not installed"
    }

    private func appExists(_ name: String) -> Bool {
        FileManager.default.fileExists(atPath: "/Applications/\(name).app")
    }

    private func blackWallpaperPath() -> String {
        "/System/Library/Desktop Pictures/Solid Colors/Black.png"
    }

    private func blackWallpaperApplied() -> Bool {
        let expected = URL(fileURLWithPath: blackWallpaperPath()).standardizedFileURL.path
        guard FileManager.default.fileExists(atPath: blackWallpaperPath()) else { return false }
        return currentDesktopPictures().contains(expected)
    }

    private func currentDesktopPictures() -> Set<String> {
        let script = "tell application \"System Events\" to tell every desktop to get picture"
        let output = processOutput("/usr/bin/osascript", ["-e", script])
        let paths = output
            .components(separatedBy: CharacterSet(charactersIn: ",\n"))
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty && $0 != "missing value" }
            .map { URL(fileURLWithPath: $0).standardizedFileURL.path }
        return Set(paths)
    }

    private func setHomebrewState(installed: Bool) {
        homebrewStatus.stringValue = installed ? localized("status.installed") : localized("status.missing")
        homebrewPrimaryButton.title = installed ? localized("button.done") : localized("button.install")
        homebrewPrimaryButton.isEnabled = !installed
    }

    private func setInstallableAppState(status: NSTextField, button: NSButton, appName: String, brewInstalled: Bool) {
        if appExists(appName) {
            status.stringValue = localized("status.installed")
            button.title = localized("button.open")
            button.isEnabled = true
        } else if brewInstalled {
            status.stringValue = localized("status.missing")
            button.title = localized("button.install")
            button.isEnabled = true
        } else {
            status.stringValue = localized("status.homebrewFirst")
            button.title = localized("button.install")
            button.isEnabled = false
        }
    }

    private func setInputMethodState(status: NSTextField, button: NSButton, name: String, brewInstalled: Bool) {
        if inputMethodStatus(name) == "Installed" {
            status.stringValue = localized("status.installed")
            button.title = localized("button.applySettings")
            button.isEnabled = true
        } else if brewInstalled {
            status.stringValue = localized("status.missing")
            button.title = localized("button.install")
            button.isEnabled = true
        } else {
            status.stringValue = localized("status.homebrewFirst")
            button.title = localized("button.install")
            button.isEnabled = false
        }
    }

    private func setGureumState(brewInstalled: Bool) {
        if inputMethodStatus("Gureum") == "Installed" && gureumInputSourceRegistered() {
            gureumStatus.stringValue = localized("status.registered")
            gureumPrimaryButton.title = localized("button.open")
            gureumPrimaryButton.isEnabled = true
        } else if inputMethodStatus("Gureum") == "Installed" {
            gureumStatus.stringValue = localized("status.needsLogout")
            gureumPrimaryButton.title = localized("button.logout")
            gureumPrimaryButton.isEnabled = true
        } else if brewInstalled {
            gureumStatus.stringValue = localized("status.missing")
            gureumPrimaryButton.title = localized("button.install")
            gureumPrimaryButton.isEnabled = true
        } else {
            gureumStatus.stringValue = localized("status.homebrewFirst")
            gureumPrimaryButton.title = localized("button.install")
            gureumPrimaryButton.isEnabled = false
        }
    }

    private func setGureumOptionState() {
        if inputMethodStatus("Gureum") != "Installed" {
            gureumOptionStatus.stringValue = localized("status.gureumFirst")
            gureumOptionPrimaryButton.title = localized("button.enable")
            gureumOptionPrimaryButton.isEnabled = false
        } else if gureumOptionSpecialCharactersApplied() {
            gureumOptionStatus.stringValue = localized("status.on")
            gureumOptionPrimaryButton.title = localized("button.disable")
            gureumOptionPrimaryButton.isEnabled = true
        } else {
            gureumOptionStatus.stringValue = localized("status.off")
            gureumOptionPrimaryButton.title = localized("button.enable")
            gureumOptionPrimaryButton.isEnabled = true
        }
    }

    private func setInputSourceSettingsState() {
        if inputMethodStatus("Gureum") != "Installed" {
            inputSourceStatus.stringValue = localized("status.gureumFirst")
            inputSourcePrimaryButton.title = localized("button.applySettings")
            inputSourcePrimaryButton.isEnabled = false
        } else if !gureumInputSourceRegistered() {
            inputSourceStatus.stringValue = localized("status.needsLogout")
            inputSourcePrimaryButton.title = localized("button.logout")
            inputSourcePrimaryButton.isEnabled = true
        } else if inputSourcesApplied() {
            inputSourceStatus.stringValue = localized("status.applied")
            inputSourcePrimaryButton.title = localized("button.reset")
            inputSourcePrimaryButton.isEnabled = true
        } else if gureumInputApplied() {
            inputSourceStatus.stringValue = localized("status.partiallyApplied")
            inputSourcePrimaryButton.title = localized("button.applySettings")
            inputSourcePrimaryButton.isEnabled = true
        } else {
            inputSourceStatus.stringValue = localized("status.notApplied")
            inputSourcePrimaryButton.title = localized("button.applySettings")
            inputSourcePrimaryButton.isEnabled = true
        }
    }

    private func setInputShortcutSettingsState() {
        if inputSourceShortcutApplied() {
            inputShortcutStatus.stringValue = localized("status.applied")
            inputShortcutPrimaryButton.title = localized("button.reset")
        } else if inputSourceShortcutPartiallyApplied() {
            inputShortcutStatus.stringValue = localized("status.partiallyApplied")
            inputShortcutPrimaryButton.title = localized("button.applySettings")
        } else {
            inputShortcutStatus.stringValue = localized("status.notApplied")
            inputShortcutPrimaryButton.title = localized("button.applySettings")
        }
        inputShortcutPrimaryButton.isEnabled = true
    }

    private func setKeyRepeatState() {
        keyRepeatStatus.stringValue = keyRepeatApplied() ? localized("status.applied") : localized("status.notApplied")
        keyRepeatPrimaryButton.title = keyRepeatApplied() ? localized("button.reset") : localized("button.apply")
        keyRepeatPrimaryButton.isEnabled = true
    }

    private func setPressAndHoldState() {
        if pressAndHoldDisabled() {
            pressAndHoldStatus.stringValue = localized("status.off")
            pressAndHoldPrimaryButton.title = localized("button.reset")
        } else {
            pressAndHoldStatus.stringValue = localized("status.on")
            pressAndHoldPrimaryButton.title = localized("button.disable")
        }
        pressAndHoldPrimaryButton.isEnabled = true
    }

    private func setFunctionKeysState() {
        functionKeysStatus.stringValue = functionKeysApplied() ? localized("status.applied") : localized("status.notApplied")
        functionKeysPrimaryButton.title = functionKeysApplied() ? localized("button.reset") : localized("button.apply")
        functionKeysPrimaryButton.isEnabled = true
    }

    private func setGlobeKeyState() {
        globeKeyStatus.stringValue = globeKeyApplied() ? localized("status.applied") : localized("status.notApplied")
        globeKeyPrimaryButton.title = globeKeyApplied() ? localized("button.reset") : localized("button.apply")
        globeKeyPrimaryButton.isEnabled = true
    }

    private func setKarabinerState(brewInstalled: Bool) {
        if appExists("Karabiner-Elements") {
            if !karabinerDriverReady() {
                karabinerStatus.stringValue = localized("status.needsPermission")
                karabinerPrimaryButton.title = localized("button.open")
            } else {
                karabinerStatus.stringValue = karabinerMappingApplied() ? localized("status.applied") : localized("status.installed")
                karabinerPrimaryButton.title = karabinerMappingApplied() ? localized("button.reset") : localized("button.applySettings")
            }
            karabinerPrimaryButton.isEnabled = true
        } else if brewInstalled {
            karabinerStatus.stringValue = localized("status.missing")
            karabinerPrimaryButton.title = localized("button.install")
            karabinerPrimaryButton.isEnabled = true
        } else {
            karabinerStatus.stringValue = localized("status.homebrewFirst")
            karabinerPrimaryButton.title = localized("button.install")
            karabinerPrimaryButton.isEnabled = false
        }
    }

    private func setAppStoreState(status: NSTextField, button: NSButton, appName: String) {
        if appExists(appName) {
            status.stringValue = localized("status.installed")
            button.title = localized("button.open")
        } else {
            status.stringValue = localized("status.appstore")
            button.title = localized("button.appstore")
        }
        button.isEnabled = true
    }

    private func setDirectDownloadState(status: NSTextField, button: NSButton, appName: String) {
        if appExists(appName) {
            status.stringValue = localized("status.installed")
            button.title = localized("button.open")
        } else {
            status.stringValue = localized("status.missing")
            button.title = localized("button.install")
        }
        button.isEnabled = true
    }

    private func updateRowStyles() {
        for pill in statusPills {
            let palette = rowPalette(for: rowVisualState(for: pill))
            pill.layer?.backgroundColor = palette.fill.cgColor
            pill.textColor = palette.text
        }
        for row in statusRows {
            let palette = rowPalette(for: rowVisualState(for: row.status))
            row.box.borderColor = palette.border
        }
    }

    private func rowVisualState(for statusField: NSTextField) -> RowVisualState {
        let status = statusField.stringValue

        if status == localized("status.applying") {
            return .info
        }
        if status == localized("status.failed") {
            return .attention
        }

        if statusField === dockAutohideStatus {
            return dockAutohidePreferenceState == .enabled ? .success : .neutral
        }
        if statusField === spellingStatus {
            return spellingPreferenceState == .disabled ? .success : .neutral
        }
        if statusField === periodStatus {
            return periodPreferenceState == .disabled ? .success : .neutral
        }
        if statusField === inlineStatus {
            return inlinePreferenceState == .disabled ? .success : .neutral
        }
        if statusField === clickDesktopStatus {
            return clickDesktopPreferenceState == .disabled ? .success : .neutral
        }
        if statusField === gureumOptionStatus,
           status == localized("status.on") || status == localized("status.off") {
            return status == localized("status.on") ? .success : .neutral
        }
        if statusField === pressAndHoldStatus,
           status == localized("status.on") || status == localized("status.off") {
            return status == localized("status.off") ? .success : .neutral
        }

        switch status {
        case localized("status.installed"),
             localized("status.done"),
             localized("status.running"),
             localized("status.registered"),
             localized("status.applied"),
             localized("status.ready"):
            return .success
        case localized("status.appstore"),
             localized("status.manualCheck"),
             localized("status.systemColor"):
            return .info
        case localized("status.missing"),
             localized("status.homebrewFirst"),
             localized("status.default"),
             localized("status.gureumFirst"),
             localized("status.needsOpen"),
             localized("status.needsPermission"),
             localized("status.needsRelogin"),
             localized("status.needsLogout"),
             localized("status.notApplied"),
             localized("status.partiallyApplied"):
            return .attention
        default:
            return .neutral
        }
    }

    private func rowPalette(for state: RowVisualState) -> (fill: NSColor, text: NSColor, border: NSColor) {
        switch state {
        case .success:
            return (
                NSColor.systemGreen.withAlphaComponent(0.16),
                NSColor.systemGreen,
                NSColor.systemGreen.withAlphaComponent(0.55)
            )
        case .attention:
            return (
                NSColor.systemOrange.withAlphaComponent(0.14),
                NSColor.systemOrange,
                NSColor.systemOrange.withAlphaComponent(0.50)
            )
        case .info:
            return (
                NSColor.systemBlue.withAlphaComponent(0.14),
                NSColor.systemBlue,
                NSColor.systemBlue.withAlphaComponent(0.50)
            )
        case .neutral:
            return (
                NSColor.controlBackgroundColor,
                NSColor.secondaryLabelColor,
                NSColor.separatorColor
            )
        }
    }

    private func setLinkOnlyState(status: NSTextField, button: NSButton, appName: String, label: String) {
        if appExists(appName) {
            status.stringValue = "Installed"
            button.title = "Open"
        } else {
            status.stringValue = "Manual"
            button.title = label
        }
        button.isEnabled = true
    }

    private func refreshDockState() {
        let labels = currentDockLabels()
        var selected = 0
        var present = 0
        for choice in dockChoices {
            guard let checkbox = dockCheckboxes[choice.title] else { continue }
            let isPresent = choice.aliases.contains { labels.contains(normalizedDockLabel($0)) }
            checkbox.state = isPresent ? .on : .off
            if checkbox.state == .on { selected += 1 }
            if isPresent { present += 1 }
        }
        let selectedText = "\(selected) \(localized("dock.selected"))"
        let presentText = "\(present) \(localized("dock.current"))"
        dockStatus.stringValue = "\(selectedText) / \(presentText)"
        dockPrimaryButton.title = localized("dock.apply")
        dockPrimaryButton.isEnabled = true
    }

    private func selectedDockAliases() -> [String] {
        var aliases: [String] = []
        for choice in dockChoices {
            guard dockCheckboxes[choice.title]?.state == .on else { continue }
            aliases.append(contentsOf: choice.aliases)
        }
        return aliases
    }

    private func normalizedDockLabel(_ label: String) -> String {
        label.replacingOccurrences(of: "\u{00a0}", with: " ")
            .components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
            .joined(separator: " ")
            .lowercased()
    }

    private func currentDockLabels() -> Set<String> {
        let url = URL(fileURLWithPath: NSHomeDirectory() + "/Library/Preferences/com.apple.dock.plist")
        guard let data = try? Data(contentsOf: url),
              let plist = try? PropertyListSerialization.propertyList(from: data, options: [], format: nil),
              let dict = plist as? [String: Any],
              let apps = dict["persistent-apps"] as? [[String: Any]] else {
            return []
        }
        var labels = Set<String>()
        for app in apps {
            guard let tileData = app["tile-data"] as? [String: Any],
                  let label = tileData["file-label"] as? String else { continue }
            labels.insert(normalizedDockLabel(label))
        }
        return labels
    }

    private func refreshAgentState() {
        let installed = appExists("MacBootstrapAgent")
        let running = isProcessRunning("MacBootstrapAgent")
        agentPrimaryButton.target = self
        agentPrimaryButton.action = #selector(primaryAgent)
        agentRemoveButton.target = self
        agentRemoveButton.action = #selector(removeAgent)
        if running {
            agentStatus.stringValue = localized("status.running")
            agentPrimaryButton.title = localized("button.open")
            agentRemoveButton.isEnabled = true
            agentRemoveButton.isHidden = false
        } else if installed {
            agentStatus.stringValue = localized("status.installed")
            agentPrimaryButton.title = localized("button.open")
            agentRemoveButton.isEnabled = true
            agentRemoveButton.isHidden = false
        } else {
            agentStatus.stringValue = localized("status.missing")
            agentPrimaryButton.title = localized("button.install")
            agentRemoveButton.isEnabled = false
            agentRemoveButton.isHidden = true
        }
        agentRemoveButton.title = localized("button.remove")
        agentPrimaryButton.isEnabled = true
    }

    private func isProcessRunning(_ name: String) -> Bool {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/pgrep")
        process.arguments = ["-x", name]
        process.standardOutput = Pipe()
        process.standardError = Pipe()
        do {
            try process.run()
            process.waitUntilExit()
            return process.terminationStatus == 0
        } catch {
            return false
        }
    }

    private func refreshAppStatusesOnly() {
        let brewInstalled = brewPath() != nil
        setHomebrewState(installed: brewInstalled)
        setInstallableAppState(status: chromeStatus, button: chromePrimaryButton, appName: "Google Chrome", brewInstalled: brewInstalled)
        setInstallableAppState(status: arcStatus, button: arcPrimaryButton, appName: "Arc", brewInstalled: brewInstalled)
        setInstallableAppState(status: asideStatus, button: asidePrimaryButton, appName: "Aside", brewInstalled: brewInstalled)
        setInstallableAppState(status: raycastStatus, button: raycastPrimaryButton, appName: "Raycast", brewInstalled: brewInstalled)
        setInstallableAppState(status: codexStatus, button: codexPrimaryButton, appName: "Codex", brewInstalled: brewInstalled)
        setInstallableAppState(status: claudeStatus, button: claudePrimaryButton, appName: "Claude", brewInstalled: brewInstalled)
        setInstallableAppState(status: cursorStatus, button: cursorPrimaryButton, appName: "Cursor", brewInstalled: brewInstalled)
        setInstallableAppState(status: vscodeStatus, button: vscodePrimaryButton, appName: "Visual Studio Code", brewInstalled: brewInstalled)
        setInstallableAppState(status: zedStatus, button: zedPrimaryButton, appName: "Zed", brewInstalled: brewInstalled)
        setDirectDownloadState(status: devinStatus, button: devinPrimaryButton, appName: "Devin")
        if !appExists("Devin") {
            devinPrimaryButton.title = effectiveLanguage() == .korean ? "다운로드" : "Download"
        }
        setInstallableAppState(status: dockerStatus, button: dockerPrimaryButton, appName: "Docker", brewInstalled: brewInstalled)
        setInstallableAppState(status: itermStatus, button: itermPrimaryButton, appName: "iTerm", brewInstalled: brewInstalled)
        setInstallableAppState(status: teamsStatus, button: teamsPrimaryButton, appName: "Microsoft Teams", brewInstalled: brewInstalled)
        setInstallableAppState(status: slackStatus, button: slackPrimaryButton, appName: "Slack", brewInstalled: brewInstalled)
        setKarabinerState(brewInstalled: brewInstalled)
        setGureumState(brewInstalled: brewInstalled)
        setGureumOptionState()
        setInputSourceSettingsState()
        setInstallableAppState(status: linearMouseStatus, button: linearMousePrimaryButton, appName: "LinearMouse", brewInstalled: brewInstalled)
        setAppStoreState(status: amphetamineStatus, button: amphetaminePrimaryButton, appName: "Amphetamine")
    }

    private func inputMethodStatus(_ name: String) -> String {
        let paths = [
            "/Library/Input Methods/\(name).app",
            NSHomeDirectory() + "/Library/Input Methods/\(name).app",
            "/Applications/\(name).app"
        ]
        return paths.contains { FileManager.default.fileExists(atPath: $0) } ? "Installed" : "Not installed"
    }

    private func tisStringProperty(_ source: TISInputSource, _ key: CFString) -> String {
        guard let raw = TISGetInputSourceProperty(source, key) else { return "" }
        return Unmanaged<CFString>.fromOpaque(raw).takeUnretainedValue() as String
    }

    private func gureumInputSourceRegistered() -> Bool {
        guard let rawSources = TISCreateInputSourceList(nil, false)?.takeRetainedValue() as? [TISInputSource] else {
            return false
        }
        return rawSources.contains { source in
            tisStringProperty(source, kTISPropertyInputSourceID) == "org.youknowone.inputmethod.Gureum.han2" &&
                tisStringProperty(source, kTISPropertyBundleID) == "org.youknowone.inputmethod.Gureum"
        }
    }

    private func gureumOptionSpecialCharactersApplied() -> Bool {
        gureumOptionKeyBehaviorValue() == "0"
    }

    private func setGureumOptionSpecialCharacters(_ enabled: Bool) {
        let value = enabled ? "0" : "1"
        runDefaults(["write", "org.youknowone.Gureum", "OptionKeyBehavior", "-int", value])
        runDefaults(["write", gureumContainerPreferencesPath(), "OptionKeyBehavior", "-int", value])
        if isProcessRunning("Gureum") {
            runProcess("/usr/bin/killall", ["Gureum"])
        }
    }

    private func gureumOptionKeyBehaviorValue() -> String {
        let containerValue = processOutput("/usr/bin/defaults", ["read", gureumContainerPreferencesPath(), "OptionKeyBehavior"])
            .trimmingCharacters(in: .whitespacesAndNewlines)
        if !containerValue.isEmpty {
            return containerValue
        }
        return defaultValue("org.youknowone.Gureum", "OptionKeyBehavior")
    }

    private func gureumContainerPreferencesPath() -> String {
        "\(NSHomeDirectory())/Library/Containers/org.youknowone.inputmethod.Gureum/Data/Library/Preferences/org.youknowone.Gureum.plist"
    }

    private func gureumInputApplied() -> Bool {
        gureumInputSourceRegistered()
    }

    private func inputSourcesApplied() -> Bool {
        gureumInputApplied() && appleKoreanInputRemoved()
    }

    private func inputSourceShortcutApplied() -> Bool {
        let data = processData("/usr/bin/defaults", ["export", "com.apple.symbolichotkeys", "-"])
        guard let data,
              let plist = try? PropertyListSerialization.propertyList(from: data, options: [], format: nil),
              let dict = plist as? [String: Any],
              let symbolic = dict["AppleSymbolicHotKeys"] as? [String: Any] else {
            return false
        }
        return symbolicHotKeyEnabled(symbolic, "60") == false &&
            symbolicHotKeyEnabled(symbolic, "61") == true &&
            symbolicHotKeyEnabled(symbolic, "64") == false &&
            symbolicHotKeyEnabled(symbolic, "65") == false &&
            symbolicHotKeyIsF18(symbolic, "61")
    }

    private func inputSourceShortcutPartiallyApplied() -> Bool {
        let data = processData("/usr/bin/defaults", ["export", "com.apple.symbolichotkeys", "-"])
        guard let data,
              let plist = try? PropertyListSerialization.propertyList(from: data, options: [], format: nil),
              let dict = plist as? [String: Any],
              let symbolic = dict["AppleSymbolicHotKeys"] as? [String: Any] else {
            return false
        }
        return symbolicHotKeyEnabled(symbolic, "60") == false ||
            symbolicHotKeyEnabled(symbolic, "64") == false ||
            symbolicHotKeyIsF18(symbolic, "61") ||
            symbolicHotKeyIsF18(symbolic, "65")
    }

    private func symbolicHotKeyIsF18(_ symbolic: [String: Any], _ key: String) -> Bool {
        symbolicHotKeyParameters(symbolic, key) == [65535, 79, 0] ||
            symbolicHotKeyParameters(symbolic, key) == [65535, 79, 8388608]
    }

    private func symbolicHotKeyEnabled(_ symbolic: [String: Any], _ key: String) -> Bool? {
        (symbolic[key] as? [String: Any])?["enabled"] as? Bool
    }

    private func symbolicHotKeyParameters(_ symbolic: [String: Any], _ key: String) -> [Int] {
        guard let item = symbolic[key] as? [String: Any],
              let value = item["value"] as? [String: Any],
              let parameters = value["parameters"] as? [Any] else {
            return []
        }
        return parameters.compactMap { $0 as? Int }
    }

    private func capsLockABCSwitchDisabled() -> Bool {
        processOutput("/usr/bin/defaults", ["read", "NSGlobalDomain", "TISRomanSwitchState"])
            .trimmingCharacters(in: .whitespacesAndNewlines) == "0"
    }

    private func keyRepeatApplied() -> Bool {
        let repeatValue = processOutput("/usr/bin/defaults", ["read", "NSGlobalDomain", "KeyRepeat"])
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let delayValue = processOutput("/usr/bin/defaults", ["read", "NSGlobalDomain", "InitialKeyRepeat"])
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return repeatValue == "1" && delayValue == "10"
    }

    private func pressAndHoldDisabled() -> Bool {
        let pressAndHold = processOutput("/usr/bin/defaults", ["read", "NSGlobalDomain", "ApplePressAndHoldEnabled"])
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return pressAndHold == "0" || pressAndHold == "false"
    }

    private func functionKeysApplied() -> Bool {
        processOutput("/usr/bin/defaults", ["read", "NSGlobalDomain", "com.apple.keyboard.fnState"])
            .trimmingCharacters(in: .whitespacesAndNewlines) == "1"
    }

    private func globeKeyApplied() -> Bool {
        processOutput("/usr/bin/defaults", ["read", "com.apple.HIToolbox", "AppleFnUsageType"])
            .trimmingCharacters(in: .whitespacesAndNewlines) == "0"
    }

    private func appleKoreanInputRemoved() -> Bool {
        let xml = processData("/usr/bin/defaults", ["export", "com.apple.HIToolbox", "-"])
        guard let data = xml,
              let plist = try? PropertyListSerialization.propertyList(from: data, options: [], format: nil),
              let dict = plist as? [String: Any] else {
            return false
        }
        for key in ["AppleEnabledInputSources", "AppleSelectedInputSources", "AppleInputSourceHistory"] {
            guard let items = dict[key] as? [[String: Any]] else { continue }
            for item in items {
                let bundleID = item["Bundle ID"] as? String ?? ""
                let inputMode = item["Input Mode"] as? String ?? ""
                let inputSourceID = item["InputSource ID"] as? String ?? ""
                if bundleID == "com.apple.inputmethod.Korean" ||
                    inputMode.hasPrefix("com.apple.inputmethod.Korean") ||
                    inputSourceID.hasPrefix("com.apple.inputmethod.Korean") {
                    return false
                }
            }
        }
        let current = dict["AppleCurrentKeyboardLayoutInputSourceID"] as? String ?? ""
        return !current.contains("2SetHangul") && !current.contains("2SetKorean")
    }

    private func karabinerMappingApplied() -> Bool {
        let path = NSHomeDirectory() + "/.config/karabiner/karabiner.json"
        guard let text = try? String(contentsOfFile: path, encoding: .utf8).lowercased() else {
            return false
        }
        return text.contains("right_command") && text.contains("f18")
    }

    private func isKarabinerRunning() -> Bool {
        isProcessRunning("Karabiner-Elements") ||
            isProcessRunning("karabiner_console_user_server") ||
            isProcessRunning("Karabiner-Core-Service") ||
            isProcessRunning("Karabiner-VirtualHIDDevice-Daemon") ||
            isProcessRunning("org.pqrs.Karabiner-DriverKit-VirtualHIDDevice") ||
            isProcessRunning("karabiner_grabber") ||
            isProcessRunning("karabiner_observer") ||
            isProcessRunning("karabiner_session_monitor")
    }

    private func karabinerDriverReady() -> Bool {
        let text = processOutput("/Library/Application Support/org.pqrs/Karabiner-Elements/bin/karabiner_cli", ["--show-settings-window-guidance"])
        return text.contains("\"driver_activated\": true") && text.contains("\"driver_connected\": true")
    }

    private func processOutput(_ executable: String, _ arguments: [String]) -> String {
        guard let data = processData(executable, arguments) else { return "" }
        return String(data: data, encoding: .utf8) ?? ""
    }

    private func processData(_ executable: String, _ arguments: [String]) -> Data? {
        let process = Process()
        let stdout = Pipe()
        process.executableURL = URL(fileURLWithPath: executable)
        process.arguments = arguments
        process.standardOutput = stdout
        process.standardError = Pipe()
        do {
            try process.run()
            process.waitUntilExit()
            return stdout.fileHandleForReading.readDataToEndOfFile()
        } catch {
            return nil
        }
    }

    private func commandExists(_ path: String) -> Bool {
        FileManager.default.isExecutableFile(atPath: path)
    }

    private func openURL(_ value: String) {
        if let url = URL(string: value) {
            NSWorkspace.shared.open(url)
        }
    }

    private func openApp(_ name: String) {
        NSWorkspace.shared.open(URL(fileURLWithPath: "/Applications/\(name).app"))
    }

    private func installBrewCask(_ cask: String, afterInstallCommand: String? = nil) {
        guard let brew = brewPath() else {
            statusLabel.stringValue = localized("status.installHomebrewFirst")
            runInstallInTerminal(#"/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)""#)
            return
        }
        var command = "sudo -v && \(shellQuote(brew)) install --cask \(shellQuote(cask))"
        if let afterInstallCommand {
            command += " && " + afterInstallCommand
        }
        runInstallInTerminal(command)
    }

    private func runInstallInTerminal(_ command: String) {
        let escaped = command
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
        let script = """
        tell application "Terminal"
          activate
          do script "\(escaped)"
        end tell
        """
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
        process.arguments = ["-e", script]
        try? process.run()
        statusLabel.stringValue = localized("status.startedTerminal")
    }

    private func shellQuote(_ value: String) -> String {
        "'\(value.replacingOccurrences(of: "'", with: "'\\''"))'"
    }

    private func brewPath() -> String? {
        for path in ["/opt/homebrew/bin/brew", "/usr/local/bin/brew"] {
            if FileManager.default.isExecutableFile(atPath: path) {
                return path
            }
        }
        return nil
    }

    private func copy(_ text: String) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)
        statusLabel.stringValue = "Copied to clipboard"
    }

    private func runScript(_ args: [String], extraEnv: [String: String] = [:]) -> String {
        let process = Process()
        let stdout = Pipe()
        let stderr = Pipe()
        process.executableURL = URL(fileURLWithPath: projectRoot() + "/bootstrap.sh")
        process.arguments = args
        var env = ProcessInfo.processInfo.environment
        for (key, value) in extraEnv { env[key] = value }
        process.environment = env
        process.standardOutput = stdout
        process.standardError = stderr
        do {
            try process.run()
            process.waitUntilExit()
            let out = String(data: stdout.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
            let err = String(data: stderr.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
            return out + (err.isEmpty ? "" : "\n" + err)
        } catch {
            return error.localizedDescription
        }
    }
}

func projectRoot() -> String {
    if let url = Bundle.main.url(forResource: "ProjectRoot", withExtension: "txt"),
       let value = try? String(contentsOf: url, encoding: .utf8).trimmingCharacters(in: .whitespacesAndNewlines),
       !value.isEmpty {
        return value
    }
    return FileManager.default.currentDirectoryPath
}

let app = NSApplication.shared
app.setActivationPolicy(.regular)
let controller = SetupWindowController()
controller.showWindow(nil)
controller.window?.center()
controller.window?.makeKeyAndOrderFront(nil)
controller.window?.orderFrontRegardless()
app.activate(ignoringOtherApps: true)
app.run()
