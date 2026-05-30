import AVFoundation
import UIKit

final class VideoCell: UICollectionViewCell {
    static let identifier = "VideoCell"

    private var coverTask: URLSessionDataTask?
    private var avatarTask: URLSessionDataTask?
    private var videoURL: URL?
    private var pendingCoverURL: URL?
    private var pendingAvatarURL: URL?

    private var player: AVPlayer?
    private var playerLayer: AVPlayerLayer?
    private var endObserver: NSObjectProtocol?

    private let coverImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.backgroundColor = .systemGray6
        return imageView
    }()

    private let gradientLayer: CAGradientLayer = {
        let layer = CAGradientLayer()
        layer.colors = [
            UIColor.clear.cgColor,
            UIColor.black.withAlphaComponent(0.1).cgColor,
            UIColor.black.withAlphaComponent(0.8).cgColor
        ]
        layer.locations = [0.0, 0.4, 1.0]
        return layer
    }()

    private let gradientView: UIView = {
        let view = UIView()
        view.isUserInteractionEnabled = false
        return view
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 2
        label.font = .systemFont(ofSize: 14, weight: .semibold)
        label.textColor = .white
        return label
    }()

    private let avatarImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 12 // 24/2 = 12 确保是圆
        imageView.backgroundColor = .systemGray4
        return imageView
    }()

    private let avatarInitialLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 12, weight: .bold) // 稍微大一点更清晰
        label.textColor = .white
        label.textAlignment = .center
        return label
    }()

    private let nameLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 11, weight: .medium)
        label.textColor = .white.withAlphaComponent(0.9)
        return label
    }()

    private let starIcon: UIImageView = {
        let iv = UIImageView(image: UIImage(systemName: "heart.fill"))
        iv.tintColor = .white.withAlphaComponent(0.8)
        iv.contentMode = .scaleAspectFit
        return iv
    }()

    private let starLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 11, weight: .medium)
        label.textColor = .white.withAlphaComponent(0.9)
        return label
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)

        contentView.backgroundColor = .secondarySystemGroupedBackground
        contentView.layer.cornerRadius = 16
        contentView.layer.masksToBounds = true

        contentView.addSubview(coverImageView)
        contentView.addSubview(gradientView)
        gradientView.layer.addSublayer(gradientLayer)

        contentView.addSubview(titleLabel)
        contentView.addSubview(avatarImageView)
        avatarImageView.addSubview(avatarInitialLabel)
        contentView.addSubview(nameLabel)
        contentView.addSubview(starIcon)
        contentView.addSubview(starLabel)

        [coverImageView, gradientView, titleLabel, avatarImageView, avatarInitialLabel, nameLabel, starIcon, starLabel].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
        }

        NSLayoutConstraint.activate([
            coverImageView.topAnchor.constraint(equalTo: contentView.topAnchor),
            coverImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            coverImageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            coverImageView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),

            gradientView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            gradientView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            gradientView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            gradientView.heightAnchor.constraint(equalToConstant: 100),

            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 10),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -10),
            titleLabel.bottomAnchor.constraint(equalTo: avatarImageView.topAnchor, constant: -8),

            avatarImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 10),
            avatarImageView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -10),
            avatarImageView.widthAnchor.constraint(equalToConstant: 24),
            avatarImageView.heightAnchor.constraint(equalToConstant: 24),

            avatarInitialLabel.centerXAnchor.constraint(equalTo: avatarImageView.centerXAnchor),
            avatarInitialLabel.centerYAnchor.constraint(equalTo: avatarImageView.centerYAnchor),

            nameLabel.leadingAnchor.constraint(equalTo: avatarImageView.trailingAnchor, constant: 8),
            nameLabel.centerYAnchor.constraint(equalTo: avatarImageView.centerYAnchor),
            nameLabel.trailingAnchor.constraint(lessThanOrEqualTo: starIcon.leadingAnchor, constant: -4),

            starLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -10),
            starLabel.centerYAnchor.constraint(equalTo: avatarImageView.centerYAnchor),

            starIcon.trailingAnchor.constraint(equalTo: starLabel.leadingAnchor, constant: -2),
            starIcon.centerYAnchor.constraint(equalTo: avatarImageView.centerYAnchor),
            starIcon.widthAnchor.constraint(equalToConstant: 12),
            starIcon.heightAnchor.constraint(equalToConstant: 12)
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        gradientLayer.frame = gradientView.bounds
        playerLayer?.frame = coverImageView.bounds
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        stopPlayback()
        coverTask?.cancel()
        avatarTask?.cancel()
        coverTask = nil
        avatarTask = nil
        videoURL = nil
        pendingCoverURL = nil
        pendingAvatarURL = nil
        coverImageView.image = nil
        avatarImageView.image = nil
        titleLabel.text = nil
        nameLabel.text = nil
        starLabel.text = nil
        transform = .identity
    }

    override var isHighlighted: Bool {
        didSet {
            UIView.animate(withDuration: 0.1) {
                self.transform = self.isHighlighted ? CGAffineTransform(scaleX: 0.96, y: 0.96) : .identity
            }
        }
    }

    func configure(with video: VideoData) {
        videoURL = video.videoURL
        pendingCoverURL = video.coverURL
        pendingAvatarURL = video.userAvatarURL

        // 标题降噪：过滤 "Untitled"，优先使用 introduction
        let displayTitle = video.title.lowercased() == "untitled" ? "" : video.title
        titleLabel.text = displayTitle.isEmpty ? video.introduction : displayTitle
        titleLabel.font = .systemFont(ofSize: 14, weight: .semibold)

        nameLabel.text = video.userName
        starLabel.text = formatCount(video.starCount)

        // 设置首字母及其彩色背景
        if let firstChar = video.userName.first {
            avatarInitialLabel.text = String(firstChar).uppercased()
            avatarInitialLabel.isHidden = false
            avatarImageView.backgroundColor = colorForString(video.userName)
        } else {
            avatarInitialLabel.text = nil
            avatarImageView.backgroundColor = .systemGray4
        }

        loadCoverImage(from: video.coverURL)
        loadAvatarImage(from: video.userAvatarURL)
    }

    private func colorForString(_ str: String) -> UIColor {
        let colors: [UIColor] = [.systemBlue, .systemIndigo, .systemPurple, .systemPink, .systemOrange, .systemTeal, .systemGreen]
        let hash = abs(str.hashValue)
        return colors[hash % colors.count].withAlphaComponent(0.9)
    }

    private func formatCount(_ count: Int) -> String {
        if count >= 10000 {
            return String(format: "%.1fw", Double(count) / 10000.0)
        } else if count >= 1000 {
            return String(format: "%.1fk", Double(count) / 1000.0)
        }
        return "\(count)"
    }

    func startPlayback() {
        guard let videoURL else { return }
        configurePlayback(with: videoURL)
        player?.play()
    }

    func stopPlayback() {
        player?.pause()
        if let endObserver {
            NotificationCenter.default.removeObserver(endObserver)
            self.endObserver = nil
        }
        playerLayer?.player = nil
        playerLayer?.removeFromSuperlayer()
        playerLayer = nil
        player = nil
    }

    private func configurePlayback(with url: URL?) {
        guard let url else {
            stopPlayback()
            return
        }

        if player == nil {
            let item = AVPlayerItem(url: url)
            let newPlayer = AVPlayer(playerItem: item)
            newPlayer.isMuted = true
            newPlayer.actionAtItemEnd = .none
            player = newPlayer

            let layer = AVPlayerLayer(player: newPlayer)
            layer.videoGravity = .resizeAspectFill
            layer.frame = coverImageView.bounds
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
        }
    }

    private func loadCoverImage(from url: URL?) {
        guard let url else { return }
        coverTask = URLSession.shared.dataTask(with: url) { [weak self] data, _, _ in
            guard let data, let image = UIImage(data: data) else { return }
            DispatchQueue.main.async {
                guard let self, self.pendingCoverURL == url else { return }
                self.coverImageView.image = image
            }
        }
        coverTask?.resume()
    }

    private func loadAvatarImage(from url: URL?) {
        guard let url else { return }
        avatarTask = URLSession.shared.dataTask(with: url) { [weak self] data, _, _ in
            guard let data, let image = UIImage(data: data) else { return }
            DispatchQueue.main.async {
                guard let self, self.pendingAvatarURL == url else { return }
                self.avatarImageView.image = image
                self.avatarInitialLabel.isHidden = true // 加载成功后隐藏文字
            }
        }
        avatarTask?.resume()
    }
}
