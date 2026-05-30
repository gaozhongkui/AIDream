import Testing
@testable import AIDream

struct AIDreamTests {
    @Test func filterOptionsAreBuiltFromTypes() async throws {
        let videos = [
            VideoData(
                workId: 1,
                workItemId: nil,
                taskId: nil,
                userId: nil,
                type: "m2v_txt2video",
                status: 99,
                contentType: "video",
                resource: MediaResource(resource: "https://example.com/video1.mp4", height: 720, width: 1280, duration: 5100),
                cover: MediaResource(resource: "https://example.com/cover1.jpg", height: 720, width: 1280, duration: 0),
                starNum: nil,
                reportNum: nil,
                createTime: 1,
                taskInfo: TaskInfo(arguments: [TaskArgument(name: "prompt", value: "Prompt 1")]),
                selfAttitude: nil,
                selfComment: nil,
                favored: nil,
                starred: nil,
                publishStatus: "published",
                deleted: false,
                title: "Video 1",
                userProfile: nil,
                publishTime: nil,
                submitTime: nil,
                lipSyncStatus: nil,
                introduction: nil
            ),
            VideoData(
                workId: 2,
                workItemId: nil,
                taskId: nil,
                userId: nil,
                type: "m2v_img2video_hq",
                status: 99,
                contentType: "video",
                resource: MediaResource(resource: "https://example.com/video2.mp4", height: 720, width: 720, duration: 4200),
                cover: MediaResource(resource: "https://example.com/cover2.jpg", height: 720, width: 720, duration: 0),
                starNum: nil,
                reportNum: nil,
                createTime: 2,
                taskInfo: TaskInfo(),
                selfAttitude: nil,
                selfComment: nil,
                favored: nil,
                starred: nil,
                publishStatus: "published",
                deleted: false,
                title: "Video 2",
                userProfile: nil,
                publishTime: nil,
                submitTime: nil,
                lipSyncStatus: nil,
                introduction: nil
            )
        ]

        let options = VideoFilterOption.options(from: videos)
        #expect(options.first == .all)
        #expect(options.contains(where: { $0.id == "m2v_txt2video" }))
        #expect(options.contains(where: { $0.id == "m2v_img2video_hq" }))
    }

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

    @Test func displayCategoryFormatsCorrectly() async throws {
        #expect(VideoData.displayCategory("m2v_txt2video") == "文生视频")
        #expect(VideoData.displayCategory("m2v_img2video_hq") == "图生视频")
        #expect(VideoData.displayCategory("dynamic_attribute_binding") == "Dynamic Attribute Binding")
    }
}
