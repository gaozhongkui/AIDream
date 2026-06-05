import AVFoundation
import UIKit
import Kingfisher

final class VideoCell: UICollectionViewCell {
    static let identifier = "VideoCell"

    private var videoURL: URL?
    private var player: AVPlayer?
    private var playerLayer: AVPlayerLayer?
    private var endObserver: NSObjectProtocol?

    private let coverImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.backgroundColor = UIColor(white: 0.1, alpha: 1)
        return imageView
    }()

    private let gradientLayer: CAGradientLayer = {
        let layer = CAGradientLayer()
        layer.colors = [
            UIColor.clear.cgColor,
            UIColor.black.withAlphaComponent(0.2).cgColor,
            UIColor.black.withAlphaComponent(0.9).cgColor
        ]
        layer.locations = [0.0, 0.5, 1.0]
        return layer
    }()

    private let glassInfoView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.white.opacity(0.08)
        let blur = UIBlurEffect(style: .systemThinMaterialDark)
        let blurView = UIVisualEffectView(effect: blur)
        view.insertSubview(blurView, at: 0)
        blurView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.layer.cornerRadius = 14
        view.clipsToBounds = true
        view.layer.borderWidth = 0.5
        view.layer.borderColor = UIColor.white.withAlphaComponent(0.1).cgColor
        return view
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 1
        label.font = .systemFont(ofSize: 13, weight: .bold)
        label.textColor = .white
        return label
    }()

    private let avatarImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 10
        imageView.backgroundColor = .systemGray4
        return imageView
    }()

    private let nameLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 10, weight: .medium)
        label.textColor = .white.withAlphaComponent(0.7)
        return label
    }()

    private let likeIcon: UIImageView = {
        let iv = UIImageView(image: UIImage(systemName: "bolt.heart.fill"))
        iv.tintColor = UIColor(red: 0, green: 242/255, blue: 255/255, alpha: 1) // accentSecondary
        iv.contentMode = .scaleAspectFit
        return iv
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)

        contentView.backgroundColor = .clear
        contentView.layer.cornerRadius = 20
        contentView.layer.masksToBounds = true

        // 外层投影 (Shadow on the layer below)
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.3
        layer.shadowOffset = CGSize(width: 0, height: 4)
        layer.shadowRadius = 8

        contentView.addSubview(coverImageView)
        coverImageView.layer.addSublayer(gradientLayer)

        contentView.addSubview(glassInfoView)
        glassInfoView.addSubview(titleLabel)
        glassInfoView.addSubview(avatarImageView)
        glassInfoView.addSubview(nameLabel)
        glassInfoView.addSubview(likeIcon)

        [coverImageView, glassInfoView, titleLabel, avatarImageView, nameLabel, likeIcon].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
        }

        NSLayoutConstraint.activate([
            coverImageView.topAnchor.constraint(equalTo: contentView.topAnchor),
            coverImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            coverImageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            coverImageView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),

            glassInfoView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 8),
            glassInfoView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -8),
            glassInfoView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8),
            glassInfoView.heightAnchor.constraint(equalToConstant: 52),

            avatarImageView.leadingAnchor.constraint(equalTo: glassInfoView.leadingAnchor, constant: 8),
            avatarImageView.centerYAnchor.constraint(equalTo: glassInfoView.centerYAnchor),
            avatarImageView.widthAnchor.constraint(equalToConstant: 24),
            avatarImageView.heightAnchor.constraint(equalToConstant: 24),

            titleLabel.leadingAnchor.constraint(equalTo: avatarImageView.trailingAnchor, constant: 8),
            titleLabel.topAnchor.constraint(equalTo: glassInfoView.topAnchor, constant: 8),
            titleLabel.trailingAnchor.constraint(equalTo: likeIcon.leadingAnchor, constant: -8),

            nameLabel.leadingAnchor.constraint(equalTo: avatarImageView.trailingAnchor, constant: 8),
            nameLabel.bottomAnchor.constraint(equalTo: glassInfoView.bottomAnchor, constant: -8),

            likeIcon.trailingAnchor.constraint(equalTo: glassInfoView.trailingAnchor, constant: -10),
            likeIcon.centerYAnchor.constraint(equalTo: glassInfoView.centerYAnchor),
            likeIcon.widthAnchor.constraint(equalToConstant: 16),
            likeIcon.heightAnchor.constraint(equalToConstant: 16)
        ])
    }

    required init?(coder: NSCoder) { fatalError() }

    override func layoutSubviews() {
        super.layoutSubviews()
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        gradientLayer.frame = coverImageView.bounds
        playerLayer?.frame = coverImageView.bounds
        CATransaction.commit()
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        stopPlayback()
        coverImageView.image = nil
        avatarImageView.image = nil
        titleLabel.text = nil
        nameLabel.text = nil
    }

    func configure(with video: VideoData) {
        videoURL = video.videoURL
        titleLabel.text = video.title.lowercased() == "untitled" ? video.introduction : video.title
        nameLabel.text = video.userName

        coverImageView.kf.setImage(with: video.coverURL, options: [.transition(.fade(0.3))])
        avatarImageView.kf.setImage(with: video.userAvatarURL, options: [.transition(.fade(0.2))])
    }

    func startPlayback() {
        guard let url = videoURL, player == nil else { return }
        let item = AVPlayerItem(url: url)
        player = AVPlayer(playerItem: item)
        player?.isMuted = true
        player?.actionAtItemEnd = .none

        let layer = AVPlayerLayer(player: player)
        layer.videoGravity = .resizeAspectFill
        layer.frame = coverImageView.bounds
        coverImageView.layer.insertSublayer(layer, at: 0)
        playerLayer = layer

        endObserver = NotificationCenter.default.addObserver(forName: .AVPlayerItemDidPlayToEndTime, object: item, queue: .main) { [weak self] _ in
            self?.player?.seek(to: .zero)
            self?.player?.play()
        }
        player?.play()
    }

    func stopPlayback() {
        player?.pause()
        if let observer = endObserver { NotificationCenter.default.removeObserver(observer) }
        playerLayer?.removeFromSuperlayer()
        playerLayer = nil
        player = nil
        endObserver = nil
    }
}

extension UIColor {
    func opacity(_ value: CGFloat) -> UIColor {
        return self.withAlphaComponent(value)
    }
}
