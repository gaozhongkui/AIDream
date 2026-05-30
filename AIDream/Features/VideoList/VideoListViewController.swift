import AVKit
import UIKit

final class VideoListViewController: UIViewController {
    private let pageSize = 20
    private var allVideos: [VideoData] = []
    private var currentOffset = 0
    private var isLoadingPage = false
    private var hasMorePages = true

    private lazy var collectionView: UICollectionView = {
        let layout = WaterfallLayout()
        layout.delegate = self

        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .systemBackground
        collectionView.register(VideoCell.self, forCellWithReuseIdentifier: VideoCell.identifier)
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.alwaysBounceVertical = true
        collectionView.refreshControl = refreshControl
        collectionView.contentInset = UIEdgeInsets(top: 12, left: 12, bottom: 24, right: 12)
        return collectionView
    }()

    private let refreshControl: UIRefreshControl = {
        let rc = UIRefreshControl()
        rc.tintColor = .systemPink
        return rc
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "探索灵感"
        view.backgroundColor = .systemBackground
        setupNavigationBar()
        setupUI()
        setupRefreshControl()
        loadPage(reset: true)
    }

    private func setupNavigationBar() {
        navigationController?.navigationBar.prefersLargeTitles = true
        let appearance = UINavigationBarAppearance()
        appearance.configureWithDefaultBackground()
        appearance.backgroundColor = .systemBackground
        navigationController?.navigationBar.standardAppearance = appearance
        navigationController?.navigationBar.scrollEdgeAppearance = appearance
    }

    private func setupUI() {
        view.addSubview(collectionView)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: view.topAnchor),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    private func setupRefreshControl() {
        refreshControl.addTarget(self, action: #selector(handleRefresh), for: .valueChanged)
    }

    @objc private func handleRefresh() {
        loadPage(reset: true)
    }

    private func loadPage(reset: Bool) {
        guard !isLoadingPage else { return }

        if reset {
            currentOffset = 0
            hasMorePages = true
        } else if !hasMorePages {
            return
        }

        isLoadingPage = true

        VideoService.shared.fetchVideos(offset: currentOffset, limit: pageSize) { [weak self] result in
            DispatchQueue.main.async {
                guard let self else { return }
                self.refreshControl.endRefreshing()
                self.isLoadingPage = false

                switch result {
                case .success(let videos):
                    if reset {
                        self.allVideos = []
                    }
                    self.append(videos: videos)
                    self.currentOffset += videos.count
                    self.hasMorePages = videos.count == self.pageSize
                    self.collectionView.reloadData()
                case .failure(let error):
                    print("Video fetch error: \(error)")
                }
            }
        }
    }

    private func append(videos: [VideoData]) {
        var seenIDs = Set(allVideos.map(\.id))
        for video in videos where seenIDs.insert(video.id).inserted {
            allVideos.append(video)
        }
    }

    private func presentPlayer(for video: VideoData) {
        guard let url = video.videoURL else { return }
        let player = AVPlayer(url: url)
        let viewController = AVPlayerViewController()
        viewController.player = player
        present(viewController, animated: true) {
            player.play()
        }
    }
}

extension VideoListViewController: UICollectionViewDataSource, UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return allVideos.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: VideoCell.identifier, for: indexPath) as! VideoCell
        cell.configure(with: allVideos[indexPath.item])
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        presentPlayer(for: allVideos[indexPath.item])
    }

    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        (cell as? VideoCell)?.startPlayback()
        if indexPath.item >= allVideos.count - 4 {
            loadPage(reset: false)
        }
    }

    func collectionView(_ collectionView: UICollectionView, didEndDisplaying cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        (cell as? VideoCell)?.stopPlayback()
    }
}

extension VideoListViewController: WaterfallLayoutDelegate {
    func collectionView(_ collectionView: UICollectionView, heightForItemAt indexPath: IndexPath, with width: CGFloat) -> CGFloat {
        let video = allVideos[indexPath.item]
        let aspectRatio = CGFloat(video.height) / CGFloat(video.width)

        // 核心优化：强制设置一个最小比例（0.75，即 3:4）
        // 这样横屏视频（如 16:9 的 0.56）也会被拉高到 0.75，聚焦中心内容，视觉上更清晰饱满
        // 同时限制最高比例为 1.6，防止极长图破坏平衡
        let finalRatio = max(0.75, min(aspectRatio, 1.6))
        return width * finalRatio
    }

    func collectionView(_ collectionView: UICollectionView, columnSpanForItemAt indexPath: IndexPath) -> Int {
        // 强制回归单列显示，确保布局严丝合缝，消除杂乱的空白死角
        return 1
    }

    func collectionView(_ collectionView: UICollectionView, heightForFullWidthItemAt indexPath: IndexPath, with width: CGFloat) -> CGFloat {
        return 0
    }
}
