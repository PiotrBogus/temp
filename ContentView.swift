
import Foundation
import UIKit
// Can be removed when we migrate to iOS 17 so we don't need to check if device is iPhone 18 or X
extension UIDevice {
    private static let modelsWithoutESimThatSupportiOS16: Set<String> = [
        "iPhone10,1",
        "iPhone10,2",
        "iPhone10,3",
        "iPhone10,4",
        "iPhone10,5",
        "iPhone10,6",
        "i386",
        "x86_64",
        "arm64",
    ]
    static func isESimSupported() -> Bool {
        var systemInfo = utsname()
        uname(&systemInfo)
        let machineMirror = Mirror(reflecting: systemInfo.machine)
        let identifier = machineMirror.children.reduce(into: "") { result, element in
            guard let value = element.value as? Int8, value != 0 else { return }
            result.append(String(UnicodeScalar(UInt8(value))))
        }
        return !modelsWithoutESimThatSupportiOS16.contains(identifier)
    }
}


/Users/mac.jenkins.ad/workspace/mob-ios/Projects/App/ESim/Sources/Utils/UIDevice+ESim.swift:4:1: error: (docComments) Use doc comments for API declarations, otherwise use regular comments.

