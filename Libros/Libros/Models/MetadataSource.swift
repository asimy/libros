import Foundation

/// Represents the source that provided metadata for a book
enum MetadataSource: String, Codable, CaseIterable, Identifiable {
    case openLibrary = "openLibrary"
    case ocrExtraction = "ocrExtraction"
    case quickPhoto = "quickPhoto"
    case manual = "manual"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .openLibrary: return "Open Library"
        case .ocrExtraction: return "OCR Extraction"
        case .quickPhoto: return "Quick Photo"
        case .manual: return "Manual Entry"
        }
    }

    var systemImage: String {
        switch self {
        case .openLibrary: return "globe"
        case .ocrExtraction: return "text.viewfinder"
        case .quickPhoto: return "camera"
        case .manual: return "keyboard"
        }
    }
}
