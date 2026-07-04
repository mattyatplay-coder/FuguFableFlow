import Foundation

enum WritingStyle: String, CaseIterable, Identifiable {
    case automatic
    case casual
    case veryCasual
    case formal

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .automatic: "Automatic"
        case .casual: "Casual"
        case .veryCasual: "Very Casual"
        case .formal: "Formal"
        }
    }
}
