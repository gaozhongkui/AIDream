import AVKit
import UIKit

final class VideoListViewController: UIViewController {
    private let pageSize = 20
    private var allVideos: [VideoData] = []
    private var filteredVideos: [VideoData] = []
    private var filterOptions: [VideoFilterOption] = [.all]
    private var selectedFilterID: String = VideoFilterOption.all.id
    private var filterButtons: [UIButton] = []
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

    private let filterContainer: UIView = {
        let view = UIView()
        view.backgroundColor = .secondarySystemGroupedBackground
        view.layer.cornerRadius = 16
        view.layer.masksToBounds = true
        return view
    }()

    private let filterScrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.alwaysBounceHorizontal = true
        return scrollView
    }()

    private let filterStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.alignment = .center
        stackView.spacing = 10
        return stackView
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
        view.addSubview(filterContainer)
        view.addSubview(collectionView)
        filterContainer.addSubview(filterScrollView)
        filterScrollView.addSubview(filterStackView)

        filterContainer.translatesAutoresizingMaskIntoConstraints = false
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        filterScrollView.translatesAutoresizingMaskIntoConstraints = false
        filterStackView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            filterContainer.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            filterContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            filterContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),

            filterScrollView.topAnchor.constraint(equalTo: filterContainer.topAnchor, constant: 8),
            filterScrollView.leadingAnchor.constraint(equalTo: filterContainer.leadingAnchor, constant: 12),
            filterScrollView.trailingAnchor.constraint(equalTo: filterContainer.trailingAnchor, constant: -12),
            filterScrollView.bottomAnchor.constraint(equalTo: filterContainer.bottomAnchor, constant: -8),

            filterStackView.topAnchor.constraint(equalTo: filterScrollView.contentLayoutGuide.topAnchor),
            filterStackView.leadingAnchor.constraint(equalTo: filterScrollView.contentLayoutGuide.leadingAnchor),
            filterStackView.trailingAnchor.constraint(equalTo: filterScrollView.contentLayoutGuide.trailingAnchor),
            filterStackView.bottomAnchor.constraint(equalTo: filterScrollView.contentLayoutGuide.bottomAnchor),
            filterStackView.heightAnchor.constraint(equalTo: filterScrollView.frameLayoutGuide.heightAnchor),

            collectionView.topAnchor.constraint(equalTo: filterContainer.bottomAnchor, constant: 12),
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
                    let pageVideos = videos
                        .filter { $0.isPlayable }
                        .sorted {
                            let leftTime = $0.publishTime ?? $0.createTime
                            let rightTime = $1.publishTime ?? $1.createTime
                            return leftTime > rightTime
                        }

                    if reset {
                        self.allVideos = []
                    }

                    self.append(videos: pageVideos)
                    self.currentOffset += videos.count
                    self.hasMorePages = videos.count == self.pageSize
                    self.updateFilterOptions()
                    self.applyCurrentFilter(loadMoreIfNeeded: true)
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

        var seenWorkIDs = Set(allVideos.map(\.workId))
        for video in videos where seenWorkIDs.insert(video.workId).inserted {
            allVideos.append(video)
        }

        allVideos.sort {
            let leftTime = $0.publishTime ?? $0.createTime
            let rightTime = $1.publishTime ?? $1.createTime
            return leftTime > rightTime
        }
    }

    private func updateFilterOptions() {
        let newOptions = VideoFilterOption.options(from: allVideos)
        let oldIDs = filterOptions.map(\.id)
        let newIDs = newOptions.map(\.id)

        if oldIDs != newIDs {
            filterOptions = newOptions
            if filterOptions.contains(where: { $0.id == selectedFilterID }) == false {
                selectedFilterID = VideoFilterOption.all.id
            }
            rebuildFilterButtons()
        }
    }

    private func rebuildFilterButtons() {
        filterStackView.arrangedSubviews.forEach { view in
            filterStackView.removeArrangedSubview(view)
            view.removeFromSuperview()
        }
        filterButtons.removeAll()

        for option in filterOptions {
            let button = UIButton(type: .system)
            var configuration = UIButton.Configuration.plain()
            configuration.contentInsets = NSDirectionalEdgeInsets(top: 8, leading: 14, bottom: 8, trailing: 14)
            button.configuration = configuration
            button.setTitle(option.title, for: .normal)
            button.tag = filterButtons.count
            button.titleLabel?.font = .systemFont(ofSize: 13, weight: .semibold)
            button.layer.cornerRadius = 16
            button.layer.masksToBounds = true
            button.layer.borderWidth = 1
            button.addTarget(self, action: #selector(handleFilterTapped(_:)), for: .touchUpInside)
            filterStackView.addArrangedSubview(button)
            filterButtons.append(button)
        }

        updateFilterButtonAppearance()
    }

    @objc private func handleFilterTapped(_ sender: UIButton) {
        guard filterButtons.indices.contains(sender.tag) else { return }
        selectedFilterID = filterOptions[sender.tag].id
        applyCurrentFilter()
    }

    private func applyCurrentFilter(loadMoreIfNeeded: Bool = false) {
        filteredVideos = allVideos.filter { video in
            selectedFilterID == VideoFilterOption.all.id || video.type == selectedFilterID
        }

        updateFilterButtonAppearance()
        collectionView.collectionViewLayout.invalidateLayout()
        collectionView.reloadData()

        DispatchQueue.main.async { [weak self] in
            self?.playVisibleCells()
            if loadMoreIfNeeded, let self, self.filteredVideos.isEmpty {
                self.loadPage(reset: false)
            }
        }
    }

    private func updateFilterButtonAppearance() {
        for (index, button) in filterButtons.enumerated() {
            let option = filterOptions[index]
            let isSelected = option.id == selectedFilterID
            button.backgroundColor = isSelected ? .label : .tertiarySystemBackground
            button.setTitleColor(isSelected ? .systemBackground : .label, for: .normal)
            button.layer.borderColor = (isSelected ? UIColor.clear : UIColor.separator).cgColor
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

    private func textHeight(for text: String, font: UIFont, width: CGFloat) -> CGFloat {
        guard !text.isEmpty else { return 0 }
        let bounding = text.boundingRect(
            with: CGSize(width: width, height: .greatestFiniteMagnitude),
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            attributes: [.font: font],
            context: nil
        )
        return ceil(bounding.height)
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
        let mediaHeight = width / max(video.aspectRatio, 0.6)
        let titleHeight = textHeight(
            for: video.displayTitle,
            font: .systemFont(ofSize: 14, weight: .semibold),
            width: width - 24
        )

        let secondaryText = video.secondaryText
        let secondaryHeight = secondaryText.isEmpty
            ? 0
            : min(textHeight(for: secondaryText, font: .systemFont(ofSize: 12), width: width - 24), 34)

        return mediaHeight + 10 + titleHeight + (secondaryHeight > 0 ? 4 : 0) + secondaryHeight + 12
    }
}
