import CarPlay
import ComposableArchitecture
import Dependencies

final class CarPlaySceneDelegate: UIResponder, CPTemplateApplicationSceneDelegate {
    @Dependency(\.carPlayCoordinator) private var coordinator

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {}

    func templateApplicationScene(
        _ templateApplicationScene: CPTemplateApplicationScene,
        didConnect interfaceController: CPInterfaceController
    ) {
        coordinator.save(interfaceController)
        presentEntryPoint()
    }

    private func presentEntryPoint() {
        let store = Store(
            initialState: CarPlayEntryPointReducer.State(),
            reducer: {
                CarPlayEntryPointReducer()
            }
        )
        coordinator.append(CarPlayEntryPointTemplate(store: store))
    }
}
