//
//  DeveloperView.swift
//  Live Capture
//
//  Created by 甜檸Citron(lcandy2) on 2/1/25.
//  Copyright © 2025 https://github.com/lcandy2. All Rights Reserved.
//

import SwiftUI
import KeychainSwift
import OSLog

@MainActor
class DeveloperViewModel: ObservableObject {
    private let logger = Logger.views.developer
    
    @Published var accounts: [AppAccount] = []
    @Published var clients: [AppClient] = []
    @Published var error: Error?
    @Published var showError = false
    
    func loadData() {
        // Load accounts
        do {
            accounts = try AppAccount.retrieveAll()
        } catch {
            self.error = error
            self.showError = true
            logger.error("Failed to load accounts: \(error.localizedDescription)")
        }
        
        // Load clients
        let keychain = KeychainSwift(keyPrefix: KeychainPrefixes.client)
        let clientKeys = keychain.allKeys.map { $0.replacingOccurrences(of: KeychainPrefixes.client, with: "") }
        clients = clientKeys.compactMap { key in
            try? AppClient.retrieve(for: key)
        }
    }
    
    func deleteAccount(_ account: AppAccount) {
        account.delete()
        loadData()
    }
    
    func deleteAllAccounts() {
        AppAccount.deleteAll()
        loadData()
    }
    
    func deleteClient(_ client: AppClient) {
        client.delete()
        loadData()
    }
    
    func deleteAllClients() {
        clients.forEach { $0.delete() }
        loadData()
    }
}

struct DeveloperView: View {
    @StateObject private var viewModel = DeveloperViewModel()
    @State private var showDeleteAllAccountsAlert = false
    @State private var showDeleteAllClientsAlert = false
    
    var body: some View {
        List {
            // Accounts Section
            Section {
                ForEach(viewModel.accounts) { account in
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Instance: \(account.instance)")
                            .font(.headline)
                        if let token = account.oauthToken {
                            Text("Token: \(token.accessToken)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text("Created: \(token.createdAt.formatted())")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                        Text("ID: \(account.id)")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    .swipeActions(edge: .trailing) {
                        Button(role: .destructive) {
                            viewModel.deleteAccount(account)
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                }
                
                if !viewModel.accounts.isEmpty {
                    Button(role: .destructive) {
                        showDeleteAllAccountsAlert = true
                    } label: {
                        Label("Delete All Accounts", systemImage: "trash")
                    }
                }
            } header: {
                Text("Accounts (\(viewModel.accounts.count))")
            }
            
            // Clients Section
            Section {
                ForEach(viewModel.clients) { client in
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Instance: \(client.instance)")
                            .font(.headline)
                        Text("Client ID: \(client.clientId)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text("Client Secret: \(client.clientSecret)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        if let vapidKey = client.vapidKey {
                            Text("Vapid Key: \(vapidKey)")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .swipeActions(edge: .trailing) {
                        Button(role: .destructive) {
                            viewModel.deleteClient(client)
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                }
                
                if !viewModel.clients.isEmpty {
                    Button(role: .destructive) {
                        showDeleteAllClientsAlert = true
                    } label: {
                        Label("Delete All Clients", systemImage: "trash")
                    }
                }
            } header: {
                Text("Clients (\(viewModel.clients.count))")
            }
        }
        .navigationTitle("Developer")
        .task {
            viewModel.loadData()
        }
        .refreshable {
            viewModel.loadData()
        }
        .alert("Error", isPresented: $viewModel.showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.error?.localizedDescription ?? "Unknown error")
        }
        .confirmationDialog(
            "Delete All Accounts",
            isPresented: $showDeleteAllAccountsAlert,
            titleVisibility: .visible
        ) {
            Button("Delete All", role: .destructive) {
                viewModel.deleteAllAccounts()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This action cannot be undone.")
        }
        .confirmationDialog(
            "Delete All Clients",
            isPresented: $showDeleteAllClientsAlert,
            titleVisibility: .visible
        ) {
            Button("Delete All", role: .destructive) {
                viewModel.deleteAllClients()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This action cannot be undone.")
        }
    }
}

