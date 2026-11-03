//
//  HealthDot.swift
//  SwiftBase
//
//  A tiny status dot for a stream link: green = online, red = offline. Hidden
//  while unknown (not yet probed) so lists stay clean until a health check runs.
//

import SwiftUI

struct HealthDot: View {
    let status: StreamStatus

    var body: some View {
        if status != .unknown {
            Circle()
                .fill(status == .online ? AppColors.success : AppColors.favorite)
                .frame(width: 9, height: 9)
                .overlay(Circle().stroke(Color.black.opacity(0.55), lineWidth: 1.5))
                .shadow(color: (status == .online ? AppColors.success : AppColors.favorite).opacity(0.6),
                        radius: 3)
        }
    }
}
