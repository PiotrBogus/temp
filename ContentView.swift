failed - A state change does not match expectation: …

      CarPlayBuyTicketReducer.State(
        _destination: nil,
        _subareaHint: nil,
        _data: CarPlayParkingsNewParkingFormModel(…),
    −   _templateState: .willAppear
    +   _templateState: .validationError(
    +     UUID(9586D9CB-CC3A-44E7-8D8E-1718C9CA1E8C),
    +     [
    +       [0]: .carNotSelected,
    +       [1]: .areaNotSelected,
    +       [2]: .timeOptionNotSelected,
    +       [3]: .accountNotSelected
    +     ]
    +   )
      )

(Expected: −, Actual: +)
