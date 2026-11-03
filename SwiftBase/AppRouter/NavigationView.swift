//
//  NavigationView.swift
//  SwiftBase
//
//  Created by VanTuan on 18/6/26.
//

import SwiftUI

struct NavigationView: View {
    @EnvironmentObject private var navigation: Navigation

    let destinationWrapper: DestinationWrapper
    @StateObject var navigationController: NavigationController

    var body: some View {
        NavigationStack(path: $navigationController.navigationPath) {
            navigation.build(destinationWrapper)
                .navigationDestination(for: DestinationWrapper.self) { destinationWrapper in
                    navigation.build(destinationWrapper)
                        // Hide the bottom tab bar on any pushed (inner) screen;
                        // the tab root keeps it.
                        .toolbar(.hidden, for: .tabBar)
                }
                .sheet(isPresented: navigationController.isPresenting(with: .sheet())) {
                    if let destinationWrapper = navigationController.navigationPresent {
                        if let detents = destinationWrapper.navigationType?.detents {
                            NavigationView(destinationWrapper: destinationWrapper, navigationController: navigation.topNavigationController)
                                .presentationDetents(detents)
                        } else {
                            NavigationView(destinationWrapper: destinationWrapper, navigationController: navigation.topNavigationController)
                        }
                    }
                }
                .fullScreenCover(isPresented: navigationController.isPresenting(with: .fullScreenCover)) {
                    if let destinationWrapper = navigationController.navigationPresent {
                        NavigationView(destinationWrapper: destinationWrapper, navigationController: navigation.topNavigationController)
                    }
                }
        }
    }
}
