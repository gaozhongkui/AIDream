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
        collectionView.backgroundColor = .clear // 使用容器背景
        collectionView.register(VideoCell.self, forCellWithReuseIdentifier: VideoCell.identifier)
        collectionView.register(LoadingFooterView.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionFooter, withReuseIdentifier: LoadingFooterView.identifier)
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.alwaysBounceVertical = true
        collectionView.refreshControl = refreshControl
        // 增加顶部间距，适应大标题
        collectionView.contentInset = UIEdgeInsets(top: 10, left: 16, bottom: 30, right: 16)
        return collectionView
    }()

    private let refreshControl: UIRefreshControl = {
        let rc = UIRefreshControl()
        rc.tintColor = UIColor(red: 0.3, green: 0.62, blue: 1.0, alpha: 1) // 匹配 accentPrimary
        return rc
    }()

    private let activityIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .large)
        indicator.color = UIColor(red: 0/255, green: 242/255, blue: 255/255, alpha: 1) // 匹配 accentSecondary
        indicator.hidesWhenStopped = true
        return indicator
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Inspiration"
        view.backgroundColor = UIColor(red: 5/255, green: 5/255, blue: 5/255, alpha: 1) // AppTheme.bgPrimary
        setupNavigationBar()
        setupUI()
        setupRefreshControl()

        loadCachedData()
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
        appearance.configureWithTransparentBackground()
        appearance.backgroundColor = .clear

        let accentColor = UIColor(red: 0.3, green: 0.62, blue: 1.0, alpha: 1) // accentPrimary

        appearance.largeTitleTextAttributes = [
            .foregroundColor: UIColor.white,
            .font: UIFont.systemFont(ofSize: 34, weight: .black),
            .kern: 0.5
        ]
        appearance.titleTextAttributes = [
            .foregroundColor: UIColor.white,
            .font: UIFont.systemFont(ofSize: 18, weight: .bold)
        ]

        navigationController?.navigationBar.standardAppearance = appearance
        navigationController?.navigationBar.scrollEdgeAppearance = appearance
        navigationController?.navigationBar.tintColor = accentColor
    }

    private func setupUI() {
        // 添加一个微弱的顶部光晕背景装饰（可选，增强科幻感）
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
            if allVideos.isEmpty {
                activityIndicator.startAnimating()
            }
        } else if !hasMorePages {
            return
        }

        isLoadingPage = true
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
                        VideoCacheService.shared.saveVideos(videos)
                    }

                    self.append(videos: videos)
                    let newVideoCount = self.allVideos.count
                    self.currentOffset += self.pageSize
                    self.hasMorePages = true

                    if reset {
                        self.collectionView.reloadData()
                    } else {
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

    private func presentDetail(at indexPath: IndexPath) {
        let detailVC = VideoDetailViewController(videos: allVideos, initialIndex: indexPath.item)
        present(detailVC, animated: true)
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
        presentDetail(at: indexPath)
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
        let finalRatio = max(0.8, min(aspectRatio, 1.5))
        return width * finalRatio
    }

    func collectionView(_ collectionView: UICollectionView, columnSpanForItemAt indexPath: IndexPath) -> Int {
        return 1
    }

    func collectionView(_ collectionView: UICollectionView, heightForFullWidthItemAt indexPath: IndexPath, with width: CGFloat) -> CGFloat {
        return 0
    }

    func collectionView(_ collectionView: UICollectionView, heightForFooterIn section: Int, contentHeight: CGFloat, availableHeight: CGFloat) -> CGFloat {
        return allVideos.isEmpty ? 0 : 80
    }
}
