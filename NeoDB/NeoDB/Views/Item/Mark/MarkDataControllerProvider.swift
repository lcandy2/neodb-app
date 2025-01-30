//
//  MarkDataControllerProvider.swift
//  Live Capture
//
//  Created by 甜檸Citron(lcandy2) on 1/31/25.
//  Copyright © 2025 https://github.com/lcandy2. All Rights Reserved.
//

import SwiftUI
import Perception

// MARK: - Protocol
@MainActor
 protocol MarkDataControlling {
    var shelfType: ShelfType { get set }
    var visibility: MarkVisibility { get set }
    var commentText: String? { get set }
    var ratingGrade: Int? { get set }
    var tags: [String] { get set }
    
    func updateMark() async
    func deleteMark() async
}

// MARK: - Provider
@MainActor
 final class MarkDataControllerProvider {
     static let shared = MarkDataControllerProvider()
    private let cacheService = CacheService()
    
    // 内存缓存，用于快速访问
    private var controllers: [String: MarkDataController] = [:]
    
     func dataController(for mark: MarkSchema, client: NetworkClient) -> MarkDataController {
        if let controller = controllers[mark.id] {
            return controller
        }
        let controller = MarkDataController(mark: mark, client: client, cacheService: cacheService)
        controllers[mark.id] = controller
        return controller
    }
    
     func updateDataControllers(for marks: [MarkSchema], client: NetworkClient) {
        for mark in marks {
            let controller = dataController(for: mark, client: client)
            controller.updateFrom(mark: mark)
        }
    }
    
     func removeController(for markId: String) {
        controllers.removeValue(forKey: markId)
    }
}

// MARK: - Controller
@Perceptible
final class MarkDataController: MarkDataControlling {
    private let mark: MarkSchema
    private let client: NetworkClient
    private let cacheService: CacheService
    
    var shelfType: ShelfType
    var visibility: MarkVisibility
    var commentText: String?
    var ratingGrade: Int?
    var tags: [String]
    var postToFediverse: Bool = true
    var createdTime: Date?
    
    init(mark: MarkSchema, client: NetworkClient, cacheService: CacheService) {
        self.mark = mark
        self.client = client
        self.cacheService = cacheService
        
        self.shelfType = mark.shelfType
        self.visibility = mark.visibility
        self.commentText = mark.commentText
        self.ratingGrade = mark.ratingGrade
        self.tags = mark.tags
    }
    
    func updateFrom(mark: MarkSchema) {
        self.shelfType = mark.shelfType
        self.visibility = mark.visibility
        self.commentText = mark.commentText
        self.ratingGrade = mark.ratingGrade
        self.tags = mark.tags
    }
    
    func updateMark() async throws {
        // 保存旧值用于回滚
        let oldValues = (shelfType, visibility, commentText, ratingGrade, tags)
        
        do {
            let markIn = MarkInSchema(
                shelfType: shelfType,
                visibility: visibility,
                commentText: commentText,
                ratingGrade: ratingGrade,
                tags: tags,
                createdTime: createdTime.map { ServerDate.from($0) },
                postToFediverse: postToFediverse
            )
            
            let endpoint = MarkEndpoint.mark(itemId: mark.item.uuid, mark: markIn)
            _ = try await client.fetch(endpoint, type: MessageSchema.self)
            
            // 更新缓存
            if let accountId = client.accountId {
                try await cacheService.cacheMark(
                    mark,
                    key: accountId,
                    itemUUID: mark.item.uuid,
                    instance: client.instance
                )
            }
            
        } catch {
            // 错误回滚
            (shelfType, visibility, commentText, ratingGrade, tags) = oldValues
            throw error
        }
    }
    
    func deleteMark() async throws {
        let endpoint = MarkEndpoint.delete(itemId: mark.item.uuid)
        _ = try await client.fetch(endpoint, type: MessageSchema.self)
        
        // 删除缓存
        if let accountId = client.accountId {
            try await cacheService.removeMark(
                key: accountId,
                itemUUID: mark.item.uuid
            )
        }
        
        // 从provider中移除controller
        MarkDataControllerProvider.shared.removeController(for: mark.id)
    }
}
