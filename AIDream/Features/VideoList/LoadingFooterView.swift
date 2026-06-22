import UIKit

final class LoadingFooterView: UICollectionReusableView {
    static let identifier = "LoadingFooterView"

    private let activityIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .medium)
        indicator.color = UIColor(red: 0.3, green: 0.62, blue: 1.0, alpha: 1.0)
        indicator.hidesWhenStopped = true
        return indicator
    }()

    private let noMoreLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 11, weight: .medium)
        label.textColor = UIColor.white.withAlphaComponent(0.2)
        label.textAlignment = .center
        label.isHidden = true
        return label
    }()

    private let separatorLine: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.white.withAlphaComponent(0.05)
        view.isHidden = true
        return view
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(activityIndicator)
        addSubview(noMoreLabel)
        addSubview(separatorLine)

        [activityIndicator, noMoreLabel, separatorLine].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
        }

        NSLayoutConstraint.activate([
            activityIndicator.centerXAnchor.constraint(equalTo: centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: centerYAnchor),

            separatorLine.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 40),
            separatorLine.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -40),
            separatorLine.topAnchor.constraint(equalTo: topAnchor, constant: 16),
            separatorLine.heightAnchor.constraint(equalToConstant: 0.5),

            noMoreLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            noMoreLabel.topAnchor.constraint(equalTo: separatorLine.bottomAnchor, constant: 14)
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setStatus(isLoading: Bool, hasMore: Bool) {
        if isLoading {
            activityIndicator.startAnimating()
            noMoreLabel.isHidden = true
            separatorLine.isHidden = true
        } else {
            activityIndicator.stopAnimating()
            if hasMore {
                noMoreLabel.isHidden = true
                separatorLine.isHidden = true
            } else {
                noMoreLabel.text = NSLocalizedString("label_end_of_universe", comment: "")
                noMoreLabel.isHidden = false
                separatorLine.isHidden = false
            }
        }
    }
}
