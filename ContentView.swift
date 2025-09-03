
extension CarPlayParkingsPreauthResponse {
    static let fixture = CarPlayParkingsPreauthResponse(
        plate: "ABC123",
        locationName: "Test Location",
        price: "10.00",
        validFrom: "2025-09-03T08:00:00Z",
        validFromTimestamp: 1_694_020_800, // przykładowy timestamp
        validTo: "2025-09-03T10:00:00Z",
        validToTimestamp: 1_694_028_000,
        transactionId: "txn_123"
    )
}
