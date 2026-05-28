import Foundation

class VideoService {
    static let shared = VideoService()

    func fetchVideos(completion: @escaping (Result<[VideoData], Error>) -> Void) {
        let urlString = "https://datasets-server.huggingface.co/rows?dataset=Rapidata/awesome-text2video-prompts&config=default&split=train&offset=0&limit=20"
        guard let url = URL(string: urlString) else { return }

        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }

            guard let data = data else { return }

            do {
                let decodedResponse = try JSONDecoder().decode(HFResponse.self, from: data)
                let videos = decodedResponse.rows.map { $0.row }
                completion(.success(videos))
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
}
