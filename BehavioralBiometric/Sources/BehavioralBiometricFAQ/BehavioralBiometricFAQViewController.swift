import ComposableArchitecture
import Foundation
import Labels
import SwiftUI

public final class BehavioralBiometricFAQViewController: UIViewController {
    private let store: StoreOf<BehavioralBiometricFAQReducer>

    public init() {
        self.store = Store(initialState: BehavioralBiometricFAQReducer.State()) { BehavioralBiometricFAQReducer()
        }
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { nil }

    override public func viewDidLoad() {
        super.viewDidLoad()
        setUpNavigationBar()
        setUpHoldsViewController()
    }

    // MARK: - Private

    private func setUpHoldsViewController() {
        let faqView = BehavioralBiometricFAQView(store: store)
        let hostingViewController = UIHostingController(rootView: faqView)
        embed(hostingViewController, in: view)
        hostingViewController.didMove(toParent: self)
    }

    private func setUpNavigationBar() {
        configureNavigationHeader(title: .labels.BehavioralBiometric_AllQuestionsScreen_lbl_ToolbarTitle.localized)
        setUpBackButton()
    }
}
