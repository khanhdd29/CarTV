//
//  Navigation.swift
//  SwiftBase
//
//  Created by VanTuan on 18/6/26.
//

import SwiftUI
import Combine

@MainActor
final class Navigation: ObservableObject {
    private var navigationControllers = [NavigationController]()

    private var removedDestinationWrapper: DestinationWrapper?

    init() {
        setupInitialNavigationController()
    }

    private func setupInitialNavigationController() {
        navigationControllers.append(
            NavigationController(onDismissPresentedNavigationController: { [weak self] navigationController in
                self?.dismissNavigationController(navigationController)
            })
        )
    }

    func push(_ destination: Destination,
              type navigationType: NavigationType = .push,
              allowDuplicate: Bool = true,
              onComplete: (() -> Void)? = nil,
              onDismiss: (() -> Void)? = nil) {

        if !allowDuplicate {
            let presentings = navigationControllers.compactMap { $0.navigationPresent }
            let pushings = navigationControllers.flatMap { $0.navigationPath }
            let exsistPresent = presentings.contains(where: { $0.destination.identifier == destination.identifier })
            let exsistPush = pushings.contains(where: { $0.destination.identifier == destination.identifier })

            if exsistPresent || exsistPush {
                return
            }
        }

        let destinationWrapper = DestinationWrapper(
            destination: destination,
            navigationType: navigationType, onCompletePush: onComplete, onDismissPush: onDismiss)

        switch navigationType {
        case .push:
            topNavigationController.navigationPath.append(destinationWrapper)
        case .fullScreenCover, .sheet:
            topNavigationController.navigationPresent = destinationWrapper
            let navigationController = NavigationController(onDismissPresentedNavigationController: { [weak self] navigationController in
                self?.dismissNavigationController(navigationController)
            })
            navigationControllers.append(navigationController)
        }
    }

    func pop(onComplete: (() -> Void)? = nil) {
        if !topNavigationController.navigationPath.isEmpty {
            removedDestinationWrapper = topNavigationController.navigationPath.last
            removedDestinationWrapper?.onCompletePop = onComplete

            topNavigationController.navigationPath.removeLast()
        } else {
            guard navigationControllers.count > 1 else { return }

            removedDestinationWrapper = nearTopNavigationController?.navigationPresent
            removedDestinationWrapper?.onCompletePop = onComplete

            navigationControllers.removeLast()
            topNavigationController.navigationPresent = nil
        }
    }

    func pop(last popCount: Int, onComplete: (() -> Void)? = nil) {
        guard popCount > 0 else { return }

        let index = flatNavigationControllers.count - popCount
        if index > 0 {
            pop(to: flatNavigationControllers[index - 1].destination, onComplete: onComplete)
        } else {
            popToRoot(.root, onComplete: onComplete)
        }
    }

    func pop(to destination: Destination, onComplete: (() -> Void)? = nil) {
        var withAnimation: Bool?
        pop(to: destination, withAnimation: &withAnimation, onComplete: onComplete)
    }

    private func pop(to destination: Destination, withAnimation: inout Bool?, onComplete: (() -> Void)? = nil) {
        if !topNavigationController.navigationPath.isEmpty {
            let destinationWrapper = topNavigationController.navigationPath.last

            if destinationWrapper?.destination != destination {
                if removedDestinationWrapper == nil {
                    removedDestinationWrapper = destinationWrapper
                    removedDestinationWrapper?.onCompletePop = onComplete
                }

                if withAnimation == nil {
                    withAnimation = true
                }

                performPop(animated: withAnimation == true || withAnimation == nil) {
                    topNavigationController.navigationPath.removeLast()
                }

                pop(to: destination, withAnimation: &withAnimation, onComplete: onComplete)
            }
        } else {
            guard navigationControllers.count > 1 else { return }

            let destinationWrapper = nearTopNavigationController?.navigationPresent

            if destinationWrapper?.destination != destination {
                if removedDestinationWrapper == nil {
                    removedDestinationWrapper = destinationWrapper
                    removedDestinationWrapper?.onCompletePop = onComplete
                }

                navigationControllers.removeLast()
                if topNavigationController.navigationPresent != nil {
                    if withAnimation == nil {
                        withAnimation = false
                    }

                    performPop(animated: withAnimation == false || withAnimation == nil) {
                        topNavigationController.navigationPresent = nil
                    }
                }

                pop(to: destination, withAnimation: &withAnimation, onComplete: onComplete)
            }
        }
    }

    func popToRoot(_ type: PopToRootType, animated: Bool = true, onComplete: (() -> Void)? = nil) {
        switch type {
        case .modal(let modalType):
            guard navigationControllers.count > 1 else { return }

            switch modalType {
            case .count(let ptrCount):
                guard ptrCount > 0 else { return }

                if !topNavigationController.navigationPath.isEmpty {
                    removedDestinationWrapper = topNavigationController.navigationPath.last
                } else {
                    removedDestinationWrapper = nearTopNavigationController?.navigationPresent
                }
                removedDestinationWrapper?.onCompletePopToRoot = onComplete

                performPop(animated: animated) {
                    popToRoot(last: min(ptrCount, navigationControllers.count - 1), popAllInRoot: false)
                }

            case .all:
                if !topNavigationController.navigationPath.isEmpty {
                    removedDestinationWrapper = topNavigationController.navigationPath.last
                } else {
                    removedDestinationWrapper = nearTopNavigationController?.navigationPresent
                }
                removedDestinationWrapper?.onCompletePopToRoot = onComplete

                performPop(animated: animated) {
                    popToRoot(last: navigationControllers.count - 1, popAllInRoot: false)
                }
            }

        case .keepModal:
            guard !topNavigationController.navigationPath.isEmpty else { return }

            removedDestinationWrapper = topNavigationController.navigationPath.last
            removedDestinationWrapper?.onCompletePopToRoot = onComplete

            performPop(animated: animated) {
                topNavigationController.navigationPath.removeAll()
            }

        case .root:
            if !topNavigationController.navigationPath.isEmpty {
                removedDestinationWrapper = topNavigationController.navigationPath.last
            } else {
                removedDestinationWrapper = nearTopNavigationController?.navigationPresent
            }
            removedDestinationWrapper?.onCompletePopToRoot = onComplete

            performPop(animated: animated) {
                popToRoot(last: max(0, navigationControllers.count - 1), popAllInRoot: true)
            }
        }
    }

    private func popToRoot(last: Int, popAllInRoot: Bool) {
        var withAnimation: Bool = true

        navigationControllers.removeLast(last)
        if topNavigationController.navigationPresent != nil {
            topNavigationController.navigationPresent = nil
            withAnimation = false
        }

        if popAllInRoot {
            performPop(animated: withAnimation) {
                topNavigationController.navigationPath.removeAll()
            }
        }
    }

    private func performPop(animated: Bool, _ body: () -> Void) {
        if animated {
            body()
        } else {
            var transaction = Transaction()
            transaction.disablesAnimations = true
            withTransaction(transaction) {
                UIView.performWithoutAnimation {
                    body()
                }
            }
        }
    }

    private func dismissNavigationController(_ navigationController: NavigationController) {
        guard let index = navigationControllers.firstIndex(where: { $0 === navigationController }) else {
            return
        }
        navigationControllers.removeLast(navigationControllers.count - 1 - index)
    }

    var rootNavigationController: NavigationController {
        guard let navigationController = navigationControllers.first else {
            fatalError("Root navigation controller not found.")
        }
        return navigationController
    }

    var topNavigationController: NavigationController {
        guard let navigationController = navigationControllers.last else {
            fatalError("Top navigation controller not found.")
        }
        return navigationController
    }

    private var nearTopNavigationController: NavigationController? {
        guard navigationControllers.count > 1 else {
            return nil
        }
        return navigationControllers[navigationControllers.count - 2]
    }

    private var flatNavigationControllers: [DestinationWrapper] {
        var flat: [DestinationWrapper] = []
        for navigationController in navigationControllers {
            flat.append(contentsOf: navigationController.navigationPath)
            if let present = navigationController.navigationPresent {
                flat.append(present)
            }
        }
        return flat
    }

    @ViewBuilder
    func build(_ destinationWrapper: DestinationWrapper) -> some View {
        screen(for: destinationWrapper)
            .toolbar(.hidden, for: .navigationBar)
            .onAppear { [weak self] in
                guard let self = self else { return }

                if let index = self.topNavigationController.navigationPath.firstIndex(where: { $0.id == destinationWrapper.id }),
                   self.topNavigationController.navigationPath[index].onCompletePush != nil {
                    self.topNavigationController.navigationPath[index].onCompletePush?()
                    self.topNavigationController.navigationPath[index].onCompletePush = nil
                }

                if let nearTopNavigationController = self.nearTopNavigationController,
                   nearTopNavigationController.navigationPresent?.onCompletePush != nil {
                    nearTopNavigationController.navigationPresent?.onCompletePush?()
                    nearTopNavigationController.navigationPresent?.onCompletePush = nil
                }
            }
            .onDisappear { [weak self] in
                guard let self = self else { return }

                if self.removedDestinationWrapper?.id == destinationWrapper.id {
                    if self.removedDestinationWrapper?.onCompletePopToRoot == nil {
                        self.removedDestinationWrapper?.onCompletePop?()
                        self.removedDestinationWrapper?.onDismissPush?()
                    } else {
                        self.removedDestinationWrapper?.onCompletePopToRoot?()
                    }
                    self.removedDestinationWrapper = nil
                }
            }
    }
}
