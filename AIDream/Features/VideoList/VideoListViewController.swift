import AVKit
import UIKit

final class VideoListViewController: UIViewController {
    private let pageSize = 20
    private var allVideos: [VideoData] = []
    private var filteredVideos: [VideoData] = []
    private var currentOffset = 0
    private var isLoadingPage = false
    private var hasMorePages = true

    private lazy var collectionView: UICollectionView = {
        let layout = WaterfallLayout()
        layout.delegate = self
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .clear
        collectionView.register(VideoCell.self, forCellWithReuseIdentifier: VideoCell.identifier)
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.alwaysBounceVertical = true
        collectionView.refreshControl = refreshControl
        return collectionView
    }()

    private let refreshControl = UIRefreshControl()

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "发现灵感"
        view.backgroundColor = .systemGroupedBackground
        setupNavigationBar()
        setupUI()
        setupRefreshControl()
        loadPage(reset: true)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        playVisibleCells()
    }

    private func setupNavigationBar() {
        navigationController?.navigationBar.prefersLargeTitles = true
        let appearance = UINavigationBarAppearance()
        appearance.configureWithTransparentBackground()
        appearance.backgroundColor = .systemGroupedBackground.withAlphaComponent(0.9)
        navigationController?.navigationBar.standardAppearance = appearance
        navigationController?.navigationBar.scrollEdgeAppearance = appearance
    }

    private func setupUI() {
        view.addSubview(collectionView)

        collectionView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
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
                    self.filteredVideos = self.allVideos
                    self.reloadVideos(loadMoreIfNeeded: true)
                case .failure(let error):
                    print("Video fetch error: \(error)")
                }
            }
        }
    }

    private func loadMoreIfNeeded(for indexPath: IndexPath) {
        guard indexPath.item >= filteredVideos.count - 4 else { return }
        guard hasMorePages, !isLoadingPage else { return }
        loadPage(reset: false)
    }

    private func append(videos: [VideoData]) {
        guard !videos.isEmpty else { return }

        var seenIDs = Set(allVideos.map(\.id))
        for video in videos where seenIDs.insert(video.id).inserted {
            allVideos.append(video)
        }
    }

    private func reloadVideos(loadMoreIfNeeded: Bool = false) {
        collectionView.collectionViewLayout.invalidateLayout()
        collectionView.reloadData()

        DispatchQueue.main.async { [weak self] in
            self?.playVisibleCells()
            if loadMoreIfNeeded, let self, self.filteredVideos.isEmpty {
                self.loadPage(reset: false)
            }
        }
    }

    private func playVisibleCells() {
        for case let cell as VideoCell in collectionView.visibleCells {
            cell.startPlayback()
        }
    }

    private func presentPlayer(for video: VideoData) {
        guard let url = video.videoURL else { return }

        let player = AVPlayer(url: url)
        player.automaticallyWaitsToMinimizeStalling = true

        let viewController = AVPlayerViewController()
        viewController.player = player
        viewController.modalPresentationStyle = .fullScreen

        present(viewController, animated: true) {
            player.play()
        }
    }


}

extension VideoListViewController: UICollectionViewDataSource, UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        filteredVideos.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: VideoCell.identifier, for: indexPath) as? VideoCell else {
            return UICollectionViewCell()
        }
        cell.configure(with: filteredVideos[indexPath.item])
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        presentPlayer(for: filteredVideos[indexPath.item])
    }

    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        guard let videoCell = cell as? VideoCell else { return }
        videoCell.startPlayback()
        loadMoreIfNeeded(for: indexPath)
    }

    func collectionView(_ collectionView: UICollectionView, didEndDisplaying cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        guard let videoCell = cell as? VideoCell else { return }
        videoCell.stopPlayback()
    }
}

extension VideoListViewController: WaterfallLayoutDelegate {
    func collectionView(_ collectionView: UICollectionView, heightForItemAt indexPath: IndexPath, with width: CGFloat) -> CGFloat {
        let video = filteredVideos[indexPath.item]
        return width / max(video.aspectRatio, 0.3)
    }
}
