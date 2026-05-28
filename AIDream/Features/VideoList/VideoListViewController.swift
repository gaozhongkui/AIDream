import UIKit

class VideoListViewController: UIViewController {

    private var videos: [VideoData] = []

    private lazy var collectionView: UICollectionView = {
        let layout = WaterfallLayout()
        layout.delegate = self
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.backgroundColor = .clear // 背景透明，显示底层的 systemGroupedBackground
        cv.register(VideoCell.self, forCellWithReuseIdentifier: VideoCell.identifier)
        cv.dataSource = self
        cv.delegate = self
        cv.alwaysBounceVertical = true // 确保始终可以有回弹效果
        return cv
    }()

    private let refreshControl = UIRefreshControl()

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "发现灵感"
        view.backgroundColor = .systemGroupedBackground // 设置 iOS 标准分组背景色
        setupNavigationBar()
        setupUI()
        setupRefreshControl()
        fetchData()
    }

    private func setupNavigationBar() {
        navigationController?.navigationBar.prefersLargeTitles = true
        let appearance = UINavigationBarAppearance()
        appearance.configureWithTransparentBackground()
        appearance.backgroundColor = .systemGroupedBackground.withAlphaComponent(0.8)
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
        collectionView.refreshControl = refreshControl
    }

    @objc private func handleRefresh() {
        fetchData()
    }

    private func fetchData() {
        VideoService.shared.fetchVideos { [weak self] result in
            DispatchQueue.main.async {
                self?.refreshControl.endRefreshing()
                switch result {
                case .success(let videos):
                    self?.videos = videos
                    self?.collectionView.collectionViewLayout.invalidateLayout()
                    self?.collectionView.reloadData()
                case .failure(let error):
                    print("Error: \(error)")
                }
            }
        }
    }
}

extension VideoListViewController: UICollectionViewDataSource, UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return videos.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: VideoCell.identifier, for: indexPath) as? VideoCell else {
            return UICollectionViewCell()
        }
        cell.configure(with: videos[indexPath.item])
        return cell
    }
}

extension VideoListViewController: WaterfallLayoutDelegate {
    func collectionView(_ collectionView: UICollectionView, heightForItemAt indexPath: IndexPath, with width: CGFloat) -> CGFloat {
        // 根据 prompt 长度动态估算高度，使瀑布流更真实
        let prompt = videos[indexPath.item].prompt
        let textHeight = prompt.boundingRect(
            with: CGSize(width: width - 20, height: .greatestFiniteMagnitude),
            options: .usesLineFragmentOrigin,
            attributes: [.font: UIFont.systemFont(ofSize: 14, weight: .medium)],
            context: nil
        ).height

        // 基础高度 = 图片(宽*1.3) + 间距(10) + 文字高度 + 底部间距(12)
        return (width * 1.3) + 10 + min(textHeight, 40) + 12
    }
}
