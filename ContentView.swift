import XCTest
import ComposableArchitecture
@testable import YourAppModule

@MainActor
final class ESimActivationReducerTests: XCTestCase {
    
    // MARK: - Test Data
    
    private func makeTestData() -> ESimActivationData {
        ESimActivationData(
            lpa: "test-lpa",
            smdpAddress: "test-smdp",
            activationCode: "test-code",
            iosActivationUrl: "https://test.esim.com/activate",
            confirmationCode: "123456",
            carrierName: "Test Carrier",
            planLabel: "Test Plan",
            cardNumber: "1234567890"
        )
    }
    
    private func makeTestState() -> ESimActivationReducer.State {
        ESimActivationReducer.State(
            data: makeTestData(),
            isLoading: true,
            isSystemConfiguratorAvailable: false,
            currentNumberOfInstalledSims: 0
        )
    }
    
    // MARK: - onAppear Tests
    
    func testOnAppear_UpdatesNumberOfInstalledSims() async {
        let mockManager = MockESimProvisioningManager()
        mockManager.mockNumberOfSims = 2
        
        let store = TestStore(
            initialState: makeTestState(),
            reducer: { ESimActivationReducer(eSimManager: mockManager) }
        )
        
        await store.send(.onAppear)
        await store.receive(\.onNumberSimInstalled, 2) {
            $0.currentNumberOfInstalledSims = 2
        }
    }
    
    // MARK: - onNumberSimInstalled Tests
    
    func testOnNumberSimInstalled_WithSystemConfigurator_OpensSystemConfigurator() async {
        let mockManager = MockESimProvisioningManager()
        mockManager.mockIsESimSupported = true
        mockManager.mockIsConfiguratorAvailable = true
        
        let store = TestStore(
            initialState: makeTestState(),
            reducer: { ESimActivationReducer(eSimManager: mockManager) }
        )
        
        await store.send(.onNumberSimInstalled(1)) {
            $0.currentNumberOfInstalledSims = 1
        }
        await store.receive(\.onOpenSystemConfigurator) {
            $0.isSystemConfiguratorAvailable = true
            $0.isLoading = false
            $0.destination = .activation("https://test.esim.com/activate")
        }
    }
    
    func testOnNumberSimInstalled_WithoutSystemConfigurator_TriggersManualAdd() async {
        let mockManager = MockESimProvisioningManager()
        mockManager.mockIsESimSupported = true
        mockManager.mockIsConfiguratorAvailable = false
        
        let store = TestStore(
            initialState: makeTestState(),
            reducer: { ESimActivationReducer(eSimManager: mockManager) }
        )
        
        await store.send(.onNumberSimInstalled(1)) {
            $0.currentNumberOfInstalledSims = 1
        }
        await store.receive(\.onManualESimAdd) {
            $0.isLoading = false
        }
    }
    
    func testOnNumberSimInstalled_ESimNotSupported_ShowsNotSupportedDestination() async {
        let mockManager = MockESimProvisioningManager()
        mockManager.mockIsESimSupported = false
        
        let store = TestStore(
            initialState: makeTestState(),
            reducer: { ESimActivationReducer(eSimManager: mockManager) }
        )
        
        await store.send(.onNumberSimInstalled(0)) {
            $0.currentNumberOfInstalledSims = 0
        }
        await store.receive(\.onESimNotSupported) {
            $0.destination = .esimNotSupported
        }
    }
    
    // MARK: - onESimNotSupported Tests
    
    func testOnESimNotSupported_SetsDestination() async {
        let mockManager = MockESimProvisioningManager()
        let store = TestStore(
            initialState: makeTestState(),
            reducer: { ESimActivationReducer(eSimManager: mockManager) }
        )
        
        await store.send(.onESimNotSupported) {
            $0.destination = .esimNotSupported
        }
    }
    
    // MARK: - onActivationSuccess Tests
    
    func testOnActivationSuccess_SetsDestination() async {
        let mockManager = MockESimProvisioningManager()
        let store = TestStore(
            initialState: makeTestState(),
            reducer: { ESimActivationReducer(eSimManager: mockManager) }
        )
        
        await store.send(.onActivationSuccess) {
            $0.destination = .activationSuccess
        }
    }
    
    // MARK: - onManualESimAdd Tests
    
    func testOnManualESimAdd_StopsLoading() async {
        let mockManager = MockESimProvisioningManager()
        let store = TestStore(
            initialState: makeTestState(),
            reducer: { ESimActivationReducer(eSimManager: mockManager) }
        )
        
        await store.send(.onManualESimAdd) {
            $0.isLoading = false
        }
    }
    
    // MARK: - onOpenSystemConfigurator Tests
    
    func testOnOpenSystemConfigurator_UpdatesStateAndDestination() async {
        let mockManager = MockESimProvisioningManager()
        let store = TestStore(
            initialState: makeTestState(),
            reducer: { ESimActivationReducer(eSimManager: mockManager) }
        )
        
        await store.send(.onOpenSystemConfigurator) {
            $0.isSystemConfiguratorAvailable = true
            $0.isLoading = false
            $0.destination = .activation("https://test.esim.com/activate")
        }
    }
    
    // MARK: - onCopyTap Tests
    
    func testOnCopyTap_CopiesTextToPasteboard() async {
        let mockManager = MockESimProvisioningManager()
        let store = TestStore(
            initialState: makeTestState(),
            reducer: { ESimActivationReducer(eSimManager: mockManager) }
        )
        
        let testText = "test-activation-code"
        await store.send(.onCopyTap(testText))
        
        XCTAssertEqual(UIPasteboard.general.string, testText)
    }
    
    // MARK: - onDeviceSettingTap Tests
    
    func testOnDeviceSettingTap_WithSystemConfigurator_OpensActivation() async {
        let mockManager = MockESimProvisioningManager()
        var state = makeTestState()
        state.isSystemConfiguratorAvailable = true
        
        let store = TestStore(
            initialState: state,
            reducer: { ESimActivationReducer(eSimManager: mockManager) }
        )
        
        await store.send(.onDeviceSettingTap) {
            $0.destination = .activation("https://test.esim.com/activate")
        }
    }
    
    func testOnDeviceSettingTap_WithoutSystemConfigurator_OpensPhoneSettings() async {
        let mockManager = MockESimProvisioningManager()
        var state = makeTestState()
        state.isSystemConfiguratorAvailable = false
        
        let store = TestStore(
            initialState: state,
            reducer: { ESimActivationReducer(eSimManager: mockManager) }
        )
        
        await store.send(.onDeviceSettingTap) {
            $0.destination = .eSimPhoneSettings
        }
    }
    
    // MARK: - onAppDidBecomeActive Tests
    
    func testOnAppDidBecomeActive_WithNewSim_ShowsActivationSuccess() async {
        let mockManager = MockESimProvisioningManager()
        mockManager.mockNumberOfSims = 2
        
        var state = makeTestState()
        state.currentNumberOfInstalledSims = 1
        
        let store = TestStore(
            initialState: state,
            reducer: { ESimActivationReducer(eSimManager: mockManager) }
        )
        
        await store.send(.onAppDidBecomeActive) {
            $0.destination = .activationSuccess
        }
    }
    
    func testOnAppDidBecomeActive_WithoutNewSim_DoesNothing() async {
        let mockManager = MockESimProvisioningManager()
        mockManager.mockNumberOfSims = 1
        
        var state = makeTestState()
        state.currentNumberOfInstalledSims = 1
        
        let store = TestStore(
            initialState: state,
            reducer: { ESimActivationReducer(eSimManager: mockManager) }
        )
        
        await store.send(.onAppDidBecomeActive)
    }
    
    func testOnAppDidBecomeActive_WithFewerSims_DoesNothing() async {
        let mockManager = MockESimProvisioningManager()
        mockManager.mockNumberOfSims = 0
        
        var state = makeTestState()
        state.currentNumberOfInstalledSims = 1
        
        let store = TestStore(
            initialState: state,
            reducer: { ESimActivationReducer(eSimManager: mockManager) }
        )
        
        await store.send(.onAppDidBecomeActive)
    }
}

// MARK: - Mock ESimProvisioningManager

final class MockESimProvisioningManager: ESimProvisioningManaging {
    var mockIsESimSupported = true
    var mockIsConfiguratorAvailable = true
    var mockNumberOfSims = 0
    
    @MainActor func isESimSupportedByDevice() -> Bool {
        return mockIsESimSupported
    }
    
    @MainActor func isSystemESimConfiguratorAvailable(configuratorLink: String) -> Bool {
        return mockIsConfiguratorAvailable
    }
    
    func numberOfAvailableSims() -> Int {
        return mockNumberOfSims
    }
}
