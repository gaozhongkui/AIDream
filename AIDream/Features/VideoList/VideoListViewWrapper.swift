import SwiftUI
import UIKit

struct VideoListViewWrapper: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> VideoListViewController {
        VideoListViewController()
    }

    func updateUIViewController(_ uiViewController: VideoListViewController, context: Context) {
        // No update needed
    }
}
