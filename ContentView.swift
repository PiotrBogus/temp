    func testOnFirstAppear_LoadsMenuAndAppInfo() async {
        let mockMenuItems = [
            MenuItemFeature.State(children: [], id: "1", parentId: nil, title: "Home"),
            MenuItemFeature.State(children: [], id: "2", parentId: nil, title: "Settings")
        ]

        let store = TestStore(
            initialState: MenuFeature.State(preselectedItemId: nil)
        ) {
            MenuFeature()
        } withDependencies: {
            $0.menuFeatureClient.loadMenuItems = { _ in mockMenuItems }
            $0.menuFeatureClient.appInfoViewModel = {
                AppInfoViewModel(version: "1.0", build: "100", environment: "Dev")
            }
            $0.menuFeatureClient.log = { _, _ in }
        }

        await store.send(.onFirstAppear)
        await store.receive { action in
            if case let .didLoadMenu(mockMenuItems) = action {
                return true
            } else {
                return false
            }
            $0.items = IdentifiedArrayOf(uniqueElements: mockMenuItems)
            $0.appVersion = "1.0"
            $0.appBuild = "100"
            $0.appEnvironment = "Dev"
        }
    }
