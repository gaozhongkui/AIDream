import Testing
@testable import AIDream

struct AIDreamTests {
    @Test func filterOptionsAreBuiltFromCategories() async throws {
        let videos = [
            VideoData(
                prompt: "Dolphins and astronauts floating together",
                video: "https://assets.rapidata.ai/002_20250114_sora.gif",
                category: "ObjectInteractionsScenes",
                videoName: "002_20250114_sora.mp4"
            ),
            VideoData(
                prompt: "Camera spirals down around tall redwood trees",
                video: "https://assets.rapidata.ai/029_20250114_sora.gif",
                category: "CameraMovements",
                videoName: "029_20250114_sora.mp4"
            )
        ]

        let options = VideoFilterOption.options(from: videos)
        #expect(options.first == .all)
        #expect(options.contains(where: { $0.id == "CameraMovements" }))
        #expect(options.contains(where: { $0.id == "ObjectInteractionsScenes" }))
    }

    @Test func videoDataDerivesDisplayFields() async throws {
        let video = VideoData(
            prompt: "Dolphins and astronauts floating together in underwater space station",
            video: "https://assets.rapidata.ai/002_20250114_sora.gif",
            category: "ObjectInteractionsScenes",
            videoName: "002_20250114_sora.mp4"
        )

        #expect(video.displayTitle == "Dolphins and astronauts floating together in underwater space station")
        #expect(video.id == "002_20250114_sora.mp4")
        #expect(video.videoURL == URL(string: "https://assets.rapidata.ai/002_20250114_sora.mp4"))
        #expect(video.coverURL == URL(string: "https://assets.rapidata.ai/002_20250114_sora.gif"))
        #expect(video.aspectRatio == 16.0 / 9.0)
    }

    @Test func displayCategoryFormatsCorrectly() async throws {
        #expect(VideoData.displayCategory("CameraMovements") == "Camera Movements")
        #expect(VideoData.displayCategory("ObjectInteractionsScenes") == "Object Interactions Scenes")
        #expect(VideoData.displayCategory("DynamicAttributeBinding") == "Dynamic Attribute Binding")
    }
}
