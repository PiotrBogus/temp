import CarPlay
import Foundation

actor CarPlayPresentationQueue: Sendable {
    static let shared = CarPlayPresentationQueue()

    private var operations: [() async -> Void] = []
    private var isRunning = false

    func enqueue(_ operation: @escaping @Sendable () async -> Void) {
        operations.append(operation)
        if !isRunning {
            isRunning = true
            Task { await processNext() }
        }
    }

    private func processNext() async {
        while !operations.isEmpty {
            let next = operations.removeFirst()
            await next()
        }
        isRunning = false
    }
}

extension CPInterfaceController: @unchecked @retroactive Sendable {
    func enqueueDismissAndPresent(
        template: CPTemplate,
        animated: Bool = true
    ) {
        Task {
            await CarPlayPresentationQueue.shared.enqueue { [weak self] in
                guard let self else { return }
                await self.dismissAndPresent(template: template, animated: animated)
            }
        }
    }

    func enqueueDismissAndPush(
        template: CPTemplate,
        animated: Bool = true
    ) {
        Task {
            await CarPlayPresentationQueue.shared.enqueue { [weak self] in
                guard let self else { return }
                await self.dismissAndPush(template: template, animated: animated)
            }
        }
    }

    func enqueueDismissAndSetAsRoot(
        template: CPTemplate,
        animated: Bool = true
    ) {
        Task {
            await CarPlayPresentationQueue.shared.enqueue { [weak self] in
                guard let self else { return }
                await self.dismissAndSetAsRoot(template: template, animated: animated)
            }
        }
    }

    private func dismissAndPresent(
        template: CPTemplate,
        animated: Bool = true
    ) async {
        await withCheckedContinuation { continuation in
            if presentedTemplate != nil {
                dismissTemplate(animated: false) { [weak self] _, _ in
                    self?.presentTemplate(template, animated: animated) { _, _ in
                        continuation.resume()
                    }
                }
            } else {
                presentTemplate(template, animated: animated) { _, _ in
                    continuation.resume()
                }
            }
        }
    }

    private func dismissAndPush(
        template: CPTemplate,
        animated: Bool = true
    ) async {
        await withCheckedContinuation { continuation in
            if presentedTemplate != nil {
                dismissTemplate(animated: false) { [weak self] _, _ in
                    self?.pushTemplate(template, animated: animated) { _, _ in
                        continuation.resume()
                    }
                }
            } else {
                pushTemplate(template, animated: animated) { _, _ in
                    continuation.resume()
                }
            }
        }
    }

    private func dismissAndSetAsRoot(
        template: CPTemplate,
        animated: Bool = true
    ) async {
        await withCheckedContinuation { continuation in
            if presentedTemplate != nil {
                dismissTemplate(animated: false) { [weak self] _, _ in
                    self?.setRootTemplate(template, animated: animated) { _, _ in
                        continuation.resume()
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
