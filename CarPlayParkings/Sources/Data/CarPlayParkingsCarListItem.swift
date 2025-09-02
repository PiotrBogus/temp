import Foundation

@objc
public final class CarPlayParkingsCarListItem: NSObject, Sendable {
    public let plateId: Int64
    public let extPlateId: String
    public let name: String
    public let plate: String
    public let defaultPlate: Bool

    @objc
    public init(_ plateId: Int64, extPlateId: String, name: String, plate: String, defaultPlate: Bool) {
        self.plateId = plateId
        self.extPlateId = extPlateId
        self.name = name
        self.plate = plate
        self.defaultPlate = defaultPlate
    }
}
