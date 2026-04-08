//
//  SleepSettingsView.swift
//  Ninety
//
//  Created by Deimante Valunaite on 07/07/2024.
//

import CoreML
import SwiftUI

struct SleepSettingsView: View {
    @ObservedObject var sleepingViewModel = SleepSettingsViewModel()
    
    var body: some View {
        NavigationStack {
            Form {
                VStack {
                    DatePicker("Wake up time", selection: $sleepingViewModel.wakeUp, displayedComponents: .hourAndMinute)
                        .datePickerStyle(.wheel)
                        .labelsHidden()
                        .frame(maxWidth: .infinity, alignment: .center)
                }
                .padding(.vertical)
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets())
                
                Section(header: Text("Sleep Duration")) {
                    Stepper(value: $sleepingViewModel.sleepAmount, in: 4...12, step: 0.25) {
                        HStack {
                            Text("Amount of sleep")
                            Spacer()
                            Text("\(sleepingViewModel.sleepAmount.formatted()) hours")
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                Section(header: Text("Daily Habits")) {
                    Stepper(value: $sleepingViewModel.coffeeAmount, in: 1...20) {
                        HStack {
                            Text("Coffee intake")
                            Spacer()
                            Text("^[\(sleepingViewModel.coffeeAmount) cup](inflect: true)")
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .navigationTitle("Best Sleeping Time")
            .navigationBarTitleDisplayMode(.automatic)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("Calculate") {
                        sleepingViewModel.calculateBedTime()
                    }
                    .bold()
                }
            }
            .alert(sleepingViewModel.alertTitle, isPresented: $sleepingViewModel.showingAlert) {
                Button("OK") { }
            } message: {
                Text(sleepingViewModel.alertMessage)
            }
        }
    }
}

#Preview {
    SleepSettingsView()
}
