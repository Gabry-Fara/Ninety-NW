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
            NavigationStack {
                ZStack {
                    HorizonBackground()
                        .ignoresSafeArea()
                    
                    VStack(spacing: 30) {
                        Spacer()
                        
                        Image("Logo design")
                            .resizable()
                            .scaledToFit()
                            .frame(height: 200)
                            .glassEffect(.clear, in: Circle())
                        
                        VStack(spacing: 20) {
                            Text("Track Your Sleep Pattern and Improve it")
                                .font(.largeTitle.bold())
                                .multilineTextAlignment(.center)
                            
                            Text("Get insights into your sleep habits and wake up refreshed with Ninety")
                                .font(.body)
                                .multilineTextAlignment(.center)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.horizontal, 40)
                        
                        Spacer()
                        
                        VStack(spacing: 20) {
                            Button("Get Started") {
                                withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                                    isOnBoarding.toggle()
                                }
                            }
                            .buttonStyle(GlassButtonStyle.glassProminent)
                            .tint(.blue)
                            .controlSize(.large)
                            
                            Text("By continuing, you agree to Ninety's \n**Terms of Service** and **Privacy Policy.**")
                                .font(.footnote)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .padding(.bottom, 40)
                    }
                }
                .navigationTitle("Ninety")
                .navigationBarTitleDisplayMode(.inline)
            }
        } else {
            ScheduleView()
        }
    }
}

#Preview {
    OnboardingView()
}
