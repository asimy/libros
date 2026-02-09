import SwiftUI
import SwiftData

/// Reusable book cover view with deterministic colored placeholders
struct BookCoverView: View {
    let book: Book
    let size: Size

    enum Size {
        case small   // List rows (50x75)
        case medium  // Detail view (120x180)
        case large   // Grid items (full width, 180 height)

        var width: CGFloat? {
            switch self {
            case .small: return 50
            case .medium: return 120
            case .large: return nil
            }
        }

        var height: CGFloat {
            switch self {
            case .small: return 75
            case .medium: return 180
            case .large: return 180
            }
        }

        var cornerRadius: CGFloat {
            switch self {
            case .small: return 4
            case .medium: return 8
            case .large: return 8
            }
        }

        var titleFont: Font {
            switch self {
            case .small: return .system(size: 8, weight: .medium)
            case .medium: return .system(size: 12, weight: .semibold)
            case .large: return .caption2.weight(.semibold)
            }
        }

        var shadowRadius: CGFloat {
            switch self {
            case .small: return 2
            case .medium: return 4
            case .large: return 4
            }
        }
    }

    var body: some View {
        Group {
            if let coverData = book.coverData,
               let uiImage = UIImage(data: coverData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: size == .medium ? .fill : .fit)
            } else if let coverURL = book.coverURL ?? book.openLibraryCoverURL {
                AsyncImage(url: coverURL) { phase in
                    switch phase {
                    case .empty:
                        placeholderCover
                            .overlay { ProgressView() }
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: size == .medium ? .fill : .fit)
                    case .failure:
                        placeholderCover
                    @unknown default:
                        placeholderCover
                    }
                }
            } else {
                placeholderCover
            }
        }
        .frame(width: size.width, height: size.height)
        .if(size == .large) { view in
            view.frame(maxWidth: .infinity)
        }
        .clipShape(RoundedRectangle(cornerRadius: size.cornerRadius))
        .shadow(
            color: size == .large ? .black.opacity(0.15) : .black.opacity(0.2),
            radius: size.shadowRadius,
            y: size == .large ? 2 : 0
        )
    }

    // MARK: - Placeholder

    private var placeholderCover: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size.cornerRadius)
                .fill(placeholderGradient)

            RoundedRectangle(cornerRadius: size.cornerRadius)
                .strokeBorder(.black.opacity(0.1), lineWidth: 0.5)

            VStack(spacing: size == .small ? 2 : 6) {
                Text(book.title)
                    .font(size.titleFont)
                    .foregroundStyle(.white.opacity(0.9))
                    .multilineTextAlignment(.center)
                    .lineLimit(size == .small ? 2 : 4)
                    .padding(.horizontal, size == .small ? 4 : 10)
            }
        }
        .overlay {
            RoundedRectangle(cornerRadius: size.cornerRadius)
                .fill(
                    .linearGradient(
                        colors: [.white.opacity(0.15), .clear],
                        startPoint: .topLeading,
                        endPoint: .center
                    )
                )
        }
    }

    private var placeholderGradient: LinearGradient {
        let color = Self.spineColor(for: book.title)
        return LinearGradient(
            colors: [color, color.opacity(0.8)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    // MARK: - Deterministic Color

    private static let spineColors: [Color] = [
        Color(red: 0.55, green: 0.27, blue: 0.07),  // Saddle brown
        Color(red: 0.18, green: 0.31, blue: 0.31),   // Dark teal
        Color(red: 0.40, green: 0.20, blue: 0.30),   // Plum
        Color(red: 0.13, green: 0.23, blue: 0.42),   // Navy
        Color(red: 0.33, green: 0.42, blue: 0.18),   // Olive
        Color(red: 0.50, green: 0.16, blue: 0.16),   // Burgundy
        Color(red: 0.28, green: 0.28, blue: 0.28),   // Charcoal
        Color(red: 0.35, green: 0.25, blue: 0.10),   // Dark gold
    ]

    static func spineColor(for title: String) -> Color {
        let hash = abs(title.hashValue)
        return spineColors[hash % spineColors.count]
    }
}

// MARK: - Conditional Modifier

private extension View {
    @ViewBuilder
    func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}
