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
            WithViewStore(store, observe: { $0 }) { viewStore in
                ForEach(store.questionsAndAnswersItems) { item in
                    Collapse(
                        isExpanded: viewStore.binding(
                            get: { $0.expandedId == item.id },
                            send: { isExpanded in
                                store.send(.onQuestionTap(isExpanded ? item.id : nil))
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
        }
        .background(Color(uiColor: .ikoWhite100))
    }



The compiler is unable to type-check this expression in reasonable time; try breaking up the expression into distinct sub-expressions
