import Foundation

// swiftc carambole/Models/{BookCatalog,BookContent,Exercise,Situation,Nuance,ContentLoader}.swift \
//   tools/nuances/NuanceLoaderTests.swift -o /tmp/nuance-loader-tests
// /tmp/nuance-loader-tests carambole/Resources/Nuances

@main
struct NuanceLoaderTests {
    static func expect(_ condition: @autoclosure () -> Bool, _ message: String) {
        guard condition() else {
            fputs("FAIL: \(message)\n", stderr)
            exit(1)
        }
    }

    static func fixtureDirectory(manifest: String, module: String) throws -> URL {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("nuance-loader-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        try manifest.write(to: directory.appendingPathComponent("nuances_manifest.json"),
                           atomically: true, encoding: .utf8)
        try module.write(to: directory.appendingPathComponent("nuances_01.json"),
                         atomically: true, encoding: .utf8)
        return directory
    }

    static func main() throws {
        let directory = URL(fileURLWithPath: CommandLine.arguments.dropFirst().first
            ?? "carambole/Resources/Nuances", isDirectory: true)
        let descriptor = BookCatalog.nuances
        expect(BookCatalog.all.map(\.id) == ["book_fr_fondations", "book_fr_en_situation", "book_fr_nuances"],
               "Nuances appears third on the shelf")
        expect(descriptor.settingsScope == descriptor.id, "Nuances settings have their own scope")

        let book = ContentLoader.loadNuanceBook(descriptor, directory: directory)
        expect(book.id == "book_fr_nuances" && book.kind == .nuances, "Nuances identity and kind")
        expect(book.modules.count == 20, "all 20 manifest modules load")
        expect(book.modules.first?.id == "nu_01" && book.modules.last?.id == "nu_20",
               "modules retain curriculum order")
        expect(book.modules.allSatisfy { $0.elements.count == 5 }, "five review elements per module")
        let elements = book.allElements
        let cards = elements.flatMap(\.nuanceCards)
        expect(elements.count == 100 && cards.count == 550, "all production elements and cards load")
        expect(Set(elements.map(\.id)).count == 100, "element IDs stay unique")
        expect(Set(cards.map(\.id)).count == 550, "card IDs stay unique")
        expect(elements.allSatisfy { $0.examples.isEmpty && $0.items.isEmpty },
               "Nuances elements do not gain Book 1 or Book 2 drills")
        expect(book.modules[0].elements[0].nuanceCards[0].id == "b3_01_word_interrompre",
               "authored card order is retained")

        let manifest = "{\"book\":\"book_fr_nuances\",\"moduleFiles\":[\"nuances_01.json\"]}"
        let source = try String(contentsOf: directory.appendingPathComponent("nuances_01.json"),
                                encoding: .utf8)
        let duplicate = source.replacingOccurrences(of: "b3_01_dialogue_event",
                                                     with: "b3_01_word_interrompre")
        expect(duplicate != source, "duplicate fixture changed the source")
        let duplicateDirectory = try fixtureDirectory(manifest: manifest, module: duplicate)
        defer { try? FileManager.default.removeItem(at: duplicateDirectory) }
        expect(ContentLoader.loadNuanceBook(descriptor, directory: duplicateDirectory).modules.isEmpty,
               "a module with duplicate card IDs is rejected")

        let empty = "{\"id\":\"nu_01\",\"number\":1,\"title\":\"Empty\",\"goal\":\"Empty\",\"elements\":[]}"
        let emptyDirectory = try fixtureDirectory(manifest: manifest, module: empty)
        defer { try? FileManager.default.removeItem(at: emptyDirectory) }
        expect(ContentLoader.loadNuanceBook(descriptor, directory: emptyDirectory).modules.isEmpty,
               "a module without elements is rejected")
        print("Nuance loader: 20 modules, 100 elements, 550 cards; duplicate and empty modules rejected")
    }
}
