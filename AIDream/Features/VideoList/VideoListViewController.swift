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
        collectionView.register(LoadingFooterView.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionFooter, withReuseIdentifier: LoadingFooterView.identifier)
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

    private let activityIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .large)
        indicator.color = .systemPink
        indicator.hidesWhenStopped = true
        return indicator
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "探索灵感"
        view.backgroundColor = .systemBackground
        setupNavigationBar()
        setupUI()
        setupRefreshControl()

        // 1. 优先加载缓存数据
        loadCachedData()

        // 2. 发起网络请求
        loadPage(reset: true)
    }

    private func loadCachedData() {
        let cachedVideos = VideoCacheService.shared.loadVideos()
        if !cachedVideos.isEmpty {
            self.allVideos = cachedVideos
            self.collectionView.reloadData()
        }
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
        view.addSubview(activityIndicator)

        collectionView.translatesAutoresizingMaskIntoConstraints = false
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: view.topAnchor),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
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
            // 如果目前没数据（包括缓存也为空），才显示中间的大 Loading
            if allVideos.isEmpty {
                activityIndicator.startAnimating()
            }
        } else if !hasMorePages {
            return
        }

        isLoadingPage = true

        // 优化：加载更多时，不全量 reloadData，避免重置已有 Cell 的播放状态
        if reset {
            collectionView.reloadData()
        } else {
            updateFooterStatus()
        }

        VideoService.shared.fetchVideos(offset: currentOffset, limit: pageSize) { [weak self] result in
            DispatchQueue.main.async {
                guard let self else { return }
                self.refreshControl.endRefreshing()
                self.activityIndicator.stopAnimating()
                self.isLoadingPage = false

                switch result {
                case .success(let videos):
                    let oldVideoCount = self.allVideos.count
                    if reset {
                        self.allVideos = []
                        // 第一页请求成功后，同步更新缓存
                        VideoCacheService.shared.saveVideos(videos)
                    }

                    self.append(videos: videos)
                    let newVideoCount = self.allVideos.count
                    self.currentOffset += videos.count
                    self.hasMorePages =  true //videos.count == self.pageSize

                    if reset {
                        // 刷新或首次加载，全量更新
                        self.collectionView.reloadData()
                    } else {
                        // 加载更多：仅插入新行，保持列表滚动位置和现有视频的播放
                        let indexPaths = (oldVideoCount..<newVideoCount).map { IndexPath(item: $0, section: 0) }
                        if !indexPaths.isEmpty {
                            self.collectionView.insertItems(at: indexPaths)
                        } else {
                            self.updateFooterStatus()
                        }
                    }
                case .failure(let error):
                    print("Video fetch error: \(error)")
                    self.updateFooterStatus()
                }
            }
        }
    }

    private func updateFooterStatus() {
        let indexPath = IndexPath(item: 0, section: 0)
        if let footer = collectionView.supplementaryView(forElementKind: UICollectionView.elementKindSectionFooter, at: indexPath) as? LoadingFooterView {
            footer.setStatus(isLoading: isLoadingPage, hasMore: hasMorePages)
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

    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        if kind == UICollectionView.elementKindSectionFooter {
            let footer = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: LoadingFooterView.identifier, for: indexPath) as! LoadingFooterView
            footer.setStatus(isLoading: isLoadingPage, hasMore: hasMorePages)
            return footer
        }
        return UICollectionReusableView()
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

    func collectionView(_ collectionView: UICollectionView, heightForFooterIn section: Int, contentHeight: CGFloat, availableHeight: CGFloat) -> CGFloat {
        // 只要有数据就显示 Footer（用于显示加载转圈或“到底了”提示）
        return allVideos.isEmpty ? 0 : 60
    }
}
