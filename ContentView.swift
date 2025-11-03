import  ComposableArchitecture

@Reducer
struct BehavioralBiometricExplanationReducer: Sendable {
    @ObservableState
    struct State: Equatable, Sendable {
        @Presents var destination: Destination.State?

        let questionsAndAnswersItems: [BehavioralBiometricQuestionAndAnswerItem] = [
            .init(
                title: "InfoScreen_btn_Question01",
                description: "InfoScreen_lbl_Answer01"
            ),
            .init(
                title: "InfoScreen_btn_Question02",
                description: "InfoScreen_lbl_Answer02"
            ),
            .init(
                title: "InfoScreen_btn_Question03",
                description: "InfoScreen_lbl_Answer03"
            ),
            .init(
                title: "InfoScreen_btn_Question04",
                description: "InfoScreen_lbl_Answer04"
            ),
            .init(
                title: "InfoScreen_btn_Question05",
                description: "InfoScreen_lbl_Answer05"
            )
        ]

        var expandedId: UUID?
    }

    @Reducer(state: .equatable, .sendable, action: .sendable)
    public enum Destination {
        case faq(BehavioralBiometricFAQReducer)
    }

    enum Action: Sendable {
        case onTurnOnAdditionalSecurityButtonTap
        case onShowAllQuestionsAndAnswersButtonTap
        case onQuestionTap(UUID?)
        case destination(PresentationAction<Destination.Action>)
    }

    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .onTurnOnAdditionalSecurityButtonTap:
                return .none
            case .onShowAllQuestionsAndAnswersButtonTap:
                state.destination = .faq(.init())
                return .none
            case let .onQuestionTap(id):
                state.expandedId = id
                return .none
            case .destination:
                return .none
            }
        }
        .ifLet(\.$destination, action: \.destination)
    }
}




import Assets
import ComposableArchitecture
import DesignSystemSwiftUI
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
        static let showAllQuestionsAndAnswersButtonFontStyle:  UIFont.Style = .regular(.size14LS18, color: .ikoBlue100)
    }

    var store: StoreOf<BehavioralBiometricExplanationReducer>

    init(store: StoreOf<BehavioralBiometricExplanationReducer>) {
        self.store = store
    }

    var body: some View {
        ZStack {
            VStack {
                ScrollView() {
                    VStack(spacing: Constants.itemSpacing) {
                        headerView
                        howItWorksSection
                        questionsAndAnswersSection
                    }
                }
                bottomPrimaryButtonView
            }
        }
        .background(Color(uiColor: .ikoBlue0))
        .navigationDestination(
            store: store.scope(state: \.$destination, action: .destination)
        ) {

        }
    }

    private var headerView: some View {
        ZStack {
            VStack(spacing: .zero) {
                Image(uiImage: Assets.imageNamed(IKOImages.ILU_ESG_SOCIETY)!)
                    .resizable()
                    .frame(width: Constants.imageSize, height: Constants.imageSize)
                    .padding(.top, Constants.imageVerticalPadding)

                VStack {
                    AttributedText("Darmowa usługa")
                        .fontStyle(Constants.statusLabelFontStyle)
                        .padding(Constants.statusLabelPadding)
                }
                .background(
                    RoundedRectangle(cornerRadius: Constants.statusLabelCornerRadius).fill(Color(uiColor: .ikoGreen100))
                )
                .padding(.top, Constants.statusLabelTopPadding)

                AttributedText("Dadtkowe zabezpieczenie")
                    .fontStyle(Constants.headerTitleLabelFontStyle)
                    .padding(.top, Constants.headerTopPadding)

                AttributedText("Wzmocnij ochronę Twoich pieniędzy przed oszustami")
                    .fontStyle(Constants.headerDescriptionFontStyle)
                    .multilineTextAlignment(.center)
                    .padding(.top, Constants.headerTopPadding)
                    .padding(.bottom, Constants.imageVerticalPadding)
                    .padding(.horizontal, Constants.commonPadding)
            }
        }
        .background(Color(uiColor: .ikoWhite100))
    }

    private var howItWorksSection: some View {
        VStack(alignment: .leading, spacing: .zero) {
            HeaderView(text:"Jak to działa?")

            VStack(alignment: .leading, spacing: Constants.itemSpacing) {
                createItemHeader(
                    image: Assets.imageNamed(IKOImages.PKO_ICON_MORE_PROTECTION)!,
                    title: "Wzmacnia bezpieczeństwo Twoich pieniędzy"
                )
                AttributedText(
                    "Sprawdzamy, czy to na pewno Ty logujesz się do aplikacji IKO."
                )
            }
            .padding(.horizontal, Constants.commonPadding)

            VStack(alignment: .leading, spacing: Constants.itemSpacing) {
                createItemHeader(
                    image: Assets.imageNamed(IKOImages.PKO_ICON_ADVISER_INDIVIDUAL)!,
                    title: "Tworzy profil Twoich zachować"
                )
                AttributedText(
                    "Rozwiązanie analizuje Twoje cechy zachowania m.in. tempo i sposób pisania na klawiaturze lub używanie ekranu dotykowego.."
                )
            }
            .padding(.horizontal, Constants.commonPadding)

            VStack(alignment: .leading, spacing: .zero) {
                createItemHeader(
                    image: Assets.imageNamed(IKOImages.PKO_ICON_DESKTOP_MOBILE)!,
                    title: "Analizuje parametry urządzenia z którego logujesz się do aplikacji IKO"
                )
                ContentMessageView(
                    icon: .hint,
                    title: "Dodatkowe zabezpieczenie nie zbiera informacji o:",
                    subtitle: "* Twoim loginie i haśle,\n* danych kontaktowych,\n* saldach, produktach i transakcjach"
                )
                .padding(.vertical, Constants.commonPadding)
            }
            .padding(.horizontal, Constants.commonPadding)
        }
        .background(Color(uiColor: .ikoWhite100))
    }

    private func createItemHeader(image: UIImage, title: String) -> some View {
        HStack(spacing: Constants.commonPadding) {
            Image(uiImage: image)
                .frame(
                    width: Constants.itemImageSize,
                    height: Constants.itemImageSize
                )
            AttributedText(title)
                .fontStyle(Constants.itemHeaderFontStyle)
        }
        .padding(.top, Constants.headerTopPadding)
    }

    private var questionsAndAnswersSection: some View {
        VStack(alignment: .leading, spacing: .zero) {
            Separator()
            HStack {
                HeaderView(text: "Pytania i odpowiedzi")
                    .with(topSeparatorHidden: true)
                    .with(bottomSeparatorHidden: true)
                Spacer()
                Button {
                    store.send(.onShowAllQuestionsAndAnswersButtonTap)
                } label: {
                    AttributedText("Wszystkie")
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
            PrimaryButton(title: "Włącz dodatkowe zabezpieczenie") {
                store.send(.onTurnOnAdditionalSecurityButtonTap)
            }
            .padding(Constants.commonPadding)
        }
        .background(Color(uiColor: .ikoWhite100))
    }
}

//#Preview {
//    BehavioralBiometricExplanationView()
//}
