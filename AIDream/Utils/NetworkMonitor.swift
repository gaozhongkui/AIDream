import Network
import Foundation

class NetworkMonitor {
    static let shared = NetworkMonitor()
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "NetworkMonitor")

    var isConnected: Bool = false
    var connectionType: NWInterface.InterfaceType = .other

    private init() {
        monitor.pathUpdateHandler = { path in
            self.isConnected = path.status == .satisfied
            self.getConnectionType(path)

            if self.isConnected {
                NotificationCenter.default.post(name: .networkBecameReachable, object: nil)
            }
        }
        monitor.start(queue: queue)
    }

    private func getConnectionType(_ path: NWPath) {
        if path.usesInterfaceType(.wifi) {
            connectionType = .wifi
        } else if path.usesInterfaceType(.cellular) {
            connectionType = .cellular
        } else if path.usesInterfaceType(.wiredEthernet) {
            connectionType = .wiredEthernet
        } else {
            connectionType = .other
        }
    }
}

extension Notification.Name {
    static let networkBecameReachable = Notification.Name("networkBecameReachable")
}
