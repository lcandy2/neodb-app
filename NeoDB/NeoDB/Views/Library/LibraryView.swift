//
//  LibraryView.swift
//  NeoDB
//
//  Created by citron(https://github.com/lcandy2) on 1/7/25.
//

import Kingfisher
import OSLog
import SwiftUI

struct LibraryView: View {
    // MARK: - Properties
    @EnvironmentObject private var router: Router
    @EnvironmentObject private var accountsManager: AppAccountsManager
    @StateObject private var viewModel = LibraryViewModel()

    // MARK: - Body
    var body: some View {
        VStack {
            // Without this, the tab bar will be transparent without any blur
            Text(verbatim: " ").frame(width: 0.01, height: 0.01)
            GeometryReader { geometry in
                TabView(selection: $viewModel.selectedShelfType) {
                    ForEach(ShelfType.allCases, id: \.self) { type in
                        Group {
                                List {
                                    shelfContentView(
                                        for: type, geometry: geometry)
                                }
                        }
                        .listStyle(.plain)
                        .refreshable {
                            await viewModel.loadShelfItems(
                                type: type, refresh: true)
                        }
                        .tag(type)
                    }
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .ignoresSafeArea(edges: .bottom)
        }
        .toolbarBackground(.visible, for: .tabBar)
        .safeAreaInset(edge: .top) {
            headerView
        }
        .navigationTitle(String(localized: "library_title", table: "Library"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Text("library_title", tableName: "Library")
                    .font(.headline)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.leading, 2)
            }
            ToolbarItem(placement: .principal) {
                Text("library_title", tableName: "Library")
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.leading, 2)
                    .hidden()
            }
        }
        .task {
            viewModel.accountsManager = accountsManager
            viewModel.loadAllShelfItems()
        }
        .onDisappear {
            viewModel.cleanup()
        }
        .enableInjection()
    }

    #if DEBUG
        @ObserveInjection var forceRedraw
    #endif

    private var headerView: some View {
        Group {
                VStack(alignment: .leading, spacing: 0) {
                    categoryFilter

                    TopTabBarView(
                        items: ShelfType.allCases,
                        selection: $viewModel.selectedShelfType
                    ) {
                        $0.displayNameForCategory(
                            viewModel.selectedCategory.itemCategory)
                    }
                    .padding(.bottom, -12)
                }
        }
    }

    private var categoryFilter: some View {
        ItemCategoryBarView(activeTab: $viewModel.selectedCategory)
    }

    // MARK: - Item View Components
    private func shelfItemView(item: ShelfMarkItem) -> some View {
        HStack(alignment: .top, spacing: 12) {
            ItemCoverView(item: item.mark.item, size: .medium)
            itemDetails(for: item)
        }
        .overlay(alignment: .topTrailing) {
            chevronIcon
                .padding(.top, 4)
        }
        .contentShape(Rectangle())
    }

    private func shelfItemView(mark: MarkSchema) -> some View {
        HStack(alignment: .top, spacing: 12) {
            ItemCoverView(item: mark.item, size: .medium)
            itemDetails(mark: mark)
        }
        .overlay(alignment: .topTrailing) {
            chevronIcon
                .padding(.top, 4)
        }
        .contentShape(Rectangle())
    }

    private func itemDetails(for item: ShelfMarkItem) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            ItemTitleView(
                item: item.mark.item,
                mode: .title,
                size: .medium
            )

            ItemRatingView(
                item: item.mark.item, size: .small, hideRatingCount: true)

            ItemDescriptionView(
                item: item.mark.item, mode: .brief, size: .medium)

            ItemMarkView(
                markController: item.controller,
                size: .medium,
                brief: true,
                showEditButton: true
            )
        }
    }

    private func itemDetails(mark: MarkSchema) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            ItemTitleView(
                item: mark.item,
                mode: .title,
                size: .medium
            )

            ItemRatingView(item: mark.item, size: .small, hideRatingCount: true)

            ItemDescriptionView(item: mark.item, mode: .brief, size: .medium)
        }
    }

    private var chevronIcon: some View {
        Image(systemSymbol: .chevronRight)
            .foregroundStyle(.secondary)
            .font(.caption)
    }

    // MARK: - Shelf Content View
    @ViewBuilder
    private func shelfContentView(
        for type: ShelfType, geometry: GeometryProxy? = nil
    ) -> some View {
        if let state = viewModel.shelfStates[type] {
            if state.items.isEmpty {
                if let error = state.error {
                    EmptyStateView(
                        String(
                            localized: "library_error_title", table: "Library"),
                        systemImage: "exclamationmark.triangle",
                        description: Text(state.detailedError ?? error)
                    )
                    .listRowInsets(EdgeInsets())
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
                    .padding(.top, (geometry?.size.height ?? 0) / 4)
                } else if !state.isLoading && !state.isRefreshing {
                    EmptyStateView(
                        String(
                            localized: "library_empty_title", table: "Library"),
                        systemImage: "books.vertical",
                        description: Text(
                            String(
                                format: String(
                                    localized: "library_empty_description",
                                    table: "Library"), type.displayName))
                    )
                    .listRowInsets(EdgeInsets())
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
                    .padding(.top, (geometry?.size.height ?? 0) / 4)
                } else {
                    shelfItemsPlaceholder()
                }
            } else {
                shelfItemsList(for: state, type: type)
            }
        }
    }

    //    @ViewBuilder
    //    private func emptyStateView(for state: ShelfItemsState, type: ShelfType) -> some View {
    //        if let error = state.error {
    //            EmptyStateView(
    //                String(localized: "library_error_title", table: "Library"),
    //                systemImage: "exclamationmark.triangle",
    //                description: Text(state.detailedError ?? error)
    //            )
    //        } else if !state.isLoading && !state.isRefreshing {
    //            EmptyStateView(
    //                String(localized: "library_empty_title", table: "Library"),
    //                systemImage: "books.vertical",
    //                description: Text(String(format: String(localized: "library_empty_description", table: "Library"), type.displayName))
    //            )
    //        } else {
    //            shelfItemsPlaceholder()
    //        }
    //    }

    @ViewBuilder
    private func shelfItemsList(for state: ShelfItemsState, type: ShelfType)
        -> some View
    {
        Group {
            Section {
                ForEach(state.items) { item in
                    Button {
                        TelemetryService.shared.trackLibraryItemClick(
                            itemId: item.mark.item.id,
                            category: item.mark.item.category,
                            currentShelfType: type,
                            currentShelfCategory: viewModel.selectedCategory)
                        router.navigate(
                            to: .itemDetailWithItem(item: item.mark.item))
                    } label: {
                        shelfItemView(item: item)
                            .onAppear {
                                if item.id == state.items.last?.id {
                                    Task {
                                        await viewModel.loadNextPage(type: type)
                                    }
                                }
                            }
                    }
                    .buttonStyle(.plain)
                }
            }

            if state.isLoading && !state.isRefreshing {
                Section {
                    ProgressView()
                        .listRowSeparator(.hidden)
                        .id(UUID())
                        .frame(maxWidth: .infinity)
                        .padding()
                        .listRowInsets(EdgeInsets())
                }
            }
        }
    }

    @ViewBuilder
    private func shelfItemsPlaceholder() -> some View {
        ForEach(PagedMarkSchema.placeholders.data) { item in
            shelfItemView(mark: item)
                .redacted(reason: .placeholder)
        }
    }
}

// MARK: - Preview
#Preview {
    NavigationStack {
        LibraryView()
            .environmentObject(Router())
            .environmentObject(AppAccountsManager())
    }
}

