//
//  ExpertsView.swift
//  Agrisense
//
//  Created by Athar Reza on 09/08/25.
import SwiftUI
#if canImport(Firebase)
import Firebase
#endif
#if canImport(FirebaseAuth)
import FirebaseAuth
#endif
#if canImport(FirebaseFirestore)
import FirebaseFirestore
#endif

struct ExpertsView: View {
    @EnvironmentObject var userManager: UserManager
    @State private var showRegister = false

    var body: some View {
        ZStack(alignment: .bottom) {
            VStack(spacing: 0) {
                Spacer().frame(height: 8)

                ScrollView {
                    LazyVStack(spacing: 16) {
                        ForEach(sampleExperts) { expert in
                            ExpertCard(expert: expert)
                        }
                    }
                    .padding()
                    .padding(.bottom, 100) // space for bottom button
                }
            }

            // Bottom Register button
            Button(action: { showRegister = true }) {
                Text("Register as Expert")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .background(Color.green)
                    .cornerRadius(24)
                    .padding(.horizontal, 20)
            }
            .padding(.bottom, 18)
        }
        .sheet(isPresented: $showRegister) {
            RegisterExpertView()
                .environmentObject(userManager)
        }
    }
}

struct ExpertCard: View {
    let expert: Expert
    @State private var showingProfile = false

    var body: some View {
        Button(action: { showingProfile = true }) {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 56, height: 56)
                    Image(systemName: "person.fill")
                        .font(.system(size: 26))
                        .foregroundColor(.black.opacity(0.8))
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text(expert.name)
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)

                    Text(expert.specialty)
                        .font(.subheadline)
                        .foregroundColor(Color.green)
                        .fontWeight(.semibold)

                    Text(expert.bio)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)

                    HStack(alignment: .center) {
                        HStack(spacing: 6) {
                            Image(systemName: "star.fill")
                                .font(.caption)
                                .foregroundColor(.orange)
                            Text(String(format: "%.1f", expert.rating))
                                .font(.caption)
                                .fontWeight(.medium)
                        }

                        Text("(\(expert.reviews) reviews)")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        Spacer()

                        Text(expert.isAvailable ? "Available" : "Busy")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(expert.isAvailable ? Color.green : Color.orange)
                    }
                }
            }
            .padding()
            .background(Color(UIColor.secondarySystemBackground))
            .cornerRadius(14)
            .shadow(color: .black.opacity(0.06), radius: 6, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
        .sheet(isPresented: $showingProfile) {
            ExpertProfileView(expert: expert)
        }
    }
}

struct ExpertProfileView: View {
    let expert: Expert
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Profile Header
                    HStack(spacing: 16) {
                        ZStack {
                            Circle()
                                .fill(Color.green)
                                .frame(width: 88, height: 88)
                            Image(systemName: "person.fill")
                                .font(.system(size: 34))
                                .foregroundColor(.black.opacity(0.8))
                        }

                        VStack(alignment: .leading, spacing: 6) {
                            Text(expert.name)
                                .font(.title2)
                                .fontWeight(.bold)

                            Text(expert.specialty)
                                .font(.headline)
                                .foregroundColor(Color.green)
                                .fontWeight(.semibold)

                            HStack(spacing: 12) {
                                HStack(spacing: 6) {
                                    Image(systemName: "star.fill")
                                        .foregroundColor(.orange)
                                    Text(String(format: "%.1f", expert.rating))
                                        .fontWeight(.bold)
                                }

                                Text("(\(expert.reviews) reviews)")
                                    .foregroundColor(.secondary)
                            }
                        }
                    }

                    // Bio
                    VStack(alignment: .leading, spacing: 8) {
                        Text("About")
                            .font(.headline)
                            .fontWeight(.semibold)

                        Text(expert.bio)
                            .font(.body)
                            .foregroundColor(.secondary)
                    }

                    // Contact Button
                    Button(action: {}) {
                        Text("Contact Expert")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(Color.green)
                            .cornerRadius(12)
                    }
                }
                .padding()
            }
            .navigationTitle("Expert Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct RegisterExpertView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var userManager: UserManager
    @State private var specialty = ""
    @State private var bio = ""
    @State private var isSubmitting = false

    var body: some View {
        NavigationView {
            Form {
                Section("Your Specialty") {
                    TextField("Specialty (e.g. Soil Science)", text: $specialty)
                    TextField("Short bio", text: $bio)
                }
            }
            .navigationTitle("Register as Expert")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Submit") { submit() }
                        .disabled(specialty.isEmpty || bio.isEmpty || isSubmitting)
                }
            }
        }
    }

    private func submit() {
        guard let user = userManager.currentUser else { return }
        isSubmitting = true
        let db = Firestore.firestore()
        let expertData: [String: Any] = [
            "name": user.name,
            "specialty": specialty,
            "bio": bio,
            "rating": 0.0,
            "reviews": 0,
            "isAvailable": true,
            "userId": user.id
        ]

        db.collection("experts").document(user.id).setData(expertData) { error in
            isSubmitting = false
            if let error = error {
                print("Error registering expert: \(error)")
                return
            }

            db.collection("users").document(user.id).updateData(["isExpert": true]) { _ in }

            var updated = user
            userManager.currentUser = updated

            dismiss()
        }
    }
}

#Preview {
    ExpertsView()
}
