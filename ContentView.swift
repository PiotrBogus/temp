@ViewBuilder
var menuOverlay: some View {
    GeometryReader { geometry in
        ZStack(alignment: .trailing) {
            if store.menu != nil {
                // Background dim
                Color.black.opacity(0.5)
                    .ignoresSafeArea()
                    .onTapGesture {
                        withAnimation(.easeInOut) {
                            store.send(.menu(.presented(.dismiss)))
                        }
                    }
                    .transition(.opacity)
            }

            IfLetStore(
                store.scope(state: \.$menu, action: \.menu)
            ) { menuStore in
                MenuView(store: menuStore)
                    .frame(width: geometry.size.width * 0.75,
                           height: geometry.size.height)
                    .background(Color.white)
                    .shadow(radius: 8)
                    // Push-style animation
                    .offset(x: store.menu == nil ? geometry.size.width : 0)
                    .animation(.easeInOut, value: store.menu != nil)
            }
        }
    }
}
