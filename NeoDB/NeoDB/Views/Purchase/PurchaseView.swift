//
//  PurchaseView.swift
//  NeoDB
//
//  Created by citron on 1/26/25.
//

import ButtonKit
import RevenueCat
import SwiftUI

enum PurchaseViewType {
    case view
    case sheet
}

struct PurchaseView: View {
    @EnvironmentObject private var storeManager: StoreManager
    @StateObject private var viewModel = PurchaseViewModel()
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL

    @State private var showRedeemSheet = false
    
    let type: PurchaseViewType
    let scrollToFeature: StoreConfig.Features?
    @Namespace private var featureSpace

    init(type: PurchaseViewType = .view, scrollToFeature: StoreConfig.Features? = nil) {
        self.type = type
        self.scrollToFeature = scrollToFeature
    }

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(spacing: 24) {
                    // 头部 Logo 与描述
                    VStack(spacing: 8) {
                        VStack(spacing: 0) {
                            Image("piecelet-symbol")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 120, height: 120)
                            Text(
                                String(localized: "store_title", defaultValue: "Piecelet+", table: "Settings")
                            )
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .padding(.leading, 8)
                        }
                        Text(
                            String(
                                localized: "store_description", defaultValue: "Unlock a richer experience for your NeoDB journey", table: "Settings")
                        )
                        .font(.headline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    }

                    // Feature List
                    VStack(spacing: 16) {
                        ForEach(StoreConfig.Features.allCases, id: \.self) { featureCase in
                            featureRow(feature: featureCase.feature, highlight: scrollToFeature == featureCase)
                                .id(featureCase)
                        }
                    }
                    .padding(.horizontal)

                    VStack(spacing: 16) {
                        // 在此插入兑换按钮，放到条款与隐私按钮之前
                        Button {
                            Purchases.shared.presentCodeRedemptionSheet()
                        } label: {
                            Text("store_button_redeem", tableName: "Settings")
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(.grayBackground)
                                .clipShape(
                                    RoundedRectangle(cornerRadius: 12))
                        }
                        .foregroundStyle(.primary)
                        .padding(.horizontal)
                        .font(.headline)

                        HStack(spacing: 16) {
                            Button(
                                String(localized: "policy_terms_of_use", table: "Settings")
                            ) {
                                openURL(StoreConfig.URLs.termsOfService)
                            }
                            Button(
                                String(
                                    localized: "policy_privacy_policy", table: "Settings")
                            ) {
                                openURL(StoreConfig.URLs.privacyPolicy)
                            }
                        }
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    }
                }
                .padding(.top, type == .view ? 0 : 32)
                .padding(.bottom, 32)
            }
            .task {
                if let feature = scrollToFeature {
                    // Add a small delay to ensure the view is loaded
                    try? await Task.sleep(for: .milliseconds(300))
                    withAnimation {
                        proxy.scrollTo(feature, anchor: .center)
                    }
                }
            }
            .onDisappear {
                TelemetryService.shared.trackPurchaseClose()
            }
        }
        .navigationTitle(String(localized: "store_title", defaultValue: "Piecelet+", table: "Settings"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text(String(localized: "store_title", defaultValue: "Piecelet+", table: "Settings"))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.leading, 2)
                    .hidden()
            }
            ToolbarItem(placement: .topBarTrailing) {
                AsyncButton(
                    String(localized: "store_button_restore", defaultValue: "Restore", table: "Settings")
                ) {
                    Task {
                        await viewModel.restorePurchases()
                    }
                }
                .asyncButtonStyle(.overlay)  // 在按钮本身覆盖显示加载动画
                .throwableButtonStyle(.none)  // 不需要抛错时摇晃
                .disabledWhenLoading()  // 加载时禁用二次点击
            }
        }
        .task {
            viewModel.initializeIfNeeded(with: storeManager)
        }
        .safeAreaInset(edge: .bottom) {
            BottomPurchaseView(
                offering: viewModel.currentOffering,
                showAllPlans: $viewModel.showAllPlans,
                selectedPackage: $viewModel.selectedPackage,
                viewModel: viewModel
            )
            .background(.bar)
            .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: -4)
        }
        .toolbar(.hidden, for: .tabBar)
        .enableInjection()
    }

    #if DEBUG
        @ObserveInjection var forceRedraw
    #endif

    private func featureRow(feature: StoreConfig.Feature, highlight: Bool = false) -> some View {
        HStack(alignment: .top, spacing: 16) {
            Image(symbol: feature.icon)
                .font(.title2)
                .frame(width: 32, height: 32)
                .foregroundStyle(feature.color)

            VStack(alignment: .leading, spacing: 4) {
                HStack(alignment: .center, spacing: 8) {
                    Text(feature.title)
                        .font(.headline)
                        .foregroundStyle(
                            feature.isComingSoon
                                ? Color.primary.opacity(0.8) : .primary)

                    if feature.isComingSoon {
                        Text("store_badge_soon", tableName: "Settings")
                            .font(.caption2)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.secondary.opacity(0.2))
                            .clipShape(Capsule())
                    }

                    if feature.isFree {
                        Text("store_badge_free", tableName: "Settings")
                            .font(.caption2)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.secondary.opacity(0.2))
                            .clipShape(Capsule())
                    }
                }

                Text(feature.description)
                    .font(.subheadline)
                    .foregroundStyle(
                        feature.isComingSoon
                            ? Color.secondary.opacity(0.6) : .secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(.grayBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(highlight ? .orange.opacity(0.5) : .clear, lineWidth: 2)
        )
        .opacity(feature.isComingSoon ? 0.8 : 1)
    }
}

#Preview {
    PurchaseView()
        .environmentObject(StoreManager())
}
