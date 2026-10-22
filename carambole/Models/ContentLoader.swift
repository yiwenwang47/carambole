import Foundation

//  ContentLoader.swift
//  carambole
//
//  Loads the course content (Book → Module → Element → Example) from bundled JSON
//  into memory. Content is STATIC bundle data, so it is not persisted in SQLite —
//  only user `review_status` lives in the database. Each book in `BookCatalog`
//  has its own manifest: *Fondations* reads `manifest.json` (grammar modules),
//  *En situation* reads `situations_manifest.json` (dialogue modules) and
//  `words.json`.
//  Every valid module listed in a manifest is loaded.

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
    let spot: SpotError?
}

enum ContentLoader {
    /// *Fondations* identity (kept for existing call sites).
    static let bookID = BookCatalog.fondations.id
    static let bookTitle = BookCatalog.fondations.title

    /// Load the selected book from the bundle.
    static func loadBook(_ descriptor: BookDescriptor) -> Book {
        switch descriptor.kind {
        case .grammar: return loadBook()
        case .situation: return loadSituationBook(descriptor)
        }
    }

    /// Load *Fondations* from the bundle. Returns `Book.sample` only if nothing
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

    // MARK: - En situation

    /// Every module listed in `situations_manifest.json`, as Book → Module →
    /// Element (one conversational move) → items. A module or word file that
    /// fails to decode is skipped with a log line; an item that fails the
    /// contract check is dropped so the view never meets an unplayable card.
    static func loadSituationBook(_ descriptor: BookDescriptor) -> Book {
        let decoder = JSONDecoder()
        var book = Book(id: descriptor.id, title: descriptor.title, sortOrder: 2, modules: [],
                        kind: .situation)
        guard let manifestURL = situationURL("situations_manifest", "json"),
              let data = try? Data(contentsOf: manifestURL),
              let manifest = try? decoder.decode(SituationManifest.self, from: data) else {
            print("ContentLoader: no situations manifest")
            return book
        }
        book.persona = manifest.persona
        if let url = situationURL("words", "json"), let data = try? Data(contentsOf: url) {
            do {
                book.words = try decoder.decode(SituationWordFile.self, from: data).glossary
            } catch {
                print("ContentLoader: failed to decode words.json: \(error)")
            }
        }
        var seenElementIDs: Set<String> = []
        for fileName in manifest.moduleFiles {
            let resource = (fileName as NSString).deletingPathExtension
            let ext = (fileName as NSString).pathExtension
            guard let url = situationURL(resource, ext), let data = try? Data(contentsOf: url) else {
                print("ContentLoader: could not read situation module \(fileName)")
                continue
            }
            let file: SituationModuleFile
            do {
                file = try decoder.decode(SituationModuleFile.self, from: data)
            } catch {
                print("ContentLoader: failed to decode \(fileName): \(error)")
                continue
            }
            let elements: [GrammarElement] = file.elements.enumerated().compactMap { index, el in
                guard el.id.hasPrefix("sit_"), seenElementIDs.insert(el.id).inserted else {
                    print("ContentLoader: skipped element \(el.id) (bad or duplicate id)")
                    return nil
                }
                let items = el.items.filter { item in
                    let errors = item.validationErrors
                    if !errors.isEmpty { print("ContentLoader: \(errors.joined(separator: "; "))") }
                    return errors.isEmpty
                }
                guard !items.isEmpty else { return nil }
                return GrammarElement(id: el.id, moduleID: file.id, sortOrder: index + 1,
                                      label: el.title, ruleNote: el.note, examples: [], items: items)
            }
            guard !elements.isEmpty else { continue }
            book.modules.append(CourseModule(id: file.id, bookID: descriptor.id, sortOrder: file.number,
                                             title: file.title, ruleNote: file.goal, elements: elements))
        }
        book.modules.sort { $0.sortOrder < $1.sortOrder }
        return book
    }

    private static func situationURL(_ resource: String, _ ext: String) -> URL? {
        Bundle.main.url(forResource: resource, withExtension: ext, subdirectory: "Situations")
            ?? Bundle.main.url(forResource: resource, withExtension: ext)
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
                     explanationEN: ex.explanationEN, spot: ex.spot)
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
