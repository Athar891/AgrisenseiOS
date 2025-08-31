import SwiftUI

struct RoleSelectionView: View {
    @State private var showFarmerAuth = false
    @State private var showSellerAuth = false
    @EnvironmentObject var localizationManager: LocalizationManager

    var body: some View {
        VStack(spacing: 32) {
            Text(localizationManager.localizedString(for: "choose_role"))
                .font(.title)
                .fontWeight(.bold)
            
            Button(localizationManager.localizedString(for: "role_farmer")) {
                showFarmerAuth = true
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.green)
            .foregroundColor(.white)
            .cornerRadius(12)
            
            Button(localizationManager.localizedString(for: "role_seller")) {
                showSellerAuth = true
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.orange)
            .foregroundColor(.white)
            .cornerRadius(12)
        }
        .padding()
        .sheet(isPresented: $showFarmerAuth) {
            SignInView(selectedRole: .farmer)
        }
        .sheet(isPresented: $showSellerAuth) {
            SignInView(selectedRole: .seller)
        }
    }
}

