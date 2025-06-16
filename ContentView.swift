import SwiftUI
import ComposableArchitecture

struct DatePickerView: View {
    enum Constants {
        static let dayViewPickerHeight: CGFloat = 72
    }

    var store: StoreOf<DatePickerFeature>
    var onDragChanged: ((CGFloat) -> Void)?
    @Binding private var maxLandscapeMonthViewHeight: CGFloat
    @Binding private var verticalDragOffset: CGFloat
    private var monthViewPickerHeight: CGFloat {
        if UIDevice.current.orientation.isLandscape {
            maxLandscapeMonthViewHeight
        } else {
            400
        }
    }

    public init(
        store: StoreOf<DatePickerFeature>,
        maxLandscapeMonthViewHeight: Binding<CGFloat>,
        verticalDragOffset:  Binding<CGFloat>,
        onDragChanged: ((CGFloat) -> Void)? = nil
    ) {
        self.store = store
        self.onDragChanged = onDragChanged
        self._maxLandscapeMonthViewHeight = maxLandscapeMonthViewHeight
        self._verticalDragOffset = verticalDragOffset
    }

    var body: some View {
        ZStack(alignment: .top) {
            Color.white.opacity(0).ignoresSafeArea()

            VStack(spacing: 0) {
                Capsule()
                    .fill(Color.textLightGray)
                    .frame(width: 40, height: 4)
                    .padding(.top, 12)

                VStack {
                    switch store.calendarType {
                    case .day:
                        DatePickerDaysLayoutView(
                            store: store.scope(
                                state: \.datePickerDaysLayoutFeature,
                                action: \.datePickerDaysLayoutFeature
                            )
                        )
                    case .month:
                        DatePickerMonthsLayoutView(
                            store: store.scope(
                                state: \.datePickerMonthsLayoutFeature,
                                action: \.datePickerMonthsLayoutFeature
                            )
                        )
                    }
                }
                .frame(height: verticalDragOffset)
                .clipped()
            }
            .background(
                UnevenRoundedRectangle(
                    cornerRadii: .init(topLeading: 16, topTrailing: 16)
                )
                .fill(.white)
                .ignoresSafeArea()
                .shadow(color: .black.opacity(0.2), radius: 2, x: 0, y: -4)
            )
            .gesture(
                DragGesture(minimumDistance: 10)
                    .onChanged { value in
                        verticalDragOffset -= value.translation.height
                        verticalDragOffset = max(Constants.dayViewPickerHeight,
                                                 min(monthViewPickerHeight, verticalDragOffset))

                        let newType: DatePickerFeature.State.CalendarType =
                            verticalDragOffset <= Constants.dayViewPickerHeight + 100 ? .day : .month
                        store.send(.calendarTypeChanged(newType))
                        onDragChanged?(verticalDragOffset)
                    }
                    .onEnded { _ in
                        withAnimation {
                            verticalDragOffset =
                                verticalDragOffset > monthViewPickerHeight / 3
                                ? monthViewPickerHeight
                                : Constants.dayViewPickerHeight
                        } completion: {
                            let newType: DatePickerFeature.State.CalendarType =
                                verticalDragOffset <= Constants.dayViewPickerHeight + 100 ? .day : .month
                            store.send(.calendarTypeChanged(newType))
                        }
                        onDragChanged?(verticalDragOffset)
                    }
            )
        }
        .frame(maxHeight: .infinity, alignment: .bottom)
        .ignoresSafeArea(edges: .bottom)
    }
}

#Preview {
    DatePickerView(
        store: Store(initialState: DatePickerFeature.State()) {
            DatePickerFeature()
        },
        maxLandscapeMonthViewHeight: .init(get: { .zero }, set: { _ in }),
        verticalDragOffset: .init(get: { .zero }, set: { _ in }),
    )
}







//
//  WatchlistDataFormat6RefactoredViewController.swift
//  BPAGenieV2
//
//  Created by Daniel Satin on 20/02/2019.
//  Copyright © 2019 HCL Technologies. All rights reserved.
//

import Combine
import ComposableArchitecture
import GenieInject
import GenieLogger
import SwiftUI
import UIKit
import WatchlistResidentialUI

class WatchlistDataFormat6RefactoredViewController: WatchlistDataFormat1RefactoredViewController, DailySalesPreviewExtension {

    var dailySalesPreviewHeight: NSLayoutConstraint?
//    var dailySalesPreview: DSPBanner = DSPBanner(mainText: "Daily Sales Preview is on", actionButtonTitle: "TURN OFF")
    var aiBanner: AIPulseBanner = AIPulseBanner(mainText: "AI PULSE")
    var aiBannerHeight: NSLayoutConstraint?
    var bannersStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.distribution = .fill
        stackView.alignment = .fill
        return stackView
    }()
    var didSwitchFromKpiOrTab = false

    private var dataTableView: DataTableView!
    private var dataTableViewModel: DataTableViewModel!
    private var headerView: HeaderScrollingView!
    private var calendarViewController: UIHostingController<DatePickerView>!
    @Published private var maxLandscapeMonthViewHeight: CGFloat  = .zero
    @Published private var calendarVerticalOffset: CGFloat = 72
    private var prevOrienation: UIDeviceOrientation?
    private var calendarHeightConstraint: NSLayoutConstraint!
    private var datePickerStore: StoreOf<DatePickerFeature> = Store(initialState: DatePickerFeature.State()) {
        DatePickerFeature()
    }
    private var observation: ObserveToken?

    private var isDailySalesBannerDataHidden = Observable<Bool>(true)
    
    var turnOffDailySalesPreviewOnKpiChange = true {
        didSet {
            if turnOffDailySalesPreviewOnKpiChange == false {
                gLogger.debug(22)
            }
        }
    }

    @Inject var setDailySalesPreviewUC: SetDailySalesPreviewUC
    var isDailySalesPreviewSwitchOffNecessary: Bool = false

    override var dataType: WatchlistDataFormat { return .dataFormat6 }
    override var currentWatchlistPageSettingsParameters: WatchlistPageSettingsParameters {
        // inheritance from OTHER KPI
        // We need to reset the settings chain, so we do not get something we do not want
        var parameters = WatchlistPageSettingsParameters()
        parameters.info = watchlistTab.info
        parameters.infoViewHasBeenSeen = hasInfoTextBeenSeen
        parameters.kpiDataFormat = dataType
        parameters.pdfDescriptionFilePath = watchlistTab.pdfDescriptionFilePath
        parameters.hasWatchlistItems = true
        parameters.hasShowInThousandsSwitch = true
        parameters.hasGroupByCategorySwitch = true
        parameters.hasAlternativeViewSwitch = true
        parameters.hasBookmarks = true
        parameters.hasDailySalesPreview = true
        parameters.hasDecoupleValuesSwitch = true
        parameters.hasAlternativeLoLfSwitch = true
        return parameters
    }
    override var hasSortingOption: Bool { true }

    override func viewDidLoad() {
        super.viewDidLoad()
        initializeView()
        addConstraints()

        turnOffDailySalesPreview()
        bindOrientationChangeObserver()
//        hideBanners()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        turnOffDailySalesPreviewOnKpiChange = true
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        observation = observe { [weak self] in // TODO: Scope is not working - it emits for each state property
            guard let self else { return }
            print("🍀🍀🍀🍀🍀🍀🍀🍀🍀🍀🍀🍀🍀", self.datePickerStore.selectedDate ?? "---", viewModel?.configurationController.selectedDate ?? "---")

            guard let selectedDate = self.datePickerStore.selectedDate, self.viewModel?.configurationController.selectedDate != selectedDate else { return }

            self.viewModel?.configurationController.selectedDate = selectedDate
            self.viewModel?.reloadData()
        }
        setMaxLandscapeHeight()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        observation?.cancel()
        if turnOffDailySalesPreviewOnKpiChange {
            turnOffDailySalesPreview()
        }
        didSwitchFromKpiOrTab = false
    }

    // this needs refactoring to support generics
    override func initViewModelIfIsNil() -> WatchlistDataViewModel {
        guard let viewModel = viewModel else {
            viewModel = WatchlistDataViewModelWithUserSettings(dataType: dataType, watchlistTab: watchlistTab, settings: settings, regionConfiguration: visibleRegionConfiguration)
            return viewModel!
        }

        viewModel.dataType = dataType
        viewModel.watchlistTab = watchlistTab
        viewModel.settings = settings
        viewModel.regionConfiguration = visibleRegionConfiguration

        return viewModel
    }

    override func setupViewModel() {
        super.setupViewModel()
        addObserverForDailySalesPreview()

        guard let viewModel = viewModel else { return }

        viewModel.dataSourceDidReloadDataHandler = { [weak self] dataSourceFormat, changes, animated, _ in
            guard let self = self else { return }
            let mapper = WatchlistDataSourceFormatToTableDataPresentationModelMapper()
            let data = mapper.map(
                model: dataSourceFormat,
                parentView: self,
                columnProjectionConfiguration: viewModel.isLandscapeMode ? (UIDevice.isIpad ? self.iPadRegularColumnProjectionConfiguration() : self.regularColumnProjectionConfiguration()) : self.limitedColumnProjectionConfiguration()
            )
            self.dataTableViewModel.setup(with: data, rawData: [])
            self.dataTableView.updateRowHeight(rowHeight: viewModel.isLandscapeMode && !UIDevice.isIpad ? Constants.regularCellHeight : Constants.limitedCellHeight)
            self.noContentViewProgramatic.isHidden = data.isNotEmpty
            self.view.layoutIfNeeded()
        }
        viewModel.headerViewModel.addObserver(fire: true) { [weak self] headerViewModel in
            guard let self = self, let headerView = self.headerView else { return }
            let mapper = WatchlistHeaderDataToHeaderScrollingViewUIModelMapper()
            let uiModel = mapper.map(
                model: headerViewModel,
                parentView: self,
                columnProjectionConfiguration: viewModel.isLandscapeMode ? (UIDevice.isIpad ? self.iPadRegularColumnProjectionConfiguration() : self.regularColumnProjectionConfiguration()) : self.limitedColumnProjectionConfiguration(),
                height: viewModel.isLandscapeMode && !UIDevice.isIpad ? Constants.regularHeaderHeight : Constants.limitedHeaderHeight)
            headerView.setup(with: uiModel)
            self.view.layoutIfNeeded()
        }
        viewModel.isTableViewHeaderHidden.addObserver { [weak self] isHidden in
            guard let self = self else { return }
            self.dataHeaderView?.isHidden = true
            self.itemHeaderView?.isHidden = true
            self.headerView?.isHidden = isHidden
            self.dataTableView?.isHidden = isHidden
            self.calendarViewController?.view.isHidden = isHidden
        }
        viewModel.isLoadingViewHidden.addObserver { [weak self] isHidden in
            guard let self = self else { return }
            self.loadingViewProgramatic.isHidden = isHidden
            !isHidden ? self.noContentViewProgramatic.isHidden = true : ()
            if isHidden {
                self.refreshControl.endRefreshing()
                self.dataTableView?.updateIsPullToRefresh(!isHidden)
            }
            self.dataHeaderView?.isHidden = true
            self.itemHeaderView?.isHidden = true
            
            self.bannersStackView.isHidden = !isHidden
        }
//        viewModel.bannerData.addObserver(fire: true, { [weak self] model in
//            guard let self = self else { return }
//
//            defer {
//                self.view.layoutIfNeeded()
//            }
//
//            guard let model = model else {
//                self.aiBannerHeight?.constant = .zero
//                self.aiBanner.isHidden = true
//                return
//            }
//
//            self.aiBanner.setMainLabel(text: model.title)
//            self.aiBanner.onActionButtonTap = { [weak self] in
//                self?.showHelpOverlay(text: model.info ?? "")
//            }
//
//            self.aiBannerHeight?.constant = Constants.bannerHeight
//            self.aiBanner.isHidden = false
//        })
        viewModel.bannerData.addObserver(fire: true, { [weak self] model in
            guard let self = self else { return }
            guard isDailySalesBannerDataHidden.value else { return } // DAILY SALES PREVIEW
            
            defer {
                self.view.layoutIfNeeded()
            }
            
            self.bannersStackView.removeAllArrangedSubviews()
            
            guard let model = model else { return }
            
            let banner = InfoBanner(mainText: model.title ?? "")
            banner.setMainLabel(text: model.title)
//            banner.setMinButtonWith(Constants.dailySalesPreviewMinButtonWith)
            
            if let infoText = model.info, infoText.isNotEmpty {
                banner.setActionButton(title: "READ")
                banner.setActionButton(isHidden: false)
                banner.onActionButtonTap = { [weak self] in
                    self?.showHelpOverlay(text: infoText)
                }
            } else {
                banner.setActionButton(isHidden: true)
            }
            
            if let hasHideButton = model.hasHideButton, hasHideButton {
                banner.setHideButton(title: "Hide")
                banner.setHideButton(isHidden: false)
                banner.onHideButtonTap = { [weak self] in
                    self?.viewModel?.hideBanner(id: model.title ?? "")
                }
            } else {
                banner.setHideButton(isHidden: true)
            }
            
            NSLayoutConstraint.activate([
                banner.heightAnchor.constraint(equalToConstant: Constants.bannerHeight)
            ])
            self.bannersStackView.addArrangedSubview(banner)
        })
        
        isDailySalesBannerDataHidden.addObserver(fire: true, { [weak self] isHidden in
            guard let self = self else { return }
            
            defer {
                self.view.layoutIfNeeded()
            }
            
            self.bannersStackView.removeAllArrangedSubviews()
            
            guard !isHidden else {
                self.viewModel?.refreshBanner()
                return
            }
            
            let dailySalesPreview = DSPBanner(mainText: "Daily Sales Preview is on", actionButtonTitle: "TURN OFF")
            dailySalesPreview.setMinButtonWith(Constants.dailySalesPreviewMinButtonWith)
            dailySalesPreview.setHideButton(isHidden: true)
            dailySalesPreview.translatesAutoresizingMaskIntoConstraints = false
            dailySalesPreview.onActionButtonTap = { [weak self] in
                self?.turnOffDailySalesPreview()
            }
            
            NSLayoutConstraint.activate([
                dailySalesPreview.heightAnchor.constraint(equalToConstant: Constants.bannerHeight)
            ])
            self.bannersStackView.addArrangedSubview(dailySalesPreview)
        })

        viewModel.pickerData.addObserver(fire: true, { [weak self] dates in
            guard let self = self else { return }
            let pickerDates = PickerDateMapper.map(dates: dates)
            self.datePickerStore.send(.datesFetched(pickerDates ?? []))
        })
    }
    
    func addObserverForDailySalesPreview() {
        (viewModel as? WatchlistDataViewModelWithUserSettings)?.userSettings.addObserver { [weak self] userSettings in
            guard let self = self else { return }
            let hasDailySalesPreview = (userSettings?.dailySalesPreview?.settingIsActive ?? false) && (userSettings?.dailySalesPreview?.settingIsVisible ?? false)
            self.isDailySalesPreviewSwitchOffNecessary = userSettings?.dailySalesPreview?.settingIsActive ?? false
//            dailySalesPreviewHeight.constant = hasDailySalesPreview ? 44 : 0
            self.view.layoutIfNeeded()
            //            self.dailySalesPreview.isHidden = !hasDailySalesPreview
            isDailySalesBannerDataHidden.value = !hasDailySalesPreview
        }
    }
    
    override func goToDrilldown(item: BaseWatchlistItemData?) {
        guard let viewController = injectionContainer.makeWatchlistDataViewController(
            watchlistTab: watchlistTab,
            drillDown: true
        ) as? WatchlistDataFormat6RefactoredDrilldownViewController else {
            return
        }
        viewController.title = watchlistTab.name
        viewController.settings = settings
        viewController.watchlistTab = watchlistTab
        viewController.isBookmarkInPresentation = isBookmarkInPresentation
        viewController.viewModel?.isBookmarkInPresentation = isBookmarkInPresentation
        viewController.viewModel?.setupDrilldown(parent: viewModel, item: item)
        viewController.viewModel?.configurationController.selectedDate = self.viewModel?.configurationController.selectedDate
        viewModel?.childViewModel = viewController.viewModel

        viewController.selectedDateChanged = { [weak self] selectedDate in
            self?.viewModel?.configurationController.selectedDate = selectedDate
        }
        
        if let watchlistViewController = navigationController?.visibleViewController as? WatchlistViewController {
            watchlistViewController.reloadDataSourceAllowed = false
        }

        turnOffDailySalesPreviewOnKpiChange = false
        navigationController?.pushViewController(viewController, animated: true)
    }

//    private func hideBanners() {
//        dailySalesPreviewHeight?.constant = .zero
//        dailySalesPreview.isHidden = true
//        aiBannerHeight?.constant = .zero
//        aiBanner.isHidden = true
//    }
}

// MARK: - Layout
extension WatchlistDataFormat6RefactoredViewController {
    private func initializeView() {
        guard let viewModel = viewModel else { return }

        headerView = .init()
        errorViewProgramatic = .init()
        let errorViewProgramatic = errorViewProgramatic!
        errorViewProgramatic.isHidden = true

        noContentViewProgramatic.setup(with: ContentMessageView.UIModel(image: UIImage(named: "no_content")!, title: "No content to display"))

        [noContentViewProgramatic, loadingViewProgramatic, headerView, errorViewProgramatic].forEach {
            view.addSubview($0)
        }

        headerView.onHorizontalContentOffsetChanged = { [weak self] contentOffset in
            self?.dataTableView.updateHorizontalContentOffset(contentOffset)
        }
        
        dataTableViewModel = DataTableViewModel()
        let rowHeight: CGFloat = viewModel.isLandscapeMode && !UIDevice.isIpad ? Constants.regularCellHeight : Constants.limitedCellHeight
        dataTableView = DataTableView(viewModel: dataTableViewModel, rowHeight: rowHeight)
        view.addSubview(dataTableView)

        dataTableView.onHorizontalContentOffsetChanged = { [weak self] contentOffset in
            self?.headerView.updateHorizontalContentOffset(contentOffset)
        }
        dataTableView.onPullToRefresh = { [weak self] in
            self?.pullToRefreshHandler()
        }

        if let view = noContentView {
            self.view.bringSubviewToFront(view)
        }
        if let view = loadingView {
            self.view.bringSubviewToFront(view)
        }

        errorViewProgramatic.bringSubviewToFront(view)

        aiBanner.translatesAutoresizingMaskIntoConstraints = false
        bannersStackView.addArrangedSubview(aiBanner)

        bannersStackView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(bannersStackView)

        let binding = Binding(
            get: { [weak self] in
                self?.maxLandscapeMonthViewHeight ?? .zero
            },
            set: { _ in }
        )
        let calendarVerticalOffsetBinding = Binding(
            get: { [weak self] in
                self?.calendarVerticalOffset ?? .zero
            },
            set: { [weak self] in
                self?.calendarVerticalOffset = $0
                self?.calendarHeightConstraint.constant = $0
                self?.view.layoutIfNeeded()
            }
        )
        let datePickerView = DatePickerView(
            store: datePickerStore,
            maxLandscapeMonthViewHeight: binding,
            verticalDragOffset: calendarVerticalOffsetBinding
        ) { [weak self] verticalDragOffset in
//            self?.calendarHeightConstraint.constant = verticalDragOffset
//            self?.view.layoutIfNeeded() // Optional: Wrap in UIView.animate if desired
        }

        calendarViewController = UIHostingController(rootView: datePickerView)
        calendarViewController.view.translatesAutoresizingMaskIntoConstraints = false
        addChild(calendarViewController)
        view.addSubview(calendarViewController.view)
        calendarViewController.didMove(toParent: self)
        calendarHeightConstraint = calendarViewController.view.heightAnchor.constraint(equalToConstant: 72)
    }

    private func addConstraints() {
        NSLayoutConstraint.activate([
            headerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            headerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            headerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor)
        ])

//        dailySalesPreviewHeight = dailySalesPreview.heightAnchor.constraint(equalToConstant: Constants.bannerHeight)
        aiBannerHeight = aiBanner.heightAnchor.constraint(equalToConstant: Constants.bannerHeight)
        NSLayoutConstraint.activate([aiBannerHeight!])
        
        aiBanner.setMinButtonWith(Constants.aiBannerMinButtonWith)

        NSLayoutConstraint.activate([
            bannersStackView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            bannersStackView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            bannersStackView.topAnchor.constraint(equalTo: headerView.bottomAnchor),
        ])

        NSLayoutConstraint.activate([
            dataTableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            dataTableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            dataTableView.topAnchor.constraint(equalTo: bannersStackView.bottomAnchor),
            dataTableView.bottomAnchor.constraint(equalTo: calendarViewController.view.topAnchor),
        ])

        NSLayoutConstraint.activate([
            calendarViewController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            calendarViewController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            calendarViewController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            calendarHeightConstraint
        ])

        NSLayoutConstraint.activate([
            loadingViewProgramatic.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            loadingViewProgramatic.centerYAnchor.constraint(equalTo: view.centerYAnchor),
        ])

        NSLayoutConstraint.activate([
            noContentViewProgramatic.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            noContentViewProgramatic.centerYAnchor.constraint(equalTo: view.centerYAnchor),
        ])

        if let errorViewProgramatic = errorViewProgramatic {
            NSLayoutConstraint.activate([
                errorViewProgramatic.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 50),
                errorViewProgramatic.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -50),
                errorViewProgramatic.centerYAnchor.constraint(equalTo: view.centerYAnchor)
            ])
        }
    }

    private func limitedColumnProjectionConfiguration() -> ColumnProjectionConfiguration {
        let screenWidth = viewModel?.isLandscapeMode ?? false ? max(UIScreen.main.bounds.width, UIScreen.main.bounds.height) : min(UIScreen.main.bounds.width, UIScreen.main.bounds.height)
        return .init(
            maxColumnCount: Constants.limitedColumnProjectionMaxColumnCount,
            columnViewMaxWidth: Constants.limitedColumnProjectionColumnViewScreenWidthPercentage * screenWidth,
            isHorizontalScrollEnabled: Constants.limitedColumnProjectionIsHorizontalScrollEnabled,
            isSeparatorLineHidden: Constants.limitedColumnProjectionIsSeparatorLineHidden
        )
    }
    
    private func regularColumnProjectionConfiguration() -> ColumnProjectionConfiguration {
        let screenWidth = viewModel?.isLandscapeMode ?? false ? max(UIScreen.main.bounds.width, UIScreen.main.bounds.height) : min(UIScreen.main.bounds.width, UIScreen.main.bounds.height)
        let trailingInset = UIDevice.current.hasNotchAtTrailingEdge ? Constants.regularColumnProjectionTrailingInsetNotched : Constants.regularColumnProjectionTrailingInset
        return .init(
            maxColumnCount: Constants.regularColumnProjectionMaxColumnCount,
            columnViewMaxWidth: Constants.regularColumnProjectionColumnViewScreenWidthPercentage * screenWidth,
            columnViewTrailingInset: trailingInset,
            isHorizontalScrollEnabled: Constants.regularColumnProjectionIsHorizontalScrollEnabled,
            isSeparatorLineHidden: Constants.regularColumnProjectionIsSeparatorLineHidden
        )
    }

    private func iPadRegularColumnProjectionConfiguration() -> ColumnProjectionConfiguration {
        let screenWidth = viewModel?.isLandscapeMode ?? false ? max(UIScreen.main.bounds.width, UIScreen.main.bounds.height) : min(UIScreen.main.bounds.width, UIScreen.main.bounds.height)
        return .init(
            maxColumnCount: Constants.iPadRegularColumnProjectionMaxColumnCount,
            columnViewMaxWidth: Constants.iPadRegularColumnProjectionColumnViewScreenWidthPercentage * screenWidth
        )
    }
    
    private func setMaxLandscapeHeight() {
        print("headerView.frame.origin.y")
        print(headerView.frame)
        guard maxLandscapeMonthViewHeight.isZero else { return }
        if UIDevice.current.orientation.isLandscape {
            maxLandscapeMonthViewHeight = view.frame.height -  (navigationController?.navigationBar.frame.height ?? 0) - 44
        } else {
            maxLandscapeMonthViewHeight = view.frame.width -  (navigationController?.navigationBar.frame.height ?? 0) - 44
        }
    }
    
    private func bindOrientationChangeObserver() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(orientationDidChange),
            name: UIDevice.orientationDidChangeNotification,
            object: nil
        )
    }
    
    @objc func orientationDidChange() {
        if UIDevice.current.orientation.isLandscape,
           (prevOrienation != .landscapeRight || prevOrienation != .landscapeLeft),
           calendarHeightConstraint.constant > maxLandscapeMonthViewHeight {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
                guard let self else { return }
                self.calendarHeightConstraint.constant = self.maxLandscapeMonthViewHeight
                self.calendarVerticalOffset = self.maxLandscapeMonthViewHeight
                self.view.layoutIfNeeded()
            }
        }
        if UIDevice.current.orientation == .portrait,
           (prevOrienation != .portrait),
           calendarHeightConstraint.constant < 400,
           calendarHeightConstraint.constant > 80 {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
                self?.calendarHeightConstraint.constant = 400
                self?.calendarVerticalOffset = 400
                self?.view.layoutIfNeeded()
            }
        }
        prevOrienation = UIDevice.current.orientation
    }
}

private extension WatchlistDataFormat6RefactoredViewController {
    enum Constants {
        static let limitedColumnProjectionMaxColumnCount: UInt = 3
        static let limitedColumnProjectionColumnViewScreenWidthPercentage: CGFloat = 0.6
        static let limitedColumnProjectionIsHorizontalScrollEnabled: Bool = false
        static let limitedColumnProjectionIsSeparatorLineHidden: Bool = true
        static let regularColumnProjectionMaxColumnCount: UInt = 7
        static let regularColumnProjectionColumnViewScreenWidthPercentage: CGFloat = 0.67
        static let regularColumnProjectionTrailingInsetNotched: CGFloat = 55
        static let regularColumnProjectionTrailingInset: CGFloat = -15
        static let regularColumnProjectionIsHorizontalScrollEnabled: Bool = true
        static let regularColumnProjectionIsSeparatorLineHidden: Bool = false
        static let iPadRegularColumnProjectionMaxColumnCount: UInt = 9
        static let iPadRegularColumnProjectionColumnViewScreenWidthPercentage: CGFloat = 0.75
        static let limitedHeaderHeight: CGFloat = 44
        static let regularHeaderHeight: CGFloat = 34
        static let limitedCellHeight: CGFloat = 44
        static let regularCellHeight: CGFloat = 28
        static let bannerHeight: CGFloat = 44
        static let dailySalesPreviewMinButtonWith: CGFloat = 110
        static let aiBannerMinButtonWith: CGFloat = 110
    }
}
