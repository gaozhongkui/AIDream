//
//  AIImageGenerator.swift
//  AIDream
//
//  Created by gaozhongkui on 2026/1/28.
//  Migrated to AIDream on 2026/05/22.
//

import SwiftUI
import UIKit
import OSLog

private let logger = Logger(subsystem: "com.aidream", category: "ImageGen")

class AIImageGenerator {

    // MARK: - Generation State

    enum GenerationState: Equatable {
        case idle
        case preparing
        case requesting
        case downloading(Double)
        case processing
        case completed
        case failed(String)

        var isLoading: Bool {
            switch self {
            case .idle, .completed, .failed(_): return false
            default: return true
            }
        }

        var description: String {
            switch self {
            case .idle: return "Ready"
            case .preparing: return "Preparing..."
            case .requesting: return "Requesting server..."
            case .downloading(let p): return "Downloading \(Int(p * 100))%"
            case .processing: return "Processing image..."
            case .completed: return "Done"
            case .failed(let e): return "Failed: \(e)"
            }
        }
    }

    // MARK: - Models

    enum Model: String, CaseIterable {
        case flux = "flux"
        case turbo = "turbo"
        case gptimage = "gptimage"
        case seedream = "seedream"
        case kontext = "kontext"

        var displayName: String { rawValue.capitalized }
    }

    enum HuggingFaceModel: String, CaseIterable {
        case fluxSchnell = "black-forest-labs/FLUX.1-schnell"
        case sdxl = "stabilityai/stable-diffusion-xl-base-1.0"
        case sdTurbo = "stabilityai/sd-turbo"

        var displayName: String {
            switch self {
            case .fluxSchnell: return "FLUX Schnell (HF)"
            case .sdxl:        return "SDXL (HF)"
            case .sdTurbo:     return "SD Turbo (HF)"
            }
        }
    }

    // MARK: - Image Provider

    enum ImageProvider: Hashable, CustomStringConvertible {
        case pollinations(Model)
        case huggingFace(HuggingFaceModel)
        case openRouter

        var description: String {
            switch self {
            case .pollinations(let m): return "Pollinations(\(m.displayName))"
            case .huggingFace(let m):  return "HuggingFace(\(m.displayName))"
            case .openRouter:          return "OpenRouter(\(AIConfig.shared.openRouterImageModel))"
            }
        }
    }

    // MARK: - Generation Options

    struct GenerationOptions {
        var model: Model = .flux
        var width: Int = 1024
        var height: Int = 1024
        var seed: Int? = nil
        var nologo: Bool = true
        var enhance: Bool = false
        var huggingFaceToken: String? = nil
        var openRouterApiKey: String? = nil

        static let `default` = GenerationOptions()

        var providerChain: [ImageProvider] {
            var chain: [ImageProvider] = [.pollinations(model)]
            for m in Model.allCases where m != model {
                chain.append(.pollinations(m))
            }
            let openRouterKey = openRouterApiKey ?? AIConfig.shared.openRouterApiKey
            if !openRouterKey.isEmpty && !AIConfig.shared.openRouterImageModel.isEmpty {
                chain.append(.openRouter)
            }
            for m in HuggingFaceModel.allCases {
                chain.append(.huggingFace(m))
            }
            return chain
        }
    }

    // MARK: - Generation Result

    struct GenerationResult {
        let image: UIImage
        let imageURL: URL?
        let prompt: String
        let usedProvider: ImageProvider
    }

    // MARK: - Callback Types

    typealias StateChangeHandler = (GenerationState) -> Void
    typealias ProgressHandler = (Double) -> Void
    typealias CompletionHandler = (Result<GenerationResult, Error>) -> Void

    // MARK: - Private Properties

    private let cooldownDuration: TimeInterval = 5 * 60
    private var providerCooldowns: [ImageProvider: Date] = [:]
    private var downloadTask: URLSessionDownloadTask?
    private var stateChangeHandler: StateChangeHandler?
    private var progressHandler: ProgressHandler?

    // MARK: - Singleton

    static let shared = AIImageGenerator()
    private init() {}

    // MARK: - Public API

    func generateImage(
        prompt: String,
        options: GenerationOptions = .default,
        onStateChange: StateChangeHandler? = nil,
        onProgress: ProgressHandler? = nil,
        completion: @escaping CompletionHandler
    ) {
        self.stateChangeHandler = onStateChange
        self.progressHandler = onProgress

        Task {
            await updateState(.preparing)
            try? await Task.sleep(nanoseconds: 500_000_000)

            let chain = options.providerChain.filter { isAvailable($0) }
            var lastError: Error = GenerationError.allProvidersFailed

            for provider in chain {
                do {
                    await updateState(.requesting)
                    let (image, url) = try await generate(
                        prompt: prompt,
                        provider: provider,
                        options: options
                    )

                    await updateState(.processing)
                    try? await Task.sleep(nanoseconds: 300_000_000)
                    await updateState(.completed)

                    let result = GenerationResult(
                        image: image,
                        imageURL: url,
                        prompt: prompt,
                        usedProvider: provider
                    )
                    await MainActor.run { completion(.success(result)) }
                    return

                } catch {
                    lastError = error
                    if shouldMarkCooldown(for: error) {
                        markCooldown(provider)
                        logger.warning("Provider \(provider.description) throttled, switching next.")
                    } else {
                        logger.error("Provider \(provider.description) failed: \(error.localizedDescription)")
                    }
                }
            }

            await updateState(.failed(lastError.localizedDescription))
            await MainActor.run { completion(.failure(lastError)) }
        }
    }

    func cancelGeneration() {
        downloadTask?.cancel()
        Task { await updateState(.idle) }
    }

    // MARK: - Provider Availability

    private func isAvailable(_ provider: ImageProvider) -> Bool {
        guard let cooldownEnd = providerCooldowns[provider] else { return true }
        return Date() > cooldownEnd
    }

    private func markCooldown(_ provider: ImageProvider) {
        providerCooldowns[provider] = Date().addingTimeInterval(cooldownDuration)
    }

    private func shouldMarkCooldown(for error: Error) -> Bool {
        if let e = error as? GenerationError, case .httpError(let code) = e {
            return code == 400 || code == 429 || code == 503 || (code >= 500 && code < 600)
        }
        return false
    }

    // MARK: - Generation Dispatch

    private func generate(
        prompt: String,
        provider: ImageProvider,
        options: GenerationOptions
    ) async throws -> (UIImage, URL?) {
        switch provider {
        case .pollinations(let model):
            let url = try buildPollinationsURL(prompt: prompt, model: model, options: options)
            let image = try await downloadImage(from: url)
            return (image, url)

        case .huggingFace(let model):
            let image = try await generateWithHuggingFace(
                prompt: prompt,
                model: model,
                options: options
            )
            return (image, nil)

        case .openRouter:
            return try await generateWithOpenRouter(
                prompt: prompt,
                options: options
            )
        }
    }

    // MARK: - Pollinations

    private func buildPollinationsURL(
        prompt: String,
        model: Model,
        options: GenerationOptions
    ) throws -> URL {
        guard let encodedPrompt = prompt.addingPercentEncoding(
            withAllowedCharacters: .urlPathAllowed
        ) else {
            throw GenerationError.invalidPrompt
        }

        var components = URLComponents(
            string: "\(AIConfig.shared.pollinationsBaseURL)/\(encodedPrompt)"
        )!

        var queryItems: [URLQueryItem] = [
            URLQueryItem(name: "model",  value: model.rawValue),
            URLQueryItem(name: "width",  value: "\(options.width)"),
            URLQueryItem(name: "height", value: "\(options.height)"),
        ]
        if let seed = options.seed {
            queryItems.append(URLQueryItem(name: "seed", value: "\(seed)"))
        }
        if options.nologo {
            queryItems.append(URLQueryItem(name: "nologo", value: "true"))
        }
        if options.enhance {
            queryItems.append(URLQueryItem(name: "enhance", value: "true"))
        }
        let apiKey = AIConfig.shared.pollinationsApiKey
        if !apiKey.isEmpty {
            queryItems.append(URLQueryItem(name: "key", value: apiKey))
        }

        components.queryItems = queryItems
        guard let url = components.url else { throw GenerationError.invalidURL }
        return url
    }

    // MARK: - HuggingFace

    private func generateWithHuggingFace(
        prompt: String,
        model: HuggingFaceModel,
        options: GenerationOptions
    ) async throws -> UIImage {
        let endpoint = "\(AIConfig.shared.huggingFaceBaseURL)/\(model.rawValue)"
        guard let url = URL(string: endpoint) else { throw GenerationError.invalidURL }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 120

        let effectiveToken = options.huggingFaceToken
            ?? (AIConfig.shared.huggingFaceToken.isEmpty ? nil : AIConfig.shared.huggingFaceToken)
        if let token = effectiveToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        let body: [String: Any] = [
            "inputs": prompt,
            "parameters": [
                "width": options.width,
                "height": options.height,
                "num_inference_steps": model == .fluxSchnell ? 4 : 20,
            ],
        ]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 120
        config.timeoutIntervalForResource = 180

        let (data, response) = try await URLSession(configuration: config).data(for: request)

        if let http = response as? HTTPURLResponse, http.statusCode != 200 {
            throw GenerationError.httpError(http.statusCode)
        }

        guard let image = UIImage(data: data) else {
            throw GenerationError.invalidImageData
        }
        return image
    }

    // MARK: - OpenRouter

    private func generateWithOpenRouter(
            prompt: String,
            options: GenerationOptions
        ) async throws -> (UIImage, URL?) {

            let apiKey = options.openRouterApiKey ?? AIConfig.shared.openRouterApiKey
            guard !apiKey.isEmpty else {
                throw GenerationError.missingAPIKey
            }

            let modelID = AIConfig.shared.openRouterImageModel

            var baseStr = AIConfig.shared.openRouterBaseURL
            if baseStr.hasSuffix("/") { baseStr = String(baseStr.dropLast()) }

            let endpoint: String
            if !baseStr.hasSuffix("/chat/completions") {
                endpoint = "\(baseStr)/chat/completions"
            } else {
                endpoint = baseStr
            }

            let body: [String: Any] = [
                "model": modelID,
                "modalities": ["image", "text"],
                "messages": [["role": "user", "content": prompt]]
            ]

            guard let url = URL(string: endpoint) else {
                throw GenerationError.invalidURL
            }

            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.timeoutInterval = 60
            request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.setValue("AIDream", forHTTPHeaderField: "X-Title")
            request.httpBody = try JSONSerialization.data(withJSONObject: body)

            let config = URLSessionConfiguration.ephemeral
            config.timeoutIntervalForRequest = 60

            let (data, response) = try await URLSession(configuration: config).data(for: request)

            if let http = response as? HTTPURLResponse, http.statusCode != 200 {
                throw GenerationError.httpError(http.statusCode)
            }

            guard let dataString = extractOpenRouterImageDataURL(from: data) else {
                throw GenerationError.invalidImageData
            }

            if dataString.hasPrefix("http://") || dataString.hasPrefix("https://") {
                if let remoteURL = URL(string: dataString) {
                    let image = try await downloadImageWithoutDelegate(from: remoteURL)
                    return (image, remoteURL)
                }
            }

            var cleanBase64 = dataString
            if dataString.hasPrefix("data:image") {
                let components = dataString.components(separatedBy: ",")
                if components.count > 1, let last = components.last {
                    cleanBase64 = last
                }
            }

            if let imageData = Data(base64Encoded: cleanBase64, options: .ignoreUnknownCharacters),
               let image = UIImage(data: imageData) {
                return (image, nil)
            }

            throw GenerationError.invalidImageData
        }

    private func extractOpenRouterImageDataURL(from data: Data) -> String? {
            guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                return nil
            }

            if let choices = json["choices"] as? [[String: Any]], !choices.isEmpty,
               let message = choices[0]["message"] as? [String: Any] {

                if let images = message["images"] as? [[String: Any]] {
                    for image in images {
                        if let imageURL = image["image_url"] as? [String: Any], let url = imageURL["url"] as? String { return url }
                        if let imageURL = image["imageUrl"] as? [String: Any], let url = imageURL["url"] as? String { return url }
                    }
                }

                if let content = message["content"] as? String, content.hasPrefix("data:image") {
                    return content
                }
            }

            if let dataArray = json["data"] as? [[String: Any]] {
                for item in dataArray {
                    if let url = item["url"] as? String { return url }
                    if let b64 = item["b64_json"] as? String { return b64 }
                }
            }

            return nil
        }

    // MARK: - Download Helpers

    private func downloadImage(from url: URL) async throws -> UIImage {
        return try await withCheckedThrowingContinuation { continuation in
            let config = URLSessionConfiguration.default
            config.timeoutIntervalForRequest = 60
            config.timeoutIntervalForResource = 120

            let session = URLSession(
                configuration: config,
                delegate: DownloadDelegate { [weak self] progress in
                    Task {
                        await self?.updateState(.downloading(progress))
                        await self?.updateProgress(progress)
                    }
                },
                delegateQueue: nil
            )

            downloadTask = session.downloadTask(with: url) { localURL, response, error in
                if let error = error {
                    continuation.resume(throwing: GenerationError.networkError(error))
                    return
                }
                if let http = response as? HTTPURLResponse, http.statusCode != 200 {
                    continuation.resume(throwing: GenerationError.httpError(http.statusCode))
                    return
                }
                guard
                    let localURL = localURL,
                    let data = try? Data(contentsOf: localURL),
                    let image = UIImage(data: data)
                else {
                    continuation.resume(throwing: GenerationError.invalidImageData)
                    return
                }
                continuation.resume(returning: image)
            }
            downloadTask?.resume()
        }
    }

    private func downloadImageWithoutDelegate(from url: URL) async throws -> UIImage {
        let (data, response) = try await URLSession.shared.data(from: url)
        if let http = response as? HTTPURLResponse, http.statusCode != 200 {
            throw GenerationError.httpError(http.statusCode)
        }
        guard let image = UIImage(data: data) else {
            throw GenerationError.invalidImageData
        }
        return image
    }

    // MARK: - State / Progress Helpers

    private func updateState(_ state: GenerationState) async {
        await MainActor.run { self.stateChangeHandler?(state) }
    }

    private func updateProgress(_ progress: Double) async {
        await MainActor.run { self.progressHandler?(progress) }
    }

    // MARK: - Error Types

    enum GenerationError: LocalizedError {
        case invalidPrompt
        case invalidURL
        case networkError(Error)
        case invalidImageData
        case httpError(Int)
        case missingAPIKey
        case allProvidersFailed

        var errorDescription: String? {
            switch self {
            case .invalidPrompt:       return "Invalid prompt"
            case .invalidURL:          return "Failed to build URL"
            case .networkError(let e): return "Network error: \(e.localizedDescription)"
            case .invalidImageData:    return "Failed to parse image data"
            case .httpError(let code): return "Server error: HTTP \(code)"
            case .missingAPIKey:        return "Missing API key"
            case .allProvidersFailed:  return "All image providers failed, please try again later"
            }
        }
    }
}

// MARK: - URLSessionDownloadDelegate

private class DownloadDelegate: NSObject, URLSessionDownloadDelegate {
    private let progressHandler: (Double) -> Void

    init(progressHandler: @escaping (Double) -> Void) {
        self.progressHandler = progressHandler
    }

    func urlSession(
        _ session: URLSession,
        downloadTask: URLSessionDownloadTask,
        didWriteData bytesWritten: Int64,
        totalBytesWritten: Int64,
        totalBytesExpectedToWrite: Int64
    ) {
        let progress = Double(totalBytesWritten) / Double(totalBytesExpectedToWrite)
        progressHandler(progress)
    }

    func urlSession(
        _ session: URLSession,
        downloadTask: URLSessionDownloadTask,
        didFinishDownloadingTo location: URL
    ) {}
}
