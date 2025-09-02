import Foundation

class CarPlayParkingsAlertModel {
    let alertMessage: String
    let alertButtonText: String
    let alertButtonAction: () -> Void

    init(alertMessage: String, alertButtonText: String, alertButtonAction: @escaping () -> Void) {
        self.alertMessage = alertMessage
        self.alertButtonText = alertButtonText
        self.alertButtonAction = alertButtonAction
    }
}
