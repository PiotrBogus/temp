import SwiftUI
import ComposableArchitecture

struct AlternativeItemView: View {
    @Bindable var store: StoreOf<AlternativeItemFeature>

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 8) {
                IndentationView(
                    level: store.level,
                    isExpandable: store.isPossibleToExpand,
                    isExpanded: store.isExpanded,
                    isSelected: store.isSelected,
                    isDisabled: store.isDisabled
                )
                .onTapGesture {
                    store.send(.didExpandItem(id: store.id))
                }

                VStack {
                    Spacer()
                    HStack(spacing: .zero) {
                        Text(store.title)
                            .font(.body)
                            .fontWeight(store.isSelected ? .bold : .regular)
                            .disabled(store.isDisabled)
                        Spacer()
                    }
                    Spacer()
                }
                .overlay(
                    Rectangle()
                        .fill(Color.separator)
                        .frame(height: 1),
                    alignment: .bottom
                )
                .onTapGesture {
                    store.send(.didTapItem(id: store.id))
                }
            }
            .contentShape(Rectangle())

            if store.isExpanded {
                ForEachStore(
                    store.scope(
                        state: \.identifiedArrayOfChildrens,
                        action: \.children
                    )
                ) { childStore in
                    AlternativeItemView(store: childStore)
                }
            }
        }
        .onAppear {
            store.send(.onAppear)
        }
    }
}


private struct IndentationView: View {
    let level: Int
    let isExpandable: Bool
    let isExpanded: Bool
    let isSelected: Bool
    let isDisabled: Bool

    var body: some View {
        VStack(spacing: .zero) {
            Rectangle()
                .fill(level > 0 ? Color.separator : Color.clear)
                .frame(width: 1, height: 14)
                .padding(.bottom, 2)

            if isExpandable {
                Image(systemName: isExpanded ? "minus.circle" : "plus.circle")
                    .foregroundColor(prepareColor())
                    .frame(width: 20, height: 20)
                    .disabled(isDisabled)
            } else {
                VStack {
                    Circle()
                        .fill(prepareColor())
                        .frame(width: 14, height: 14)
                        .disabled(isDisabled)
                }
                .frame(width: 20, height: 20)
            }
            Rectangle()
                .fill(level > 0 || (level == 0 && isExpanded) ? Color.separator : Color.clear)
                .frame(width: 1, height: 14)
                .padding(.top, 2)
        }
    }

    private func prepareColor() -> Color {
        switch level {
        case 0:
            Color(uiColor: .bluePrimary)
        case 1:
            Color(hex: 0x8d1f1b)
        case 2:
            Color(hex: 0xe74a21)
        case 3:
            Color(hex: 0xFCB13B)
        case 4:
            Color(hex: 0x6ad545)
        case 5:
            Color(hex: 0x45d5b1)
        default:
            Color.random()
        }
    }
}
