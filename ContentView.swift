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
        presentNotificationPopUp()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        observation = observe { [weak self] in // TODO: Scope is not working - it emits for each state property
            guard let self else { return }
            print("🍀🍀🍀🍀🍀🍀🍀🍀🍀🍀🍀🍀🍀", self.datePickerStore.selectedDate ?? "---", viewModel?.configurationController.selectedDate ?? "---")

            guard let selectedDate = self.datePickerStore.selectedDate, self.viewModel?.configurationController.selectedDate != selectedDate else { return }
            returnCalendarToDayLayout()

            self.viewModel?.configurationController.selectedDate = selectedDate
            self.viewModel?.reloadData()
        }
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

        setupCalendarView()
    }
    
    private func setupCalendarView() {
        let datePickerView = DatePickerView(
            store: datePickerStore
        ) { [weak self] verticalDragOffset in
            self?.calendarHeightConstraint.constant = verticalDragOffset
            self?.view.layoutIfNeeded() // Optional: Wrap in UIView.animate if desired
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
            calendarViewController.view.topAnchor.constraint(greaterThanOrEqualTo: headerView.bottomAnchor),
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
    
    private func returnCalendarToDayLayout() {
        calendarHeightConstraint.constant = DatePickerViewConstants.dayViewPickerHeight
        datePickerStore.send(.updateVerticalOffset(DatePickerViewConstants.dayViewPickerHeight))
        datePickerStore.send(.calendarTypeChanged(.day))
        view.layoutIfNeeded()
    }
    
    private func bindOrientationChangeObserver() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(orientationDidChange),
            name: UIDevice.orientationDidChangeNotification,
            object: nil
        )
    }
    
    @objc private func orientationDidChange() {
        if UIDevice.currentOrientation.isLandscape || UIDevice.currentOrientation == .portraitUpsideDown,
           (prevOrienation != .landscapeRight || prevOrienation != .landscapeLeft || prevOrienation == .portraitUpsideDown),
           calendarHeightConstraint.constant > datePickerStore.maxLandscapeMonthLayoutHeight {
                self.calendarHeightConstraint.constant = self.datePickerStore.maxLandscapeMonthLayoutHeight
                self.datePickerStore.send(.updateVerticalOffset(self.datePickerStore.maxLandscapeMonthLayoutHeight))
                self.view.layoutIfNeeded()
        }
        if UIDevice.currentOrientation == .portrait,
           (prevOrienation != .portrait),
           calendarHeightConstraint.constant < DatePickerViewConstants.defaultMonthLayoutHeight,
           calendarHeightConstraint.constant > DatePickerViewConstants.dayViewPickerHeight {
            self.calendarHeightConstraint.constant = DatePickerViewConstants.defaultMonthLayoutHeight
            self.datePickerStore.send(.updateVerticalOffset(DatePickerViewConstants.defaultMonthLayoutHeight))
            self.view.layoutIfNeeded()
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




Unable to simultaneously satisfy constraints.
	Probably at least one of the constraints in the following list is one you don't want. 
	Try this: 
		(1) look at each constraint and try to figure out which you don't expect; 
		(2) find the code that added the unwanted constraint or constraints and fix it. 
(
    "<NSLayoutConstraint:0x60000245b7f0 H:|-(5)-[UIStackView:0x128e0aad0]   (active, names: '|':WatchlistResidentialUI.HeaderButtonView:0x1294c6db0 )>",
    "<NSLayoutConstraint:0x60000245bed0 UIStackView:0x128e0aad0.trailing == WatchlistResidentialUI.HeaderButtonView:0x1294c6db0.trailing - 5   (active)>",
    "<NSLayoutConstraint:0x6000061159a0 'fittingSizeHTarget' UIStackView:0x127a5ce40.width == 0   (active)>",
    "<NSLayoutConstraint:0x6000025fc320 'UISV-canvas-connection' UIStackView:0x127a5ce40.leading == WatchlistResidentialUI.HeaderButtonView:0x1294c6db0.leading   (active)>",
    "<NSLayoutConstraint:0x6000025fce60 'UISV-canvas-connection' H:[WatchlistResidentialUI.HeaderButtonView:0x1294d49b0]-(0)-|   (active, names: '|':UIStackView:0x127a5ce40 )>",
    "<NSLayoutConstraint:0x6000025fc690 'UISV-fill-equally' WatchlistResidentialUI.HeaderButtonView:0x1294d49b0.width == WatchlistResidentialUI.HeaderButtonView:0x1294c6db0.width   (active)>",
    "<NSLayoutConstraint:0x6000025fcaa0 'UISV-spacing' H:[WatchlistResidentialUI.HeaderButtonView:0x1294c6db0]-(0)-[WatchlistResidentialUI.HeaderButtonView:0x1294d49b0]   (active)>"
)

Will attempt to recover by breaking constraint 
<NSLayoutConstraint:0x60000245bed0 UIStackView:0x128e0aad0.trailing == WatchlistResidentialUI.HeaderButtonView:0x1294c6db0.trailing - 5   (active)>

Make a symbolic breakpoint at UIViewAlertForUnsatisfiableConstraints to catch this in the debugger.
The methods in the UIConstraintBasedLayoutDebugging category on UIView listed in <UIKitCore/UIView.h> may also be helpful.
Unable to simultaneously satisfy constraints.
	Probably at least one of the constraints in the following list is one you don't want. 
	Try this: 
		(1) look at each constraint and try to figure out which you don't expect; 
		(2) find the code that added the unwanted constraint or constraints and fix it. 
(
    "<NSLayoutConstraint:0x60000258cd20 H:|-(5)-[UIStackView:0x128ebc960]   (active, names: '|':WatchlistResidentialUI.HeaderButtonView:0x1294d49b0 )>",
    "<NSLayoutConstraint:0x600002597390 UIStackView:0x128ebc960.trailing == WatchlistResidentialUI.HeaderButtonView:0x1294d49b0.trailing - 5   (active)>",
    "<NSLayoutConstraint:0x6000061159a0 'fittingSizeHTarget' UIStackView:0x127a5ce40.width == 0   (active)>",
    "<NSLayoutConstraint:0x6000025fc320 'UISV-canvas-connection' UIStackView:0x127a5ce40.leading == WatchlistResidentialUI.HeaderButtonView:0x1294c6db0.leading   (active)>",
    "<NSLayoutConstraint:0x6000025fce60 'UISV-canvas-connection' H:[WatchlistResidentialUI.HeaderButtonView:0x1294d49b0]-(0)-|   (active, names: '|':UIStackView:0x127a5ce40 )>",
    "<NSLayoutConstraint:0x6000025fc690 'UISV-fill-equally' WatchlistResidentialUI.HeaderButtonView:0x1294d49b0.width == WatchlistResidentialUI.HeaderButtonView:0x1294c6db0.width   (active)>",
    "<NSLayoutConstraint:0x6000025fcaa0 'UISV-spacing' H:[WatchlistResidentialUI.HeaderButtonView:0x1294c6db0]-(0)-[WatchlistResidentialUI.HeaderButtonView:0x1294d49b0]   (active)>"
)

Will attempt to recover by breaking constraint 
<NSLayoutConstraint:0x600002597390 UIStackView:0x128ebc960.trailing == WatchlistResidentialUI.HeaderButtonView:0x1294d49b0.trailing - 5   (active)>

Make a symbolic breakpoint at UIViewAlertForUnsatisfiableConstraints to catch this in the debugger.
The methods in the UIConstraintBasedLayoutDebugging category on UIView listed in <UIKitCore/UIView.h> may also be helpful.
Unable to simultaneously satisfy constraints.
	Probably at least one of the constraints in the following list is one you don't want. 
	Try this: 
		(1) look at each constraint and try to figure out which you don't expect; 
		(2) find the code that added the unwanted constraint or constraints and fix it. 
(
    "<NSLayoutConstraint:0x60000245b7f0 H:|-(5)-[UIStackView:0x128e0aad0]   (active, names: '|':WatchlistResidentialUI.HeaderButtonView:0x1294c6db0 )>",
    "<NSLayoutConstraint:0x60000245bed0 UIStackView:0x128e0aad0.trailing == WatchlistResidentialUI.HeaderButtonView:0x1294c6db0.trailing - 5   (active)>",
    "<NSLayoutConstraint:0x600006193d90 'fittingSizeHTarget' UIStackView:0x127a5ce40.width == 0   (active)>",
    "<NSLayoutConstraint:0x6000025fc320 'UISV-canvas-connection' UIStackView:0x127a5ce40.leading == WatchlistResidentialUI.HeaderButtonView:0x1294c6db0.leading   (active)>",
    "<NSLayoutConstraint:0x6000025fce60 'UISV-canvas-connection' H:[WatchlistResidentialUI.HeaderButtonView:0x1294d49b0]-(0)-|   (active, names: '|':UIStackView:0x127a5ce40 )>",
    "<NSLayoutConstraint:0x6000025fc690 'UISV-fill-equally' WatchlistResidentialUI.HeaderButtonView:0x1294d49b0.width == WatchlistResidentialUI.HeaderButtonView:0x1294c6db0.width   (active)>",
    "<NSLayoutConstraint:0x6000025fcaa0 'UISV-spacing' H:[WatchlistResidentialUI.HeaderButtonView:0x1294c6db0]-(0)-[WatchlistResidentialUI.HeaderButtonView:0x1294d49b0]   (active)>"
)

Will attempt to recover by breaking constraint 
<NSLayoutConstraint:0x60000245bed0 UIStackView:0x128e0aad0.trailing == WatchlistResidentialUI.HeaderButtonView:0x1294c6db0.trailing - 5   (active)>

Make a symbolic breakpoint at UIViewAlertForUnsatisfiableConstraints to catch this in the debugger.
The methods in the UIConstraintBasedLayoutDebugging category on UIView listed in <UIKitCore/UIView.h> may also be helpful.
Unable to simultaneously satisfy constraints.
	Probably at least one of the constraints in the following list is one you don't want. 
	Try this: 
		(1) look at each constraint and try to figure out which you don't expect; 
		(2) find the code that added the unwanted constraint or constraints and fix it. 
(
    "<NSLayoutConstraint:0x60000258cd20 H:|-(5)-[UIStackView:0x128ebc960]   (active, names: '|':WatchlistResidentialUI.HeaderButtonView:0x1294d49b0 )>",
    "<NSLayoutConstraint:0x600002597390 UIStackView:0x128ebc960.trailing == WatchlistResidentialUI.HeaderButtonView:0x1294d49b0.trailing - 5   (active)>",
    "<NSLayoutConstraint:0x600006193d90 'fittingSizeHTarget' UIStackView:0x127a5ce40.width == 0   (active)>",
    "<NSLayoutConstraint:0x6000025fc320 'UISV-canvas-connection' UIStackView:0x127a5ce40.leading == WatchlistResidentialUI.HeaderButtonView:0x1294c6db0.leading   (active)>",
    "<NSLayoutConstraint:0x6000025fce60 'UISV-canvas-connection' H:[WatchlistResidentialUI.HeaderButtonView:0x1294d49b0]-(0)-|   (active, names: '|':UIStackView:0x127a5ce40 )>",
    "<NSLayoutConstraint:0x6000025fc690 'UISV-fill-equally' WatchlistResidentialUI.HeaderButtonView:0x1294d49b0.width == WatchlistResidentialUI.HeaderButtonView:0x1294c6db0.width   (active)>",
    "<NSLayoutConstraint:0x6000025fcaa0 'UISV-spacing' H:[WatchlistResidentialUI.HeaderButtonView:0x1294c6db0]-(0)-[WatchlistResidentialUI.HeaderButtonView:0x1294d49b0]   (active)>"
)

Will attempt to recover by breaking constraint 
<NSLayoutConstraint:0x600002597390 UIStackView:0x128ebc960.trailing == WatchlistResidentialUI.HeaderButtonView:0x1294d49b0.trailing - 5   (active)>

Make a symbolic breakpoint at UIViewAlertForUnsatisfiableConstraints to catch this in the debugger.
The methods in the UIConstraintBasedLayoutDebugging category on UIView listed in <UIKitCore/UIView.h> may also be helpful.
