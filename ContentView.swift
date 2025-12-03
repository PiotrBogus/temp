import SwiftUI
import ComposableArchitecture
import GenieCommonPresentation

struct MenuItemView: View {
    @Bindable var store: StoreOf<MenuItemFeature>

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            if store.isPossibleToExpand,
               store.isExpanded {
                groupView
            } else {
                button
                    .background(
                        RoundedRectangle(cornerRadius: 26)
                            .fill(createRowBackgroundColor())
                    )
            }
        }
        .task {
            store.send(.onAppear)
        }
        .background(
            Color.darkBlueBackground
        )
    }

    private var button: some View {
        Button(action: {
            store.send(.didTapItem(id: store.id))
        }, label: {
            VStack {
                HStack {
                    Text(store.title)
                        .font(.title3)
                        .fontWeight(store.isExpanded || store.isSelected ? .semibold : .regular)
                        .foregroundStyle(createTextColor(store.isSelected))
                    
                    Spacer()
                    
                    if store.isPossibleToExpand {
                        Image(systemName: store.isExpanded ? "chevron.down" : "chevron.right")
                            .foregroundStyle(Color.whiteText)
                    }
                }
                .padding(.horizontal, 16)
                if store.isPossibleToExpand  {
                    separatorView
                        .opacity(store.isExpanded ? 0 : 1)
                }
            }
        })
        .frame(height: 52)
    }

    private var groupView: some View {
        VStack(alignment: .leading, spacing: 4) {
            button
                .background(
                    RoundedRectangle(cornerRadius: 26)
                        .fill(createRowBackgroundColor())
                )
                childrenView
                .background(
                    Color.darkBlueBackground
                )
        }
        .background(
            Color.darkBlueBackground
        )
    }

    private var childrenView: some View {
        VStack {
            ForEach(
                store.scope(
                    state: \.identifiedArrayOfChildrens,
                    action: \.children
                ),
                id: \.state.id
            ) {
                MenuItemView(store: $0)
            }
            if store.isPossibleToExpand, store.isExpanded {
                separatorView
            }
        }
    }
    
    var separatorView: some View {
            Rectangle()
                .fill(Color.white)
                .frame(height: 1)
                .padding(.horizontal, 4)
    }


    private func createTextColor(_ isSelected: Bool) -> Color {
        isSelected ? Color.darkBlueBackground : Color.whiteText
    }

    private func createRowBackgroundColor() -> Color {
        if store.isSelected {
            return Color.whiteBackground
        }
        return Color.darkBlueBackground
    }
}





import SwiftUI
import ComposableArchitecture
import GenieCommonPresentation

public struct MenuView: View {
    @Bindable var store: StoreOf<MenuFeature>

    public init(store: StoreOf<MenuFeature>) {
        self.store = store
    }

    public var body: some View {
        VStack(spacing: 0) {
            headerView
            listView
            versionView
        }
        .background(
            Color.darkBlueBackground
        )
        .onAppear {
            store.send(.onFirstAppear)
        }
    }
    
    var headerView: some View {
        HStack(spacing: 6) {
            Image(uiImage: Asset.Assets.lightLogo.image)
            Text(L10n.menuViewTitle)
                .foregroundStyle(Color.whiteText)
                .font(.title)
                .fontWeight(.bold)
            Spacer()
            Button(action: {
                store.send(.dismiss)
            }) {
                Image(systemName: "xmark")
                    .resizable()
                    .frame(width: 16, height: 16)
                    .foregroundStyle(Color.whiteText)
            }
        }
        .padding(.top, 20)
        .padding(.horizontal, 32)
        .frame(width: menuWidth)
    }

    var listView: some View {
        ScrollView {
            VStack(alignment: store.deviceOrientation.isLandscape ? .center : .leading, spacing: 12) {
                ForEach(
                    store.scope(
                        state: \.items,
                        action: \.items
                    ),
                    id: \.state.id
                ) {
                    MenuItemView(store: $0)
                        .padding(.horizontal, 16)
                }
            }
            .padding(.vertical)
        }
        .onTapGesture {
            store.send(.dismiss)
        }
        .padding(.bottom, store.deviceOrientation.isLandscape ? 0 : 50)
        .frame(width: menuWidth)
    }
    
    private var menuWidth: CGFloat? {
        store.deviceOrientation.isLandscape ? 315 : nil
    }
    
    var versionView: some View {
        VStack {
            HStack(alignment: .center, spacing: 3) {
                Text(L10n.loginViewLoginVersion)
                    .font(.title3.weight(.semibold))
                    .foregroundColor(Color.headerLabelBackground)

                Text("\(store.state.appVersion) (\(store.state.appBuild))")
                    .font(.title3.weight(.semibold))
                    .foregroundColor(Color.headerLabelBackground)
            }
            .frame(maxWidth: .infinity, alignment: .trailing)
            .padding(.trailing, 15)
            .padding(.bottom, 15)
            
        }
        .frame(height: 15)
    }
}
