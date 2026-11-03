//
//  IntroPage.swift
//  SwiftBase
//
//  Created by VanTuan on 18/6/26.
//

import SwiftUI

struct IntroPage: Identifiable {
    let id = UUID()
    let systemImage: String
    let title: String
    let message: String
    let tint: Color

    /// The three slides shown in order.
    static let all: [IntroPage] = [
        IntroPage(
            systemImage: "square.grid.2x2.fill",
            title: "intro_title_1",
            message: "intro_message_1",
            tint: .blue
        ),
        IntroPage(
            systemImage: "bolt.fill",
            title: "intro_title_2",
            message: "intro_message_2",
            tint: .orange
        ),
        IntroPage(
            systemImage: "checkmark.seal.fill",
            title: "intro_title_3",
            message: "intro_message_3",
            tint: .green
        )
    ]
}
