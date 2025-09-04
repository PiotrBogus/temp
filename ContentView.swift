import ComposableArchitecture

extension CarPlayBuyTicketReducer.Action {
    // Top-level
    static var effect: CasePath<Self, Effect> { /Self.effect }
    static var template: CasePath<Self, Template> { /Self.template }

    // Effect
    enum EffectPath {
        static let didLoadData = (/CarPlayBuyTicketReducer.Action.effect)
            .appending(path: /CarPlayBuyTicketReducer.Action.Effect.didLoadData)
        
        static let onValidationFormError = (/CarPlayBuyTicketReducer.Action.effect)
            .appending(path: /CarPlayBuyTicketReducer.Action.Effect.onValidationFormError)

        static let onValidationFormSuccess = (/CarPlayBuyTicketReducer.Action.effect)
            .appending(path: /CarPlayBuyTicketReducer.Action.Effect.onValidationFormSuccess)
        
        static let didLoadAccounts = (/CarPlayBuyTicketReducer.Action.effect)
            .appending(path: /CarPlayBuyTicketReducer.Action.Effect.didLoadAccounts)

        static let didLoadSelectedCity = (/CarPlayBuyTicketReducer.Action.effect)
            .appending(path: /CarPlayBuyTicketReducer.Action.Effect.didLoadSelectedCity)

        static let didLoadCars = (/CarPlayBuyTicketReducer.Action.effect)
            .appending(path: /CarPlayBuyTicketReducer.Action.Effect.didLoadCars)

        static let didPreauthorizeParking = (/CarPlayBuyTicketReducer.Action.effect)
            .appending(path: /CarPlayBuyTicketReducer.Action.Effect.didPreauthorizeParking)

        static let error = (/CarPlayBuyTicketReducer.Action.effect)
            .appending(path: /CarPlayBuyTicketReducer.Action.Effect.error)
    }

    // Template
    enum TemplatePath {
        static let onNextButtonTap = (/CarPlayBuyTicketReducer.Action.template)
            .appending(path: /CarPlayBuyTicketReducer.Action.Template.onNextButtonTap)

        static let onSelectZoneTap = (/CarPlayBuyTicketReducer.Action.template)
            .appending(path: /CarPlayBuyTicketReducer.Action.Template.onSelectZoneTap)

        static let onSelectTimeOptionsTap = (/CarPlayBuyTicketReducer.Action.template)
            .appending(path: /CarPlayBuyTicketReducer.Action.Template.onSelectTimeOptionsTap)

        static let onSelectAccountsTap = (/CarPlayBuyTicketReducer.Action.template)
            .appending(path: /CarPlayBuyTicketReducer.Action.Template.onSelectAccountsTap)

        static let onSelectCarTap = (/CarPlayBuyTicketReducer.Action.template)
            .appending(path: /CarPlayBuyTicketReducer.Action.Template.onSelectCarTap)

        static let onSelectTimeOption = (/CarPlayBuyTicketReducer.Action.template)
            .appending(path: /CarPlayBuyTicketReducer.Action.Template.onSelectTimeOption)

        static let onErrorButtonTap = (/CarPlayBuyTicketReducer.Action.template)
            .appending(path: /CarPlayBuyTicketReducer.Action.Template.onErrorButtonTap)
    }
}
