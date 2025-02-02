//
//  SearchURLView.swift
//  NeoDB
//
//  Created by 甜檸Citron(lcandy2) on 2/2/25.
//  Copyright © 2025 https://github.com/lcandy2. All Rights Reserved.
//

import OSLog
import SwiftUI

@MainActor
class SearchURLViewModel: ObservableObject {
    private let logger = Logger.views.discover.searchURL

    @Published var urlInput = ""
    @Published var isShowingURLInput = false
    @Published var isLoadingURL = false
    @Published var urlError: Error?
    @Published private(set) var item: ItemSchema?

    var accountsManager: AppAccountsManager?

    func fetchFromURL(_ urlString: String) async {
        guard let url = URL(string: urlString) else {
            urlError = NSError(
                domain: "", code: -1,
                userInfo: [
                    NSLocalizedDescriptionKey: String(
                        localized: "discover_search_invalid_url",
                        table: "Discover")
                ])
            return
        }

        isLoadingURL = true
        urlError = nil

        do {
            guard let accountsManager = accountsManager else { return }
            let endpoint = CatalogEndpoint.fetch(url: url)
            let result = try await accountsManager.currentClient.fetch(
                endpoint, type: ItemSchema.self)

            // Reset states
            isLoadingURL = false
            isShowingURLInput = false
            urlInput = ""

            // Set the result
            item = result
        } catch {
            urlError = error
            isLoadingURL = false
        }
    }
}

struct SearchURLView: View {
    @StateObject private var viewModel = SearchURLViewModel()
    @EnvironmentObject private var accountsManager: AppAccountsManager
    @EnvironmentObject private var router: Router

    var body: some View {
        Section {
            GroupBox {
                VStack(alignment: .center, spacing: 16) {
                    Label("Search from everywhere", systemImage: "link")
                        .labelStyle(.titleOnly)
                    
                    HStack(spacing: 4) {
                        Image("discover.searchURL.douban")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 40)
                        Image("discover.searchURL.books")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 40)
                        Image("discover.searchURL.movies")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 40)
                        Image("discover.searchURL.music")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 40)
                        Image("discover.searchURL.games")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 40)
                    }
                    
                    HStack(spacing: 8) {
                        ZStack(alignment: .trailing) {
                            TextField("Enter URL", text: $viewModel.urlInput)
                                .autocorrectionDisabled()
                                .textInputAutocapitalization(.never)
                                .padding()
                                .background(.white)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                            
                            if viewModel.urlInput.isEmpty {
                                PasteButton(payloadType: String.self) { strings in
                                    guard let urlString = strings.first else { return }
                                    Task { @MainActor in
                                        viewModel.urlInput = urlString
                                        await viewModel.fetchFromURL(urlString)
                                    }
                                }
                                .buttonBorderShape(.capsule)
                                .labelStyle(.iconOnly)
                                .padding(.trailing)
                            } else {
                                Button {
                                    Task {
                                        await viewModel.fetchFromURL(viewModel.urlInput)
                                    }
                                } label: {
                                    Label("Get Item by URL", systemSymbol: .arrowRightCircleFill)
                                        .labelStyle(.iconOnly)
                                        .font(.title)
                                }
                                .buttonBorderShape(.capsule)
                                .padding(.trailing)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity)
                    
                    if viewModel.isLoadingURL {
                        ProgressView()
                    }
                    
                    if let error = viewModel.urlError {
                        Text(error.localizedDescription)
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                }
                .padding(.vertical, 8)
            }
            .frame(maxWidth: .infinity)
            .cornerRadius(12)
            .backgroundStyle(Color.grayBackground)
            .listRowSeparator(.hidden)
        }
        .task {
            viewModel.accountsManager = accountsManager
        }
        .onChange(of: viewModel.item) { item in
            if let item = item {
                HapticFeedback.selection()
                router.navigate(to: .itemDetailWithItem(item: item))
            }
        }
        .enableInjection()
    }

    #if DEBUG
        @ObserveInjection var forceRedraw
    #endif
}

#Preview {
    List {
        SearchURLView()
            .environmentObject(Router())
            .environmentObject(AppAccountsManager())
    }
}
