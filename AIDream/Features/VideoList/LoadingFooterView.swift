import UIKit

final class LoadingFooterView: UICollectionReusableView {
    static let identifier = "LoadingFooterView"

    private let activityIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .medium)
        indicator.hidesWhenStopped = true
        return indicator
    }()

    private let noMoreLabel: UILabel = {
        let label = UILabel()
        label.text = "— 已经到底啦 —"
        label.font = .systemFont(ofSize: 12)
        label.textColor = .systemGray
        label.textAlignment = .center
        label.isHidden = true
        return label
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(activityIndicator)
        addSubview(noMoreLabel)

        [activityIndicator, noMoreLabel].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
        }

        NSLayoutConstraint.activate([
            activityIndicator.centerXAnchor.constraint(equalTo: centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: centerYAnchor),

            noMoreLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            noMoreLabel.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setStatus(isLoading: Bool, hasMore: Bool) {
        if isLoading {
            activityIndicator.startAnimating()
            noMoreLabel.isHidden = true
        } else {
            activityIndicator.stopAnimating()
            noMoreLabel.isHidden = hasMore // 如果没有更多了，就显示文字
        }
    }
}
