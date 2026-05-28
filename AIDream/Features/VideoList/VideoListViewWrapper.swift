import SwiftUI
import UIKit

struct VideoListViewWrapper: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> UINavigationController {
        let videoListVC = VideoListViewController()
        let navController = UINavigationController(rootViewController: videoListVC)
        return navController
    }

    func updateUIViewController(_ uiViewController: UINavigationController, context: Context) {
        // No update needed
    }
}
