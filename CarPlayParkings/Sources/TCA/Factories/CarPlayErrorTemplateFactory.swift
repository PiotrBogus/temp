import CarPlay
import Foundation

struct CarPlayErrorTemplateFactory {
    static func make<T>(errorModel: CarPlayErrorTemplateModel<T>, onButtonTap: @escaping () -> Void) -> CPAlertTemplate {
        let alertAction = CPAlertAction(title: errorModel.buttonTitle, style: .default) { _ in
            onButtonTap()
        }
        let template = CPAlertTemplate(titleVariants: [errorModel.title],
                                       actions: [alertAction])
        return template
    }
}
