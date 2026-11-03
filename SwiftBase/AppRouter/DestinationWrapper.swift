//
//  DestinationWrapper.swift
//  SwiftBase
//
//  Created by VanTuan on 18/6/26.
//

import Foundation

struct DestinationWrapper: Identifiable, Hashable {
    let id: String
    let destination: Destination
    let navigationType: NavigationType?
    var onCompletePush: (() -> Void)?
    var onDismissPush: (() -> Void)?
    var onCompletePop: (() -> Void)?
    var onCompletePopToRoot: (() -> Void)?

    init(id: String = UUID().uuidString,
         destination: Destination,
         navigationType: NavigationType?,
         onCompletePush: (() -> Void)? = nil,
         onDismissPush: (() -> Void)? = nil,
         onCompletePop: (() -> Void)? = nil,
         onCompletePopToRoot: (() -> Void)? = nil) {
        self.id = id
        self.destination = destination
        self.navigationType = navigationType
        self.onCompletePush = onCompletePush
        self.onDismissPush = onDismissPush
        self.onCompletePop = onCompletePop
        self.onCompletePopToRoot = onCompletePopToRoot
    }

    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
