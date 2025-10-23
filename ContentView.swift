import Foundation
import CarPlay

actor CarPlayPresentationQueue: @unchecked Sendable {
    private var isProcessing = false
    private var queue: [() async -> Void] = []

    func enqueue(_ operation: @escaping () async -> Void) {
        queue.append(operation)
        if !isProcessing {
            isProcessing = true
            Task { await processQueue() }
        }
    }

    private func processQueue() async {
        while !queue.isEmpty {
            let next = queue.removeFirst()
            await next()
        }
        isProcessing = false
    }
}




import XCTest
@testable import YourModuleName

final class CarPlayPresentationQueueTests: XCTestCase {
    func testQueueProcessesTasksInOrder() async {
        let queue = CarPlayPresentationQueue()
        var results: [String] = []
        let expectation = XCTestExpectation(description: "All tasks executed in order")

        await queue.enqueue {
            results.append("first")
        }

        await queue.enqueue {
            results.append("second")
        }

        await queue.enqueue {
            results.append("third")
            expectation.fulfill()
        }

        await fulfillment(of: [expectation], timeout: 1.0)
        XCTAssertEqual(results, ["first", "second", "third"])
    }

    func testQueueProcessesSequentiallyEvenWithAsyncDelays() async {
        let queue = CarPlayPresentationQueue()
        var results: [String] = []
        let expectation = XCTestExpectation(description: "Sequential processing")

        await queue.enqueue {
            results.append("A")
            try? await Task.sleep(nanoseconds: 200_000_000) // 0.2s
            results.append("A done")
        }

        await queue.enqueue {
            results.append("B")
            results.append("B done")
            expectation.fulfill()
        }

        await fulfillment(of: [expectation], timeout: 2.0)

        XCTAssertEqual(results, ["A", "A done", "B", "B done"])
    }

    func testQueueAllowsConcurrentEnqueuesButSerialExecution() async {
        let queue = CarPlayPresentationQueue()
        var results: [String] = []
        let expectation = XCTestExpectation(description: "All tasks executed serially")

        await withTaskGroup(of: Void.self) { group in
            for i in 1...5 {
                group.addTask {
                    await queue.enqueue {
                        results.append("Task \(i)")
                        if i == 5 { expectation.fulfill() }
                    }
                }
            }
        }

        await fulfillment(of: [expectation], timeout: 1.0)
        XCTAssertEqual(results, ["Task 1", "Task 2", "Task 3", "Task 4", "Task 5"])
    }
}






final class CarPlayPresentationQueue: @unchecked Sendable {
    static let shared = CarPlayPresentationQueue()

    private let queue = DispatchQueue(label: "carplay.presentation.queue", qos: .userInitiated)
    private var operations: [() async -> Void] = []
    private var isRunning = false

    func enqueue(_ operation: @escaping @Sendable () async -> Void) {
        queue.async {
            self.operations.append(operation)
            self.runNextIfNeeded()
        }
    }

    private func runNextIfNeeded() {
        guard !isRunning, !operations.isEmpty else { return }
        isRunning = true
        let next = operations.removeFirst()
        Task {
            await next()
            queue.async {
                self.isRunning = false
                self.runNextIfNeeded()
            }
        }
    }
}
