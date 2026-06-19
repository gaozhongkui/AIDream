import Foundation
import SwiftUI
import Combine
import OSLog

private let logger = Logger(subsystem: "com.aidream", category: "Creation")

enum CreationMediaType: String, Codable {
    case video
    case image
}

struct CreationItem: Identifiable, Codable {
    let id: UUID
    let date: Date
    let prompt: String
    let fileName: String
    let type: CreationMediaType

    var fileURL: URL {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return docs.appendingPathComponent(fileName)
    }

    var displayDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

@MainActor
final class CreationService: ObservableObject {
    static let shared = CreationService()

    private let storageKey = "com.aidream.creations.final.v301" // Increment version
    @Published var creations: [CreationItem] = []

    private init() {
        loadCreations()
    }

    /// Records a creation.
    func addCreation(prompt: String, url: URL? = nil, image: UIImage? = nil) {
        let fileManager = FileManager.default
        let docs = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]

        Task {
            do {
                let fileName: String
                let type: CreationMediaType

                if let image = image {
                    type = .image
                    fileName = "\(UUID().uuidString).jpg"
                    let destinationURL = docs.appendingPathComponent(fileName)
                    if let data = image.jpegData(compressionQuality: 0.9) {
                        try data.write(to: destinationURL)
                    } else {
                        return
                    }
                } else if let url = url {
                    type = .video
                    fileName = "\(UUID().uuidString).mp4"
                    let destinationURL = docs.appendingPathComponent(fileName)

                    if url.isFileURL {
                        if fileManager.fileExists(atPath: url.path) {
                            try fileManager.copyItem(at: url, to: destinationURL)
                        } else {
                            logger.error("Source file missing at: \(url.path)")
                            return
                        }
                    } else {
                        logger.info("Downloading remote video for history: \(url)")
                        var request = URLRequest(url: url, timeoutInterval: 60)
                        let (data, _) = try await URLSession.shared.data(for: request)
                        try data.write(to: destinationURL)
                    }
                } else {
                    return
                }

                let newItem = CreationItem(
                    id: UUID(),
                    date: Date(),
                    prompt: prompt.isEmpty ? "AI Generation" : prompt,
                    fileName: fileName,
                    type: type
                )

                creations.insert(newItem, at: 0)
                saveCreations()
                logger.info("Creation recorded and file saved: \(fileName)")
            }  catch {
                logger.error("Failed to save creation to history: \(error)")
            }
        }
    }

    func deleteCreation(_ item: CreationItem) {
        creations.removeAll { $0.id == item.id }
        try? FileManager.default.removeItem(at: item.fileURL)
        saveCreations()
    }

    private func saveCreations() {
        if let encoded = try? JSONEncoder().encode(creations) {
            UserDefaults.standard.set(encoded, forKey: storageKey)
        }
    }

    private func loadCreations() {
        guard let data = UserDefaults.standard.data(forKey: storageKey) else { return }
        if let decoded = try? JSONDecoder().decode([CreationItem].self, from: data) {
            self.creations = decoded.filter { item in
                FileManager.default.fileExists(atPath: item.fileURL.path)
            }
        }
    }
}
