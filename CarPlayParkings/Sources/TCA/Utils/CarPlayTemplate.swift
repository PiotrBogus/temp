import Foundation

protocol CarPlayTemplate: Identifiable {
    var id: String { get }
}

extension CarPlayTemplate {
    var id: String { String(describing: Self.self) }
}
