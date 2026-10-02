/// A source from macOS TIS's enabled-only list. Installed sources and
/// HIToolbox selection/history entries do not indicate current activation.
public struct EnabledInputSource {
    public let id: String
    public let bundleID: String

    public init(id: String, bundleID: String) {
        self.id = id
        self.bundleID = bundleID
    }
}

public enum InputSourceState {
    public static func gureumEnabled(_ sources: [EnabledInputSource]) -> Bool {
        sources.contains {
            $0.id == "org.youknowone.inputmethod.Gureum.han2" &&
                $0.bundleID == "org.youknowone.inputmethod.Gureum"
        }
    }

    public static func appleKoreanEnabled(_ sources: [EnabledInputSource]) -> Bool {
        sources.contains {
            $0.bundleID == "com.apple.inputmethod.Korean" ||
                $0.id.hasPrefix("com.apple.inputmethod.Korean.")
        }
    }
}
