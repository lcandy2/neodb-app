//
//  GalleryCategoryView.swift
//  NeoDB
//
//  Created by 甜檸Citron(lcandy2) on 2/2/25.
//  Copyright © 2025 https://github.com/lcandy2. All Rights Reserved.
//

import SwiftUI

struct GalleryCategoryView: View {
    let galleryState: GalleryViewModel.State
    @EnvironmentObject private var router: Router
    
    var body: some View {
        List {
            if !galleryState.trendingGallery.isEmpty {
                ForEach(galleryState.trendingGallery, id: \.uuid) { item in
                    Button {
                        HapticFeedback.selection()
                        router.navigate(to: .itemDetailWithItem(item: item))
                    } label: {
                        SearchItemView(item: item, showCategory: false)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .listStyle(.plain)
        .navigationTitle(galleryState.galleryCategory.displayName)
        .navigationBarTitleDisplayMode(.large)
        .enableInjection()
    }

    #if DEBUG
    @ObserveInjection var forceRedraw
    #endif
}

#Preview {
    NavigationStack {
        GalleryCategoryView(
            galleryState: GalleryViewModel.State(
                galleryCategory: .book,
                trendingGallery: [ItemSchema.preview]
            )
        )
        .environmentObject(Router())
    }
}

