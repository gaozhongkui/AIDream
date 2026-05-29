//
//  AIDreamTests.swift
//  AIDreamTests
//
//  Created by  高中奎 on 2026/5/28.
//

import Testing
@testable import AIDream

struct AIDreamTests {
    @Test func filterOptionsAreBuiltFromTypes() async throws {
        let videos = [
            VideoData(
                workId: 1,
                type: "m2v_txt2video",
                status: 99,
                contentType: "video",
                resource: MediaResource(resource: "https://example.com/video1.mp4", height: 720, width: 1280, duration: 5100),
                cover: nil,
                starNum: nil,
                reportNum: nil,
                createTime: 1,
                taskInfo: TaskInfo(),
                publishStatus: "published",
                deleted: false,
                title: "A",
                introduction: nil,
                publishTime: nil,
                submitTime: nil
            ),
            VideoData(
                workId: 2,
                type: "m2v_img2video_hq",
                status: 99,
                contentType: "video",
                resource: MediaResource(resource: "https://example.com/video2.mp4", height: 720, width: 720, duration: 4200),
                cover: nil,
                starNum: nil,
                reportNum: nil,
                createTime: 2,
                taskInfo: TaskInfo(),
                publishStatus: "published",
                deleted: false,
                title: "B",
                introduction: nil,
                publishTime: nil,
                submitTime: nil
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
            type: "m2v_txt2video",
            status: 99,
            contentType: "video",
            resource: MediaResource(resource: "https://example.com/video.mp4", height: 720, width: 1280, duration: 5100),
            cover: MediaResource(resource: "https://example.com/cover.jpg", height: 720, width: 1280, duration: 0),
            starNum: 3,
            reportNum: 0,
            createTime: 1,
            taskInfo: TaskInfo(arguments: [TaskArgument(name: "prompt", value: "Create a photorealistic catwalk scene")]),
            publishStatus: "published",
            deleted: false,
            title: "Catwalk Scene",
            introduction: "A photorealistic catwalk scene",
            publishTime: 2,
            submitTime: 3
        )

        #expect(video.displayTitle == "Catwalk Scene")
        #expect(video.promptText == "Create a photorealistic catwalk scene")
        #expect(video.secondaryText == "A photorealistic catwalk scene")
        #expect(video.durationText == "5s")
    }
}
