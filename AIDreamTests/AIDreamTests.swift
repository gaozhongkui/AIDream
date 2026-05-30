import Testing
@testable import AIDream

struct AIDreamTests {
    @Test func videoDataDerivesDisplayFields() async throws {
        let video = VideoData(
            workId: 1,
            workItemId: 0,
            taskId: 96941141,
            userId: 6628016,
            type: "m2v_txt2video",
            status: 99,
            contentType: "video",
            resource: MediaResource(resource: "https://example.com/video.mp4", height: 720, width: 1280, duration: 5100),
            cover: MediaResource(resource: "https://example.com/cover.jpg", height: 720, width: 1280, duration: 0),
            starNum: 3,
            reportNum: 0,
            createTime: 1,
            taskInfo: TaskInfo(arguments: [TaskArgument(name: "prompt", value: "Create a photorealistic catwalk scene")]),
            selfAttitude: "unknown",
            selfComment: SelfComment(tags: [], content: "", prompts: []),
            favored: false,
            starred: false,
            publishStatus: "published",
            deleted: false,
            title: "Catwalk Scene",
            userProfile: UserProfile(
                userId: 6628016,
                userName: "KLING8016",
                userAvatar: [],
                introduction: "",
                features: [],
                enableConsole: false,
                enableInvoiceTitleCollection: true,
                kol: false
            ),
            publishTime: 2,
            submitTime: 3,
            lipSyncStatus: 99,
            introduction: "A photorealistic catwalk scene"
        )

        #expect(video.displayTitle == "Catwalk Scene")
        #expect(video.prompt == "Create a photorealistic catwalk scene")
        #expect(video.secondaryText == "A photorealistic catwalk scene")
        #expect(video.durationText == "5s")
        #expect(video.videoURL == URL(string: "https://example.com/video.mp4"))
        #expect(video.coverURL == URL(string: "https://example.com/cover.jpg"))
        #expect(video.category == "m2v_txt2video")
    }
}
