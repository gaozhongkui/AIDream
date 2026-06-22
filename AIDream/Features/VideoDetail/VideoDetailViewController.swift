import UIKit

extension Notification.Name {
    static let switchToReferenceMode = Notification.Name("SwitchToReferenceMode")
}

final class VideoDetailViewController: UIViewController {
    private var videos: [VideoData]
    private var initialIndex: Int
    private var isInitialScrollDone = false

    private lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.minimumLineSpacing = 0
        layout.minimumInteritemSpacing = 0
        layout.itemSize = UIScreen.main.bounds.size

        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.backgroundColor = .black
        cv.isPagingEnabled = true
        cv.contentInsetAdjustmentBehavior = .never
        cv.showsVerticalScrollIndicator = false
        cv.register(VideoDetailCell.self, forCellWithReuseIdentifier: VideoDetailCell.identifier)
        cv.dataSource = self
        cv.delegate = self
        return cv
    }()

    init(videos: [VideoData], initialIndex: Int) {
        self.videos = videos
        self.initialIndex = initialIndex
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .fullScreen
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        view.addSubview(collectionView)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: view.topAnchor),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        // 在布局完成后，且仅执行一次精准滚动
        if !isInitialScrollDone {
            isInitialScrollDone = true
            let indexPath = IndexPath(item: initialIndex, section: 0)
            collectionView.scrollToItem(at: indexPath, at: .top, animated: false)

            // 滚动后立即触发当前可见 Cell 的播放
            DispatchQueue.main.async {
                if let cell = self.collectionView.cellForItem(at: indexPath) as? VideoDetailCell {
                    cell.startPlayback()
                }
            }
        }
    }

    override var prefersStatusBarHidden: Bool {
        return true
    }

    private func showFeedbackAlert() {
        let feedbackVC = FeedbackPopupViewController()
        feedbackVC.modalPresentationStyle = .overFullScreen
        feedbackVC.modalTransitionStyle = .crossDissolve
        feedbackVC.onSuccess = { [weak self] in
            self?.showSuccessToast()
        }
        present(feedbackVC, animated: true)
    }

    private func showSuccessToast() {
        let toast = UIAlertController(
            title: NSLocalizedString("alert_feedback_success_title", comment: ""),
            message: NSLocalizedString("alert_feedback_success_msg", comment: ""),
            preferredStyle: .alert
        )
        present(toast, animated: true)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            toast.dismiss(animated: true)
        }
    }
}

extension VideoDetailViewController: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return videos.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: VideoDetailCell.identifier, for: indexPath) as! VideoDetailCell
        cell.configure(with: videos[indexPath.item])
        cell.onBackTapped = { [weak self] in
            self?.dismiss(animated: true)
        }
        cell.onRemixTapped = { [weak self] in
            self?.dismiss(animated: true) {
                NotificationCenter.default.post(name: .switchToReferenceMode, object: nil)
            }
        }
        cell.onFeedbackTapped = { [weak self] in
            self?.showFeedbackAlert()
        }
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        // 当 Cell 即将显示时，重新开始播放
        (cell as? VideoDetailCell)?.startPlayback()
    }

    func collectionView(_ collectionView: UICollectionView, didEndDisplaying cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        (cell as? VideoDetailCell)?.stopPlayback()
    }
}

// MARK: - Custom Feedback Popup
final class FeedbackPopupViewController: UIViewController {
    var onSuccess: (() -> Void)?

    private let containerView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor(red: 22/255, green: 20/255, blue: 24/255, alpha: 1) // bgSecondary
        view.layer.cornerRadius = 24
        view.layer.borderWidth = 1
        view.layer.borderColor = UIColor.white.withAlphaComponent(0.1).cgColor
        view.clipsToBounds = true
        return view
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = NSLocalizedString("title_feedback", comment: "")
        label.textColor = .white
        label.font = .systemFont(ofSize: 20, weight: .bold)
        label.textAlignment = .center
        return label
    }()

    private let subtitleLabel: UILabel = {
        let label = UILabel()
        label.text = NSLocalizedString("label_feedback_subtitle", comment: "")
        label.textColor = UIColor.white.withAlphaComponent(0.6)
        label.font = .systemFont(ofSize: 14)
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()

    private let textView: UITextView = {
        let tv = UITextView()
        tv.backgroundColor = UIColor.white.withAlphaComponent(0.05)
        tv.layer.cornerRadius = 12
        tv.textColor = .white
        tv.font = .systemFont(ofSize: 15)
        tv.textContainerInset = UIEdgeInsets(top: 12, left: 12, bottom: 12, right: 12)
        return tv
    }()

    private let placeholderLabel: UILabel = {
        let label = UILabel()
        label.text = NSLocalizedString("placeholder_feedback", comment: "")
        label.textColor = UIColor.white.withAlphaComponent(0.3)
        label.font = .systemFont(ofSize: 15)
        return label
    }()

    private lazy var submitButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle(NSLocalizedString("btn_submit", comment: ""), for: .normal)
        btn.setTitleColor(.white, for: .normal)
        btn.titleLabel?.font = .systemFont(ofSize: 16, weight: .bold)
        btn.backgroundColor = UIColor(red: 111/255, green: 49/255, blue: 213/255, alpha: 1) // accentPrimary
        btn.layer.cornerRadius = 14
        btn.isEnabled = false
        btn.alpha = 0.5
        return btn
    }()

    private let cancelButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle(NSLocalizedString("btn_cancel", comment: ""), for: .normal)
        btn.setTitleColor(UIColor.white.withAlphaComponent(0.5), for: .normal)
        btn.titleLabel?.font = .systemFont(ofSize: 15)
        return btn
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        textView.delegate = self
        submitButton.addTarget(self, action: #selector(submitTapped), for: .touchUpInside)
        cancelButton.addTarget(self, action: #selector(cancelTapped), for: .touchUpInside)

        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        view.addGestureRecognizer(tap)
    }

    private func setupUI() {
        view.backgroundColor = UIColor.black.withAlphaComponent(0.7)
        view.addSubview(containerView)
        containerView.translatesAutoresizingMaskIntoConstraints = false

        [titleLabel, subtitleLabel, textView, placeholderLabel, submitButton, cancelButton].forEach {
            containerView.addSubview($0)
            $0.translatesAutoresizingMaskIntoConstraints = false
        }

        NSLayoutConstraint.activate([
            containerView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            containerView.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -40),
            containerView.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.85),

            titleLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 24),
            titleLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),

            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            subtitleLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 24),
            subtitleLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -24),

            textView.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: 20),
            textView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            textView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),
            textView.heightAnchor.constraint(equalToConstant: 120),

            placeholderLabel.topAnchor.constraint(equalTo: textView.topAnchor, constant: 12),
            placeholderLabel.leadingAnchor.constraint(equalTo: textView.leadingAnchor, constant: 16),

            submitButton.topAnchor.constraint(equalTo: textView.bottomAnchor, constant: 24),
            submitButton.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            submitButton.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),
            submitButton.heightAnchor.constraint(equalToConstant: 50),

            cancelButton.topAnchor.constraint(equalTo: submitButton.bottomAnchor, constant: 8),
            cancelButton.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            cancelButton.heightAnchor.constraint(equalToConstant: 44),
            cancelButton.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -12)
        ])
    }

    @objc private func submitTapped() {
        dismiss(animated: true) {
            self.onSuccess?()
        }
    }

    @objc private func cancelTapped() {
        dismiss(animated: true)
    }

    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }
}

extension FeedbackPopupViewController: UITextViewDelegate {
    func textViewDidChange(_ textView: UITextView) {
        let isEmpty = textView.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        placeholderLabel.isHidden = !textView.text.isEmpty
        submitButton.isEnabled = !isEmpty
        submitButton.alpha = isEmpty ? 0.5 : 1.0
    }
}
