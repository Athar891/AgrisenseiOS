//
//  DependencyContainer.swift
//  Agrisense
//
//  Created by GitHub Copilot on 14/08/25.
//

import Foundation

// MARK: - Dependency Injection Container

public struct DI {
    public let api: APIClient
    public let auth: AuthService
    public let storage: Storage
    public let logger: Logger
    public let productService: ProductService
    public let postService: PostService
    public let chatService: ChatService
    public let accountService: AccountService
    
    public init(
        api: APIClient,
        auth: AuthService,
        storage: Storage,
        logger: Logger,
        productService: ProductService,
        postService: PostService,
        chatService: ChatService,
        accountService: AccountService
    ) {
        self.api = api
        self.auth = auth
        self.storage = storage
        self.logger = logger
        self.productService = productService
        self.postService = postService
        self.chatService = chatService
        self.accountService = accountService
    }
    
    // Factory method for production dependencies
    public static func live() -> DI {
        let storage = UserDefaultsStorage()
        let logger = ConsoleLogger()
        let api = LiveAPIClient(logger: logger)
        let auth = FirebaseAuthService(storage: storage, logger: logger)
        
        return DI(
            api: api,
            auth: auth,
            storage: storage,
            logger: logger,
            productService: LiveProductService(api: api, logger: logger),
            postService: LivePostService(api: api, logger: logger),
            chatService: LiveChatService(api: api, logger: logger),
            accountService: LiveAccountService(api: api, logger: logger)
        )
    }
    
    // Factory method for testing/preview dependencies
    public static func mock() -> DI {
        return DI(
            api: MockAPIClient(),
            auth: MockAuthService(),
            storage: MockStorage(),
            logger: MockLogger(),
            productService: MockProductService(),
            postService: MockPostService(),
            chatService: MockChatService(),
            accountService: MockAccountService()
        )
    }
}

// MARK: - Protocol Definitions

public protocol APIClient {
    // Add API client methods here
}

public protocol AuthService {
    // Add auth service methods here
}

public protocol Storage {
    // Add storage methods here
}

public protocol Logger {
    func log(_ message: String)
    func logError(_ error: Error)
}

public protocol ProductService {
    // Add product service methods here
}

public protocol PostService {
    // Add post service methods here
}

public protocol ChatService {
    // Add chat service methods here
}

public protocol AccountService {
    // Add account service methods here
}

// MARK: - Mock Implementations

public class MockAPIClient: APIClient {
    public init() {}
}

public class MockAuthService: AuthService {
    public init() {}
}

public class MockStorage: Storage {
    public init() {}
}

public class MockLogger: Logger {
    public init() {}
    
    public func log(_ message: String) {
        print("[MOCK LOG] \(message)")
    }
    
    public func logError(_ error: Error) {
        print("[MOCK ERROR] \(error)")
    }
}

public class MockProductService: ProductService {
    public init() {}
}

public class MockPostService: PostService {
    public init() {}
}

public class MockChatService: ChatService {
    public init() {}
}

public class MockAccountService: AccountService {
    public init() {}
}

// MARK: - Live Implementations

public class LiveAPIClient: APIClient {
    private let logger: Logger
    
    public init(logger: Logger) {
        self.logger = logger
    }
}

public class FirebaseAuthService: AuthService {
    private let storage: Storage
    private let logger: Logger
    
    public init(storage: Storage, logger: Logger) {
        self.storage = storage
        self.logger = logger
    }
}

public class UserDefaultsStorage: Storage {
    public init() {}
}

public class ConsoleLogger: Logger {
    public init() {}
    
    public func log(_ message: String) {
        print("[LOG] \(message)")
    }
    
    public func logError(_ error: Error) {
        print("[ERROR] \(error)")
    }
}

public class LiveProductService: ProductService {
    private let api: APIClient
    private let logger: Logger
    
    public init(api: APIClient, logger: Logger) {
        self.api = api
        self.logger = logger
    }
}

public class LivePostService: PostService {
    private let api: APIClient
    private let logger: Logger
    
    public init(api: APIClient, logger: Logger) {
        self.api = api
        self.logger = logger
    }
}

public class LiveChatService: ChatService {
    private let api: APIClient
    private let logger: Logger
    
    public init(api: APIClient, logger: Logger) {
        self.api = api
        self.logger = logger
    }
}

public class LiveAccountService: AccountService {
    private let api: APIClient
    private let logger: Logger
    
    public init(api: APIClient, logger: Logger) {
        self.api = api
        self.logger = logger
    }
}