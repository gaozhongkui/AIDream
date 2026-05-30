import UIKit

final class VideoDetailViewController: UIViewController {
    private var videos: [VideoData]
    private var initialIndex: Int
    private var isInitialScrollDone = false

    private lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.minimumLineSpacing = 0
        layout.minimumInteritemSpacing = 0
        layout.itemSize = UIScreen.main.bounds.size

        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.backgroundColor = .black
        cv.isPagingEnabled = true
        cv.contentInsetAdjustmentBehavior = .never
        cv.showsVerticalScrollIndicator = false
        cv.register(VideoDetailCell.self, forCellWithReuseIdentifier: VideoDetailCell.identifier)
        cv.dataSource = self
        cv.delegate = self
        return cv
    }()

    init(videos: [VideoData], initialIndex: Int) {
        self.videos = videos
        self.initialIndex = initialIndex
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .fullScreen
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        view.addSubview(collectionView)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: view.topAnchor),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        // 核心：在布局完成后，且仅执行一次精准滚动
        if !isInitialScrollDone {
            isInitialScrollDone = true
            let indexPath = IndexPath(item: initialIndex, section: 0)
            collectionView.scrollToItem(at: indexPath, at: .top, animated: false)
        }
    }

    override var prefersStatusBarHidden: Bool {
        return true
    }
}

extension VideoDetailViewController: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return videos.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: VideoDetailCell.identifier, for: indexPath) as! VideoDetailCell
        cell.configure(with: videos[indexPath.item])
        cell.onBackTapped = { [weak self] in
            self?.dismiss(animated: true)
        }
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, didEndDisplaying cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        (cell as? VideoDetailCell)?.stopPlayback()
    }
}
