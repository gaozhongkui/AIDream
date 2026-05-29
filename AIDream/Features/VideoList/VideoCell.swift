import UIKit
import Kingfisher

final class VideoCell: UICollectionViewCell {
    static let identifier = "VideoCell"

    // MARK: - Views

    private let gifImageView: AnimatedImageView = {
        let v = AnimatedImageView()
        v.contentMode = .scaleAspectFill
        v.clipsToBounds = true
        v.backgroundColor = .systemGray5
        v.framePreloadCount = 10
        v.repeatCount = .infinite
        return v
    }()

    private let gradientView: UIView = {
        let v = UIView()
        v.isUserInteractionEnabled = false
        return v
    }()
    private var gradientLayer: CAGradientLayer?

    private let titleLabel: UILabel = {
        let l = UILabel()
        l.numberOfLines = 3
        l.font = .systemFont(ofSize: 16, weight: .bold)
        l.textColor = .white
        l.shadowColor = UIColor.black.withAlphaComponent(0.4)
        l.shadowOffset = CGSize(width: 0, height: 1)
        return l
    }()


    // MARK: - Init

    override init(frame: CGRect) {
        super.init(frame: frame)

        contentView.layer.cornerRadius = 16
        contentView.layer.masksToBounds = true

        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.15
        layer.shadowOffset = CGSize(width: 0, height: 4)
        layer.shadowRadius = 10
        layer.masksToBounds = false

        contentView.addSubview(gifImageView)
        contentView.addSubview(gradientView)
        contentView.addSubview(titleLabel)

        [gifImageView, gradientView, titleLabel].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
        }

        NSLayoutConstraint.activate([
            gifImageView.topAnchor.constraint(equalTo: contentView.topAnchor),
            gifImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            gifImageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            gifImageView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),

            gradientView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            gradientView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            gradientView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            gradientView.heightAnchor.constraint(equalTo: contentView.heightAnchor, multiplier: 0.6),

            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 12),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -12),
            titleLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -12),
        ])
    }

    required init?(coder: NSCoder) { fatalError() }

    // MARK: - Layout

    override func layoutSubviews() {
        super.layoutSubviews()
        if gradientLayer == nil {
            let gl = CAGradientLayer()
            gl.colors = [
                UIColor.clear.cgColor,
                UIColor.black.withAlphaComponent(0.75).cgColor
            ]
            gl.locations = [0, 1]
            gradientLayer = gl
            gradientView.layer.insertSublayer(gl, at: 0)
        }
        gradientLayer?.frame = gradientView.bounds
    }

    // MARK: - Reuse

    override func prepareForReuse() {
        super.prepareForReuse()
        gifImageView.kf.cancelDownloadTask()
        gifImageView.image = nil
        gifImageView.stopAnimating()
        titleLabel.text = nil
        transform = .identity
    }

    override var isHighlighted: Bool {
        didSet {
            UIView.animate(withDuration: 0.15) {
                self.transform = self.isHighlighted
                    ? CGAffineTransform(scaleX: 0.96, y: 0.96)
                    : .identity
            }
        }
    }

    // MARK: - Configure

    func configure(with video: VideoData) {
        titleLabel.text = video.displayTitle

        guard let url = video.coverURL else { return }
        gifImageView.kf.setImage(with: url, options: [.cacheOriginalImage, .backgroundDecode])
    }

    func startPlayback() { gifImageView.startAnimating() }
    func stopPlayback()  { gifImageView.stopAnimating() }
}
