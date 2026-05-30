import AVFoundation
import UIKit

final class VideoCell: UICollectionViewCell {
    static let identifier = "VideoCell"

    private var coverTask: URLSessionDataTask?
    private var videoURL: URL?
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

    private let overlayView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.black.withAlphaComponent(0.10)
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
        coverImageView.addSubview(overlayView)
        coverImageView.addSubview(categoryBadge)
        coverImageView.addSubview(durationBadge)
        coverImageView.addSubview(playBadge)
        playBadge.addSubview(playImageView)
        contentView.addSubview(titleLabel)
        contentView.addSubview(subtitleLabel)

        [coverImageView, overlayView, categoryBadge, durationBadge, playBadge, playImageView, titleLabel, subtitleLabel].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
        }

        NSLayoutConstraint.activate([
            coverImageView.topAnchor.constraint(equalTo: contentView.topAnchor),
            coverImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            coverImageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),

            overlayView.topAnchor.constraint(equalTo: coverImageView.topAnchor),
            overlayView.leadingAnchor.constraint(equalTo: coverImageView.leadingAnchor),
            overlayView.trailingAnchor.constraint(equalTo: coverImageView.trailingAnchor),
            overlayView.bottomAnchor.constraint(equalTo: coverImageView.bottomAnchor),

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

    override func layoutSubviews() {
        super.layoutSubviews()
        playerLayer?.frame = coverImageView.bounds
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        stopPlayback()
        coverTask?.cancel()
        coverTask = nil
        videoURL = nil
        coverImageView.image = nil
        titleLabel.text = nil
        subtitleLabel.text = nil
        subtitleLabel.isHidden = false
        categoryBadge.text = nil
        durationBadge.text = nil
        durationBadge.isHidden = false
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
        categoryBadge.text = "  \(VideoData.displayCategory(video.category))  "
        let durationText = video.durationText
        durationBadge.text = durationText.isEmpty ? nil : "  \(durationText)  "
        durationBadge.isHidden = durationText.isEmpty

        loadCoverImage(from: video.coverURL)
    }

    func startPlayback() {
        guard let videoURL else { return }
        configurePlayback(with: videoURL)
        player?.play()
        playBadge.isHidden = true
        playerLayer?.isHidden = false
    }

    func stopPlayback() {
        player?.pause()
        playBadge.isHidden = false
        if let endObserver {
            NotificationCenter.default.removeObserver(endObserver)
            self.endObserver = nil
        }
        playerLayer?.player = nil
        playerLayer?.removeFromSuperlayer()
        playerLayer = nil
        player = nil
    }

    func configurePlayback(with url: URL?) {
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
            coverImageView.layer.insertSublayer(layer, below: overlayView.layer)
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
        guard let url else {
            coverImageView.image = nil
            return
        }

        coverTask = URLSession.shared.dataTask(with: url) { [weak self] data, _, _ in
            guard let data, let image = UIImage(data: data) else { return }
            DispatchQueue.main.async {
                self?.coverImageView.image = image
            }
        }
        coverTask?.resume()
    }
}
