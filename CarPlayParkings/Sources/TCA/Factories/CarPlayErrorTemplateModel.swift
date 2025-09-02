import Foundation

struct CarPlayErrorTemplateModel<T: Sendable>: Identifiable, Equatable, Sendable {
    let id = UUID()
    let type: T
    let title: String
    let description: String?
    let buttonTitle: String

    static func == (lhs: CarPlayErrorTemplateModel<T>, rhs: CarPlayErrorTemplateModel<T>) -> Bool {
        lhs.id == rhs.id &&
        lhs.title == rhs.title &&
        lhs.description == rhs.description &&
        lhs.buttonTitle == rhs.buttonTitle
    }
}
