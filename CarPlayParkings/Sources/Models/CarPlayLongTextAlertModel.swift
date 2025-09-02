import CarPlay
import Foundation

struct CarPlayLongTextAlertModel {
    let title: String
    let items: [String]?
    let buttonTitle: String
    let onButtonHandler: (() -> Void)?
}
