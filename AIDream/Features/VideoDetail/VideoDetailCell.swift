import UIKit
import AVFoundation
import Kingfisher

// MARK: - UIKit Accent Colors (mirrors AppTheme)
private extension UIColor {
    static let accentPrimary   = UIColor(red: 77/255,  green: 159/255, blue: 255/255, alpha: 1)
    static let accentSecondary = UIColor(red: 0,      green: 242/255, blue: 255/255, alpha: 1)
    static let accentGlow      = UIColor(red: 77/255,  green: 159/255, blue: 255/255, alpha: 0.4)
}

// MARK: - GradientButton（自动同步渐变背景 frame）
private final class GradientButton: UIButton {
    private let accentGradient: CAGradientLayer = {
        let layer = CAGradientLayer()
        layer.colors = [UIColor.accentPrimary.cgColor, UIColor.accentSecondary.cgColor]
        layer.startPoint = CGPoint(x: 0, y: 0.5)
        layer.endPoint   = CGPoint(x: 1, y: 0.5)
        layer.name = "accentGradient"
        return layer
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        layer.insertSublayer(accentGradient, at: 0)
    }
    required init?(coder: NSCoder) { fatalError() }

    override func layoutSubviews() {
        super.layoutSubviews()
        accentGradient.frame = bounds
    }
}

final class VideoDetailCell: UICollectionViewCell {
    static let identifier = "VideoDetailCell"

    private var player: AVPlayer?
    private var playerLayer: AVPlayerLayer?
    private var videoURL: URL?
    private var playerLayerObserver: NSKeyValueObservation?
    private var favoriteObserver: NSObjectProtocol?

    private var videoData: VideoData?
    private var isLiked: Bool = false
    private var currentStarCount: Int = 0

    // MARK: - Player & Cover
    private let playerContainer: UIView = {
        let view = UIView()
        view.backgroundColor = .black
        return view
    }()

    private let coverImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.backgroundColor = .black
        return iv
    }()

    // MARK: - Bottom Gradient (text readability)
    private let bottomGradient: CAGradientLayer = {
        let layer = CAGradientLayer()
        layer.colors = [
            UIColor.clear.cgColor,
            UIColor.black.withAlphaComponent(0.55).cgColor,
            UIColor.black.withAlphaComponent(0.85).cgColor
        ]
        layer.locations = [0.0, 0.5, 1.0]
        return layer
    }()

    // MARK: - Top Gradient (status bar area)
    private let topGradient: CAGradientLayer = {
        let layer = CAGradientLayer()
        layer.colors = [
            UIColor.black.withAlphaComponent(0.6).cgColor,
            UIColor.clear.cgColor
        ]
        layer.locations = [0.0, 1.0]
        return layer
    }()

    // MARK: - Back Button
    private let backButton: UIButton = {
        let btn = UIButton(type: .system)
        let config = UIImage.SymbolConfiguration(pointSize: 16, weight: .bold)
        btn.setImage(UIImage(systemName: "chevron.left", withConfiguration: config), for: .normal)
        btn.tintColor = .white
        btn.backgroundColor = UIColor.black.withAlphaComponent(0.4)
        btn.layer.cornerRadius = 18
        return btn
    }()

    // MARK: - Info Stack
    private let infoStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 6
        stack.alignment = .leading
        return stack
    }()

    private let nameLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 13, weight: .semibold)
        label.textColor = .accentSecondary
        return label
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 24, weight: .black)
        label.textColor = .white
        label.numberOfLines = 2
        return label
    }()

    private let introLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14, weight: .regular)
        label.textColor = UIColor.white.withAlphaComponent(0.7)
        label.numberOfLines = 3
        return label
    }()

    // MARK: - Like Button
    private let likeButton: UIButton = {
        var config = UIButton.Configuration.filled()
        config.image = UIImage(systemName: "heart")
        config.imagePlacement = .top
        config.imagePadding = 4
        config.baseBackgroundColor = UIColor.black.withAlphaComponent(0.35)
        config.baseForegroundColor = .white
        config.cornerStyle = .large
        let btn = UIButton(configuration: config)
        btn.layer.borderWidth = 0.5
        btn.layer.borderColor = UIColor.white.withAlphaComponent(0.1).cgColor
        btn.layer.cornerRadius = 16
        btn.clipsToBounds = true
        return btn
    }()

    // MARK: - Remix Button
    private let remixButton: GradientButton = {
        let btn = GradientButton(type: .system)
        btn.setTitle("  Remix This Style", for: .normal)
        btn.setTitleColor(.white, for: .normal)
        btn.titleLabel?.font = .systemFont(ofSize: 16, weight: .bold)

        let config = UIImage.SymbolConfiguration(pointSize: 14, weight: .bold)
        btn.setImage(UIImage(systemName: "wand.and.stars", withConfiguration: config), for: .normal)
        btn.tintColor = .white

        btn.layer.cornerRadius = 20
        btn.clipsToBounds = true

        btn.layer.shadowColor = UIColor.accentPrimary.withAlphaComponent(0.4).cgColor
        btn.layer.shadowOffset = CGSize(width: 0, height: 4)
        btn.layer.shadowOpacity = 1
        btn.layer.shadowRadius = 12
        return btn
    }()

    var onBackTapped: (() -> Void)?

    // MARK: - Init
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        setupObservers()
    }

    required init?(coder: NSCoder) { fatalError() }

    private func setupUI() {
        contentView.addSubview(playerContainer)
        contentView.addSubview(coverImageView)
        contentView.layer.addSublayer(topGradient)
        contentView.layer.addSublayer(bottomGradient)
        contentView.addSubview(backButton)
        contentView.addSubview(infoStackView)
        contentView.addSubview(likeButton)
        contentView.addSubview(remixButton)

        [playerContainer, coverImageView, backButton, infoStackView, likeButton, remixButton].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
        }

        infoStackView.addArrangedSubview(nameLabel)
        infoStackView.addArrangedSubview(titleLabel)
        infoStackView.addArrangedSubview(introLabel)

        NSLayoutConstraint.activate([
            playerContainer.topAnchor.constraint(equalTo: contentView.topAnchor),
            playerContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            playerContainer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            playerContainer.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),

            coverImageView.topAnchor.constraint(equalTo: contentView.topAnchor),
            coverImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            coverImageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            coverImageView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),

            backButton.topAnchor.constraint(equalTo: contentView.safeAreaLayoutGuide.topAnchor, constant: 8),
            backButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            backButton.widthAnchor.constraint(equalToConstant: 36),
            backButton.heightAnchor.constraint(equalToConstant: 36),

            remixButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            remixButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            remixButton.bottomAnchor.constraint(equalTo: contentView.safeAreaLayoutGuide.bottomAnchor, constant: -16),
            remixButton.heightAnchor.constraint(equalToConstant: 52),

            infoStackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            infoStackView.bottomAnchor.constraint(equalTo: remixButton.topAnchor, constant: -24),
            infoStackView.trailingAnchor.constraint(equalTo: likeButton.leadingAnchor, constant: -16),

            likeButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            likeButton.bottomAnchor.constraint(equalTo: infoStackView.bottomAnchor),
            likeButton.widthAnchor.constraint(equalToConstant: 56),
            likeButton.heightAnchor.constraint(equalToConstant: 60)
        ])

        backButton.addTarget(self, action: #selector(backTapped), for: .touchUpInside)
        likeButton.addTarget(self, action: #selector(likeTapped), for: .touchUpInside)
    }

    private func setupObservers() {
        favoriteObserver = NotificationCenter.default.addObserver(
            forName: FavoriteService.favoritesChangedNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let self,
                  let videoId = notification.userInfo?["videoId"] as? Int,
                  self.videoData?.id == videoId else { return }
            let newState = FavoriteService.shared.isFavorited(videoId)
            if self.isLiked != newState {
                self.isLiked = newState
                self.currentStarCount += newState ? 1 : -1
                self.currentStarCount = max(0, self.currentStarCount)
                self.updateLikeButtonStyle(animated: true)
            }
        }
    }

    deinit {
        if let observer = favoriteObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }

    @objc private func backTapped() { onBackTapped?() }

    @objc private func likeTapped() {
        guard let video = videoData else { return }
        FavoriteService.shared.toggleFavorite(video)
    }

    private func updateLikeButtonStyle(animated: Bool) {
        let color: UIColor = isLiked ? .systemRed : .white
        let starText = formatCount(currentStarCount)

        var config = likeButton.configuration
        config?.baseForegroundColor = color
        config?.image = UIImage(systemName: isLiked ? "heart.fill" : "heart")
        likeButton.configuration = config
        likeButton.setTitle(starText, for: .normal)

        if animated {
            let animation = CAKeyframeAnimation(keyPath: "transform.scale")
            animation.values = [1.0, 1.3, 0.9, 1.0]
            animation.duration = 0.25
            likeButton.layer.add(animation, forKey: "bounce")
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        }
    }

    func configure(with video: VideoData) {
        self.videoData = video
        self.videoURL = video.videoURL

        nameLabel.text = "@\(video.userName)"
        titleLabel.text = video.title.lowercased() == "untitled" ? video.introduction : video.title
        introLabel.text = video.introduction

        self.currentStarCount = video.starCount
        self.isLiked = FavoriteService.shared.isFavorited(video.id)
        updateLikeButtonStyle(animated: false)

        coverImageView.isHidden = false
        coverImageView.alpha = 1
        coverImageView.kf.setImage(
            with: video.coverURL,
            options: [.keepCurrentImageWhileLoading]
        )

        setupPlayer()
    }

    private func setupPlayer() {
        guard let url = videoURL else { return }
        stopPlayback()

        let item = AVPlayerItem(url: url)
        player = AVPlayer(playerItem: item)
        let layer = AVPlayerLayer(player: player)
        layer.videoGravity = .resizeAspectFill
        layer.frame = contentView.bounds
        playerContainer.layer.insertSublayer(layer, at: 0)
        self.playerLayer = layer

        playerLayerObserver = layer.observe(\.isReadyForDisplay, options: [.new]) { [weak self] layer, _ in
            if layer.isReadyForDisplay {
                DispatchQueue.main.async {
                    UIView.animate(withDuration: 0.3) { self?.coverImageView.alpha = 0 }
                }
            }
        }
        player?.play()
    }

    func stopPlayback() {
        player?.pause()
        playerLayer?.removeFromSuperlayer()
        player = nil
        playerLayer = nil
        playerLayerObserver?.invalidate()
        playerLayerObserver = nil
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        playerLayer?.frame = bounds
        topGradient.frame = CGRect(x: 0, y: 0, width: bounds.width, height: 180)
        bottomGradient.frame = CGRect(x: 0, y: bounds.height - 320, width: bounds.width, height: 320)
        CATransaction.commit()
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        stopPlayback()
        coverImageView.image = nil
        coverImageView.alpha = 1
        videoData = nil
    }

    private func formatCount(_ count: Int) -> String {
        if count >= 1000 {
            return String(format: "%.1fk", Double(count) / 1000.0)
        }
        return "\(count)"
    }
}