import XCTest
import Dependencies
@testable import AppCompositionDomain
@testable import GenieApi // jeśli typy są z tego modułu

final class MenuRepositoryImplTests: XCTestCase {

    struct MockApiClient {
        var menuHandler: @Sendable () async throws -> GenieApi.MenuV1Response
    }

    func test_loadMenu_returnsDecodedItems() async throws {
        // Given
        let mockItems: [MenuItemDto] = [
            MenuItemDto(id: 1, title: "Test Root", parentId: nil, externalKPIURL: nil),
            MenuItemDto(id: 2, title: "Child", parentId: 1, externalKPIURL: "https://example.com/kpi/2")
        ]

        // Stwórz mock API zwracający identyczną strukturę jak `apiClient.menuV1().ok.body`
        let mockApiClient = ApiClient(
            menuV1: {
                .ok(.json(mockItems))
            }
        )

        let repository = withDependencies {
            $0.apiClient = mockApiClient
        } operation: {
            MenuRepositoryImpl()
        }

        // When
        let result = try await repository.loadMenu()

        // Then
        XCTAssertEqual(result.count, 2)
        XCTAssertEqual(result.first?.title, "Test Root")
        XCTAssertEqual(result.last?.externalKPIURL, "https://example.com/kpi/2")
    }

    func test_loadMenu_throwsOnError() async {
        // Given
        enum DummyError: Error { case network }

        let mockApiClient = ApiClient(
            menuV1: {
                throw DummyError.network
            }
        )

        let repository = withDependencies {
            $0.apiClient = mockApiClient
        } operation: {
            MenuRepositoryImpl()
        }

        // When / Then
        do {
            _ = try await repository.loadMenu()
            XCTFail("Expected error to be thrown")
        } catch {
            guard case DummyError.network = error else {
                return XCTFail("Unexpected error type: \(error)")
            }
        }
    }
}



import Dependencies
import GenieApi

extension ApiClient: TestDependencyKey {
    public static let testValue = ApiClient(
        menuV1: { .ok(.json([])) }
    )
}


