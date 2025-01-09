//
//  Router.swift
//  NeoDB
//
//  Created by citron(https://github.com/lcandy2) on 1/7/25.
//

import SwiftUI
import OSLog

enum RouterDestination: Hashable {
    // Library
    case itemDetail(id: String)
    case itemDetailWithItem(item: ItemSchema)
    case shelfDetail(type: ShelfType)
    case userShelf(userId: String, type: ShelfType)
    
    // Social
    case userProfile(id: String)
    case userProfileWithUser(user: User)
    case statusDetail(id: String)
    case statusDetailWithStatus(status: Status)
    case hashTag(tag: String)
    
    // Lists
    case followers(id: String)
    case following(id: String)
    
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
        case .hashTag(let tag):
            hasher.combine(8)
            hasher.combine(tag)
        case .followers(let id):
            hasher.combine(9)
            hasher.combine(id)
        case .following(let id):
            hasher.combine(10)
            hasher.combine(id)
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
        case (.userShelf(let userId1, let type1), .userShelf(let userId2, let type2)):
            return userId1 == userId2 && type1 == type2
        case (.userProfile(let id1), .userProfile(let id2)):
            return id1 == id2
        case (.userProfileWithUser(let user1), .userProfileWithUser(let user2)):
            return user1.url == user2.url
        case (.statusDetail(let id1), .statusDetail(let id2)):
            return id1 == id2
        case (.statusDetailWithStatus(let status1), .statusDetailWithStatus(let status2)):
            return status1.id == status2.id
        case (.hashTag(let tag1), .hashTag(let tag2)):
            return tag1 == tag2
        case (.followers(let id1), .followers(let id2)):
            return id1 == id2
        case (.following(let id1), .following(let id2)):
            return id1 == id2
        default:
            return false
        }
    }
}

enum SheetDestination: Identifiable {
    case newStatus
    case editStatus(status: Status)
    case replyToStatus(status: Status)
    case addToShelf(item: ItemSchema)
    case editShelfItem(mark: MarkSchema)
    
    var id: String {
        switch self {
        case .newStatus, .editStatus, .replyToStatus:
            return "statusEditor"
        case .addToShelf:
            return "shelfEditor"
        case .editShelfItem:
            return "shelfItemEditor"
        }
    }
}

@MainActor
class Router: ObservableObject {
    @Published var path: [RouterDestination] = []
    @Published var presentedSheet: SheetDestination?
    @Published var itemToLoad: ItemSchema?
    
    private let logger = Logger(subsystem: "app.neodb", category: "Router")
    
    func navigate(to destination: RouterDestination) {
        path.append(destination)
        
        // Store item for loading if navigating to item detail
        if case .itemDetailWithItem(let item) = destination {
            itemToLoad = item
        }
        
        logger.debug("Navigated to: \(String(describing: destination))")
    }
    
    func dismissSheet() {
        presentedSheet = nil
    }
    
    func handleURL(_ url: URL) -> Bool {
        logger.debug("Handling URL: \(url.absoluteString)")
        
        // Handle deep links and internal navigation
        if url.host == "neodb.social" {
            let pathComponents = url.pathComponents
            
            if pathComponents.contains("items"),
               let id = pathComponents.last {
                navigate(to: .itemDetail(id: id))
                return true
            }
            
            if pathComponents.contains("users"),
               let id = pathComponents.last {
                navigate(to: .userProfile(id: id))
                return true
            }
            
            if pathComponents.contains("status"),
               let id = pathComponents.last {
                navigate(to: .statusDetail(id: id))
                return true
            }
            
            if pathComponents.contains("tags"),
               let tag = pathComponents.last {
                navigate(to: .hashTag(tag: tag))
                return true
            }
        }
        
        return false
    }
    
    func handleStatus(status: Status, url: URL) -> Bool {
        logger.debug("Handling status URL: \(url.absoluteString)")
        
        let pathComponents = url.pathComponents
        
        // Handle hashtags
        if pathComponents.contains("tags"),
           let tag = pathComponents.last {
            navigate(to: .hashTag(tag: tag))
            return true
        }
        
        // Handle mentions
        if pathComponents.contains("users"),
           let id = pathComponents.last {
            navigate(to: .userProfile(id: id))
            return true
        }
        
        // Handle status links
        if pathComponents.contains("status"),
           let id = pathComponents.last {
            navigate(to: .statusDetail(id: id))
            return true
        }
        
        return false
    }
} 