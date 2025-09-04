    enum Action: Sendable {
        case destination(PresentationAction<Destination.Action>)
        case onAppear
        case refresh
        case template(Template)
        case effect(Effect)

        enum Effect: Sendable {
            case didLoadData(CarPlayParkingsNewParkingFormModel)
            case onValidationFormError([BuyTicketFormValidationError])
            case onValidationFormSuccess
            case didLoadAccounts([CarPlayParkingsAccount])
            case didLoadSelectedCity(CarPlayParkingsCity)
            case didLoadCars([CarPlayParkingsCarListItem])
            case didPreauthorizeParking(CarPlayParkingsPreauthResponse)
            case error(Error)
        }

        enum Template: Sendable {
            case onNextButtonTap
            case onSelectZoneTap
            case onSelectTimeOptionsTap
            case onSelectAccountsTap
            case onSelectCarTap
            case onSelectTimeOption(CarPlayParkingsTariffTimeOption?)
            case onErrorButtonTap(CarPlayBuyTicketFeatureErrorType)
        }
    }
