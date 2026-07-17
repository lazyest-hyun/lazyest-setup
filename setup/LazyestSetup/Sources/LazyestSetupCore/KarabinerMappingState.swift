import Foundation

public enum KarabinerMappingState {
    public static let ownedRuleDescription = "Lazyest Setup: right_command to F18"
    public static let legacyOwnedRuleDescription = "MacBootstrap: right_command to F18"

    public static func isApplied(data: Data) -> Bool {
        guard
            let root = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
            let profiles = root["profiles"] as? [[String: Any]],
            let profile = profiles.first(where: { $0["selected"] as? Bool == true }) ?? profiles.first
        else {
            return false
        }

        return containsOwnedComplexRule(profile) && !containsLegacySimpleMapping(profile)
    }

    private static func containsOwnedComplexRule(_ profile: [String: Any]) -> Bool {
        guard
            let complexModifications = profile["complex_modifications"] as? [String: Any],
            let rules = complexModifications["rules"] as? [[String: Any]]
        else {
            return false
        }

        return rules.contains { rule in
            guard
                let description = rule["description"] as? String,
                [ownedRuleDescription, legacyOwnedRuleDescription].contains(description),
                let manipulators = rule["manipulators"] as? [[String: Any]]
            else {
                return false
            }
            return manipulators.contains {
                $0["type"] as? String == "basic" && isRightCommandToF18Manipulator($0)
            }
        }
    }

    private static func containsLegacySimpleMapping(_ profile: [String: Any]) -> Bool {
        if let mappings = profile["simple_modifications"] as? [[String: Any]],
           mappings.contains(where: isRightCommandToF18Manipulator) {
            return true
        }

        guard let devices = profile["devices"] as? [[String: Any]] else {
            return false
        }
        return devices.contains { device in
            guard let mappings = device["simple_modifications"] as? [[String: Any]] else {
                return false
            }
            return mappings.contains(where: isRightCommandToF18Manipulator)
        }
    }

    private static func isRightCommandToF18Manipulator(_ value: [String: Any]) -> Bool {
        guard
            let from = value["from"] as? [String: Any],
            from["key_code"] as? String == "right_command",
            let targets = value["to"] as? [[String: Any]]
        else {
            return false
        }
        return targets.contains { $0["key_code"] as? String == "f18" }
    }
}
