import Foundation

class VideoService {
    static let shared = VideoService()

    func fetchVideos(completion: @escaping (Result<[VideoData], Error>) -> Void) {
        fetchVideos(offset: 0, limit: 20, completion: completion)
    }
    
    //https://datasets-server.huggingface.co/rows?dataset=nyuuzyou/klingai&config=default&split=train&offset=0&limit=2

    func fetchVideos(offset: Int, limit: Int, completion: @escaping (Result<[VideoData], Error>) -> Void) {
        var components = URLComponents(string: "https://datasets-server.huggingface.co/rows")
        components?.queryItems = [
            URLQueryItem(name: "dataset", value: "nyuuzyou/klingai"),
            URLQueryItem(name: "config", value: "default"),
            URLQueryItem(name: "split", value: "train"),
            URLQueryItem(name: "offset", value: String(offset)),
            URLQueryItem(name: "limit", value: String(limit))
        ]

        guard let url = components?.url else {
            completion(.failure(URLError(.badURL)))
            return
        }

        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                Task { @MainActor in
                    completion(.failure(error))
                }
                return
            }

            guard let data = data else {
                Task { @MainActor in
                    completion(.failure(URLError(.badServerResponse)))
                }
                return
            }

            Task { @MainActor in
                do {
                    let decodedResponse = try JSONDecoder().decode(HFResponse.self, from: data)
                    let videos = decodedResponse.rows.map { $0.row.toVideoData() }
                    completion(.success(videos))
                } catch {
                    completion(.failure(error))
                }
            }
        }.resume()
    }
}
