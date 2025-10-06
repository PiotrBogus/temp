import SwiftUI
import UIKit

final class MenuOverlayWindow {
    private var hostingController: UIHostingController<AnyView>?

    func show<Content: View>(_ view: Content) {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootWindow = windowScene.windows.first else {
            return
        }

        // Usuń stary overlay jeśli istnieje
        hide()

        let hosting = UIHostingController(rootView: AnyView(view))
        hosting.view.backgroundColor = .clear
        hosting.view.frame = rootWindow.bounds
        hosting.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        hosting.view.isUserInteractionEnabled = true

        // Dodaj jako subview — ale na samą górę hierarchii
        rootWindow.addSubview(hosting.view)

        // Animacja fade-in
        hosting.view.alpha = 0
        UIView.animate(withDuration: 0.25) {
            hosting.view.alpha = 1
        }

        hostingController = hosting
    }

    func hide(animated: Bool = true) {
        guard let view = hostingController?.view else { return }

        let remove = {
            view.removeFromSuperview()
            self.hostingController = nil
        }

        if animated {
            UIView.animate(withDuration: 0.25, animations: {
                view.alpha = 0
            }, completion: { _ in
                remove()
            })
        } else {
            remove()
        }
    }
}
