private struct QuestionRow: View {
    let item: BehavioralBiometricQuestionAndAnswerItem
    let expandedId: UUID?
    let onTap: (UUID?) -> Void

    var body: some View {
        let isExpanded = expandedId == item.id

        Collapse(
            isExpanded: Binding(
                get: { isExpanded },
                set: { newValue in
                    onTap(newValue ? item.id : nil)
                }
            )
        ) {
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




private var questionsAndAnswersSection: some View {
    VStack(alignment: .leading, spacing: .zero) {
        WithViewStore(store, observe: { $0 }) { viewStore in
            ForEach(viewStore.questionsAndAnswersItems) { item in
                QuestionRow(
                    item: item,
                    expandedId: viewStore.expandedId,
                    onTap: { id in
                        viewStore.send(.onQuestionTap(id))
                    }
                )
            }
        }
    }
    .background(Color(uiColor: .ikoWhite100))
}
