import Foundation
import SwiftData

/// Orchestrates background services: processes pending lookups and caches covers when online
@Observable @MainActor
final class BackgroundTaskCoordinator {
    private(set) var isProcessingLookups = false
    private(set) var isCachingCovers = false
    private(set) var pendingLookupCount: Int = 0

    private let modelContainer: ModelContainer
    private let networkMonitor: NetworkMonitor
    private let lookupService: OfflineLookupService
    private let coverCacheService: CoverCacheService

    private var observationTask: Task<Void, Never>?
    private var periodicTask: Task<Void, Never>?

    init(modelContainer: ModelContainer, networkMonitor: NetworkMonitor = NetworkMonitor.shared) {
        self.modelContainer = modelContainer
        self.networkMonitor = networkMonitor
        self.lookupService = OfflineLookupService(modelContainer: modelContainer)
        self.coverCacheService = CoverCacheService(modelContainer: modelContainer)
    }

    func start() {
        // Immediate run if online
        if networkMonitor.isConnected {
            Task { await processAll() }
        }

        // Watch for connectivity changes
        observationTask = Task { [weak self] in
            var wasConnected = self?.networkMonitor.isConnected ?? false
            while !Task.isCancelled {
                guard let self else { return }
                let currentlyConnected = await withCheckedContinuation { continuation in
                    withObservationTracking {
                        _ = self.networkMonitor.isConnected
                    } onChange: {
                        Task { @MainActor in
                            continuation.resume(returning: self.networkMonitor.isConnected)
                        }
                    }
                }

                if !wasConnected && currentlyConnected {
                    await self.processAll()
                }
                wasConnected = currentlyConnected
            }
        }

        // Periodic safety net: every 60 seconds when online
        periodicTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(60))
                guard let self, !Task.isCancelled else { return }
                if self.networkMonitor.isConnected {
                    await self.processAll()
                }
            }
        }
    }

    func stop() {
        observationTask?.cancel()
        observationTask = nil
        periodicTask?.cancel()
        periodicTask = nil
    }

    // MARK: - Private

    private func processAll() async {
        await processLookups()
        await cacheCovers()
        await updatePendingCount()
        await cleanupCompleted()
    }

    private func processLookups() async {
        guard !isProcessingLookups else { return }
        isProcessingLookups = true
        await lookupService.processPendingLookups()
        isProcessingLookups = false
    }

    private func cacheCovers() async {
        guard !isCachingCovers else { return }
        isCachingCovers = true
        await coverCacheService.cacheUncachedCovers()
        isCachingCovers = false
    }

    private func updatePendingCount() async {
        let context = ModelContext(modelContainer)
        let completed = LookupStatus.completed
        let descriptor = FetchDescriptor<PendingLookup>(
            predicate: #Predicate<PendingLookup> { $0.status != completed }
        )
        pendingLookupCount = (try? context.fetchCount(descriptor)) ?? 0
    }

    private func cleanupCompleted() async {
        let context = ModelContext(modelContainer)
        let cutoff = Calendar.current.date(byAdding: .hour, value: -24, to: Date()) ?? Date()
        let completed = LookupStatus.completed
        let descriptor = FetchDescriptor<PendingLookup>(
            predicate: #Predicate<PendingLookup> { $0.status == completed && $0.dateQueued < cutoff }
        )

        guard let old = try? context.fetch(descriptor) else { return }
        for lookup in old {
            context.delete(lookup)
        }
        try? context.save()
    }
}
