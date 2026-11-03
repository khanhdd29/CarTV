//
//  HealthRefreshScheduler.swift
//  SwiftBase
//
//  Periodic background health check (spec §Driver 3). Uses BGTaskScheduler so
//  the OS wakes the app occasionally to re-probe links, keeping status dots
//  fresh without the user opening the app. Local-only.
//

import BackgroundTasks
import Factory

enum HealthRefreshScheduler {
    static let taskID = "com.klyra.iptv.player.health"

    /// Register the handler — must run before the app finishes launching.
    static func register() {
        BGTaskScheduler.shared.register(forTaskWithIdentifier: taskID, using: nil) { task in
            guard let task = task as? BGProcessingTask else { task.setTaskCompleted(success: false); return }
            handle(task)
        }
    }

    /// Ask the OS to run the task again later (best-effort; the system decides when).
    static func schedule() {
        let request = BGProcessingTaskRequest(identifier: taskID)
        request.requiresNetworkConnectivity = true
        request.requiresExternalPower = false
        request.earliestBeginDate = Date(timeIntervalSinceNow: 2 * 3600)
        try? BGTaskScheduler.shared.submit(request)
    }

    private static func handle(_ task: BGProcessingTask) {
        schedule()   // chain the next run
        let work = Task {
            let playlists = Container.shared.playlistRepository()
            let health = Container.shared.healthRepository()
            let channels = (try? await playlists.channels(group: nil, limit: 80, offset: 0)) ?? []
            _ = await health.probe(channels, onProgress: nil)
            task.setTaskCompleted(success: true)
        }
        task.expirationHandler = { work.cancel() }
    }
}
