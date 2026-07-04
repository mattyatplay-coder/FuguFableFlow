import Carbon.HIToolbox
import Foundation

struct HotKeyShortcut: Equatable {
    var keyCode: UInt32
    var modifiers: UInt32

    static let defaultDictation = HotKeyShortcut(
        keyCode: UInt32(kVK_Space),
        modifiers: UInt32(controlKey | optionKey)
    )

    var displayName: String {
        let modifierNames = HotKeyModifierOption.allCases
            .filter { modifiers & $0.carbonValue != 0 }
            .map(\.displayName)
        let keyName = HotKeyKeyOption.option(for: keyCode)?.displayName ?? "Key \(keyCode)"
        return (modifierNames + [keyName]).joined(separator: " + ")
    }

    var validationMessage: String? {
        let modifierCount = HotKeyModifierOption.allCases.filter { modifiers & $0.carbonValue != 0 }.count
        if modifierCount == 0 {
            return "Shortcut must include at least one modifier."
        }
        if modifierCount > 2 {
            return "Shortcut must contain 3 keys or fewer."
        }
        if HotKeyKeyOption.option(for: keyCode) == nil {
            return "Shortcut key is not supported."
        }
        return nil
    }
}

enum DictationShortcutMode: String, CaseIterable, Identifiable {
    case rightFunctionRightCommandPushToTalk
    case rightCommandPushToTalk
    case customToggle

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .rightFunctionRightCommandPushToTalk:
            "Right Fn + Right Command"
        case .rightCommandPushToTalk:
            "Right Command"
        case .customToggle:
            "Custom Toggle Shortcut"
        }
    }

    var detail: String {
        switch self {
        case .rightFunctionRightCommandPushToTalk:
            "Hold to dictate; release to stop and paste."
        case .rightCommandPushToTalk:
            "Hold to dictate; release to stop and paste. Use this when macOS does not expose Fn to apps."
        case .customToggle:
            "Press once to start, press again to stop."
        }
    }
}

enum HotKeyModifierOption: String, CaseIterable, Identifiable {
    case control
    case option
    case command
    case shift

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .control: "Control"
        case .option: "Option"
        case .command: "Command"
        case .shift: "Shift"
        }
    }

    var carbonValue: UInt32 {
        switch self {
        case .control: UInt32(controlKey)
        case .option: UInt32(optionKey)
        case .command: UInt32(cmdKey)
        case .shift: UInt32(shiftKey)
        }
    }
}

struct HotKeyKeyOption: Identifiable, Hashable {
    let keyCode: UInt32
    let displayName: String

    var id: UInt32 { keyCode }

    static let supported: [HotKeyKeyOption] = [
        HotKeyKeyOption(keyCode: UInt32(kVK_Space), displayName: "Space"),
        HotKeyKeyOption(keyCode: UInt32(kVK_ANSI_D), displayName: "D"),
        HotKeyKeyOption(keyCode: UInt32(kVK_ANSI_F), displayName: "F"),
        HotKeyKeyOption(keyCode: UInt32(kVK_ANSI_V), displayName: "V"),
        HotKeyKeyOption(keyCode: UInt32(kVK_F13), displayName: "F13"),
        HotKeyKeyOption(keyCode: UInt32(kVK_F14), displayName: "F14"),
        HotKeyKeyOption(keyCode: UInt32(kVK_F15), displayName: "F15"),
        HotKeyKeyOption(keyCode: UInt32(kVK_F16), displayName: "F16"),
        HotKeyKeyOption(keyCode: UInt32(kVK_F17), displayName: "F17"),
        HotKeyKeyOption(keyCode: UInt32(kVK_F18), displayName: "F18"),
        HotKeyKeyOption(keyCode: UInt32(kVK_F19), displayName: "F19")
    ]

    static func option(for keyCode: UInt32) -> HotKeyKeyOption? {
        supported.first { $0.keyCode == keyCode }
    }
}
