//
//  RouterDestination.swift
//  NeoDB
//
//  Created by 甜檸Citron(lcandy2) on 2/9/25.
//  Copyright © 2025 https://github.com/lcandy2. All Rights Reserved.
//

import SwiftUI

enum RouterDestination: Hashable {
    // Library
    case itemDetail(id: String)
    case itemDetailWithItem(item: any ItemProtocol)
    case shelfDetail(type: ShelfType)
    case userShelf(userId: String, type: ShelfType)

    // Social
    case userProfile(id: String)
    case userProfileWithUser(user: User)
    case statusDetail(id: String)
    case statusDetailWithStatus(status: MastodonStatus)
    case statusDetailWithStatusAndItem(status: MastodonStatus, item: any ItemProtocol)
    case hashTag(tag: String)

    // Lists
    case followers(id: String)
    case following(id: String)

    // Discover
    case galleryCategory(galleryState: GalleryViewModel.State)

    // Store
    case purchase
    case purchaseWithFeature(feature: StoreConfig.Features)

    // Login
    case instance
    case login(instanceAddress: String)
    // case loginWithInstance(instance: MastodonInstance, instanceAddress: String)

    func hash(into hasher: inout Hasher) {
        switch self {
        case .itemDetail(let id):
            hasher.combine(0)
            hasher.combine(id)
        case .itemDetailWithItem(let item):
            hasher.combine(1)
            hasher.combine(item.id)
        case .shelfDetail(let type):
            hasher.combine(2)
            hasher.combine(type)
        case .userShelf(let userId, let type):
            hasher.combine(3)
            hasher.combine(userId)
            hasher.combine(type)
        case .userProfile(let id):
            hasher.combine(4)
            hasher.combine(id)
        case .userProfileWithUser(let user):
            hasher.combine(5)
            hasher.combine(user.url)
        case .statusDetail(let id):
            hasher.combine(6)
            hasher.combine(id)
        case .statusDetailWithStatus(let status):
            hasher.combine(7)
            hasher.combine(status.id)
        case .statusDetailWithStatusAndItem(let status, let item):
            hasher.combine(8)
            hasher.combine(status.id)
            hasher.combine(item.id)
        case .hashTag(let tag):
            hasher.combine(9)
            hasher.combine(tag)
        case .followers(let id):
            hasher.combine(9)
            hasher.combine(id)
        case .following(let id):
            hasher.combine(10)
            hasher.combine(id)
        case .galleryCategory(let galleryState):
            hasher.combine(11)
            hasher.combine(galleryState.galleryCategory)
        case .purchase:
            hasher.combine(12)
        case .purchaseWithFeature(let feature):
            hasher.combine(13)
            hasher.combine(feature)
        case .instance:
            hasher.combine(14)
        case .login(let instanceAddress):
            hasher.combine(15)
            hasher.combine(instanceAddress)
            
        }
    }

    static func == (lhs: RouterDestination, rhs: RouterDestination) -> Bool {
        switch (lhs, rhs) {
        case (.itemDetail(let id1), .itemDetail(let id2)):
            return id1 == id2
        case (.itemDetailWithItem(let item1), .itemDetailWithItem(let item2)):
            return item1.id == item2.id
        case (.shelfDetail(let type1), .shelfDetail(let type2)):
            return type1 == type2
        case (
            .userShelf(let userId1, let type1),
            .userShelf(let userId2, let type2)
        ):
            return userId1 == userId2 && type1 == type2
        case (.userProfile(let id1), .userProfile(let id2)):
            return id1 == id2
        case (.userProfileWithUser(let user1), .userProfileWithUser(let user2)):
            return user1.url == user2.url
        case (.statusDetail(let id1), .statusDetail(let id2)):
            return id1 == id2
        case (
            .statusDetailWithStatus(let status1),
            .statusDetailWithStatus(let status2)
        ):
            return status1.id == status2.id
        case (.hashTag(let tag1), .hashTag(let tag2)):
            return tag1 == tag2
        case (.followers(let id1), .followers(let id2)):
            return id1 == id2
        case (.following(let id1), .following(let id2)):
            return id1 == id2
        case (.purchase, .purchase):
            return true
        default:
            return false
        }
    }
}

// MARK: - View Builder
extension RouterDestination {
    @ViewBuilder
    var destinationView: some View {
        switch self {
        case .itemDetail(let id):
            ItemView(
                id: id,
                category: .book
            )
        case .itemDetailWithItem(let item):
            ItemView(
                id: item.id,
                category: item.type.category ?? item.category,
                item: item
            )
        case .shelfDetail(let type):
            Text("Shelf: \(type.displayName)")  // TODO: Implement ShelfDetailView
        case .userShelf(let userId, let type):
            Text("User Shelf: \(userId) - \(type.displayName)")  // TODO: Implement UserShelfView
        case .userProfile(let id):
            ProfileView(id: id)
        case .userProfileWithUser(let user):
            ProfileView(id: user.username, user: user)
        case .statusDetail(let id):
            MastodonStatusView(id: id)
        case .statusDetailWithStatus(let status):
            MastodonStatusView(id: status.id, status: status)
        case .statusDetailWithStatusAndItem(let status, let item):
            MastodonStatusView(id: status.id, status: status, item: item)
        case .hashTag(let tag):
            Text("Tag: #\(tag)")  // TODO: Implement HashTagView
        case .followers(let id):
            Text("Followers: \(id)")  // TODO: Implement FollowersView
        case .following(let id):
            Text("Following: \(id)")  // TODO: Implement FollowingView
        case .galleryCategory(let galleryState):
            GalleryCategoryView(galleryState: galleryState)
        case .purchase:
            PurchaseView()
        case .purchaseWithFeature(let feature):
            PurchaseView(scrollToFeature: feature)
        case .instance:
            InstanceView()
        case .login(let instanceAddress):
            LoginView(instanceAddress: instanceAddress)
        // case .loginWithInstance(let instance, let instanceAddress):
            // LoginView(instance: instance, instanceAddress: instanceAddress)
        }
    }
}

// MARK: - Navigation Extension
extension View {
    func navigationDestination(for router: Router) -> some View {
        self.navigationDestination(for: RouterDestination.self) { destination in
            destination.destinationView
        }
    }
}
