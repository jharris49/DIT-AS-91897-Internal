//
//  ContentView.swift
//  DIT Major Project
//
//  Created by Josh Harris on 03/06/2025.
//

import SwiftUI
import Charts
import CoreData

// Creates the tabs on the bottom
struct HomeView: View {
    @State var selectedTab = 0
    @State var time = ""
    var body: some View {
        // Creates a a tabview, this is the options on the bottom
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
    @Environment(\.managedObjectContext) private var viewContext
    
    @Binding var selectedTab: Int
    @Binding var time: String
    @State private var showTabs = true
    @State private var message = ""
    @State private var selectedDate = Date()
    
    var body: some View {
        NavigationStack{
            VStack {
                Form {
                    Section ("Screen Time") {
                        LabeledContent {
                            TextField("Screentime (Hours)", text: $time)
                                .multilineTextAlignment(.trailing)
                        } label: {
                            Text("Hours")
                        }
                        DatePicker("Date",
                                   selection: $selectedDate,
                                   displayedComponents: [.date])
                        Button {
                            selectedTab = 1
                            addData()
                        } label: {
                            Text("Confirm")
                        }.frame(maxWidth: .infinity)
                    }
                }
                .navigationTitle("Input Data")
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .toolbar{
                    ToolbarItem(placement: .navigationBarLeading) { NavigationLink(
                        destination: AccountView()){
                            Image(systemName: "person.crop.circle.fill")
                        }
                    }
                    ToolbarItem(placement: .navigationBarTrailing) {
                        NavigationLink(
                            destination: HelpView()){
                                Image(systemName: "questionmark")
                            }
                    }
                }
            }
        }
    }
    func addData() {
        let newData = Screentime(context: viewContext)
        newData.date = selectedDate
        newData.hours = Int64(time) ?? 0
        do {
            try viewContext.save()
        } catch {
    
        }
    }
}
  

struct DataView: View {
    @Binding var time: String
    var body: some View {
        NavigationView {
            VStack {
            let yearlyTime = (Int(time) ?? 0 ) * 365
            if yearlyTime == 0 {
                Text("Please enter some hours")
            } else {
                Text("At this rate you will spend \(yearlyTime) hours on your phone this year")
            }
        }
        .navigationTitle("Data")
        .toolbar{
            ToolbarItem(placement: .navigationBarLeading) { NavigationLink(
                destination: AccountView()){
                    Image(systemName: "person.crop.circle.fill")
                }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                NavigationLink(
                    destination: HelpView()){
                        Image(systemName: "questionmark")
                    }
            }
            }
        }
    }
}


struct AccountView: View {
    var body: some View {
        VStack{
            Text("")
            .navigationTitle("Account Details")
        }
        
    }
}



struct HelpView: View {
    var body: some View {
        VStack{
            Text("")
            .navigationTitle("Help")
        }
    }
}

#Preview {
    HomeView()
}
