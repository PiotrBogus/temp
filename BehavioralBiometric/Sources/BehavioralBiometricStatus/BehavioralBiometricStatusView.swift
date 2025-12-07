import ComposableArchitecture
import DesignSystemSwiftUI
import Foundation
import Labels
import SwiftUI

struct BehavioralBiometricStatusView: View {
    private struct Constants {
        static let horizontalPadding: CGFloat = 16
        static let defaultSpacing: CGFloat = 18
        static let statusViewSpacing: CGFloat = 10
        static let titleFontStyle: UIFont.Style = .regular(.size14LS18)
        static let valueFontStyle: UIFont.Style = .regular(.size16LS22)
        static let agreementsViewTopPadding: CGFloat = 30
        static let progressViewScaleSize: CGFloat = 1.85
    }
    
    var store: StoreOf<BehavioralBiometricStatusReducer>

    init(store: StoreOf<BehavioralBiometricStatusReducer>) {
        self.store = store
    }

    var body: some View {
        ZStack {
            if store.isLoading {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle())
                    .scaleEffect(Constants.progressViewScaleSize)
                    .tint(Color(uiColor: .ikoGray140))
            } else {
                contentView
            }
        }
        .background(Color(uiColor: .ikoWhite100))
    }

    private var contentView: some View {
        VStack(spacing: .zero) {
            ScrollView() {
                statusVieW

                if store.isBehavioralBiometricEnabled {
                    dateView
                }

                ContentMessage(
                    model: .init(
                        icon: .info,
                        title: .labels.MyData_DetailsAdditionalSecurity_lbl_ContentMessageTitle.localized,
                        subtitle: .labels.MyData_DetailsAdditionalSecurity_lbl_ContentMessageSubtitle.localized
                    ),
                    linkButton: LinkButton(
                        title: .labels.MyData_DetailsAdditionalSecurity_btn_ContentMessageMoreInfo.localized,
                        onTap: {
                            store.send(.onMoreInfoLinkTap)
                        })
                )
                .padding(.top, Constants.defaultSpacing)
                .padding(.horizontal, Constants.horizontalPadding)

                if store.isBehavioralBiometricEnabled {
                    agreementsView
                        .padding(.top, Constants.agreementsViewTopPadding)
                }
            }

            primaryButtonView
        }
    }

    private var statusVieW: some View {
        HStack(spacing: .zero) {
            VStack(alignment: .leading, spacing: Constants.statusViewSpacing) {
                AttributedText(.labels.MyData_DetailsAdditionalSecurity_lbl_StatusKey.localized)
                    .fontStyle(Constants.titleFontStyle)
                AttributedText(store.isBehavioralBiometricEnabled ?
                    .labels.MyData_DetailsAdditionalSecurity_lbl_StatusValueOn.localized : .labels.MyData_DetailsAdditionalSecurity_lbl_StatusValueOff.localized)
                    .fontStyle(Constants.valueFontStyle)
            }

            Spacer()
        }
        .padding(.top, Constants.defaultSpacing)
        .padding(.horizontal, Constants.horizontalPadding)
    }

    private var dateView: some View {
        HStack(spacing: .zero) {
            VStack(alignment: .leading, spacing: Constants.statusViewSpacing) {
                AttributedText(.labels.MyData_DetailsAdditionalSecurity_lbl_DateKey.localized)
                    .fontStyle(Constants.titleFontStyle)
                AttributedText(store.status?.agreementsDate ?? "")
                    .fontStyle(Constants.valueFontStyle)
            }

            Spacer()
        }
        .padding(.top, Constants.defaultSpacing)
        .padding(.horizontal, Constants.horizontalPadding)
    }

    private var agreementsView: some View {
            VStack(spacing: .zero) {
                HeaderView(text: .labels.MyData_DetailsAdditionalSecurity_lbl_AgreementsHeader.localized)
                    .padding(.bottom, Constants.defaultSpacing)
                ForEach(store.status?.agreements ?? []) { agreement in
                    AttributedText(agreement.text)
                    .padding(.horizontal, Constants.horizontalPadding)
                }
            }
    }

    private var primaryButtonView: some View {
        VStack {
            PrimaryButton(title: store.isBehavioralBiometricEnabled ? .labels.MyData_DetailsAdditionalSecurity_btn_TurnOff.localized : .labels.MyData_DetailsAdditionalSecurity_btn_TurnOn.localized) {
                store.send(.onPrimaryButtonTap)
            }
            .padding(Constants.horizontalPadding)
        }
        .background(Color(uiColor: .ikoWhite100))
    }
}
