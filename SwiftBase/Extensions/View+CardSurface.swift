//
//  View+CardSurface.swift
//  SwiftBase
//
//  Created by VanTuan on 18/6/26.
//

import SwiftUI

extension View {
    /// Pads the content and places it on a rounded secondary-background card.
    func cardSurface(cornerRadius: CGFloat = 14) -> some View {
        self
            .padding()
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(Color(.secondarySystemBackground))
            )
    }
}
