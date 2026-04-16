//
//  OnboardingView.swift
//  Ninety
//
//  Created by Deimante Valunaite on 07/07/2024.
//

import SwiftUI

struct OnboardingView: View {
    @AppStorage("isBoarding") var isOnBoarding: Bool = true

    var body: some View {
        if isOnBoarding {
            ZStack {
                HorizonBackground()
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    Spacer()

                    // Logo — no glass variant: decorative image, not a navigation control
                    Image("Logo design")
                        .resizable()
                        .scaledToFit()
                        .frame(height: 160)
                        .accessibilityLabel("Ninety logo")

                    VStack(spacing: 12) {
                        Text("Ninety")
                            .font(.largeTitle.bold())

                        Text("Track your sleep pattern and wake up refreshed.")
                            .font(.body)
                            .multilineTextAlignment(.center)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.top, 28)
                    .padding(.horizontal, 40)

                    Spacer()

                    VStack(spacing: 16) {
                        Button("Get Started") {
                            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                                isOnBoarding.toggle()
                            }
                        }
                        .buttonStyle(GlassButtonStyle.glassProminent)
                        .tint(.blue)
                        .controlSize(.large)
                        .accessibilityHint("Opens the main sleep schedule")

                        Text("By continuing, you agree to Ninety's \n**Terms of Service** and **Privacy Policy.**")
                            .font(.footnote)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.horizontal, 40)
                    .padding(.bottom, 48)
                }
            }
        } else {
            ScheduleView()
        }
    }
}

#Preview {
    OnboardingView()
}
