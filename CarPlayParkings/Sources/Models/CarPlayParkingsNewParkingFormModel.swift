import Foundation
import IKOCommon

public final class CarPlayParkingsNewParkingFormModel: Equatable, @unchecked Sendable {
    private let resourceProvider: CarPlayParkingsResourceProviding
    private let timeOptionsResourceProvider: CarPlayParkingsTimeOptionsResourceProviding

    var zoneTitle: String
    var zoneDescription: String
    var zoneSelectionEnabled: Bool = false
    var timeTitle: String
    var timeSelectionEnabled: Bool = false
    var timeDescription: String
    var carTitle: String {
        selectedCar?.name ?? resourceProvider.newParkingCarTitleText
    }
    var carDescription: String {
        selectedCar?.plate ?? resourceProvider.selectText
    }
    var carSelectionEnabled: Bool {
        cars.hasMultipleElements
    }
    var accountTitle: String {
        resourceProvider.newParkingAccountTitleText
    }
    var accountDescription: String {
        selectedAccount == nil ? resourceProvider.selectText : selectedAccount!.name
    }
    var accountSelectionEnabled: Bool {
        accounts.hasMultipleElements || selectedAccount == nil
    }

    var refreshTemplateHandler: (() -> Void)?

    var selectedSubarea: CarPlayParkingsSubareaListItem?
    var selectedTimeOption: CarPlayParkingsTariffTimeOption?
    var selectedCar: CarPlayParkingsCarListItem?
    var selectedAccount: CarPlayParkingsAccount?
    var selectedTicket: CarPlayParkingsTicketListItem?
    private let accounts: [CarPlayParkingsAccount]
    private let cars: [CarPlayParkingsCarListItem]

    public init(
        city: CarPlayParkingsCity,
        subareaHint: String?,
        cars: [CarPlayParkingsCarListItem],
        accounts: [CarPlayParkingsAccount],
        resourceProvider: CarPlayParkingsResourceProviding,
        timeOptionsResourceProvider: CarPlayParkingsTimeOptionsResourceProviding
    ) {
        self.resourceProvider = resourceProvider
        self.timeOptionsResourceProvider = timeOptionsResourceProvider
        self.accounts = accounts
        self.cars = cars

        let subareas = city.tarrifs.flatMap { tariff in
            tariff.subareas.filter { !$0.timeOptions.isEmpty }
        }

        if subareas.isEmpty {
            zoneTitle = city.name
            zoneDescription = resourceProvider.noActiveParkingSelectZoneEmptyText
        } else if subareas.hasOneElement {
            selectedSubarea = subareas.first
            zoneTitle = city.name
            zoneDescription = subareas.first!.name
        } else {
            if let subarea = subareas.first(where: { subarea in
                subarea.extendedSubareaId == subareaHint
            }) {
                selectedSubarea = subarea
                zoneTitle = city.name
                zoneDescription = subarea.name
            } else {
                zoneTitle = resourceProvider.parkingZoneText
                zoneDescription = resourceProvider.selectText
            }
            zoneSelectionEnabled = true
        }

        timeTitle = resourceProvider.newParkingTimeTypeTitleText
        if let selectedSubarea = selectedSubarea, selectedSubarea.timeOptions.hasOneElement {
            selectedTimeOption = selectedSubarea.timeOptions.first
            timeDescription = selectedSubarea.timeOptions.first!.toDescription(resourceProvider: timeOptionsResourceProvider)
        } else {
            timeDescription = resourceProvider.selectText
            timeSelectionEnabled = selectedSubarea != nil
        }

        selectedCar = cars.selectedCar
        selectedAccount = accounts.selectedAccount
    }

    public init(
        ticket: CarPlayParkingsTicketListItem,
        timeOptions: [CarPlayParkingsTariffTimeOption],
        cars: [CarPlayParkingsCarListItem],
        accounts: [CarPlayParkingsAccount],
        resourceProvider: CarPlayParkingsResources,
        timeOptionsResourceProvider: CarPlayParkingsTimeOptionsResourceProviding
    ) {
        self.resourceProvider = resourceProvider
        self.timeOptionsResourceProvider = timeOptionsResourceProvider
        self.selectedTicket = ticket
        self.accounts = accounts
        self.cars = cars

        zoneTitle = ticket.locationName
        zoneDescription = ticket.subareaName
        timeTitle = resourceProvider.newParkingTimeTypeTitleText
        if timeOptions.isEmpty {
            timeDescription = resourceProvider.lastParkingTicketRepeatNoActiveTypesText
        } else if timeOptions.hasOneElement {
            selectedTimeOption = timeOptions.first
            timeDescription = timeOptions.first!.toDescription(resourceProvider: timeOptionsResourceProvider)
        } else {
            let preferredTimeOption = CarPlayParkingsNewParkingFormModel.preferredTimeOption(ticket: ticket, timeOptions: timeOptions)
            if let preferredTimeOption = preferredTimeOption {
                selectedTimeOption = preferredTimeOption
                timeDescription = preferredTimeOption.toDescription(resourceProvider: timeOptionsResourceProvider)
            } else {
                timeDescription = resourceProvider.selectText
            }
        }
        timeSelectionEnabled = timeOptions.hasMultipleElements
        selectedCar = cars.selectedCar
        selectedAccount = accounts.selectedAccount
    }

    func refresh() {
        if let selectedSubarea {
            zoneDescription = selectedSubarea.name
        }
        if let selectedTimeOption {
            timeDescription = selectedTimeOption.toDescription(resourceProvider: timeOptionsResourceProvider)
        } else {
            timeDescription = resourceProvider.selectText
        }
        timeSelectionEnabled = selectedSubarea != nil

        if let refreshTemplateHandler {
            refreshTemplateHandler()
        }
    }

    public static func == (lhs: CarPlayParkingsNewParkingFormModel, rhs: CarPlayParkingsNewParkingFormModel) -> Bool {
        lhs.zoneTitle == rhs.zoneTitle &&
        lhs.zoneDescription == rhs.zoneDescription &&
        lhs.zoneSelectionEnabled == rhs.zoneSelectionEnabled &&
        lhs.timeTitle == rhs.timeTitle &&
        lhs.timeSelectionEnabled == rhs.timeSelectionEnabled &&
        lhs.timeDescription == rhs.timeDescription &&
        lhs.selectedSubarea == rhs.selectedSubarea &&
        lhs.selectedTimeOption == rhs.selectedTimeOption &&
        lhs.selectedCar == rhs.selectedCar &&
        lhs.selectedAccount == rhs.selectedAccount &&
        lhs.selectedTicket == rhs.selectedTicket
    }
}

private extension Array where Element == CarPlayParkingsAccount {
    var selectedAccount: CarPlayParkingsAccount? {
        if let defaultAccount = self.first(where: { $0.isDefault }) {
            return defaultAccount
        }
        if self.hasOneElement {
            return self.first
        }
        return nil
    }
}

private extension Array where Element == CarPlayParkingsCarListItem {
    var selectedCar: CarPlayParkingsCarListItem? {
        if self.hasOneElement {
            return self.first!
        } else {
            return self.first(where: { $0.defaultPlate })
        }
    }
}

private extension CarPlayParkingsNewParkingFormModel {
    static func preferredTimeOption(ticket: CarPlayParkingsTicketListItem, timeOptions: [CarPlayParkingsTariffTimeOption]) -> CarPlayParkingsTariffTimeOption? {
        var timeOption: CarPlayParkingsTariffTimeOption?
        if !ticket.isTimeLimited {
            timeOption = .startStop
        } else {
            guard let boughtMinutes = ticket.boughtMinutes() else { return nil }
            timeOption = CarPlayParkingsTariffTimeOption(minutes: boughtMinutes)
        }
        timeOption = timeOptions.first(where: { option in
            option == timeOption
        })
        return timeOption
    }
}
