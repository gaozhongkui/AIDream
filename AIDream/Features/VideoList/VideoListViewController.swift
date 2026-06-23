import AVKit
import UIKit
import SwiftUI

final class VideoListViewController: UIViewController {
    private let pageSize = 20
    private var allVideos: [VideoData] = []
    private var currentOffset = 0
    private var isLoadingPage = false
    private var hasMorePages = true

    private var hideBannerWorkItem: DispatchWorkItem?

    // MARK: - Custom Header
    private let headerContainer: UIView = {
        let view = UIView()
        view.backgroundColor = .clear
        return view
    }()

    private let headerBlurView: UIVisualEffectView = {
        let blurEffect = UIBlurEffect(style: .systemMaterialDark)
        return UIVisualEffectView(effect: blurEffect)
    }()

    private let headerTitleLabel: UILabel = {
        let label = UILabel()
        label.text = NSLocalizedString("tab_explore", comment: "")
        label.font = .systemFont(ofSize: 32, weight: .black)
        label.textColor = .white
        return label
    }()

    private let headerSubtitleLabel: UILabel = {
        let label = UILabel()
        label.text = NSLocalizedString("label_explore_subtitle", comment: "")
        label.font = .systemFont(ofSize: 13, weight: .medium)
        label.textColor = UIColor.white.withAlphaComponent(0.4)
        return label
    }()

    private lazy var vipButton: UIButton = {
        let button = UIButton(type: .system)
        let config = UIImage.SymbolConfiguration(pointSize: 18, weight: .bold)
        let image = UIImage(systemName: "crown.fill", withConfiguration: config)
        button.setImage(image, for: .normal)
        button.tintColor = UIColor(red: 200/255, green: 167/255, blue: 104/255, alpha: 1)
        button.backgroundColor = UIColor.white.withAlphaComponent(0.08)
        button.layer.cornerRadius = 20
        button.layer.borderWidth = 0.5
        button.layer.borderColor = UIColor.white.withAlphaComponent(0.15).cgColor
        button.addTarget(self, action: #selector(vipButtonTapped), for: .touchUpInside)
        return button
    }()

    // MARK: - Collection View
    private lazy var collectionView: UICollectionView = {
        let layout = WaterfallLayout()
        layout.delegate = self

        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .clear
        // Disable automatic inset adjustment so we have full control over the layout
        collectionView.contentInsetAdjustmentBehavior = .never

        collectionView.register(VideoCell.self, forCellWithReuseIdentifier: VideoCell.identifier)
        collectionView.register(LoadingFooterView.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionFooter, withReuseIdentifier: LoadingFooterView.identifier)
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.alwaysBounceVertical = true
        collectionView.refreshControl = refreshControl
        return collectionView
    }()

    private let refreshControl: UIRefreshControl = {
        let rc = UIRefreshControl()
        rc.tintColor = UIColor(red: 111/255, green: 49/255, blue: 213/255, alpha: 1) // AppTheme.accentPrimary
        let attributes: [NSAttributedString.Key: Any] = [
            .foregroundColor: UIColor.white.withAlphaComponent(0.5),
            .font: UIFont.systemFont(ofSize: 12, weight: .medium)
        ]
        rc.attributedTitle = NSAttributedString(string: NSLocalizedString("toast_pull_to_refresh", comment: ""), attributes: attributes)
        return rc
    }()

    private let activityIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .large)
        indicator.color = UIColor(red: 111/255, green: 49/255, blue: 213/255, alpha: 1)
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
        label.text = NSLocalizedString("label_no_videos", comment: "")
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

        setupUI()
        setupHeader()
        setupRefreshControl()
        setupNotifications()

        loadCachedData()
        loadPage(reset: true)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        view.bringSubviewToFront(headerContainer)

        let headerHeight = headerContainer.frame.height
        let bottomPadding = view.safeAreaInsets.bottom + 20

        if headerHeight > 0 && collectionView.contentInset.top != headerHeight {
            collectionView.contentInset = UIEdgeInsets(top: headerHeight, left: 10, bottom: bottomPadding, right: 10)
            collectionView.scrollIndicatorInsets = UIEdgeInsets(top: headerHeight, left: 0, bottom: view.safeAreaInsets.bottom, right: 0)

            if collectionView.contentOffset.y == 0 {
                collectionView.contentOffset = CGPoint(x: 0, y: -headerHeight)
            }
        }
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
        headerContainer.addSubview(headerBlurView)
        headerContainer.addSubview(headerTitleLabel)
        headerContainer.addSubview(headerSubtitleLabel)
        headerContainer.addSubview(vipButton)

        [headerContainer, headerBlurView, headerTitleLabel, headerSubtitleLabel, vipButton].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
        }

        NSLayoutConstraint.activate([
            headerContainer.topAnchor.constraint(equalTo: view.topAnchor),
            headerContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            headerContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor),

            headerBlurView.topAnchor.constraint(equalTo: headerContainer.topAnchor),
            headerBlurView.leadingAnchor.constraint(equalTo: headerContainer.leadingAnchor),
            headerBlurView.trailingAnchor.constraint(equalTo: headerContainer.trailingAnchor),
            headerBlurView.bottomAnchor.constraint(equalTo: headerContainer.bottomAnchor),

            headerTitleLabel.leadingAnchor.constraint(equalTo: headerContainer.leadingAnchor, constant: 24),
            headerTitleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 12),

            headerSubtitleLabel.leadingAnchor.constraint(equalTo: headerContainer.leadingAnchor, constant: 24),
            headerSubtitleLabel.topAnchor.constraint(equalTo: headerTitleLabel.bottomAnchor, constant: 4),
            headerSubtitleLabel.bottomAnchor.constraint(equalTo: headerContainer.bottomAnchor, constant: -16),

            vipButton.trailingAnchor.constraint(equalTo: headerContainer.trailingAnchor, constant: -20),
            vipButton.centerYAnchor.constraint(equalTo: headerTitleLabel.centerYAnchor),
            vipButton.widthAnchor.constraint(equalToConstant: 40),
            vipButton.heightAnchor.constraint(equalToConstant: 40)
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
            collectionView.topAnchor.constraint(equalTo: view.topAnchor),
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
            errorBanner.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 100),
            errorBanner.heightAnchor.constraint(equalToConstant: 44),

            errorLabel.centerXAnchor.constraint(equalTo: errorBanner.centerXAnchor),
            errorLabel.centerYAnchor.constraint(equalTo: errorBanner.centerYAnchor)
        ])
    }

    private func setupRefreshControl() {
        refreshControl.addTarget(self, action: #selector(handleRefresh), for: .valueChanged)
    }

    private func setupNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(networkBack), name: .networkBecameReachable, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleForegroundRefresh), name: UIApplication.willEnterForegroundNotification, object: nil)
    }

    @objc private func networkBack() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            if self.allVideos.isEmpty && !self.isLoadingPage {
                self.loadPage(reset: true)
            }
        }
    }

    @objc private func handleRefresh() {
        errorBanner.isHidden = true
        HapticManager.shared.impact(style: .light)
        loadPage(reset: true)
    }

    @objc private func handleForegroundRefresh() {
        // 应用从后台返回前台时刷新数据
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            if !self.isLoadingPage {
                self.loadPage(reset: true)
            }
        }
    }

    @objc private func vipButtonTapped() {
        HapticManager.shared.impact(style: .medium)
        let premiumVC = UIHostingController(rootView: PremiumView())
        premiumVC.modalPresentationStyle = .fullScreen
        present(premiumVC, animated: true)
    }

    private func showErrorBanner(_ message: String) {
        errorLabel.text = message
        errorBanner.isHidden = false
        hideBannerWorkItem?.cancel()
        UIView.animate(withDuration: 0.3) { self.view.layoutIfNeeded() }
        let workItem = DispatchWorkItem { [weak self] in
            UIView.animate(withDuration: 0.3) { self?.errorBanner.isHidden = true }
        }
        hideBannerWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 4, execute: workItem)
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
            // 使用随机 offset 确保每次进入页面都能看到不同的数据
            currentOffset = Int.random(in: 0..<50) * pageSize
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
                    let fetchedCount = videos.count
                    self.currentOffset += fetchedCount
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
                case .failure(_):
                    self.showErrorBanner(NSLocalizedString("toast_network_error_retry", comment: ""))
                    self.emptyStateView.isHidden = !self.allVideos.isEmpty
                    self.updateFooterStatus()
                }
            }
        }
    }

    private func updateFooterStatus() {
        let indexPath = IndexPath(item: 0, section: 0)
        if let footer = collectionView.supplementaryView(forElementKind: UICollectionView.elementKindSectionFooter, at: indexPath) as? LoadingFooterView {
            let shouldShowLoading = isLoadingPage && !allVideos.isEmpty
            footer.setStatus(isLoading: shouldShowLoading, hasMore: hasMorePages)
        }
    }

    private func append(videos: [VideoData]) {
        var seenIDs = Set(allVideos.map(\.id))
        for video in videos where seenIDs.insert(video.id).inserted {
            allVideos.append(video)
        }
    }

    private func presentDetail(at indexPath: IndexPath) {
        HapticManager.shared.impact(style: .medium)
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
        let shouldShowLoading = isLoadingPage && !allVideos.isEmpty
        footer.setStatus(isLoading: shouldShowLoading, hasMore: hasMorePages)
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
}

// MARK: - WaterfallLayoutDelegate
extension VideoListViewController: WaterfallLayoutDelegate {
    func collectionView(_ collectionView: UICollectionView, heightForItemAt indexPath: IndexPath, with width: CGFloat) -> CGFloat {
        guard indexPath.item < allVideos.count else { return 260 }
        let video = allVideos[indexPath.item]
        let aspect = video.aspectRatio
        let photoHeight: CGFloat = aspect > 0 ? max(160, min(width * aspect, 340)) : 220
        return photoHeight + 40
    }

    func collectionView(_ collectionView: UICollectionView, columnSpanForItemAt indexPath: IndexPath) -> Int { return 1 }
    func collectionView(_ collectionView: UICollectionView, heightForFullWidthItemAt indexPath: IndexPath, with width: CGFloat) -> CGFloat {
        return width * 0.75
    }
    func collectionView(_ collectionView: UICollectionView, heightForFooterIn section: Int, contentHeight: CGFloat, availableHeight: CGFloat) -> CGFloat {
        if allVideos.isEmpty { return 0 }
        let remainingSpace = availableHeight - contentHeight
        return remainingSpace > 0 ? max(remainingSpace, 60) : 60
    }
}
