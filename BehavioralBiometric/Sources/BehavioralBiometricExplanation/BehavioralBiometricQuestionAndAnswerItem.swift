import Foundation
import Labels

struct BehavioralBiometricQuestionAndAnswerItem: Sendable, Equatable, Identifiable {
    let id: UUID = .init()
    let title: String
    let description: String
}

extension BehavioralBiometricQuestionAndAnswerItem {
    static let explanation: [BehavioralBiometricQuestionAndAnswerItem] = [
        .init(
            title: .labels.BehavioralBiometric_InfoScreen_btn_Question01.localized ,
            description: .labels.BehavioralBiometric_InfoScreen_lbl_Answer01.localized
        ),
        .init(
            title: .labels.BehavioralBiometric_InfoScreen_btn_Question02.localized ,
            description: .labels.BehavioralBiometric_InfoScreen_lbl_Answer02.localized
        ),
        .init(
            title: .labels.BehavioralBiometric_InfoScreen_btn_Question03.localized ,
            description: .labels.BehavioralBiometric_InfoScreen_lbl_Answer03.localized
        ),
        .init(
            title: .labels.BehavioralBiometric_InfoScreen_btn_Question04.localized ,
            description: .labels.BehavioralBiometric_InfoScreen_lbl_Answer04.localized
        ),
        .init(
            title: .labels.BehavioralBiometric_InfoScreen_btn_Question05.localized ,
            description: .labels.BehavioralBiometric_InfoScreen_lbl_Answer05.localized
        )
    ]

    static let faq: [BehavioralBiometricQuestionAndAnswerItem] = [
        .init(
            title: .labels.BehavioralBiometric_InfoScreen_btn_Question01.localized ,
            description: .labels.BehavioralBiometric_InfoScreen_lbl_Answer01.localized
        ),
        .init(
            title: .labels.BehavioralBiometric_InfoScreen_btn_Question02.localized ,
            description: .labels.BehavioralBiometric_InfoScreen_lbl_Answer02.localized
        ),
        .init(
            title: .labels.BehavioralBiometric_InfoScreen_btn_Question03.localized ,
            description: .labels.BehavioralBiometric_InfoScreen_lbl_Answer03.localized
        ),
        .init(
            title: .labels.BehavioralBiometric_InfoScreen_btn_Question04.localized ,
            description: .labels.BehavioralBiometric_InfoScreen_lbl_Answer04.localized
        ),
        .init(
            title: .labels.BehavioralBiometric_InfoScreen_btn_Question05.localized ,
            description: .labels.BehavioralBiometric_InfoScreen_lbl_Answer05.localized
        ),
        .init(
            title: .labels.BehavioralBiometric_InfoScreen_btn_Question06.localized ,
            description: .labels.BehavioralBiometric_InfoScreen_lbl_Answer06.localized
        ),
        .init(
            title: .labels.BehavioralBiometric_InfoScreen_btn_Question07.localized ,
            description: .labels.BehavioralBiometric_InfoScreen_lbl_Answer07.localized
        ),
        .init(
            title: .labels.BehavioralBiometric_InfoScreen_btn_Question08.localized ,
            description: .labels.BehavioralBiometric_InfoScreen_lbl_Answer08.localized
        ),
        .init(
            title: .labels.BehavioralBiometric_InfoScreen_btn_Question09.localized ,
            description: .labels.BehavioralBiometric_InfoScreen_lbl_Answer09.localized
        ),
        .init(
            title: .labels.BehavioralBiometric_InfoScreen_btn_Question10.localized ,
            description: .labels.BehavioralBiometric_InfoScreen_lbl_Answer10.localized
        ),
        .init(
            title: .labels.BehavioralBiometric_InfoScreen_btn_Question11.localized ,
            description: .labels.BehavioralBiometric_InfoScreen_lbl_Answer11.localized
        ),
    ]
}
