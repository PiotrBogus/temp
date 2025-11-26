//
//  IntMarketTrackerRepository.swift
//  KpiIntMarketTracker
//
//  Created by Ekin Celik on 14.10.2025.
//

import GenieApi
import GenieCommonDomain
import KpiIntlMarketTrackerDomain

/// @mockable
public protocol IntMarketTrackerRepository: Sendable {
    func fetchData(
        selectors: [SelectorParamEntity],
        measureSelectors: [MeasureSelectorParamEntity],
        drillDownParams: [DrillDownParamEntity]
    ) async throws -> MarketTrackerKpiDataEntity
}

public extension IntMarketTrackerRepository {
    func fetchData(
        selectors: [SelectorParamEntity] = [],
        measureSelectors: [MeasureSelectorParamEntity] = [],
        drillDownParams: [DrillDownParamEntity] = []
    ) async throws -> MarketTrackerKpiDataEntity {
        try await fetchData(
            selectors: selectors,
            measureSelectors: measureSelectors,
            drillDownParams: drillDownParams
        )
    }
}



//
//  IntMarketTrackerRepositoryKey.swift
//  KpiIntMarketTracker
//
//  Created by Ekin Celik on 14.10.2025.
//

import Dependencies

public enum IntMarketTrackerRepositoryKey: DependencyKey {
    public static var liveValue: IntMarketTrackerRepository {
        return IntMarketTrackerRepositoryLive()
    }
}

public extension DependencyValues {
    var intMarketTrackerRepository: IntMarketTrackerRepository {
        get { self[IntMarketTrackerRepositoryKey.self] }
        set { self[IntMarketTrackerRepositoryKey.self] = newValue }
    }
}
