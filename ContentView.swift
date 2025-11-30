import Foundation
import ComposableArchitecture
import CoreTelephony

// MARK: - EsimActivationData

struct EsimActivationData: Equatable, Sendable {
    let lpa: String
    let smdpAddress: String
    let activationCode: String
    let iosActivationUrl: String
    let confirmationCode: String
    let carrierName: String
    let planLabel: String
}

// MARK: - Dependency Client

struct EsimProvisioningClient: DependencyKey {

    var supportsEsim: @Sendable () -> Bool
    var activate: @Sendable (EsimActivationData) async throws -> Bool

    static let liveValue = Self(
        supportsEsim: {
            CTCellularPlanProvisioning().supportsCellularPlan()
        },
        activate: { data in
            let provisioning = CTCellularPlanProvisioning()
            let request = CTCellularPlanProvisioningRequest()
            request.address = data.smdpAddress
            request.matchingID = data.activationCode
            request.confirmationCode = data.confirmationCode

            return try await withCheckedThrowingContinuation { cont in
                provisioning.addPlan(with: request) { result in
                    switch result {
                    case .success:
                        cont.resume(returning: true)
                    case .fail, .unknown:
                        cont.resume(returning: false)
                    @unknown default:
                        cont.resume(throwing: NSError(domain: "esim", code: -1))
                    }
                }
            }
        }
    )
}

extension DependencyValues {
    var esimClient: EsimProvisioningClient {
        get { self[EsimProvisioningClient.self] }
        set { self[EsimProvisioningClient.self] = newValue }
    }
}

// MARK: - Reducer (TCA new style)

@Reducer
struct EsimActivationFeature {

    // MARK: - State

    @ObservableState
    struct State: Equatable {
        var data: EsimActivationData

        var isLoading = false
        var isSuccess = false
        var errorMessage: String?
    }

    // MARK: - Actions

    enum Action: Equatable, Sendable {
        case activateTapped
        case _checkSupport
        case _activate
        case activationResult(Bool)
        case failed(String)
    }

    // MARK: - Reducer

    @Dependency(\.esimClient) var esimClient

    var body: some ReducerOf<Self> {

        Reduce { state, action in
            switch action {

            case .activateTapped:
                state.isLoading = true
                state.errorMessage = nil
                state.isSuccess = false
                return .send(._checkSupport)

            case ._checkSupport:
                if esimClient.supportsEsim() == false {
                    return .send(.failed("Urządzenie nie obsługuje eSIM."))
                }
                return .send(._activate)

            case ._activate:
                return .run { [data = state.data] send in
                    let result = try await esimClient.activate(data)
                    await send(.activationResult(result))
                } catch: { error, send in
                    await send(.failed("Błąd aktywacji eSIM."))
                }

            case let .activationResult(success):
                state.isLoading = false
                state.isSuccess = success
                if success == false {
                    state.errorMessage = "Nie udało się aktywować eSIM."
                }
                return .none

            case let .failed(message):
                state.isLoading = false
                state.isSuccess = false
                state.errorMessage = message
                return .none
            }
        }
    }
}



import SwiftUI
import ComposableArchitecture

struct EsimActivationView: View {
    @Bindable var store: StoreOf<EsimActivationFeature>

    var body: some View {
        VStack(spacing: 20) {

            Text("Aktywacja eSIM")
                .font(.title)

            if store.isLoading {
                ProgressView("Trwa aktywacja…")
            }

            if let error = store.errorMessage {
                Text(error).foregroundColor(.red)
            }

            if store.isSuccess {
                Text("eSIM został pomyślnie dodany!")
                    .foregroundColor(.green)
            }

            Button("Aktywuj eSIM") {
                store.send(.activateTapped)
            }
            .disabled(store.isLoading)
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }
}

