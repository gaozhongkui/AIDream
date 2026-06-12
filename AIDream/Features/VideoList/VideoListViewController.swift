import AVKit
import UIKit

final class VideoListViewController: UIViewController {
    private let pageSize = 20
    private var allVideos: [VideoData] = []
    private var currentOffset = 0
    private var isLoadingPage = false
    private var hasMorePages = true

    // MARK: - Custom Header
    private let headerContainer: UIView = {
        let view = UIView()
        view.backgroundColor = .clear
        return view
    }()

    private let headerTitleLabel: UILabel = {
        let label = UILabel()
        label.text = "Explore"
        label.font = .systemFont(ofSize: 32, weight: .black)
        label.textColor = .white
        return label
    }()

    private let headerSubtitleLabel: UILabel = {
        let label = UILabel()
        label.text = "Discover AI-generated masterpieces"
        label.font = .systemFont(ofSize: 13, weight: .medium)
        label.textColor = UIColor.white.withAlphaComponent(0.4)
        return label
    }()

    // MARK: - Collection View
    private lazy var collectionView: UICollectionView = {
        let layout = WaterfallLayout()
        layout.delegate = self

        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .clear
        collectionView.register(VideoCell.self, forCellWithReuseIdentifier: VideoCell.identifier)
        collectionView.register(LoadingFooterView.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionFooter, withReuseIdentifier: LoadingFooterView.identifier)
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.alwaysBounceVertical = true
        collectionView.refreshControl = refreshControl
        collectionView.contentInset = UIEdgeInsets(top: 0, left: 10, bottom: 30, right: 10)
        return collectionView
    }()

    private let refreshControl: UIRefreshControl = {
        let rc = UIRefreshControl()
        rc.tintColor = UIColor(red: 0.3, green: 0.62, blue: 1.0, alpha: 1)
        let attributes: [NSAttributedString.Key: Any] = [
            .foregroundColor: UIColor.white.withAlphaComponent(0.5),
            .font: UIFont.systemFont(ofSize: 12, weight: .medium)
        ]
        rc.attributedTitle = NSAttributedString(string: "Pull to refresh", attributes: attributes)
        return rc
    }()

    private let activityIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .large)
        indicator.color = UIColor(red: 0.3, green: 0.62, blue: 1.0, alpha: 1)
        indicator.hidesWhenStopped = true
        return indicator
    }()

    // MARK: - Empty State
    private let emptyStateView: UIView = {
        let view = UIView()
        view.isHidden = true
        return view
    }()

    private let emptyIcon: UIImageView = {
        let iv = UIImageView(image: UIImage(systemName: "play.slash"))
        iv.tintColor = UIColor.white.withAlphaComponent(0.15)
        iv.contentMode = .scaleAspectFit
        return iv
    }()

    private let emptyLabel: UILabel = {
        let label = UILabel()
        label.text = "No videos yet"
        label.font = .systemFont(ofSize: 16, weight: .medium)
        label.textColor = UIColor.white.withAlphaComponent(0.3)
        label.textAlignment = .center
        return label
    }()

    // MARK: - Error Banner
    private let errorBanner: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor(red: 1, green: 0.3, blue: 0.3, alpha: 0.15)
        view.layer.cornerRadius = 12
        view.isHidden = true
        return view
    }()

    private let errorLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 13, weight: .medium)
        label.textColor = UIColor(red: 1, green: 0.5, blue: 0.5, alpha: 1)
        label.textAlignment = .center
        return label
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(red: 5/255, green: 5/255, blue: 5/255, alpha: 1)

        setupHeader()
        setupUI()
        setupRefreshControl()

        loadCachedData()
        loadPage(reset: true)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }

    // MARK: - Header Setup
    private func setupHeader() {
        view.addSubview(headerContainer)
        headerContainer.addSubview(headerTitleLabel)
        headerContainer.addSubview(headerSubtitleLabel)

        [headerContainer, headerTitleLabel, headerSubtitleLabel].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
        }

        NSLayoutConstraint.activate([
            headerContainer.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            headerContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            headerContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            headerContainer.heightAnchor.constraint(equalToConstant: 64),

            headerTitleLabel.leadingAnchor.constraint(equalTo: headerContainer.leadingAnchor, constant: 24),
            headerTitleLabel.bottomAnchor.constraint(equalTo: headerContainer.bottomAnchor, constant: -4),

            headerSubtitleLabel.leadingAnchor.constraint(equalTo: headerContainer.leadingAnchor, constant: 24),
            headerSubtitleLabel.topAnchor.constraint(equalTo: headerTitleLabel.bottomAnchor, constant: 2)
        ])
    }

    // MARK: - UI Setup
    private func setupUI() {
        view.addSubview(collectionView)
        view.addSubview(activityIndicator)
        view.addSubview(emptyStateView)
        view.addSubview(errorBanner)
        errorBanner.addSubview(errorLabel)
        emptyStateView.addSubview(emptyIcon)
        emptyStateView.addSubview(emptyLabel)

        [collectionView, activityIndicator, emptyStateView, emptyIcon, emptyLabel, errorBanner, errorLabel].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
        }

        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: headerContainer.bottomAnchor),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor),

            emptyStateView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            emptyStateView.centerYAnchor.constraint(equalTo: view.centerYAnchor),

            emptyIcon.centerXAnchor.constraint(equalTo: emptyStateView.centerXAnchor),
            emptyIcon.topAnchor.constraint(equalTo: emptyStateView.topAnchor),
            emptyIcon.widthAnchor.constraint(equalToConstant: 48),
            emptyIcon.heightAnchor.constraint(equalToConstant: 48),

            emptyLabel.centerXAnchor.constraint(equalTo: emptyStateView.centerXAnchor),
            emptyLabel.topAnchor.constraint(equalTo: emptyIcon.bottomAnchor, constant: 16),

            errorBanner.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            errorBanner.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            errorBanner.topAnchor.constraint(equalTo: headerContainer.bottomAnchor, constant: 8),
            errorBanner.heightAnchor.constraint(equalToConstant: 44),

            errorLabel.centerXAnchor.constraint(equalTo: errorBanner.centerXAnchor),
            errorLabel.centerYAnchor.constraint(equalTo: errorBanner.centerYAnchor)
        ])
    }

    private func setupRefreshControl() {
        refreshControl.addTarget(self, action: #selector(handleRefresh), for: .valueChanged)
    }

    @objc private func handleRefresh() {
        errorBanner.isHidden = true
        loadPage(reset: true)
    }

    private func showErrorBanner(_ message: String) {
        errorLabel.text = message
        errorBanner.isHidden = false
        UIView.animate(withDuration: 0.3) { self.view.layoutIfNeeded() }
        DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
            UIView.animate(withDuration: 0.3) { self.errorBanner.isHidden = true }
        }
    }

    // MARK: - Data Loading
    private func loadCachedData() {
        let cachedVideos = VideoCacheService.shared.loadVideos()
        if !cachedVideos.isEmpty {
            self.allVideos = cachedVideos
            self.collectionView.reloadData()
        }
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
                    self.hasMorePages = !videos.isEmpty

                    self.emptyStateView.isHidden = !self.allVideos.isEmpty

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
                    self.showErrorBanner("Network error — pull to retry")
                    self.emptyStateView.isHidden = !self.allVideos.isEmpty
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

// MARK: - UICollectionViewDataSource / Delegate
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
        let footer = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: LoadingFooterView.identifier, for: indexPath) as! LoadingFooterView
        footer.setStatus(isLoading: isLoadingPage, hasMore: hasMorePages)
        return footer
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

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let offsetY = scrollView.contentOffset.y
        let contentHeight = scrollView.contentSize.height
        let frameHeight = scrollView.frame.height

        if offsetY > contentHeight - frameHeight - 300 {
            loadPage(reset: false)
        }
    }
}

// MARK: - WaterfallLayoutDelegate
extension VideoListViewController: WaterfallLayoutDelegate {
    func collectionView(_ collectionView: UICollectionView, heightForItemAt indexPath: IndexPath, with width: CGFloat) -> CGFloat {
        guard indexPath.item < allVideos.count else { return 220 }
        let video = allVideos[indexPath.item]
        let aspect = video.aspectRatio
        guard aspect > 0 else { return 220 }
        return max(160, min(width * aspect, 340))
    }

    func collectionView(_ collectionView: UICollectionView, columnSpanForItemAt indexPath: IndexPath) -> Int { return 1 }
    func collectionView(_ collectionView: UICollectionView, heightForFullWidthItemAt indexPath: IndexPath, with width: CGFloat) -> CGFloat {
        return width * 0.75
    }
    func collectionView(_ collectionView: UICollectionView, heightForFooterIn section: Int, contentHeight: CGFloat, availableHeight: CGFloat) -> CGFloat {
        let remainingSpace = availableHeight - contentHeight
        return remainingSpace > 0 ? max(remainingSpace, 60) : 60
    }
}
