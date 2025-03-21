//
//  PurchaseViewModel.swift
//  Live Capture
//
//  Created by 甜檸Citron(lcandy2) on 2/1/25.
//  Copyright © 2025 https://github.com/lcandy2. All Rights Reserved.
//

import SwiftUI
import RevenueCat
import Perception
import OSLog

@MainActor
class PurchaseViewModel: ObservableObject {
    private let logger = Logger.views.purchase
    @Published private(set) var purchaseError: String?
    @Published var isLoading = false
    @Published var isTrialEligible = false
    @Published var showAllPlans = false {
        didSet {
            if oldValue != showAllPlans {
                TelemetryService.shared.trackPurchaseShowAllPlans(isShow: showAllPlans)
            }
        }
    }
    @Published var selectedPackage: Package? {
        didSet {
            if oldValue != selectedPackage {
                TelemetryService.shared.trackPurchasePackageChange(package: selectedPackage?.storeProduct.productIdentifier ?? "")
            }
        }
    }
    @Published var shouldDismiss = false

    private var storeManager: StoreManager? // 由外部注入，避免重复创建

    func initializeIfNeeded(with storeManager: StoreManager) {
        // 保证只在需要时进行初始加载
        if self.storeManager == nil {
            self.storeManager = storeManager
            Task {
                await loadOfferings()
                await checkTrialEligibility()
            }
        }
    }

    var currentOffering: Offering? {
        return storeManager?.plusOffering
    }

    // 这里重新声明或保留 calculateSavings 方法，供外部调用
    func calculateSavings(for annualPackage: Package, in offering: Offering) -> Int? {
        guard
            let monthlyPackage = offering.availablePackages.first(where: {
                $0.packageType == .monthly
            })
        else {
            return nil
        }

        let monthlyPrice = monthlyPackage.storeProduct.price as Decimal
        let annualPrice = annualPackage.storeProduct.price as Decimal
        let twelve = Decimal(12)
        let hundred = Decimal(100)
        let monthlyTotal = monthlyPrice * twelve
        var savings = (monthlyTotal - annualPrice) / monthlyTotal * hundred
        var rounded = Decimal()
        NSDecimalRound(&rounded, &savings, 0, .plain)
        return Int(truncating: rounded as NSNumber)
    }

    func loadOfferings() async {
        isLoading = true
        defer { isLoading = false }
        await storeManager?.loadOfferings()
        selectedPackage = currentOffering?.availablePackages.first(where: { $0.packageType == .annual })
    }

    func checkTrialEligibility() async {
        guard let storeManager = storeManager,
              let offering = storeManager.plusOffering,
              let package = offering.availablePackages.first(where: { $0.packageType == .annual })
        else { return }

        let eligibility = try await Purchases.shared.checkTrialOrIntroDiscountEligibility(product: package.storeProduct)
        isTrialEligible = eligibility == .eligible
    }

    func purchase(_ package: Package) async {
        TelemetryService.shared.trackPurchaseStart(package: package.storeProduct.productIdentifier)
        guard let storeManager else { return }

        do {
            let customerInfo = try await storeManager.purchase(package)
            TelemetryService.shared.trackPurchaseComplete(package: package.storeProduct.productIdentifier)
            // 如果已经解锁，则可以关闭当前购买页
            if !customerInfo.entitlements.active.isEmpty {
                shouldDismiss = true
            }
        } catch {
            // 包括用户手动取消，也会进入 catch
            TelemetryService.shared.trackPurchaseError(package: package.storeProduct.productIdentifier, error: error.localizedDescription)
            purchaseError = error.localizedDescription
        }
    }

    func restorePurchases() async {
        TelemetryService.shared.trackPurchaseRestore()
        isLoading = true
        defer { isLoading = false }
        guard let storeManager else { return }
        do {
            let customerInfo = try await storeManager.restorePurchases()
            if !customerInfo.entitlements.active.isEmpty {
                shouldDismiss = true
            }
        } catch {
            purchaseError = error.localizedDescription
        }
    }
}
