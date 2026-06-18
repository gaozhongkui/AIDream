import Foundation
import SwiftUI
import Combine
import OSLog

private let logger = Logger(subsystem: "com.aidream", category: "Creation")

struct CreationItem: Identifiable, Codable {
    let id: UUID
    let date: Date
    let prompt: String
    let videoFileName: String

    var videoURL: URL {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return docs.appendingPathComponent(videoFileName)
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

    private let storageKey = "com.aidream.creations.final.v300"
    @Published var creations: [CreationItem] = []

    private init() {
        loadCreations()
    }

    /// Records a creation. If url is remote, it will be downloaded to Documents.
    func addCreation(prompt: String, url: URL) {
        let fileManager = FileManager.default
        let docs = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let fileName = "\(UUID().uuidString).mp4"
        let destinationURL = docs.appendingPathComponent(fileName)

        Task {
            do {
                if url.isFileURL {
                    // Local to permanent Documents
                    if fileManager.fileExists(atPath: url.path) {
                        try fileManager.copyItem(at: url, to: destinationURL)
                    } else {
                        logger.error("Source file missing at: \(url.path)")
                        return
                    }
                } else {
                    // Download from remote to permanent Documents
                    logger.info("Downloading remote video for history: \(url)")
                    var request = URLRequest(url: url, timeoutInterval: 60)
                    let (data, _) = try await URLSession.shared.data(for: request)
                    try data.write(to: destinationURL)
                }

                let newItem = CreationItem(
                    id: UUID(),
                    date: Date(),
                    prompt: prompt.isEmpty ? "AI Generation" : prompt,
                    videoFileName: fileName
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
        try? FileManager.default.removeItem(at: item.videoURL)
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
                FileManager.default.fileExists(atPath: item.videoURL.path)
            }
        }
    }
}
