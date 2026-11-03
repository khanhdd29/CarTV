//
//  NavigationController.swift
//  SwiftBase
//
//  Created by VanTuan on 18/6/26.
//

import SwiftUI
import Combine

@MainActor
final class NavigationController: ObservableObject {
    @Published var navigationPath = [DestinationWrapper]()

    @Published var navigationPresent: DestinationWrapper?

    private let onDismissPresentedNavigationController: (NavigationController) -> Void

    init(onDismissPresentedNavigationController: @escaping (NavigationController) -> Void) {
        self.onDismissPresentedNavigationController = onDismissPresentedNavigationController
    }

    func isPresenting(with type: NavigationType) -> Binding<Bool> {
        Binding<Bool>(get: { [weak self] in
            guard let self = self, let currentType = self.navigationPresent?.navigationType else { return false }

            return self.compareTypeOnly(currentType, type)
        }, set: { [weak self] newValue in
            guard let self = self, newValue == false else { return }

            self.navigationPresent = nil
            self.onDismissPresentedNavigationController(self)
        })
    }

    private func compareTypeOnly(_ lhs: NavigationType, _ rhs: NavigationType) -> Bool {
        switch (lhs, rhs) {
        case (.fullScreenCover, .fullScreenCover):
            return true
        case (.sheet, .sheet):
            return true
        default:
            return false
        }
    }
}
