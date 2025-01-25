//
//  MarkView.swift
//  NeoDB
//
//  Created by citron on 1/15/25.
//

import SwiftUI

struct MarkView: View {
    @StateObject private var viewModel: MarkViewModel
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var accountsManager: AppAccountsManager
    @State private var showAdvanced = false
    @State private var detent: PresentationDetent = .medium

    init(
        item: any ItemProtocol, mark: MarkSchema? = nil,
        shelfType: ShelfType? = nil
    ) {
        _viewModel = StateObject(
            wrappedValue: MarkViewModel(
                item: item, mark: mark, shelfType: shelfType))
    }

    var body: some View {
        VStack(spacing: 0) {
            // Custom title bar
            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    Text(viewModel.title)
                        .font(.headline)
                    Spacer()
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.gray)
                            .font(.title2)
                    }
                }
                .padding(.horizontal)
                .padding(.top)
                .padding(.bottom)
                .padding(.leading, 4)
                shelfTypeButtons
            }
            
            TabView(selection: Binding(
                get: { viewModel.shelfType ?? .wishlist },
                set: { viewModel.shelfType = $0 }
            )) {
                ForEach(ShelfType.allCases, id: \.self) { type in
                    markContentView
                        .tag(type)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
        }
        .background(.ultraThinMaterial)
        .compositingGroup()
        .presentationDetents([.medium, .large], selection: $detent)
        .presentationDragIndicator(.visible)
        .onChange(of: viewModel.isDismissed) { dismissed in
            if dismissed {
                dismiss()
            }
        }
        .alert(
            String(localized: "mark_error_title", table: "Item"),
            isPresented: $viewModel.showError
        ) {
            Button("OK", role: .cancel) {}
        } message: {
            if let error = viewModel.error {
                Text(error.localizedDescription)
            }
        }
        .onAppear {
            viewModel.accountsManager = accountsManager
        }
        .enableInjection()
    }

    private var shelfTypeButtons: some View {
        TopTabBarView(
            items: ShelfType.allCases,
            selection: Binding(
                get: { viewModel.shelfType ?? .wishlist },
                set: { newValue in
                    if viewModel.shelfType != newValue {
                        viewModel.shelfType = newValue
                        HapticFeedback.impact(.light)
                    }
                }
            )
        ) { $0.displayName }
    }

    private var markContentView: some View {
        VStack(spacing: 0) {
            List {
                // Rating Section (not shown for wishlist)
                if viewModel.shelfType != .wishlist {
                    Section {
                        StarRatingView(inputRating: $viewModel.rating)
                            .frame(maxWidth: .infinity)
                    }
                    .listRowInsets(EdgeInsets(top: 2, leading: 6, bottom: 2, trailing: 6))
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
                }

                // Comment Section
                Section {
                    TextEditor(text: $viewModel.comment)
                        .frame(minHeight: 100)
                } header: {
                    Text("mark_comment_label", tableName: "Item")
                } footer: {
                    Text("mark_comment_optional", tableName: "Item")
                }

                // Advanced Options Section
                Section {
                    DisclosureGroup(
                        String(localized: "mark_advanced_section", table: "Item"),
                        isExpanded: $showAdvanced
                    ) {
                        Toggle(
                            String(localized: "mark_public_toggle", table: "Item"),
                            isOn: $viewModel.isPublic)
                        Toggle(
                            String(localized: "mark_share_fediverse_toggle", table: "Item"),
                            isOn: $viewModel.postToFediverse)
                        Toggle(
                            String(localized: "mark_use_current_time_toggle", table: "Item"),
                            isOn: $viewModel.useCurrentTime)

                        if !viewModel.useCurrentTime {
                            DatePicker(
                                String(localized: "mark_created_time_label", table: "Item"),
                                selection: $viewModel.createdTime,
                                displayedComponents: [.date, .hourAndMinute]
                            )
                        }
                    }
                }

                // Delete Button Section
                if viewModel.existingMark != nil {
                    Section {
                        Button(role: .destructive) {
                            Task {
                                await viewModel.deleteMark()
                            }
                        } label: {
                            Text("mark_delete_button", tableName: "Item")
                                .frame(maxWidth: .infinity)
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .safeContentMargins(.top, EdgeInsets())
            .scrollContentBackground(.hidden)

            // Bottom Save Button
            VStack(spacing: 16) {
                Button {
                    Task {
                        await viewModel.saveMark()
                    }
                } label: {
                    Text("mark_save_button", tableName: "Item")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                }
                .buttonStyle(.borderedProminent)
                .disabled(viewModel.isLoading)
                .padding(.horizontal)
            }
            .padding(.vertical)
            .background(.ultraThinMaterial)
            .compositingGroup()
        }
    }

    #if DEBUG
        @ObserveInjection var forceRedraw
    #endif
}

#Preview {
    MarkView(item: ItemSchema.preview)
        .environmentObject(AppAccountsManager())
}
