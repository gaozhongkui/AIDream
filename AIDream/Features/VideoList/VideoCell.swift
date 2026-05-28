import UIKit
import ImageIO

class VideoCell: UICollectionViewCell {
    static let identifier = "VideoCell"

    private let imageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.layer.cornerRadius = 16 // 增大圆角，更有现代手机 App 感
        iv.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        iv.backgroundColor = .systemGray6
        return iv
    }()

    private let promptLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 2
        label.font = .systemFont(ofSize: 13, weight: .semibold)
        label.textColor = .label
        label.lineBreakMode = .byTruncatingTail
        return label
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)

        // 容器样式优化
        contentView.backgroundColor = .systemBackground
        contentView.layer.cornerRadius = 16
        contentView.layer.masksToBounds = true

        // 细腻的投影
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.05
        layer.shadowOffset = CGSize(width: 0, height: 4)
        layer.shadowRadius = 10
        layer.masksToBounds = false

        contentView.addSubview(imageView)
        contentView.addSubview(promptLabel)

        imageView.translatesAutoresizingMaskIntoConstraints = false
        promptLabel.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: contentView.topAnchor),
            imageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),

            promptLabel.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 12),
            promptLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 12),
            promptLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -12),
            promptLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -14)
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // 增加点击时的缩放反馈，让它更有“手机应用”的交互感
    override var isHighlighted: Bool {
        didSet {
            UIView.animate(withDuration: 0.2) {
                self.transform = self.isHighlighted ? CGAffineTransform(scaleX: 0.96, y: 0.96) : .identity
            }
        }
    }

    func configure(with video: VideoData) {
        promptLabel.text = video.prompt

        // 加载 GIF
        if let url = URL(string: video.video) {
            URLSession.shared.dataTask(with: url) { [weak self] data, _, _ in
                if let data = data, let image = UIImage.gifImageWithData(data) {
                    DispatchQueue.main.async {
                        self?.imageView.image = image
                    }
                }
            }.resume()
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        imageView.image = nil
        promptLabel.text = nil
    }
}
