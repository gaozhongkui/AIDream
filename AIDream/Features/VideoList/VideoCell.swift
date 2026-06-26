import AVFoundation
import UIKit
import Kingfisher

/// 专门用于展示底部渐变的视图，自动处理 Layer 布局
final class GradientOverlayView: UIView {
    override class var layerClass: AnyClass {
        return CAGradientLayer.self
    }

    private var gradientLayer: CAGradientLayer {
        return layer as! CAGradientLayer
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupGradient()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupGradient()
    }

    private func setupGradient() {
        gradientLayer.colors = [
            UIColor.clear.cgColor,
            UIColor.clear.cgColor,
            UIColor.black.withAlphaComponent(0.72).cgColor
        ]
        gradientLayer.locations = [0.0, 0.52, 1.0]
    }
}

final class VideoCell: UICollectionViewCell {
    static let identifier = "VideoCell"

    private var videoData: VideoData?
    private var videoURL: URL?
    private var player: AVPlayer?
    private var playerLayer: AVPlayerLayer?
    private var endObserver: NSObjectProtocol?
    private var favoriteObserver: NSObjectProtocol?

    // MARK: - Cover Image
    private let coverImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.backgroundColor = UIColor(white: 0.07, alpha: 1)
        return iv
    }()

    // MARK: - Shimmer Skeleton
    private let shimmerView: UIView = {
        let v = UIView()
        v.backgroundColor = UIColor(white: 0.12, alpha: 1)
        v.isUserInteractionEnabled = false
        return v
    }()

    private let shimmerGradientLayer: CAGradientLayer = {
        let g = CAGradientLayer()
        g.colors = [
            UIColor(white: 0.12, alpha: 1).cgColor,
            UIColor(white: 0.22, alpha: 1).cgColor,
            UIColor(white: 0.12, alpha: 1).cgColor
        ]
        g.locations = [0, 0.5, 1]
        g.startPoint = CGPoint(x: 0, y: 0.5)
        g.endPoint   = CGPoint(x: 1, y: 0.5)
        return g
    }()

    // MARK: - Gradient View
    private let gradientView = GradientOverlayView()

    // MARK: - Floating Info
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 2
        label.font = .systemFont(ofSize: 12, weight: .semibold)
        label.textColor = UIColor.white.withAlphaComponent(0.95)
        return label
    }()

    private let metaLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 1
        label.font = .systemFont(ofSize: 10, weight: .medium)
        label.textColor = UIColor.white.withAlphaComponent(0.45)
        return label
    }()

    private let likeButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "heart"), for: .normal)
        button.tintColor = UIColor.white.withAlphaComponent(0.3)
        button.imageView?.contentMode = .scaleAspectFit
        return button
    }()

    // MARK: - Init
    override init(frame: CGRect) {
        super.init(frame: frame)

        contentView.backgroundColor = UIColor(red: 0.05, green: 0.05, blue: 0.07, alpha: 1)
        contentView.layer.cornerRadius = 12
        contentView.layer.masksToBounds = true
        contentView.layer.borderWidth = 0.5
        contentView.layer.borderColor = UIColor.white.withAlphaComponent(0.05).cgColor

        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.35
        layer.shadowOffset = CGSize(width: 0, height: 2)
        layer.shadowRadius = 6

        contentView.addSubview(coverImageView)
        contentView.addSubview(shimmerView)
        shimmerView.layer.addSublayer(shimmerGradientLayer)
        contentView.addSubview(gradientView)

        contentView.addSubview(titleLabel)
        contentView.addSubview(metaLabel)
        contentView.addSubview(likeButton)

        [coverImageView, shimmerView, gradientView, titleLabel, metaLabel, likeButton].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
        }

        NSLayoutConstraint.activate([
            coverImageView.topAnchor.constraint(equalTo: contentView.topAnchor),
            coverImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            coverImageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            coverImageView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),

            shimmerView.topAnchor.constraint(equalTo: contentView.topAnchor),
            shimmerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            shimmerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            shimmerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),

            gradientView.topAnchor.constraint(equalTo: contentView.topAnchor),
            gradientView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            gradientView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            gradientView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),

            likeButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -10),
            likeButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -10),
            likeButton.widthAnchor.constraint(equalToConstant: 26),
            likeButton.heightAnchor.constraint(equalToConstant: 26),

            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 10),
            titleLabel.trailingAnchor.constraint(equalTo: likeButton.leadingAnchor, constant: -8),
            titleLabel.bottomAnchor.constraint(equalTo: metaLabel.topAnchor, constant: -2),

            metaLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 10),
            metaLabel.trailingAnchor.constraint(equalTo: likeButton.leadingAnchor, constant: -8),
            metaLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -10)
        ])

        likeButton.addTarget(self, action: #selector(likeTapped), for: .touchUpInside)

        favoriteObserver = NotificationCenter.default.addObserver(
            forName: FavoriteService.favoritesChangedNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let self,
                  let videoId = notification.userInfo?["videoId"] as? Int,
                  self.videoData?.id == videoId else { return }
            self.updateLikeState()
        }
    }

    required init?(coder: NSCoder) { fatalError() }

    deinit {
        if let observer = favoriteObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }

    // MARK: - Like Action
    @objc private func likeTapped() {
        guard let video = videoData else { return }
        FavoriteService.shared.toggleFavorite(video)
        updateLikeState()

        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()

        UIView.animate(withDuration: 0.12, animations: {
            self.likeButton.transform = CGAffineTransform(scaleX: 1.35, y: 1.35)
        }) { _ in
            UIView.animate(withDuration: 0.12, delay: 0, usingSpringWithDamping: 0.5, initialSpringVelocity: 0.5) {
                self.likeButton.transform = .identity
            }
        }
    }

    private func updateLikeState() {
        guard let video = videoData else { return }
        let favorited = FavoriteService.shared.isFavorited(video.id)
        likeButton.tintColor = favorited
            ? UIColor.systemRed
            : UIColor.white.withAlphaComponent(0.3)
        likeButton.setImage(
            UIImage(systemName: favorited ? "heart.fill" : "heart"),
            for: .normal
        )
    }

    // MARK: - Shimmer
    private func startShimmer() {
        shimmerView.isHidden = false
        shimmerGradientLayer.frame = shimmerView.bounds

        let animation = CABasicAnimation(keyPath: "locations")
        animation.fromValue = [-1.0, -0.5, 0.0]
        animation.toValue   = [1.0,  1.5,  2.0]
        animation.duration  = 1.2
        animation.repeatCount = .infinity
        shimmerGradientLayer.add(animation, forKey: "shimmer")
    }

    private func stopShimmer() {
        shimmerGradientLayer.removeAnimation(forKey: "shimmer")
        UIView.animate(withDuration: 0.25) { self.shimmerView.alpha = 0 } completion: { _ in
            self.shimmerView.isHidden = true
            self.shimmerView.alpha = 1
        }
    }

    // MARK: - Layout
    override func apply(_ layoutAttributes: UICollectionViewLayoutAttributes) {
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        super.apply(layoutAttributes)
        CATransaction.commit()
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        shimmerGradientLayer.frame = shimmerView.bounds

        if let playerLayer = playerLayer {
            CATransaction.begin()
            CATransaction.setDisableActions(true)
            playerLayer.frame = coverImageView.bounds
            CATransaction.commit()
        }
    }

    // MARK: - Reuse
    override func prepareForReuse() {
        super.prepareForReuse()
        stopPlayback()
        coverImageView.kf.cancelDownloadTask()
        coverImageView.image = nil
        titleLabel.text = nil
        metaLabel.text = nil
        videoData = nil
        shimmerGradientLayer.removeAnimation(forKey: "shimmer")
        shimmerView.alpha = 1
        shimmerView.isHidden = false
    }

    // MARK: - Configure
    func configure(with video: VideoData) {
        self.videoData = video
        videoURL = video.videoURL

        let displayTitle = video.title.lowercased() == "untitled"
            ? video.introduction
            : video.title
        titleLabel.text = displayTitle

        let stars = formatCount(video.starCount)
        metaLabel.text = "@\(video.userName) · ★\(stars)"

        startShimmer()
        coverImageView.kf.setImage(
            with: video.coverURL,
            options: [
                .transition(.fade(0.25)),
                .onFailureImage(UIImage(systemName: "play.slash")?.withTintColor(
                    UIColor.white.withAlphaComponent(0.15), renderingMode: .alwaysOriginal
                ))
            ],
            completionHandler: { [weak self] _ in
                self?.stopShimmer()
            }
        )

        updateLikeState()
    }

    // MARK: - Playback
    func startPlayback() {
        guard let url = videoURL, player == nil else { return }

        // 使用缓存路径（如果存在）
        let finalURL = VideoCacheService.shared.cachedLocation(for: url) ?? url

        let item = AVPlayerItem(url: finalURL)
        player = AVPlayer(playerItem: item)
        player?.isMuted = true
        player?.actionAtItemEnd = .none
        // 减少起播等待
        player?.automaticallyWaitsToMinimizeStalling = false

        let layer = AVPlayerLayer(player: player)
        layer.videoGravity = .resizeAspectFill

        CATransaction.begin()
        CATransaction.setDisableActions(true)
        layer.frame = coverImageView.bounds
        CATransaction.commit()

        coverImageView.layer.insertSublayer(layer, at: 0)
        playerLayer = layer

        endObserver = NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: item,
            queue: .main
        ) { [weak self] _ in
            self?.player?.seek(to: .zero)
            self?.player?.play()
        }
        player?.play()
    }

    func stopPlayback() {
        player?.pause()
        if let observer = endObserver {
            NotificationCenter.default.removeObserver(observer)
        }
        playerLayer?.removeFromSuperlayer()
        playerLayer = nil
        player = nil
        endObserver = nil
    }

    // MARK: - Helpers
    private func formatCount(_ count: Int) -> String {
        if count >= 1000 {
            return String(format: "%.1fk", Double(count) / 1000.0)
        }
        return "\(count)"
    }
}
