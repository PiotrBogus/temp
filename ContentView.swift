import Assets
import ComposableArchitecture
import DesignSystemAssets
import DesignSystemSwiftUI
import Foundation
import Labels
import SwiftUI

struct BehavioralBiometricExplanationView: View {
    private struct Constants {
        static let commonPadding: CGFloat = 16
        static let imageSize: CGFloat = 96
        static let imageVerticalPadding: CGFloat = 24
        static let statusLabelFontStyle: UIFont.Style = .regular(.size12LS16, color: .ikoWhite100)
        static let statusLabelPadding: CGFloat = 4
        static let statusLabelCornerRadius: CGFloat = 4
        static let statusLabelTopPadding: CGFloat = 12
        static let headerTitleLabelFontStyle: UIFont.Style = .regular(.size24LS32)
        static let headerDescriptionFontStyle: UIFont.Style = .regular(.size18LS22)
        static let headerDescriptionLabelTopPadding: CGFloat = 14
        static let itemImageSize: CGFloat = 48
        static let itemHeaderFontStyle: UIFont.Style = .bold(.size16LS22)
        static let headerTopPadding: CGFloat = 20
        static let itemSpacing: CGFloat = 10
        static let answerFontStyle: UIFont.Style = .regular(.size16LS22)
        static let showAllQuestionsAndAnswersButtonFontStyle: UIFont.Style = .regular(.size14LS18, color: .ikoBlue100)
    }

    var store: StoreOf<BehavioralBiometricExplanationReducer>

    init(store: StoreOf<BehavioralBiometricExplanationReducer>) {
        self.store = store
    }

    var body: some View {
        NavigationStack {
            VStack {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: .zero) {
                        headerView
                        howItWorksSection
                        questionsAndAnswersSection
                            .padding(.top, Constants.itemSpacing)
                    }
                }
                if store.isPrimaryButtonVisible {
                    bottomPrimaryButtonView
                }
            }
            .background(Color(uiColor: .ikoBlue0))
            .onAppear {
                store.send(.onAppear)
            }
        }
    }

    private var headerView: some View {
        HStack {
            Spacer()
            VStack(spacing: .zero) {
                IllustrativeIcons.iluESGSociety48.image
                    .renderingMode(.original)
                    .resizable()
                    .frame(width: Constants.imageSize, height: Constants.imageSize)
                    .padding(.top, Constants.imageVerticalPadding)

                VStack {
                    AttributedText(.labels.BehavioralBiometric_InfoScreen_lbl_FreeService.localized)
                        .fontStyle(Constants.statusLabelFontStyle)
                        .padding(Constants.statusLabelPadding)
                }
                .background(
                    RoundedRectangle(cornerRadius: Constants.statusLabelCornerRadius).fill(Color(uiColor: .ikoGreen100))
                )
                .padding(.top, Constants.statusLabelTopPadding)

                AttributedText(.labels.BehavioralBiometric_InfoScreen_lbl_ToolbarTitle.localized)
                    .fontStyle(Constants.headerTitleLabelFontStyle)
                    .padding(.top, Constants.headerTopPadding)
                    .padding(.bottom, Constants.imageVerticalPadding)
            }
            Spacer()
        }
        .background(
            Color(uiColor: .ikoWhite100)
        )
    }

    private var howItWorksSection: some View {
        VStack(alignment: .leading, spacing: .zero) {
            HeaderView(text: .labels.BehavioralBiometric_InfoScreen_lbl_MiddleSectionHeader.localized)

            VStack(alignment: .leading, spacing: Constants.itemSpacing) {
                createItem(
                    image: SystemIcons.webIconMoreProtection24.image,
                    title: .labels.BehavioralBiometric_InfoScreen_lbl_MiddleSectionTitle1.localized,
                    subtitle: .labels.BehavioralBiometric_InfoScreen_lbl_MiddleSectionSubtitle1.localized
                )
            }
            .padding(.horizontal, Constants.commonPadding)

            VStack(alignment: .leading, spacing: Constants.itemSpacing) {
                createItem(
                    image: SystemIcons.pkoIconAdviserIndividual24.image,
                    title: .labels.BehavioralBiometric_InfoScreen_lbl_MiddleSectionTitle2.localized,
                    subtitle: .labels.BehavioralBiometric_InfoScreen_lbl_MiddleSectionSubtitle2.localized
                )
            }
            .padding(.horizontal, Constants.commonPadding)

            VStack(alignment: .leading, spacing: .zero) {
                createItem(
                    image: SystemIcons.pkoIconDesktopMobile24.image,
                    title: .labels.BehavioralBiometric_InfoScreen_lbl_MiddleSectionTitle2.localized,
                    subtitle: .labels.BehavioralBiometric_InfoScreen_lbl_MiddleSectionSubtitle3.localized
                )
                ContentMessage(
                    model: .init(
                        icon: .hint,
                        title: .labels.BehavioralBiometric_InfoScreen_lbl_ConentMessageTitle.localized,
                        subtitle: .labels.BehavioralBiometric_InfoScreen_lbl_ConentMessageSubtitle.localized
                    ),
                    linkButton: nil
                )
                .padding(.vertical, Constants.commonPadding)
            }
            .padding(.horizontal, Constants.commonPadding)
        }
        .background(Color(uiColor: .ikoWhite100))
    }

    private func createItem(image: Image, title: String, subtitle: String) -> some View {
        HStack(spacing: Constants.commonPadding) {
            image
                .resizable()
                .frame(
                    width: Constants.itemImageSize,
                    height: Constants.itemImageSize
                )
            VStack(alignment: .leading, spacing: .zero) {
                AttributedText(title)
                    .fontStyle(Constants.itemHeaderFontStyle)
                AttributedText(
                    .labels.BehavioralBiometric_InfoScreen_lbl_MiddleSectionSubtitle1.localized
                )
            }
        }
        .padding(.top, Constants.headerTopPadding)
    }

    private var questionsAndAnswersSection: some View {
        VStack(alignment: .leading, spacing: .zero) {
            Separator()
            HStack {
                HeaderView(text: .labels.BehavioralBiometric_InfoScreen_lbl_BottomSectionHeader.localized)
                    .with(topSeparatorHidden: true)
                    .with(bottomSeparatorHidden: true)
                Spacer()
                Button {
                    store.send(.onShowAllQuestionsAndAnswersButtonTap)
                } label: {
                    AttributedText(.labels.BehavioralBiometric_InfoScreen_btn_BottomSectionAll.localized)
                        .fontStyle(Constants.showAllQuestionsAndAnswersButtonFontStyle)
                }
                .padding(.trailing, Constants.commonPadding)
            }
            ForEach(store.questionsAndAnswersItems) { item in
                let binding = Binding(
                    get: { store.expandedId == item.id },
                    set: { isExpanded in
                        store.send(.onQuestionTap(isExpanded ? item.id : nil))
                    }
                )
                Collapse(isExpanded: binding) {
                    AttributedText(item.description)
                        .fontStyle(Constants.answerFontStyle)
                        .padding(.horizontal, Constants.commonPadding)
                        .padding(.vertical, Constants.itemSpacing)
                } header: {
                    HeaderCollapse(title: item.title)
                        .headerStyle(.default(hideBottomSeparatorOnCollapsed: true))
                }
            }
        }
        .background(Color(uiColor: .ikoWhite100))
    }

    private var bottomPrimaryButtonView: some View {
        VStack {
            PrimaryButton(title: .labels.BehavioralBiometric_InfoScreen_btn_Activation.localized) {
                store.send(.onTurnOnAdditionalSecurityButtonTap)
            }
            .padding(Constants.commonPadding)
        }
        .background(Color(uiColor: .ikoWhite100))
    }
}
