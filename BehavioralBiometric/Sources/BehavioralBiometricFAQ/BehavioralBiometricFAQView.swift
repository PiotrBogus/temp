import ComposableArchitecture
import DesignSystemSwiftUI
import Foundation
import SwiftUI

struct BehavioralBiometricFAQView: View {
    private struct Constants {
        static let answerFontStyle: UIFont.Style = .regular(.size16LS22)
    }
    var store: StoreOf<BehavioralBiometricFAQReducer>

    init(store: StoreOf<BehavioralBiometricFAQReducer>) {
        self.store = store
    }

    var body: some View {
        ZStack {
            ScrollView() {
                questionsAndAnswersSection
            }
        }
        .background(Color(uiColor: .ikoBlue0))
    }

    private var questionsAndAnswersSection: some View {
        VStack(alignment: .leading, spacing: .zero) {
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
}
