import Foundation

class VideoService {
    static let shared = VideoService()

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
                DispatchQueue.main.async { completion(.failure(error)) }
                return
            }

            guard let data = data else {
                DispatchQueue.main.async { completion(.failure(URLError(.badServerResponse))) }
                return
            }

            do {
                let decodedResponse = try JSONDecoder().decode(HFResponse.self, from: data)
                let videos = decodedResponse.rows.map { $0.row.toVideoData() }
                DispatchQueue.main.async {
                    completion(.success(videos))
                }
            } catch {
                DispatchQueue.main.async { completion(.failure(error)) }
            }
        }.resume()
    }
}
