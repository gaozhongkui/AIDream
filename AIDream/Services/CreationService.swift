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
    let remoteURL: String?

    var fileURL: URL {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return docs.appendingPathComponent(fileName)
    }

    /// 获取可用的播放地址：优先本地文件（需校验大小），否则返回远程地址
    var availableURL: URL? {
        if FileManager.default.fileExists(atPath: fileURL.path) {
            if let attrs = try? FileManager.default.attributesOfItem(atPath: fileURL.path),
               let size = attrs[.size] as? UInt64, size > 2048 { // 只有大于2KB才认为是有效视频
                return fileURL
            }
        }
        if let remoteStr = remoteURL, let url = URL(string: remoteStr) {
            return url
        }
        return nil
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

    private let storageKey = "com.aidream.creations.final.v301"
    @Published var creations: [CreationItem] = []
    @Published var downloadingIDs: Set<UUID> = []

    private init() {
        loadCreations()
    }

    func addCreation(prompt: String, url: URL? = nil, image: UIImage? = nil) {
        let id = UUID()
        let fileManager = FileManager.default
        let docs = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]

        let type: CreationMediaType = (image != nil) ? .image : .video
        let fileName = (type == .image) ? "\(id.uuidString).jpg" : "\(id.uuidString).mp4"
        let remoteURLString = (url?.isFileURL == false) ? url?.absoluteString : nil

        let newItem = CreationItem(
            id: id,
            date: Date(),
            prompt: prompt.isEmpty ? NSLocalizedString("label_ai_generation", comment: "") : prompt,
            fileName: fileName,
            type: type,
            remoteURL: remoteURLString
        )

        // 1. 立即更新列表
        self.creations.insert(newItem, at: 0)
        self.saveCreations()

        // 2. 后台处理文件保存
        Task(priority: .background) {
            do {
                let destinationURL = docs.appendingPathComponent(fileName)

                if let image = image {
                    if let data = image.jpegData(compressionQuality: 0.9) {
                        try data.write(to: destinationURL)
                    }
                } else if let sourceURL = url {
                    if sourceURL.isFileURL {
                        if fileManager.fileExists(atPath: sourceURL.path) {
                            try? fileManager.removeItem(at: destinationURL)
                            try fileManager.copyItem(at: sourceURL, to: destinationURL)
                            logger.info("Local file copied to history: \(fileName)")
                        }
                    } else {
                        await MainActor.run { self.downloadingIDs.insert(id) }
                        defer { Task { @MainActor in self.downloadingIDs.remove(id) } }

                        logger.info("Background downloading with headers: \(sourceURL)")
                        let delegate = CreationRedirectHandler()
                        let session = URLSession(configuration: .default, delegate: delegate, delegateQueue: nil)
                        var request = URLRequest(url: sourceURL, timeoutInterval: 60)

                        if sourceURL.absoluteString.contains("openrouter.ai") {
                            request.setValue("Bearer \(AIConfig.shared.openRouterApiKey)", forHTTPHeaderField: "Authorization")
                            request.setValue("https://aidream.app", forHTTPHeaderField: "HTTP-Referer")
                            request.setValue("AIDream", forHTTPHeaderField: "X-Title")
                        }
                        request.setValue("Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1", forHTTPHeaderField: "User-Agent")

                        let (tempURL, response) = try await session.download(for: request)
                        let statusCode = (response as? HTTPURLResponse)?.statusCode ?? -1

                        if statusCode == 200 {
                            if fileManager.fileExists(atPath: destinationURL.path) {
                                try? fileManager.removeItem(at: destinationURL)
                            }
                            try fileManager.moveItem(at: tempURL, to: destinationURL)
                            logger.info("Background download complete: \(fileName)")
                            await MainActor.run { self.objectWillChange.send() }
                        } else {
                            logger.error("Download failed status: \(statusCode) for \(sourceURL)")
                            // 如果下载失败，我们可能下载到了一个报错页面，删掉它避免占位
                            if fileManager.fileExists(atPath: destinationURL.path) {
                                try? fileManager.removeItem(at: destinationURL)
                            }
                        }
                    }
                }
            } catch {
                logger.error("Creation background task error: \(error.localizedDescription)")
            }
        }
    }

    func deleteCreation(_ item: CreationItem) {
        creations.removeAll { $0.id == item.id }
        try? FileManager.default.removeItem(at: item.fileURL)
        saveCreations()
    }

    /// 清除所有历史作品及本地文件
    func clearAll() {
        for item in creations {
            try? FileManager.default.removeItem(at: item.fileURL)
        }
        creations = []
        UserDefaults.standard.removeObject(forKey: storageKey)
    }

    private func saveCreations() {
        if let encoded = try? JSONEncoder().encode(creations) {
            UserDefaults.standard.set(encoded, forKey: storageKey)
        }
    }

    private func loadCreations() {
        guard let data = UserDefaults.standard.data(forKey: storageKey) else { return }
        if let decoded = try? JSONDecoder().decode([CreationItem].self, from: data) {
            self.creations = decoded
        }
    }
}

final class CreationRedirectHandler: NSObject, URLSessionTaskDelegate {
    func urlSession(_ session: URLSession, task: URLSessionTask, willPerformHTTPRedirection response: HTTPURLResponse, newRequest: URLRequest, completionHandler: @escaping (URLRequest?) -> Void) {
        var req = newRequest
        if let nHost = newRequest.url?.host, !nHost.contains("openrouter.ai") {
            req.setValue(nil, forHTTPHeaderField: "Authorization")
            logger.info("Stripped Authorization header for redirect to: \(nHost)")
        }
        completionHandler(req)
    }
}
