//
//  RecommendButton.swift
//  Deshi_Store_2207034
//
//  Created by macos on 26/11/26.
//

import SwiftUI

/// Yellow-outlined "like" button. Filled yellow once the current user has recommended the product.
struct RecommendButton: View {
    let product: Product
    @EnvironmentObject private var recommendations: RecommendationsViewModel

    var body: some View {
        let isOn = recommendations.isRecommended(product.id)
        let busy = recommendations.isPending(product.id)

        Button {
            Task { await recommendations.toggle(product) }
        } label: {
            HStack(spacing: 8) {
                if busy {
                    ProgressView().tint(isOn ? Color.black : Theme.yellow)
                } else {
                    Image(systemName: isOn ? "hand.thumbsup.fill" : "hand.thumbsup")
                        .foregroundStyle(isOn ? Color.black : Theme.yellow)
                }
                Text(isOn ? "Recommended" : "Recommend")
                Text("· \(product.recommendCount)")
            }
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(isOn ? Color.black : Color.primary)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(Capsule().fill(isOn ? Theme.yellow : Color.clear))
            .overlay(Capsule().stroke(Theme.yellow, lineWidth: 2))
        }
        .buttonStyle(.plain)
        .disabled(busy)
        .accessibilityLabel(isOn ? "Remove your recommendation" : "Recommend this product")
        .accessibilityValue("\(product.recommendCount) recommendations")
    }
}
