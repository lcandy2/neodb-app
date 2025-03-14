# Routeur.swift
```swift
import Foundation
import SwiftUI
import Models
import Network

public enum RouteurDestinations: Hashable {
  case accountDetail(id: String)
  case accountDetailWithAccount(account: Account)
  case statusDetail(id: String)
  case hashTag(tag: String, account: String?)
  case list(list: Models.List)
  case followers(id: String)
  case following(id: String)
  case favouritedBy(id: String)
  case rebloggedBy(id: String)
}

public enum SheetDestinations: Identifiable {
  case newStatusEditor
  case editStatusEditor(status: Status)
  case replyToStatusEditor(status: Status)
  case quoteStatusEditor(status: Status)
  case listEdit(list: Models.List)
  case listAddAccount(account: Account)
  
  public var id: String {
    switch self {
    case .editStatusEditor, .newStatusEditor, .replyToStatusEditor, .quoteStatusEditor:
      return "statusEditor"
    case .listEdit:
      return "listEdit"
    case .listAddAccount:
      return "listAddAccount"
    }
  }
}

@MainActor
public class RouterPath: ObservableObject {
  public var client: Client?
  
  @Published public var path: [RouteurDestinations] = []
  @Published public var presentedSheet: SheetDestinations?
  
  public init() {}
  
  public func navigate(to: RouteurDestinations) {
    path.append(to)
  }
  
  public func handleStatus(status: AnyStatus, url: URL) -> OpenURLAction.Result {
    if url.pathComponents.contains(where: { $0 == "tags" }),
        let tag = url.pathComponents.last {
      navigate(to: .hashTag(tag: tag, account: nil))
      return .handled
    } else if let mention = status.mentions.first(where: { $0.url == url }) {
      navigate(to: .accountDetail(id: mention.id))
      return .handled
    } else if let client = client,
              let id = Int(url.lastPathComponent) {
      if url.absoluteString.contains(client.server) {
        navigate(to: .statusDetail(id: String(id)))
      } else {
        Task {
          await navigateToStatusFrom(url: url)
        }
      }
      return .handled
    }
    return .systemAction
  }
  
  public func handle(url: URL) -> OpenURLAction.Result {
    if url.pathComponents.contains(where: { $0 == "tags" }),
        let tag = url.pathComponents.last {
      navigate(to: .hashTag(tag: tag, account: nil))
      return .handled
    } else if url.lastPathComponent.first == "@", let host = url.host {
      let acct = "\(url.lastPathComponent)@\(host)"
      Task {
        await navigateToAccountFrom(acct: acct, url: url)
      }
      return .handled
    }
    return .systemAction
  }
  
  public func navigateToStatusFrom(url: URL) async {
    guard let client else { return }
    Task {
      let results: SearchResults? = try? await client.get(endpoint: Search.search(query: url.absoluteString,
                                                                                   type: "statuses",
                                                                                  offset: nil,
                                                                                  following: nil),
                                                          forceVersion: .v2)
      if let status = results?.statuses.first {
        navigate(to: .statusDetail(id: status.id))
      } else {
        await UIApplication.shared.open(url)
      }
    }
  }
  
  public func navigateToAccountFrom(acct: String, url: URL) async {
    guard let client else { return }
    Task {
      let results: SearchResults? = try? await client.get(endpoint: Search.search(query: acct,
                                                                                   type: "accounts",
                                                                                  offset: nil,
                                                                                  following: nil),
                                                          forceVersion: .v2)
      if let account = results?.accounts.first {
        navigate(to: .accountDetailWithAccount(account: account))
      } else {
        await UIApplication.shared.open(url)
      }
    }
  }
}
```
