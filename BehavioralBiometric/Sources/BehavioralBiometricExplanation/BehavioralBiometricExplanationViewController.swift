import Assembly
import ComposableArchitecture
import Foundation
import Labels
import UIComponents
import SwiftUI
import SwinjectAutoregistration

public final class BehavioralBiometricExplanationViewController: IKOBaseViewController {
    private let store: StoreOf<BehavioralBiometricExplanationReducer>
    private let navigationProvider: BehavioralBiometricExtendedNavigationProviding = IKOAssembler.resolver~>

    public init(isPrimaryButtonVisible: Bool) {
        self.store = Store(initialState: BehavioralBiometricExplanationReducer.State(isPrimaryButtonVisible: isPrimaryButtonVisible)) { BehavioralBiometricExplanationReducer()
        }
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { nil }

    override public func viewDidLoad() {
        super.viewDidLoad()
        setUpNavigationBar()
        setUpHoldsViewController()
        observe { [weak self] in
            guard let self else { return }
            self.updateNavigation()
        }
    }

    // MARK: - Private

    private func setUpHoldsViewController() {
        let explanationView = BehavioralBiometricExplanationView(store: store)
        let hostingViewController = UIHostingController(rootView: explanationView)
        embed(hostingViewController, in: view)
        hostingViewController.didMove(toParent: self)
    }

    private func setUpNavigationBar() {
        configureNavigationHeader(title: .labels.BehavioralBiometric_InfoScreen_lbl_ToolbarTitle.localized)
        setUpBackButton()
    }

    private func updateNavigation() {
        switch store.destination {
        case .agreements:
            navigationProvider.pushBehavioralBiometricAgreementsViewController(on: self)
        case .faq:
            navigationProvider.pushBehavioralBiometricFAQView(on: self)
        case .none:
            return
        }
        store.send(.onResetDestination)
    }
}
