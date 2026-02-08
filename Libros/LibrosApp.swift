import SwiftUI
import SwiftData

/// Main entry point for the Libros app
@main
struct LibrosApp: App {

    /// The SwiftData model container
    let modelContainer: ModelContainer

    init() {
        do {
            // Configure the schema with all our models
            let schema = Schema([
                Book.self,
                BookCopy.self,
                Author.self,
                Series.self,
                Genre.self,
                Tag.self,
                Location.self
            ])

            // Configure for CloudKit sync
            let modelConfiguration = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: false,
                cloudKitDatabase: .automatic
            )

            modelContainer = try ModelContainer(
                for: schema,
                configurations: [modelConfiguration]
            )
        } catch {
            fatalError("Failed to initialize ModelContainer: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(modelContainer)
    }
}

// MARK: - Preview Container

extension ModelContainer {
    /// Creates an in-memory container for previews and testing
    static var preview: ModelContainer {
        do {
            let schema = Schema([
                Book.self,
                BookCopy.self,
                Author.self,
                Series.self,
                Genre.self,
                Tag.self,
                Location.self
            ])

            let configuration = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: true
            )

            let container = try ModelContainer(
                for: schema,
                configurations: [configuration]
            )

            // Add sample data
            let context = container.mainContext

            // Create sample authors
            let asimov = Author(name: "Isaac Asimov", openLibraryId: "OL34221A")
            let herbert = Author(name: "Frank Herbert", openLibraryId: "OL20187A")
            let leguin = Author(name: "Ursula K. Le Guin", openLibraryId: "OL24529A")

            context.insert(asimov)
            context.insert(herbert)
            context.insert(leguin)

            // Create sample series
            let foundation = Series(name: "Foundation", expectedCount: 7)
            let dune = Series(name: "Dune", expectedCount: 6)
            let earthsea = Series(name: "Earthsea", expectedCount: 6)

            context.insert(foundation)
            context.insert(dune)
            context.insert(earthsea)

            // Create sample genres
            let fiction = Genre(name: "Fiction", isUserCreated: false)
            let sciFi = Genre(name: "Science Fiction", parent: fiction, isUserCreated: false)

            context.insert(fiction)
            context.insert(sciFi)

            // Create sample locations
            let livingRoom = Location(name: "Living Room Bookshelf")
            let office = Location(name: "Office")

            context.insert(livingRoom)
            context.insert(office)

            // Create sample books
            let foundationBook = Book(title: "Foundation", isbn13: "9780553293357")
            foundationBook.authors = [asimov]
            foundationBook.series = foundation
            foundationBook.seriesOrder = 1
            foundationBook.genres = [sciFi]
            foundationBook.rating = 5
            foundationBook.readStatus = .read
            foundationBook.synopsis = "For twelve thousand years the Galactic Empire has ruled supreme."
            foundationBook.updateSearchableText()

            let duneBook = Book(title: "Dune", isbn13: "9780441172719")
            duneBook.authors = [herbert]
            duneBook.series = dune
            duneBook.seriesOrder = 1
            duneBook.genres = [sciFi]
            duneBook.rating = 5
            duneBook.readStatus = .read
            duneBook.synopsis = "Set on the desert planet Arrakis, Dune is the story of the boy Paul Atreides."
            duneBook.updateSearchableText()

            let leftHand = Book(title: "The Left Hand of Darkness", isbn13: "9780441478125")
            leftHand.authors = [leguin]
            leftHand.genres = [sciFi]
            leftHand.readStatus = .unread
            leftHand.updateSearchableText()

            context.insert(foundationBook)
            context.insert(duneBook)
            context.insert(leftHand)

            // Create sample copies
            let foundationCopy = BookCopy(format: .paperback, condition: .good, location: livingRoom)
            foundationCopy.book = foundationBook

            let duneCopy = BookCopy(format: .hardcover, condition: .likeNew, location: office)
            duneCopy.book = duneBook

            context.insert(foundationCopy)
            context.insert(duneCopy)

            try context.save()

            return container
        } catch {
            fatalError("Failed to create preview container: \(error)")
        }
    }
}
