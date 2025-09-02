import CarPlay
import ComposableArchitecture
import Dependencies
import IKOCommon

@Reducer
struct CarPlayConfirmParkingReducer: Sendable {
    @ObservableState
    struct State: Equatable, Sendable {
        var templateState: TemplateState = .didAppear
        let preauthResponse: CarPlayParkingsPreauthResponse
        let model: CarPlayParkingsNewParkingFormModel
    }

    enum TemplateState: Equatable {
        case didAppear
        case loading
        case error(CarPlayErrorTemplateModel<CarPlayConfirmParkingErrorType>)
        case entryPoint
    }

    enum Action: Sendable {
        case onConfirm
        case onAuthorizeParkingSuccess
        case onAuthorizeParkingFailure(Error)
        case onTryAgain
    }

    @Dependency(\.confirmParkingReducerClient) private var reducerClient
    @Dependency(\.carPlayParkingsErrorParser) private var errorParser

    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .onConfirm, .onTryAgain:
                state.templateState = .loading
                return authorizeParking(preauthResponse: state.preauthResponse)
            case .onAuthorizeParkingSuccess:
                state.templateState = .entryPoint
                return notifyEntryPoint()
            case let .onAuthorizeParkingFailure(error):
                let errorTitle = errorParser.getMessage(error: error)
                state.templateState =
                    .error(.init(
                        type: .authorizeParkingError,
                        title: errorTitle,
                        description: nil,
                        buttonTitle: reducerClient.resourceProvider.alertButtonTryAgainText
                    ))
                return .none
            }
        }
    }

    private func authorizeParking(preauthResponse: CarPlayParkingsPreauthResponse) -> Effect<Action> {
        return .run { send in
            do {
                try await reducerClient.authorizeParking(preauthResponse)
                await send(.onAuthorizeParkingSuccess)
            } catch {
                await send(.onAuthorizeParkingFailure(error))
            }
        }
    }

    private func notifyEntryPoint() -> Effect<Action> {
        return .run { _ in
            await MainActor.run {
                NotificationCenter.default.post(
                    name: Notification.Name(rawValue: kIKOParkingPlacesListRefresh),
                    object: nil
                )
            }
        }
    }
}
