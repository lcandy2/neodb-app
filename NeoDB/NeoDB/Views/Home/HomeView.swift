//
//  HomeView.swift
//  NeoDB
//
//  Created by citron(https://github.com/lcandy2) on 1/7/25.
//

import OSLog
import SwiftUI

@MainActor
class HomeViewModel: ObservableObject {
    var accountsManager: AppAccountsManager? {
        didSet {
            if oldValue !== accountsManager {
                statuses = []
            }
        }
    }

    private let cacheService: CacheService
    private let logger = Logger.home

    @Published var statuses: [MastodonStatus] = []
    @Published var isLoading = false
    @Published var error: String?
    @Published var detailedError: String?

    // Pagination
    private var maxId: String?
    private var hasMore = true

    init() {
        self.cacheService = CacheService()
    }

    func loadTimeline(refresh: Bool = false) async {
        guard let accountsManager = accountsManager else {
            logger.debug("No accountsManager available")
            return
        }

        logger.debug(
            "Loading timeline for instance: \(accountsManager.currentAccount.instance)"
        )

        if refresh {
            logger.debug("Refreshing timeline, resetting pagination")
            maxId = nil
            hasMore = true
            statuses = []
        }

        guard !isLoading, hasMore else {
            logger.debug(
                "Skip loading: isLoading=\(isLoading), hasMore=\(hasMore)")
            return
        }

        isLoading = true
        error = nil
        detailedError = nil

        let cacheKey = "\(accountsManager.currentAccount.instance)_timeline"
        logger.debug("Using cache key: \(cacheKey)")

        do {
            if !refresh,
                let cached = try? await cacheService.retrieve(
                    forKey: cacheKey, type: [MastodonStatus].self)
            {
                statuses = cached
                logger.debug("Loaded \(cached.count) statuses from cache")
            }

            guard accountsManager.isAuthenticated else {
                logger.error("User not authenticated")
                throw NetworkError.unauthorized
            }

            let endpoint = TimelinesEndpoint.pub(
                sinceId: nil, maxId: maxId, minId: nil, local: true)
            logger.debug(
                "Fetching timeline with endpoint: \(String(describing: endpoint)), maxId: \(maxId ?? "nil")"
            )

            let newStatuses = try await accountsManager.currentClient.fetch(
                endpoint, type: [MastodonStatus].self)

            if refresh {
                statuses = newStatuses
            } else {
                statuses.append(contentsOf: newStatuses)
            }

            try? await cacheService.cache(
                statuses, forKey: cacheKey, type: [MastodonStatus].self)

            maxId = newStatuses.last?.id
            hasMore = !newStatuses.isEmpty
            logger.debug("Successfully loaded \(newStatuses.count) statuses")

        } catch {
            logger.error(
                "Failed to load timeline: \(error.localizedDescription)")
            self.error = "Failed to load timeline"
            if let networkError = error as? NetworkError {
                detailedError = networkError.localizedDescription
            }
        }

        isLoading = false
    }
}

struct HomeView: View {
    @StateObject private var viewModel = HomeViewModel()
    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject private var router: Router
    @EnvironmentObject private var accountsManager: AppAccountsManager

    var body: some View {
        Group {
            if let error = viewModel.error {
                EmptyStateView(
                    "Couldn't Load Timeline",
                    systemImage: "exclamationmark.triangle",
                    description: Text(viewModel.detailedError ?? error)
                )
            } else if viewModel.statuses.isEmpty && !viewModel.isLoading {
                EmptyStateView(
                    "No Posts Yet",
                    systemImage: "text.bubble",
                    description: Text(
                        "Follow some users to see their posts here")
                )
            } else {
                timelineContent
            }
        }
        .navigationTitle("Home")
        .task {
            viewModel.accountsManager = accountsManager
            await viewModel.loadTimeline()
        }
    }

    private var timelineContent: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(viewModel.statuses) { status in
                    Button {
                        router.navigate(
                            to: .statusDetailWithStatus(status: status))
                    } label: {
                        StatusView(status: status)
                            .onAppear {
                                if status.id == viewModel.statuses.last?.id {
                                    Task {
                                        await viewModel.loadTimeline()
                                    }
                                }
                            }
                    }
                    .buttonStyle(.plain)
                }

                if viewModel.isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                        .padding()
                }
            }
        }
        .refreshable {
            await viewModel.loadTimeline(refresh: true)
        }
    }
}
