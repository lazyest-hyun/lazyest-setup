public protocol InputSourceBackend {
    func registerGureum() -> Bool
    func sources(includeDisabled: Bool) -> [EnabledInputSource]?
    func enable(_ id: String) -> Bool
    func select(_ id: String) -> Bool
    func disable(_ id: String) -> Bool
}

public enum InputSourceSetup {
    public enum Outcome: Equatable {
        case applied
        case registrationFailed
        case activationFailed
        case cleanupFailed
    }

    public static func apply(using backend: InputSourceBackend) -> Outcome {
        let prepared = prepare(using: backend)
        guard prepared == .applied else { return prepared }
        return finish(using: backend)
    }

    public static func prepare(using backend: InputSourceBackend) -> Outcome {
        guard backend.registerGureum() else { return .registrationFailed }
        let bundle = "org.youknowone.inputmethod.Gureum"
        let han2 = bundle + ".han2"
        guard let installed = backend.sources(includeDisabled: true),
              InputSourceState.gureumEnabled(installed) else { return .registrationFailed }
        for id in ["org.youknowone.inputmethod.Korean", bundle + ".system", han2] {
            if installed.contains(where: { $0.id == id && $0.bundleID == bundle }),
               !backend.enable(id) { return .activationFailed }
        }
        return .applied
    }

    public static func finish(using backend: InputSourceBackend) -> Outcome {
        // A fresh process must load installed sources before reading enabled modes.
        _ = backend.sources(includeDisabled: true)
        let han2 = "org.youknowone.inputmethod.Gureum.han2"
        guard let enabled = backend.sources(includeDisabled: false),
              InputSourceState.gureumEnabled(enabled) else { return .activationFailed }
        // Select the working replacement before removing the existing Korean fallback.
        guard backend.select(han2) else { return .activationFailed }
        for source in enabled.filter({ InputSourceState.appleKoreanEnabled([$0]) })
            .sorted(by: { $0.id.count > $1.id.count }) {
            guard backend.disable(source.id) else { return .cleanupFailed }
        }
        guard let final = backend.sources(includeDisabled: false),
              InputSourceState.gureumEnabled(final), !InputSourceState.appleKoreanEnabled(final) else {
            return .cleanupFailed
        }
        return .applied
    }

    public static func reset(using backend: InputSourceBackend) -> Outcome {
        let apple = "com.apple.inputmethod.Korean"
        let han2 = apple + ".2SetKorean"
        guard let installed = backend.sources(includeDisabled: true),
              installed.contains(where: { $0.id == han2 && $0.bundleID == apple }) else {
            return .activationFailed
        }
        for id in [apple, han2] where installed.contains(where: { $0.id == id }) {
            guard backend.enable(id) else { return .activationFailed }
        }
        guard let enabled = backend.sources(includeDisabled: false),
              enabled.contains(where: { $0.id == han2 && $0.bundleID == apple }), backend.select(han2) else {
            return .activationFailed
        }
        for source in enabled.filter({ $0.bundleID == "org.youknowone.inputmethod.Gureum" })
            .sorted(by: { $0.id.count > $1.id.count }) {
            guard backend.disable(source.id) else { return .cleanupFailed }
        }
        guard let final = backend.sources(includeDisabled: false),
              final.contains(where: { $0.id == han2 && $0.bundleID == apple }),
              !final.contains(where: { $0.bundleID == "org.youknowone.inputmethod.Gureum" }) else {
            return .cleanupFailed
        }
        return .applied
    }
}
