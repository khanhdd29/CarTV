//
//  IntroPage.swift
//  SwiftBase
//
//  Created by VanTuan on 18/6/26.
//

import SwiftUI

struct IntroPage: Identifiable {
    let id = UUID()
    /// Full-bleed background image (asset catalog name).
    let imageName: String
    let title: String
    let message: String

    /// The three slides shown in order. Localized strings are reused as-is.
    static let all: [IntroPage] = [
        IntroPage(imageName: "onboard_1", title: "intro_title_1", message: "intro_message_1"),
        IntroPage(imageName: "onboard_2", title: "intro_title_2", message: "intro_message_2"),
        IntroPage(imageName: "onboard_3", title: "intro_title_3", message: "intro_message_3")
    ]
}
