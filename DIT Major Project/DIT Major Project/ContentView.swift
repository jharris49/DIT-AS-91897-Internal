//
//  ContentView.swift
//  DIT Major Project
//
//  Created by Josh Harris on 03/06/2025.
//

import SwiftUI

struct HomeView: View {
    @State var selectedTab = 0
    @State var time = ""
    var body: some View {
        TabView (selection: $selectedTab) {
            InputView(selectedTab: $selectedTab, time: $time)
                .tabItem{
                    Label("Input Data", systemImage: "rectangle.and.pencil.and.ellipsis")
                }
                .tag(0)
            DataView(time: $time)
                .tabItem {
                    Label("View Data", systemImage: "chart.pie.fill")
                        }
                .tag(1)
                }
        }
    }

struct InputView: View {
    @Binding var selectedTab: Int
    @Binding var time: String
    @State private var message = ""
    var body: some View {
        VStack(spacing: 20) {
            TextField("Enter some data to begin", text: $time)
                .textFieldStyle(.roundedBorder)
                .padding()
            Button {
                let intTime = Int(time) ?? 0
                message = "\(intTime) saved"
                selectedTab = 1
            } label: {
                Text("Confirm")
            }
            .buttonStyle(.bordered)
            Text(message)
        
            }
        }
    }


struct DataView: View {
    @Binding var time: String
    var body: some View {
        if time == "0" {
            Text("Please enter some hours")
        } else {
            let yearlyTime = (Int(time) ?? 0) * 365
            Text("At this rate you will spend \(yearlyTime) hours on your phone this year")
            
        }
    }
}


#Preview {
    HomeView()
}
