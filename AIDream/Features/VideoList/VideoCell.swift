import AVFoundation
import UIKit

final class VideoCell: UICollectionViewCell {
    static let identifier = "VideoCell"

    private var coverTask: URLSessionDataTask?
    private var videoURL: URL?
    private var pendingCoverURL: URL?
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
        view.isUserInteractionEnabled = false
        return view
    }()

    private let bottomGradientView: UIView = {
        let view = UIView()
        view.isUserInteractionEnabled = false
        return view
    }()

    private let bottomGradientLayer: CAGradientLayer = {
        let layer = CAGradientLayer()
        layer.colors = [
            UIColor.clear.cgColor,
            UIColor.black.withAlphaComponent(0.20).cgColor,
            UIColor.black.withAlphaComponent(0.65).cgColor
        ]
        layer.locations = [0.0, 0.45, 1.0]
        return layer
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 2
        label.font = .systemFont(ofSize: 26, weight: .bold)
        label.textColor = .white
        label.shadowColor = UIColor.black.withAlphaComponent(0.55)
        label.shadowOffset = CGSize(width: 0, height: 1)
        return label
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)

        contentView.backgroundColor = .black
        contentView.layer.cornerRadius = 28
        contentView.layer.masksToBounds = true

        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.10
        layer.shadowOffset = CGSize(width: 0, height: 6)
        layer.shadowRadius = 16
        layer.masksToBounds = false

        contentView.addSubview(coverImageView)
        coverImageView.addSubview(overlayView)
        bottomGradientView.layer.addSublayer(bottomGradientLayer)
        overlayView.addSubview(bottomGradientView)
        bottomGradientView.addSubview(titleLabel)

        [coverImageView, overlayView, bottomGradientView, titleLabel].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
        }

        NSLayoutConstraint.activate([
            coverImageView.topAnchor.constraint(equalTo: contentView.topAnchor),
            coverImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            coverImageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            coverImageView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),

            overlayView.topAnchor.constraint(equalTo: coverImageView.topAnchor),
            overlayView.leadingAnchor.constraint(equalTo: coverImageView.leadingAnchor),
            overlayView.trailingAnchor.constraint(equalTo: coverImageView.trailingAnchor),
            overlayView.bottomAnchor.constraint(equalTo: coverImageView.bottomAnchor),

            bottomGradientView.leadingAnchor.constraint(equalTo: overlayView.leadingAnchor),
            bottomGradientView.trailingAnchor.constraint(equalTo: overlayView.trailingAnchor),
            bottomGradientView.bottomAnchor.constraint(equalTo: overlayView.bottomAnchor),
            bottomGradientView.heightAnchor.constraint(equalTo: overlayView.heightAnchor, multiplier: 0.34),

            titleLabel.leadingAnchor.constraint(equalTo: bottomGradientView.leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: bottomGradientView.trailingAnchor, constant: -20),
            titleLabel.bottomAnchor.constraint(equalTo: bottomGradientView.bottomAnchor, constant: -18)
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        playerLayer?.frame = coverImageView.bounds
        bottomGradientLayer.frame = bottomGradientView.bounds
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        stopPlayback()
        coverTask?.cancel()
        coverTask = nil
        videoURL = nil
        pendingCoverURL = nil
        coverImageView.image = nil
        titleLabel.text = nil
        transform = .identity
    }

    override var isHighlighted: Bool {
        didSet {
            UIView.animate(withDuration: 0.18) {
                self.transform = self.isHighlighted ? CGAffineTransform(scaleX: 0.98, y: 0.98) : .identity
            }
        }
    }

    func configure(with video: VideoData) {
        videoURL = video.videoURL
        pendingCoverURL = video.coverURL
        titleLabel.text = video.displayTitle
        titleLabel.textAlignment = .center
        titleLabel.shadowColor = UIColor.black.withAlphaComponent(0.70)
        titleLabel.shadowOffset = CGSize(width: 0, height: 2)
        titleLabel.layer.shadowOpacity = 0
        coverImageView.image = Self.makeLoadingPlaceholderImage()
        loadCoverImage(from: video.coverURL)
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
            coverImageView.image = Self.makeLoadingPlaceholderImage()
            return
        }

        coverTask = URLSession.shared.dataTask(with: url) { [weak self] data, _, _ in
            guard let data, let image = UIImage(data: data) else { return }
            DispatchQueue.main.async {
                guard let self, self.pendingCoverURL == url else { return }
                self.coverImageView.image = image
            }
        }
        coverTask?.resume()
    }

    private static func makeLoadingPlaceholderImage() -> UIImage {
        if let image = UIImage(named: "LoadingPlaceholder") {
            return image
        }

        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 48, height: 48))
        return renderer.image { context in
            UIColor.systemGray5.setFill()
            context.fill(CGRect(x: 0, y: 0, width: 48, height: 48))
        }
    }
}
