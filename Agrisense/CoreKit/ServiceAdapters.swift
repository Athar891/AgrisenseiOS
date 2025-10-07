import SwiftUI
#if canImport(FirebaseAuth)
import FirebaseAuth
#endif

// This addresses the concurrency warning by adding @preconcurrency
@preconcurrency class FirebaseAuthAdapter: AuthService {
    var userID: String? {
        Auth.auth().currentUser?.uid
    }
    
    var isAuthenticated: Bool {
        Auth.auth().currentUser != nil
    }
    
    func signIn(email: String, password: String) async throws {
        do {
            let _ = try await Auth.auth().signIn(withEmail: email, password: password)
        } catch {
            throw error
        }
    }
    
    func signOut() throws {
        do {
            try Auth.auth().signOut()
        } catch {
            throw error
        }
    }
    
    func signUp(email: String, password: String) async throws {
        do {
            // No need for await here as the operation is not actually async
            let _ = try await Auth.auth().createUser(withEmail: email, password: password)
        } catch {
            throw error
        }
    }
    
    func resetPassword(email: String) async throws {
        do {
            try await Auth.auth().sendPasswordReset(withEmail: email)
        } catch {
            throw error
        }
    }
}
