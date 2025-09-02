import Foundation

public struct CarPlayParkingsTarrifListItem: Sendable {
    let subareas: [CarPlayParkingsSubareaListItem]

    public init(subareas: [CarPlayParkingsSubareaListItem]) {
        self.subareas = subareas
    }
}
