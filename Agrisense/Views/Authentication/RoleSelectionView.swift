import SwiftUI

struct RoleSelectionView: View {
    @State private var showFarmerAuth = false
    @State private var showSellerAuth = false

    var body: some View {
        VStack(spacing: 32) {
            Text("Choose Your Role")
                .font(.title)
                .fontWeight(.bold)
            
            Button("I'm a Farmer") {
                showFarmerAuth = true
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.green)
            .foregroundColor(.white)
            .cornerRadius(12)
            
            Button("I'm a Seller") {
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
            SignInView()
        }
        .sheet(isPresented: $showSellerAuth) {
            SignInView()
        }
    }
}

