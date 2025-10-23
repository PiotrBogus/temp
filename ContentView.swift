import CarPlay
import Foundation

final class CarPlayPresentationQueue {
    static let shared = CarPlayPresentationQueue()

    private let queue = DispatchQueue(label: "carplay.presentation.queue", qos: .userInitiated)
    private var operations: [() async -> Void] = []
    private var isRunning = false

    func enqueue(_ operation: @escaping () async -> Void) {
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



extension CPInterfaceController {
    func enqueueDismissAndPresent(
        _ template: CPTemplate,
        animated: Bool = true
    ) {
        CarPlayPresentationQueue.shared.enqueue { [weak self] in
            guard let self else { return }
            await self._dismissAndPresent(template, animated: animated)
        }
    }

    func enqueueDismissAndPush(
        _ template: CPTemplate,
        animated: Bool = true
    ) {
        CarPlayPresentationQueue.shared.enqueue { [weak self] in
            guard let self else { return }
            await self._dismissAndPush(template, animated: animated)
        }
    }

    func enqueueDismissAndSetAsRoot(
        _ template: CPTemplate,
        animated: Bool = true
    ) {
        CarPlayPresentationQueue.shared.enqueue { [weak self] in
            guard let self else { return }
            await self._dismissAndSetAsRoot(template, animated: animated)
        }
    }

    private func _dismissAndPresent(
        _ template: CPTemplate,
        animated: Bool
    ) async {
        await withCheckedContinuation { continuation in
            if presentedTemplate != nil {
                dismissTemplate(animated: false) { [weak self] _, _ in
                    DispatchQueue.main.async {
                        self?.presentTemplate(template, animated: animated) { _, _ in
                            continuation.resume()
                        }
                    }
                }
            } else {
                presentTemplate(template, animated: animated) { _, _ in
                    continuation.resume()
                }
            }
        }
    }

    private func _dismissAndPush(
        _ template: CPTemplate,
        animated: Bool
    ) async {
        await withCheckedContinuation { continuation in
            if presentedTemplate != nil {
                dismissTemplate(animated: false) { [weak self] _, _ in
                    DispatchQueue.main.async {
                        self?.pushTemplate(template, animated: animated) { _, _ in
                            continuation.resume()
                        }
                    }
                }
            } else {
                pushTemplate(template, animated: animated) { _, _ in
                    continuation.resume()
                }
            }
        }
    }

    private func _dismissAndSetAsRoot(
        _ template: CPTemplate,
        animated: Bool
    ) async {
        await withCheckedContinuation { continuation in
            if presentedTemplate != nil {
                dismissTemplate(animated: false) { [weak self] _, _ in
                    DispatchQueue.main.async {
                        self?.setRootTemplate(template, animated: animated) { _, _ in
                            continuation.resume()
                        }
                    }
                }
            } else {
                setRootTemplate(template, animated: animated) { _, _ in
                    continuation.resume()
                }
            }
        }
    }
}
