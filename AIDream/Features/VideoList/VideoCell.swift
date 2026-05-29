import AVFoundation
import UIKit

final class VideoCell: UICollectionViewCell {
    static let identifier = "VideoCell"

    private var imageTask: URLSessionDataTask?
    private var aspectConstraint: NSLayoutConstraint?
    private var videoURL: URL?
    private var player: AVPlayer?
    private var playerLayer: AVPlayerLayer?
    private var endObserver: NSObjectProtocol?

    private let coverImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.backgroundColor = .systemGray6
        imageView.layer.cornerRadius = 16
        imageView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        return imageView
    }()

    private let dimmingView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.black.withAlphaComponent(0.08)
        view.isUserInteractionEnabled = false
        return view
    }()

    private let playBadge: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.black.withAlphaComponent(0.35)
        view.layer.cornerRadius = 20
        view.isUserInteractionEnabled = false
        return view
    }()

    private let playImageView: UIImageView = {
        let imageView = UIImageView(image: UIImage(systemName: "play.fill"))
        imageView.tintColor = .white
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()

    private let categoryBadge: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 11, weight: .semibold)
        label.textColor = .white
        label.backgroundColor = UIColor.black.withAlphaComponent(0.45)
        label.layer.cornerRadius = 10
        label.layer.masksToBounds = true
        label.textAlignment = .center
        return label
    }()

    private let durationBadge: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 11, weight: .semibold)
        label.textColor = .white
        label.backgroundColor = UIColor.black.withAlphaComponent(0.45)
        label.layer.cornerRadius = 10
        label.layer.masksToBounds = true
        label.textAlignment = .center
        return label
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 2
        label.font = .systemFont(ofSize: 14, weight: .semibold)
        label.textColor = .label
        return label
    }()

    private let subtitleLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 2
        label.font = .systemFont(ofSize: 12, weight: .regular)
        label.textColor = .secondaryLabel
        return label
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)

        contentView.backgroundColor = .systemBackground
        contentView.layer.cornerRadius = 16
        contentView.layer.masksToBounds = true

        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.08
        layer.shadowOffset = CGSize(width: 0, height: 4)
        layer.shadowRadius = 10
        layer.masksToBounds = false

        contentView.addSubview(coverImageView)
        coverImageView.addSubview(dimmingView)
        coverImageView.addSubview(categoryBadge)
        coverImageView.addSubview(durationBadge)
        coverImageView.addSubview(playBadge)
        playBadge.addSubview(playImageView)
        contentView.addSubview(titleLabel)
        contentView.addSubview(subtitleLabel)

        coverImageView.translatesAutoresizingMaskIntoConstraints = false
        dimmingView.translatesAutoresizingMaskIntoConstraints = false
        categoryBadge.translatesAutoresizingMaskIntoConstraints = false
        durationBadge.translatesAutoresizingMaskIntoConstraints = false
        playBadge.translatesAutoresizingMaskIntoConstraints = false
        playImageView.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            coverImageView.topAnchor.constraint(equalTo: contentView.topAnchor),
            coverImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            coverImageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),

            dimmingView.topAnchor.constraint(equalTo: coverImageView.topAnchor),
            dimmingView.leadingAnchor.constraint(equalTo: coverImageView.leadingAnchor),
            dimmingView.trailingAnchor.constraint(equalTo: coverImageView.trailingAnchor),
            dimmingView.bottomAnchor.constraint(equalTo: coverImageView.bottomAnchor),

            categoryBadge.topAnchor.constraint(equalTo: coverImageView.topAnchor, constant: 10),
            categoryBadge.leadingAnchor.constraint(equalTo: coverImageView.leadingAnchor, constant: 10),
            categoryBadge.heightAnchor.constraint(equalToConstant: 20),

            durationBadge.topAnchor.constraint(equalTo: coverImageView.topAnchor, constant: 10),
            durationBadge.trailingAnchor.constraint(equalTo: coverImageView.trailingAnchor, constant: -10),
            durationBadge.heightAnchor.constraint(equalToConstant: 20),

            playBadge.centerXAnchor.constraint(equalTo: coverImageView.centerXAnchor),
            playBadge.centerYAnchor.constraint(equalTo: coverImageView.centerYAnchor),
            playBadge.widthAnchor.constraint(equalToConstant: 40),
            playBadge.heightAnchor.constraint(equalToConstant: 40),

            playImageView.centerXAnchor.constraint(equalTo: playBadge.centerXAnchor),
            playImageView.centerYAnchor.constraint(equalTo: playBadge.centerYAnchor),
            playImageView.widthAnchor.constraint(equalToConstant: 14),
            playImageView.heightAnchor.constraint(equalToConstant: 14),

            titleLabel.topAnchor.constraint(equalTo: coverImageView.bottomAnchor, constant: 10),
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 12),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -12),

            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
            subtitleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 12),
            subtitleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -12),
            subtitleLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -12)
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        imageTask?.cancel()
        imageTask = nil
        stopPlayback()
        coverImageView.image = nil
        titleLabel.text = nil
        subtitleLabel.text = nil
        subtitleLabel.isHidden = false
        categoryBadge.text = nil
        durationBadge.text = nil
        durationBadge.isHidden = false
        videoURL = nil
        aspectConstraint?.isActive = false
        aspectConstraint = nil
        transform = .identity
    }

    override var isHighlighted: Bool {
        didSet {
            UIView.animate(withDuration: 0.18) {
                self.transform = self.isHighlighted ? CGAffineTransform(scaleX: 0.97, y: 0.97) : .identity
            }
        }
    }

    func configure(with video: VideoData) {
        videoURL = video.videoURL
        titleLabel.text = video.displayTitle
        let subtitle = video.secondaryText
        subtitleLabel.text = subtitle.isEmpty ? nil : subtitle
        subtitleLabel.isHidden = subtitle.isEmpty
        categoryBadge.text = "  \(VideoData.filterTitle(for: video.type))  "
        let durationText = video.durationText
        durationBadge.text = durationText.isEmpty ? nil : "  \(durationText)  "
        durationBadge.isHidden = durationText.isEmpty

        updateAspectRatio(video.aspectRatio)
        loadCoverImage(from: video.coverURL)
    }

    func startPlayback() {
        guard let videoURL else { return }

        if player == nil {
            let playerItem = AVPlayerItem(url: videoURL)
            let player = AVPlayer(playerItem: playerItem)
            player.isMuted = true
            player.actionAtItemEnd = .none
            self.player = player

            let layer = AVPlayerLayer(player: player)
            layer.videoGravity = .resizeAspectFill
            layer.frame = coverImageView.bounds
            coverImageView.layer.insertSublayer(layer, at: 0)
            playerLayer = layer

            if endObserver == nil {
                endObserver = NotificationCenter.default.addObserver(
                    forName: .AVPlayerItemDidPlayToEndTime,
                    object: playerItem,
                    queue: .main
                ) { [weak self] _ in
                    guard let self else { return }
                    self.player?.seek(to: .zero)
                    self.player?.play()
                }
            }
        }

        playBadge.isHidden = true
        playerLayer?.frame = coverImageView.bounds
        player?.play()
    }

    func stopPlayback() {
        player?.pause()
        playBadge.isHidden = false
        playerLayer?.player = nil
        playerLayer?.removeFromSuperlayer()
        playerLayer = nil
        player = nil

        if let endObserver {
            NotificationCenter.default.removeObserver(endObserver)
            self.endObserver = nil
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        playerLayer?.frame = coverImageView.bounds
    }

    private func updateAspectRatio(_ aspectRatio: CGFloat) {
        aspectConstraint?.isActive = false
        let safeRatio = max(aspectRatio, 0.6)
        let constraint = coverImageView.heightAnchor.constraint(equalTo: coverImageView.widthAnchor, multiplier: 1 / safeRatio)
        constraint.isActive = true
        aspectConstraint = constraint
    }

    private func loadCoverImage(from url: URL?) {
        guard let url else {
            coverImageView.image = nil
            return
        }

        imageTask = URLSession.shared.dataTask(with: url) { [weak self] data, _, _ in
            guard let data, let image = UIImage(data: data) else { return }
            DispatchQueue.main.async {
                self?.coverImageView.image = image
            }
        }
        imageTask?.resume()
    }
}
