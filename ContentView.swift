import ComposableArchitecture
import GenieCommonData
import GenieCommonDomain
import SwiftUI

// Convenience typealiases for specific ChartContainerFeature types
typealias ToolbarFiltersWithStrings = ToolbarFilters<String>
typealias ToolbarFiltersWithChartData = ToolbarFilters<ChartData>

/// Generic ToolbarFilters that works with any ChartContainerFeature<T>
struct ToolbarFilters<T: Equatable & Sendable>: View {
    @Bindable
    var store: StoreOf<ChartTableToolbarFeature<T>>

    init(store: StoreOf<ChartTableToolbarFeature<T>>) {
        self.store = store
    }

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 16) {
                // Render selectors
                ForEach(store.selectors, id: \.id) { selector in
                    FilterPill(dimension: selector) { option in
                        store.send(.setSelectorOption(selectorId: selector, option: option))
                    }
                }

                // Render dimensions
                ForEach(store.dimensions, id: \.id) { dimension in
                    switch dimension.type {
                    case .list:
                        FilterPill(dimension: dimension) { option in
                            store.send(
                                .toggleDimensionOption(dimensionId: dimension.id, option: option))
                        }
                    case .segmented:
                        SegmentedPill(dimension: dimension) { option in
                            store.send(
                                .toggleDimensionOption(dimensionId: dimension.id, option: option))
                        }
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
        }
    }
}

// MARK: - FilterPill that works with Dimension
struct FilterPill: View {
    let dimension: GenieCommonDomain.Dimension?
    let title: String
    let count: Int
    let options: [GenieCommonDomain.Dimension.Option]
    let onSelect: ((GenieCommonDomain.Dimension.Option) -> Void)?

    @State private var selectedId: Int
    @State private var showingModal: Bool = false

    init(
        dimension: GenieCommonDomain.Dimension,
        onSelect: @escaping (GenieCommonDomain.Dimension.Option) -> Void
    ) {
        self.dimension = dimension
        self.title = dimension.name
        self.count = 0
        self.options = dimension.options
        self.onSelect = onSelect
        _selectedId = State(
            initialValue: dimension.selectedOptions.first?.id ?? dimension.options.first?.id ?? 0)
    }

    // fallback initializer used by preview
    init(title: String, count: Int, options: [String] = ["All", "Option 1", "Option 2"]) {
        self.dimension = nil
        self.title = title
        self.count = count
        self.options = options.enumerated().map {
            Dimension.Option(id: $0.offset, title: $0.element)
        }
        self.onSelect = nil
        _selectedId = State(initialValue: self.options.first?.id ?? 0)
    }

    var body: some View {
        Button {
            showingModal = true
        } label: {
            titleBuilder()
        }
        .buttonStyle(PlainButtonStyle())
        .sheet(isPresented: $showingModal) {
            if let dim = dimension {
                ChartTableFilterModalView(filter: dim) { updated in
                    handleFilterUpdate(updated)
                }
            } else {
                EmptyView()
            }
        }
        .onChange(of: dimension?.selectedOptions) { _, new in
            if let new = new, let firstId = new.first?.id {
                selectedId = firstId
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func handleFilterUpdate(_ updated: GenieCommonDomain.Dimension) {
        if !updated.allowsMultiselect {
            // Single select: notify via onSelect for the selected option
            if let first = updated.selectedOptions.first {
                selectedId = first.id
                onSelect?(first)
            } else {
                // No selection - use first available option
                if let firstOption = updated.options.first {
                    selectedId = firstOption.id
                    onSelect?(firstOption)
                }
            }
        } else {
            // Multiselect: notify for each selected option
            // This ensures all selections are communicated to the parent
            for selectedOption in updated.selectedOptions {
                onSelect?(selectedOption)
            }
            
            // Update local selectedId to first selected option
            if let first = updated.selectedOptions.first {
                selectedId = first.id
            } else if let firstOption = updated.options.first {
                selectedId = firstOption.id
            }
        }
    }

    @ViewBuilder
    private func titleBuilder() -> some View {
        let filterTitle = title.isEmpty ? "Filter" : title

        let displayText: String = {
            if let selected = dimension?.selectedOptions {
                if selected.count == 1 {
                    return selected.first?.title ?? filterTitle
                } else if selected.count > 1 {
                    return "\(filterTitle) +\(selected.count)"
                }
            }

            return options.first(where: { $0.id == selectedId })?.title ?? filterTitle
        }()

        HStack(spacing: 8) {
            Text(displayText)
                .font(.system(size: 16, weight: .regular))
            Image(systemName: "chevron.down")
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(Capsule().fill(Color(.systemGray6)))
    }
}

// MARK: - Segmented pill that works with Dimension
struct SegmentedPill: View {
    let dimension: GenieCommonDomain.Dimension
    let options: [GenieCommonDomain.Dimension.Option]
    let onSelect: (GenieCommonDomain.Dimension.Option) -> Void

    // Configurable colors with defaults
    let backgroundColor: Color
    let thumbColor: Color
    let selectedTextColor: Color
    let unselectedTextColor: Color

    init(
        dimension: GenieCommonDomain.Dimension,
        onSelect: @escaping (GenieCommonDomain.Dimension.Option) -> Void,
        backgroundColor: Color = Color(UIColor.grayBackground),
        thumbColor: Color = Color(UIColor.groupBackground),
        selectedTextColor: Color = Color(UIColor.rowTitle),
        unselectedTextColor: Color = Color(UIColor.secondaryText)
    ) {
        self.dimension = dimension
        self.options = dimension.options
        self.onSelect = onSelect
        self.backgroundColor = backgroundColor
        self.thumbColor = thumbColor
        self.selectedTextColor = selectedTextColor
        self.unselectedTextColor = unselectedTextColor
    }

    var body: some View {
        GeometryReader { geo in
            let segmentWidth = geo.size.width / CGFloat(max(1, options.count))
            let selectedIndex =
                options.firstIndex(where: { $0.id == dimension.selectedOptions.first?.id }) ?? 0
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(backgroundColor)
                Capsule()
                    .fill(thumbColor)
                    .frame(width: segmentWidth)
                    .offset(x: CGFloat(selectedIndex) * segmentWidth)
                    .shadow(radius: 1)
                    .animation(.spring(), value: dimension.selectedOptions.first?.id)
                HStack(spacing: 0) {
                    ForEach(Array(options.enumerated()), id: \.element.id) { idx, option in
                        segmentLabel(
                            option.title,
                            isSelected: option.id == dimension.selectedOptions.first?.id
                        )
                        .frame(width: segmentWidth)
                        .contentShape(Rectangle())
                        .onTapGesture { onSelect(option) }
                    }
                }
            }
        }
        .frame(width: 160, height: 36)
        .padding(.horizontal, 4)
    }

    @ViewBuilder
    private func segmentLabel(_ text: String, isSelected: Bool) -> some View {
        Text(text)
            .font(.system(size: 16, weight: isSelected ? .semibold : .regular))
            .foregroundColor(isSelected ? selectedTextColor : unselectedTextColor)
            .multilineTextAlignment(.center)
    }
}

#Preview("Toolbar", traits: .landscapeLeft) {
    // Preview with a Store initialized from mock data so the preview reflects real state
    let initialDimensions = mockDimensions
    let initialItems = mockChartDataWithVisibility
    let visible = initialItems.filter { item in
        ChartTableToolbarFeatureWithStrings.isItemVisible(
            item,
            with: ChartTableToolbarFeatureWithStrings.dimensionSelectedMap(from: initialDimensions))
    }

    let store = Store(
        initialState: ChartTableToolbarFeatureWithStrings.State(
            items: initialItems,
            dimensions: initialDimensions,
            selectedDimensionIds: Set(initialDimensions.map { $0.id }),
            visibleChartData: visible
        )
    ) {
        ChartTableToolbarFeatureWithStrings()
    }

    ToolbarFilters<String>(store: store)
}

#Preview("FilterPills Example", traits: .landscapeLeft) {
    // Build two dimensions: one with 1 selected option, another with 3 selected options
    let options = (0..<6).map {
        GenieCommonDomain.FilterWithOptions.Option(id: $0, title: "Opt \($0)")
    }

    let dimOneSelected = GenieCommonDomain.FilterWithOptions(
        id: 1,
        name: "Title single",
        type: .list,
        selectedOptions: [options[1]],
        options: options,
        allowsMultiselect: true
    )

    let dimThreeSelected = GenieCommonDomain.FilterWithOptions(
        id: 2,
        name: "Title Multi",
        type: .list,
        selectedOptions: [options[0], options[2], options[3]],
        options: options,
        allowsMultiselect: true
    )

    HStack(spacing: 16) {
        FilterPill(dimension: dimOneSelected) { _ in }
        FilterPill(dimension: dimThreeSelected) { _ in }
    }
    .padding()
}
