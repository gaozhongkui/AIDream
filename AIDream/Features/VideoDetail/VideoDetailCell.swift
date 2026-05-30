import UIKit
import AVFoundation
import Kingfisher

final class VideoDetailCell: UICollectionViewCell {
    static let identifier = "VideoDetailCell"

    private var player: AVPlayer?
    private var playerLayer: AVPlayerLayer?
    private var playerItemContext = 0
    private var videoURL: URL?

    // UI Components
    private let playerContainer = UIView()

    private let backButton: UIButton = {
        let btn = UIButton(type: .system)
        let config = UIImage.SymbolConfiguration(pointSize: 20, weight: .bold)
        btn.setImage(UIImage(systemName: "chevron.left", withConfiguration: config), for: .normal)
        btn.tintColor = .white
        btn.backgroundColor = .black.withAlphaComponent(0.3)
        btn.layer.cornerRadius = 20
        return btn
    }()

    private let reportButton: UIButton = {
        let btn = UIButton(type: .system)
        let config = UIImage.SymbolConfiguration(pointSize: 18, weight: .bold)
        btn.setImage(UIImage(systemName: "exclamationmark.triangle", withConfiguration: config), for: .normal)
        btn.tintColor = .white
        btn.backgroundColor = .black.withAlphaComponent(0.3)
        btn.layer.cornerRadius = 20
        return btn
    }()

    private let infoStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 8
        stack.alignment = .leading
        return stack
    }()

    private let avatarContainer: UIView = {
        let view = UIView()
        view.layer.cornerRadius = 28
        view.layer.borderWidth = 2
        view.layer.borderColor = UIColor.white.cgColor
        view.clipsToBounds = true
        return view
    }()

    private let avatarImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.backgroundColor = .systemGray6
        return iv
    }()

    private let addButton: UIButton = {
        let btn = UIButton()
        btn.setImage(UIImage(systemName: "plus.circle.fill"), for: .normal)
        btn.tintColor = .systemPurple
        btn.backgroundColor = .white
        btn.layer.cornerRadius = 10
        return btn
    }()

    private let nameLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 15, weight: .bold)
        label.textColor = .white
        return label
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 20, weight: .black)
        label.textColor = .white
        return label
    }()

    private let introLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14, weight: .medium)
        label.textColor = .white.withAlphaComponent(0.9)
        label.numberOfLines = 0
        return label
    }()

    private let likeButton: UIButton = {
        var config = UIButton.Configuration.filled()
        config.image = UIImage(systemName: "heart.fill")
        config.imagePlacement = .top
        config.imagePadding = 4
        config.baseBackgroundColor = .black.withAlphaComponent(0.3)
        config.baseForegroundColor = .white
        config.cornerStyle = .medium

        let btn = UIButton(configuration: config)
        return btn
    }()

    private let useTemplateButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.backgroundColor = .systemPurple
        btn.setTitle("Use Template", for: .normal)
        btn.setTitleColor(.white, for: .normal)
        btn.titleLabel?.font = .systemFont(ofSize: 18, weight: .bold)
        btn.layer.cornerRadius = 25

        let config = UIImage.SymbolConfiguration(pointSize: 18, weight: .bold)
        btn.setImage(UIImage(systemName: "sparkles", withConfiguration: config), for: .normal)
        btn.tintColor = .white
        btn.imageEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 10)
        return btn
    }()

    var onBackTapped: (() -> Void)?

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        contentView.addSubview(playerContainer)
        contentView.addSubview(backButton)
        contentView.addSubview(reportButton)
        contentView.addSubview(infoStackView)
        contentView.addSubview(likeButton)
        contentView.addSubview(useTemplateButton)
        contentView.addSubview(avatarContainer)
        avatarContainer.addSubview(avatarImageView)
        contentView.addSubview(addButton)

        playerContainer.translatesAutoresizingMaskIntoConstraints = false
        backButton.translatesAutoresizingMaskIntoConstraints = false
        reportButton.translatesAutoresizingMaskIntoConstraints = false
        infoStackView.translatesAutoresizingMaskIntoConstraints = false
        likeButton.translatesAutoresizingMaskIntoConstraints = false
        useTemplateButton.translatesAutoresizingMaskIntoConstraints = false
        avatarContainer.translatesAutoresizingMaskIntoConstraints = false
        avatarImageView.translatesAutoresizingMaskIntoConstraints = false
        addButton.translatesAutoresizingMaskIntoConstraints = false

        infoStackView.addArrangedSubview(nameLabel)
        infoStackView.addArrangedSubview(titleLabel)
        infoStackView.addArrangedSubview(introLabel)

        NSLayoutConstraint.activate([
            playerContainer.topAnchor.constraint(equalTo: contentView.topAnchor),
            playerContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            playerContainer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            playerContainer.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),

            backButton.topAnchor.constraint(equalTo: contentView.safeAreaLayoutGuide.topAnchor, constant: 10),
            backButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            backButton.widthAnchor.constraint(equalToConstant: 40),
            backButton.heightAnchor.constraint(equalToConstant: 40),

            reportButton.topAnchor.constraint(equalTo: contentView.safeAreaLayoutGuide.topAnchor, constant: 10),
            reportButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            reportButton.widthAnchor.constraint(equalToConstant: 40),
            reportButton.heightAnchor.constraint(equalToConstant: 40),

            useTemplateButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            useTemplateButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            useTemplateButton.bottomAnchor.constraint(equalTo: contentView.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            useTemplateButton.heightAnchor.constraint(equalToConstant: 54),

            infoStackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            infoStackView.bottomAnchor.constraint(equalTo: useTemplateButton.topAnchor, constant: -30),
            infoStackView.trailingAnchor.constraint(equalTo: likeButton.leadingAnchor, constant: -20),

            avatarContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            avatarContainer.bottomAnchor.constraint(equalTo: infoStackView.topAnchor, constant: -20),
            avatarContainer.widthAnchor.constraint(equalToConstant: 56),
            avatarContainer.heightAnchor.constraint(equalToConstant: 56),

            avatarImageView.topAnchor.constraint(equalTo: avatarContainer.topAnchor),
            avatarImageView.leadingAnchor.constraint(equalTo: avatarContainer.leadingAnchor),
            avatarImageView.trailingAnchor.constraint(equalTo: avatarContainer.trailingAnchor),
            avatarImageView.bottomAnchor.constraint(equalTo: avatarContainer.bottomAnchor),

            addButton.centerXAnchor.constraint(equalTo: avatarContainer.leadingAnchor, constant: 8),
            addButton.centerYAnchor.constraint(equalTo: avatarContainer.topAnchor, constant: 45),
            addButton.widthAnchor.constraint(equalToConstant: 20),
            addButton.heightAnchor.constraint(equalToConstant: 20),

            likeButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            likeButton.bottomAnchor.constraint(equalTo: useTemplateButton.topAnchor, constant: -40),
            likeButton.widthAnchor.constraint(equalToConstant: 64),
            likeButton.heightAnchor.constraint(equalToConstant: 64)
        ])

        backButton.addTarget(self, action: #selector(backTapped), for: .touchUpInside)
    }

    @objc private func backTapped() {
        onBackTapped?()
    }

    func configure(with video: VideoData) {
        self.videoURL = video.videoURL
        nameLabel.text = "@\(video.userName)"
        titleLabel.text = video.title.lowercased() == "untitled" ? "" : video.title
        introLabel.text = video.introduction

        let starText = video.starCount >= 1000 ? String(format: "%.1fK", Double(video.starCount)/1000.0) : "\(video.starCount)"
        likeButton.setTitle(starText, for: .normal)

        avatarImageView.kf.setImage(with: video.userAvatarURL, options: [.transition(.fade(0.2))])

        setupPlayer()
    }

    private func setupPlayer() {
        guard let url = videoURL else { return }

        stopPlayback()

        let playerItem = AVPlayerItem(url: url)
        let player = AVPlayer(playerItem: playerItem)
        let playerLayer = AVPlayerLayer(player: player)
        playerLayer.videoGravity = .resizeAspectFill
        playerLayer.frame = contentView.bounds

        playerContainer.layer.addSublayer(playerLayer)

        self.player = player
        self.playerLayer = playerLayer

        NotificationCenter.default.addObserver(self, selector: #selector(playerItemDidReachEnd), name: .AVPlayerItemDidPlayToEndTime, object: playerItem)

        player.play()
    }

    @objc private func playerItemDidReachEnd(notification: Notification) {
        player?.seek(to: .zero)
        player?.play()
    }

    func stopPlayback() {
        player?.pause()
        playerLayer?.removeFromSuperlayer()
        player = nil
        playerLayer = nil
        NotificationCenter.default.removeObserver(self)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        playerLayer?.frame = bounds
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        stopPlayback()
        avatarImageView.kf.cancelDownloadTask()
        avatarImageView.image = nil
        nameLabel.text = nil
        titleLabel.text = nil
        introLabel.text = nil
    }
}
