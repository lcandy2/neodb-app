//
//  InstanceViewModel.swift
//  NeoDB
//
//  Created by 甜檸Citron(lcandy2) on 2/1/25.
//  Copyright © 2025 https://github.com/lcandy2. All Rights Reserved.
//

import Foundation
import SwiftUI
import OSLog

@MainActor
final class InstanceViewModel: ObservableObject {
    private var fetchTask: Task<Void, Never>?
    private var client: NetworkClient?
    private let versionIdentifier = "neodb"
    private let logger = Logger.views.login

    @Published var isLoading = false
    @Published var instanceInfo: MastodonInstance?
    @Published var error: Error?
    @Published var showIncompatibleAlert = false
    @Published var instanceAddress: String = ""
    
    var disableInteractiveDismiss = false

    var isCompatible: Bool {
        guard let instance = instanceInfo else { return false }
        return instance.version.localizedCaseInsensitiveContains(
            versionIdentifier)
    }

    func updateSearchText(_ text: String) {
        // Cancel previous task if exists
        fetchTask?.cancel()
        showIncompatibleAlert = false

        guard text.contains(".") else {
            instanceInfo = nil
            error = nil
            return
        }

        isLoading = true

        // Create new task for fetching instance info
        fetchTask = Task { @MainActor in
            do {
                client = NetworkClient(instance: text)
                guard let client = client else { return }

                let instance = try await client.fetch(
                    InstanceEndpoint.instance(), type: MastodonInstance.self)

                if !Task.isCancelled {
                    instanceInfo = instance
                    error = nil
                }
            } catch {
                if !Task.isCancelled {
                    self.error = error
                    instanceInfo = nil
                }
            }

            isLoading = false
        }
    }
    
    func showIncompatibleInstanceAlert() {
        showIncompatibleAlert = true
    }
    
    func dismissIncompatibleAlert() {
        showIncompatibleAlert = false
    }
}
