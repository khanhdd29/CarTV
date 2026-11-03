//
//  BasicHeaderView.swift
//  SwiftBase
//
//  Created by VanTuan on 18/6/26.
//

import SwiftUI

struct BasicHeaderView<Leading: View, Trailing: View>: View {

    /// Shown centered. Pass an already-localized string (e.g. `"home".localized`).
    let title: String

    /// When `true`, the leading slot shows a default back chevron that calls
    /// `backAction`. When `false`, it shows `leadingView` instead.
    var showBack: Bool

    /// Called when the default back button is tapped.
    var backAction: (() -> Void)?

    /// Called when `trailingView` is tapped. If `nil`, the trailing view is shown
    /// as a plain (non-tappable) accessory.
    var trailingAction: (() -> Void)?

    @ViewBuilder private let leadingView: () -> Leading
    @ViewBuilder private let trailingView: () -> Trailing

    init(
        _ title: String,
        showBack: Bool = false,
        backAction: (() -> Void)? = nil,
        trailingAction: (() -> Void)? = nil,
        @ViewBuilder leadingView: @escaping () -> Leading = { EmptyView() },
        @ViewBuilder trailingView: @escaping () -> Trailing = { EmptyView() }
    ) {
        self.title = title
        self.showBack = showBack
        self.backAction = backAction
        self.trailingAction = trailingAction
        self.leadingView = leadingView
        self.trailingView = trailingView
    }

    var body: some View {
        ZStack {
            Text(title)
                .font(.headline)
                .lineLimit(1)
                .padding(.horizontal, 56) // keep the title clear of the side slots

            HStack(spacing: 0) {
                leading
                Spacer(minLength: 0)
                trailing
            }
        }
        .frame(height: 44)
        .frame(maxWidth: .infinity)
        .padding(.horizontal)
        .contentShape(Rectangle())
    }

    // MARK: - Slots

    @ViewBuilder
    private var leading: some View {
        if showBack {
            Button {
                backAction?()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(.primary)
                    .frame(width: 32, height: 32, alignment: .leading)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        } else {
            leadingView()
        }
    }

    @ViewBuilder
    private var trailing: some View {
        if let trailingAction {
            Button {
                trailingAction()
            } label: {
                trailingView()
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        } else {
            trailingView()
        }
    }
}

#if DEBUG
#Preview {
    VStack(spacing: 24) {
        BasicHeaderView("Home", showBack: true, backAction: {})

        BasicHeaderView(
            "Settings",
            trailingAction: {},
            trailingView: { Image(systemName: "square.and.pencil") }
        )

        BasicHeaderView(
            "Favorites",
            leadingView: { Image(systemName: "line.3.horizontal") },
            trailingView: { Image(systemName: "plus") }
        )
    }
    .padding(.vertical)
}
#endif
