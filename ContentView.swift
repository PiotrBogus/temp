import ComposableArchitecture
import DesignSystemSwiftUI
import Labels
import SwiftUI

struct ESimActivationView: View {
    private struct Constants {
        static let progressViewScaleSize: CGFloat = 1.6
        static let checkESimTitleFont: UIFont.Style = .regular(.size18LS22)
        static let checkESimSubtitleFont: UIFont.Style = .regular(.size18LS22)
        static let commonPadding: CGFloat = 16
        static let mediumPadding: CGFloat = 8
        static let smallPadding: CGFloat = 4
        static let titleLabelGroupFont: UIFont.Style = .regular(.size14LS18)
        static let descriptionLabelGroupFont: UIFont.Style = .regular(.size14LS18)
    }

    let store: StoreOf<ESimActivationReducer>

    var body: some View {
        ZStack {
            Color(uiColor: .ikoBlue0)

            if store.isLoading {
                checkESimAvailabilityView
            } else {
                manualAddESimView
            }
        }
    }

    private var checkESimAvailabilityView: some View {
        VStack(spacing: .zero) {
            Spacer()

            ProgressView()
                  .progressViewStyle(CircularProgressViewStyle())
                  .scaleEffect(Constants.progressViewScaleSize)
                  .tint(Color(uiColor: .ikoGray140))

            AttributedText(.labels.ESim_InstallSplash_lbl_Title.localized)
                .fontStyle(Constants.checkESimTitleFont)
                .padding(.top, Constants.commonPadding)

            AttributedText(.labels.ESim_InstallSplash_lbl_Description.localized)
                .fontStyle(Constants.checkESimSubtitleFont)
                .padding(.top, Constants.mediumPadding)

            Spacer()
        }
    }

    private var manualAddESimView: some View {
        VStack(spacing: Constants.commonPadding) {
            ContentMessage(
                model: .init(
                    icon: .hint,
                    subtitle: .labels.ESim_InstallDetails_lbl_ContentMessage.localized
                )
            )

            labelsGroup(
                title: .labels.ESim_InstallDetails_lbl_TariffName.localized,
                description: "\(store.data.carrierName) - \(store.data.planLabel)",
                isCopyButtonVisible: false
            )

            labelsGroup(
                title: .labels.ESim_InstallDetails_lbl_SimNumber.localized,
                description: store.data.cardNumber,
                isCopyButtonVisible: false
            )

            labelsGroup(
                title: .labels.ESim_InstallDetails_lbl_ActivationCode.localized,
                description: store.data.activationCode,
                isCopyButtonVisible: true
            )

            labelsGroup(
                title: .labels.ESim_InstallDetails_lbl_AddressSMDP.localized,
                description: store.data.smdpAddress,
                isCopyButtonVisible: true
            )

            Spacer()

            PrimaryButton(title: .labels.ESim_Install_btn_DeviceSettings.localized) {
                store.send(.onDeviceSettingTap)
            }
        }
        .padding(Constants.commonPadding)
    }

    private func labelsGroup(
        title: String,
        description: String,
        isCopyButtonVisible: Bool
    ) -> some View {
        HStack(alignment: .top, spacing: .zero) {
            VStack(alignment: .leading, spacing: Constants.smallPadding) {
                AttributedText(title)
                    .fontStyle(Constants.titleLabelGroupFont)

                AttributedText(description)
                    .fontStyle(Constants.descriptionLabelGroupFont)
            }

            Spacer(minLength: Constants.smallPadding)

            if isCopyButtonVisible {
                Button(action: {
                    store.send(.onCopyTap(description))
                }) {
                    AttributedText(.labels.ESim_InstallDetails_btn_Copy.localized)
                        .fontStyle(Constants.titleLabelGroupFont)
                        .textColor(.ikoBlue100)
                }
            }
        }
    }
}
