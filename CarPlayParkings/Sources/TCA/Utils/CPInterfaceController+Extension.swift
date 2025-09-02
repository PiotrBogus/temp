import CarPlay
import Foundation

extension CPInterfaceController {
    func dismissAndPresent(
        template: CPTemplate,
        animated: Bool = true,
        completion: ((Bool, (any Error)?) -> Void)? = nil
    ) {
        if presentedTemplate != nil {
            dismissTemplate(animated: false) { [weak self] _, _ in
                self?.presentTemplate(template, animated: animated, completion: completion)
            }
        } else {
            presentTemplate(template, animated: animated, completion: completion)
        }
    }

    func dismissAndPush(
        template: CPTemplate,
        animated: Bool = true,
        completion: ((Bool, (any Error)?) -> Void)? = nil
    ) {
        if presentedTemplate != nil {
            dismissTemplate(animated: false) { [weak self] _, _ in
                self?.pushTemplate(template, animated: animated, completion: completion)
            }
        } else {
            pushTemplate(template, animated: animated, completion: completion)
        }
    }

    func dismissAndSetAsRoot(
        template: CPTemplate,
        animated: Bool = true,
        completion: ((Bool, (any Error)?) -> Void)? = nil
    ) {
        if presentedTemplate != nil {
            dismissTemplate(animated: false) { [weak self] _, _ in
                self?.setRootTemplate(template, animated: animated, completion: completion)
            }
        } else {
            setRootTemplate(template, animated: animated, completion: completion)
        }
    }
}
