import Foundation

//  ContentLoader.swift
//  carambole
//
//  Loads the course content (Book → Module → Element → Example) from bundled JSON
//  into memory. Content is STATIC bundle data, so it is not persisted in SQLite —
//  only user `review_status` lives in the database. The manifest lists the module
//  files; all modules load into one `Book` (the model supports many; v1 ships one).

/// Manifest listing the per-module JSON files, in load order.
private struct ContentManifest: Codable {
    let moduleFiles: [String]
}

// MARK: - JSON DTOs (decoded shape; ids for the leaf are injected from context)

private struct ModuleDTO: Codable {
    let id: String
    let sortOrder: Int
    let title: String
    let ruleNote: String
    let elements: [ElementDTO]
}

private struct ElementDTO: Codable {
    let id: String
    let sortOrder: Int
    let label: String
    let ruleNote: String
    let examples: [ExampleDTO]
}

private struct ExampleDTO: Codable {
    let id: String
    let type: ExerciseType
    let prompt: String
    let cue: String?
    let answerTokens: [String]
    let tokenBank: [String]
    let inputMode: InputMode
    let explanation: String
    let translation: String?
    let hint: String?
    let explanationEN: String?
}

enum ContentLoader {
    /// The single book's identity (v1). A future manifest could declare several.
    static let bookID = "book_fr_fondations"
    static let bookTitle = "Français — Fondations"

    /// Load the book from the bundle. Returns `Book.sample` only if nothing
    /// decodes (e.g. a missing manifest) so the UI always has something to show.
    static func loadBook() -> Book {
        guard let manifestURL = bundleURL(forResource: "manifest", withExtension: "json"),
              let data = try? Data(contentsOf: manifestURL),
              let manifest = try? JSONDecoder().decode(ContentManifest.self, from: data) else {
            print("ContentLoader: no manifest — falling back to sample book")
            return .sample
        }

        let modules: [CourseModule] = manifest.moduleFiles.compactMap { fileName in
            let resource = (fileName as NSString).deletingPathExtension
            let ext = (fileName as NSString).pathExtension
            guard let url = bundleURL(forResource: resource, withExtension: ext),
                  let data = try? Data(contentsOf: url) else {
                print("ContentLoader: could not read module file \(fileName)")
                return nil
            }
            do {
                let dto = try JSONDecoder().decode(ModuleDTO.self, from: data)
                return module(from: dto)
            } catch {
                print("ContentLoader: failed to decode \(fileName): \(error)")
                return nil
            }
        }

        guard !modules.isEmpty else { return .sample }
        return Book(id: bookID, title: bookTitle, sortOrder: 1,
                    modules: modules.sorted { $0.sortOrder < $1.sortOrder })
    }

    // MARK: - DTO → domain (injecting parent ids down the tree)

    private static func module(from dto: ModuleDTO) -> CourseModule {
        let elements = dto.elements
            .sorted { $0.sortOrder < $1.sortOrder }
            .map { element(from: $0, moduleID: dto.id) }
        return CourseModule(id: dto.id, bookID: bookID, sortOrder: dto.sortOrder,
                            title: dto.title, ruleNote: dto.ruleNote, elements: elements)
    }

    private static func element(from dto: ElementDTO, moduleID: String) -> GrammarElement {
        let examples = dto.examples.map { ex in
            Exercise(id: ex.id, elementID: dto.id, type: ex.type, prompt: ex.prompt,
                     cue: ex.cue, answerTokens: ex.answerTokens, tokenBank: ex.tokenBank,
                     inputMode: ex.inputMode, explanation: ex.explanation,
                     translation: ex.translation, hint: ex.hint,
                     explanationEN: ex.explanationEN)
        }
        return GrammarElement(id: dto.id, moduleID: moduleID, sortOrder: dto.sortOrder,
                              label: dto.label, ruleNote: dto.ruleNote, examples: examples)
    }

    /// Resolves a bundled resource, trying the `Topics` subdirectory first and
    /// falling back to the flattened bundle root (synchronized groups flatten).
    private static func bundleURL(forResource resource: String, withExtension ext: String) -> URL? {
        Bundle.main.url(forResource: resource, withExtension: ext, subdirectory: "Topics")
            ?? Bundle.main.url(forResource: resource, withExtension: ext)
    }
}
