import UIKit
import AVFoundation
import Kingfisher

final class VideoDetailCell: UICollectionViewCell {
    static let identifier = "VideoDetailCell"

    private var player: AVPlayer?
    private var playerLayer: AVPlayerLayer?
    private var videoURL: URL?
    private var playerLayerObserver: NSKeyValueObservation?

    private var videoData: VideoData?
    private var isLiked: Bool = false
    private var currentStarCount: Int = 0

    // UI Components
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

    private let backButton: UIButton = {
        let btn = UIButton(type: .system)
        let config = UIImage.SymbolConfiguration(pointSize: 18, weight: .bold)
        btn.setImage(UIImage(systemName: "chevron.left", withConfiguration: config), for: .normal)
        btn.tintColor = .white
        btn.backgroundColor = UIColor.white.withAlphaComponent(0.12)
        btn.layer.cornerRadius = 20
        btn.layer.borderWidth = 0.5
        btn.layer.borderColor = UIColor.white.withAlphaComponent(0.15).cgColor
        return btn
    }()

    private let infoStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 8
        stack.alignment = .leading
        return stack
    }()

    private let nameLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 15, weight: .bold)
        label.textColor = UIColor(red: 0, green: 242/255, blue: 255/255, alpha: 1) // accentSecondary
        return label
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 22, weight: .black)
        label.textColor = .white
        label.layer.shadowColor = UIColor.black.cgColor
        label.layer.shadowOffset = CGSize(width: 0, height: 2)
        label.layer.shadowOpacity = 0.8
        return label
    }()

    private let introLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14, weight: .medium)
        label.textColor = .white.withAlphaComponent(0.8)
        label.numberOfLines = 2
        return label
    }()

    private let likeButton: UIButton = {
        var config = UIButton.Configuration.filled()
        config.image = UIImage(systemName: "bolt.heart.fill")
        config.imagePlacement = .top
        config.imagePadding = 6
        config.baseBackgroundColor = UIColor.white.withAlphaComponent(0.08)
        config.baseForegroundColor = .white
        config.cornerStyle = .large
        let btn = UIButton(configuration: config)
        btn.layer.borderWidth = 0.5
        btn.layer.borderColor = UIColor.white.withAlphaComponent(0.1).cgColor
        btn.layer.cornerRadius = 18
        btn.clipsToBounds = true
        return btn
    }()

    private let useTemplateButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle("Remix Concept", for: .normal)
        btn.setTitleColor(.white, for: .normal)
        btn.titleLabel?.font = .systemFont(ofSize: 17, weight: .black)
        btn.layer.cornerRadius = 22
        btn.clipsToBounds = true

        let config = UIImage.SymbolConfiguration(pointSize: 16, weight: .bold)
        btn.setImage(UIImage(systemName: "wand.and.stars.inverse", withConfiguration: config), for: .normal)
        btn.tintColor = .white
        btn.imageEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 12)

        let gradient = CAGradientLayer()
        gradient.colors = [
            UIColor(red: 0.3, green: 0.62, blue: 1.0, alpha: 1).cgColor,
            UIColor(red: 0, green: 0.95, blue: 1.0, alpha: 1).cgColor
        ]
        gradient.startPoint = CGPoint(x: 0, y: 0.5)
        gradient.endPoint   = CGPoint(x: 1, y: 0.5)
        gradient.name = "accentGradient"
        btn.layer.insertSublayer(gradient, at: 0)

        btn.layer.shadowColor = UIColor(red: 0.3, green: 0.62, blue: 1.0, alpha: 0.4).cgColor
        btn.layer.shadowOffset = CGSize(width: 0, height: 4)
        btn.layer.shadowOpacity = 1
        btn.layer.shadowRadius = 12
        return btn
    }()

    var onBackTapped: (() -> Void)?

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) { fatalError() }

    private func setupUI() {
        contentView.addSubview(playerContainer)
        contentView.addSubview(coverImageView)
        contentView.addSubview(backButton)
        contentView.addSubview(infoStackView)
        contentView.addSubview(likeButton)
        contentView.addSubview(useTemplateButton)

        [playerContainer, coverImageView, backButton, infoStackView, likeButton, useTemplateButton].forEach {
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

            backButton.topAnchor.constraint(equalTo: contentView.safeAreaLayoutGuide.topAnchor, constant: 10),
            backButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            backButton.widthAnchor.constraint(equalToConstant: 40),
            backButton.heightAnchor.constraint(equalToConstant: 40),

            useTemplateButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
            useTemplateButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -24),
            useTemplateButton.bottomAnchor.constraint(equalTo: contentView.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            useTemplateButton.heightAnchor.constraint(equalToConstant: 58),

            infoStackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            infoStackView.bottomAnchor.constraint(equalTo: useTemplateButton.topAnchor, constant: -30),
            infoStackView.trailingAnchor.constraint(equalTo: likeButton.leadingAnchor, constant: -20),

            likeButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            likeButton.bottomAnchor.constraint(equalTo: useTemplateButton.topAnchor, constant: -40),
            likeButton.widthAnchor.constraint(equalToConstant: 64),
            likeButton.heightAnchor.constraint(equalToConstant: 68)
        ])

        backButton.addTarget(self, action: #selector(backTapped), for: .touchUpInside)
        likeButton.addTarget(self, action: #selector(likeTapped), for: .touchUpInside)
    }

    @objc private func backTapped() { onBackTapped?() }

    @objc private func likeTapped() {
        guard let video = videoData else { return }

        isLiked.toggle()
        if isLiked { currentStarCount += 1 } else { currentStarCount = max(0, currentStarCount - 1) }

        // 核心修复：同步到收藏服务
        FavoriteService.shared.toggleFavorite(video)

        updateLikeButtonStyle(animated: true)
    }

    private func updateLikeButtonStyle(animated: Bool) {
        let color = isLiked ? UIColor.systemRed : UIColor.white
        let starText = currentStarCount >= 1000 ? String(format: "%.1fK", Double(currentStarCount)/1000.0) : "\(currentStarCount)"

        var config = likeButton.configuration
        config?.baseForegroundColor = color
        likeButton.configuration = config
        likeButton.setTitle(starText, for: .normal)

        if animated {
            let animation = CAKeyframeAnimation(keyPath: "transform.scale")
            animation.values = [1.0, 1.4, 0.9, 1.0]
            animation.duration = 0.3
            likeButton.layer.add(animation, forKey: "bounce")
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        }
    }

    func configure(with video: VideoData) {
        self.videoData = video
        self.videoURL = video.videoURL
        nameLabel.text = "@\(video.userName)"
        titleLabel.text = video.title.lowercased() == "untitled" ? "" : video.title
        introLabel.text = video.introduction

        self.currentStarCount = video.starCount

        // 核心修复：从服务读取初始状态
        self.isLiked = FavoriteService.shared.isFavorited(video.id)
        updateLikeButtonStyle(animated: false)

        coverImageView.isHidden = false
        coverImageView.alpha = 1
        coverImageView.kf.setImage(with: video.coverURL)

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
        playerContainer.layer.addSublayer(layer)
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
        playerLayer?.frame = bounds
        if let grad = useTemplateButton.layer.sublayers?.first(where: { $0.name == "accentGradient" }) {
            grad.frame = useTemplateButton.bounds
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        stopPlayback()
        coverImageView.image = nil
        coverImageView.alpha = 1
        videoData = nil
    }
}
