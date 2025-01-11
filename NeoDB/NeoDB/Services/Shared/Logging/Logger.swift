import Foundation
import OSLog

/// A unified logging system for the NeoDB app
extension Logger {
    /// Using bundle identifier as subsystem for unique identification
    private static var subsystem = Bundle.main.bundleIdentifier!

    // MARK: - App Lifecycle
    /// Logs related to app lifecycle events
    static let lifecycle = Logger(subsystem: subsystem, category: "lifecycle")
    
    // MARK: - Networking
    /// Logs related to network requests and responses
    static let network = Logger(subsystem: subsystem, category: "network")
    static let networkAuth = Logger(subsystem: subsystem, category: "network.auth")
    static let networkTimeline = Logger(subsystem: subsystem, category: "network.timeline")
    static let networkItem = Logger(subsystem: subsystem, category: "network.item")
    static let networkShelf = Logger(subsystem: subsystem, category: "network.shelf")
    static let networkUser = Logger(subsystem: subsystem, category: "network.user")
    
    // MARK: - Data
    /// Logs related to data persistence and caching
    static let data = Logger(subsystem: subsystem, category: "data")
    
    // MARK: - Authentication
    /// Logs related to user authentication
    static let auth = Logger(subsystem: subsystem, category: "auth")
    
    // MARK: - View Lifecycle
    /// Logs related to view lifecycle events
    static let view = Logger(subsystem: subsystem, category: "view")
    
    // MARK: - Navigation
    /// Logs related to navigation and routing
    static let router = Logger(subsystem: subsystem, category: "router")
    
    // MARK: - Views
    /// Logs related to specific views
    static let library = Logger(subsystem: subsystem, category: "view.library")
    static let home = Logger(subsystem: subsystem, category: "view.home")
    static let htmlContent = Logger(subsystem: subsystem, category: "view.html")
    
    // MARK: - User Actions
    /// Logs related to user interactions
    static let userAction = Logger(subsystem: subsystem, category: "userAction")
    
    // MARK: - Performance
    /// Logs related to performance metrics
    static let performance = Logger(subsystem: subsystem, category: "performance")
}

// MARK: - Convenience Methods
extension Logger {
    private func formatMessage(_ message: String, file: String = #file, function: String = #function, line: Int = #line) -> String {
        #if DEBUG
        let filename = (file as NSString).lastPathComponent
        return "[\(filename):\(line)] \(function) - \(message)"
        #else
        return message
        #endif
    }
    
    /// Log a message with the debug level
    /// - Parameters:
    ///   - message: The message to log
    ///   - file: The file where the log was called
    ///   - function: The function where the log was called
    ///   - line: The line where the log was called
    func debug(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        log(level: .debug, "\(formatMessage(message, file: file, function: function, line: line))")
    }
    
    /// Log a message with the info level
    /// - Parameters:
    ///   - message: The message to log
    ///   - file: The file where the log was called
    ///   - function: The function where the log was called
    ///   - line: The line where the log was called
    func info(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        log(level: .info, "\(formatMessage(message, file: file, function: function, line: line))")
    }
    
    /// Log a message with the error level
    /// - Parameters:
    ///   - message: The message to log
    ///   - file: The file where the log was called
    ///   - function: The function where the log was called
    ///   - line: The line where the log was called
    func error(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        log(level: .error, "\(formatMessage(message, file: file, function: function, line: line))")
    }
    
    /// Log a message with the warning level
    /// - Parameters:
    ///   - message: The message to log
    ///   - file: The file where the log was called
    ///   - function: The function where the log was called
    ///   - line: The line where the log was called
    func warning(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        log(level: .default, "\(formatMessage(message, file: file, function: function, line: line))")
    }
}
