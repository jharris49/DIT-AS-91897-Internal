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
            DataView()
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
        newData.hours = Double(time) ?? 0
        do {
            try viewContext.save()
        } catch {
    
        }
    }
    
}

struct pChartData: Identifiable {
    var id = UUID()
    var category: String
    var hours: Double
}

struct DataView: View {
    @Environment(\.managedObjectContext) private var viewContext
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Screentime.date, ascending: true)]
    ) var allData: FetchedResults<Screentime>
    @State private var wantedDate = Date()
    
    
    var body: some View {
        var todayData: [Screentime] {
            let calendar = Calendar.current
            let start = calendar.startOfDay(for: wantedDate)
            let end = calendar.date(byAdding: .day, value: 1, to: start)!
            
            return allData.filter { entry in
                if let date = entry.date {
                    return date >= start && date < end
                }
                return false
            }
        }
        
        var screenTimeToday: [Screentime] {
            return todayData.filter { data in
                return data.hours > 0
            }
        }
        
        var screenTimeDouble: Double {
            var total: Double = 0
               for entry in screenTimeToday {
                   total += entry.hours
               }
               return Double(total)
        }
        
        var averageSleep: Double = 8
        var averageNecessities: Double = 2.5
        
        var pCatagories: [pChartData] { [
            .init(category: "Screentime", hours: screenTimeDouble),
            .init(category: "Sleep", hours: averageSleep),
            .init(category: "Necessities", hours: averageNecessities),
            .init(category: "Other", hours: 24 - screenTimeDouble - averageSleep - averageNecessities)
        ]
        }
        
        return NavigationView {
            VStack {
                HStack{
                    Button {
                        wantedDate = Calendar.current.date(byAdding: .day, value: -1, to: wantedDate)!
                        
                    } label: {
                        Image(systemName: "arrowshape.left.fill")
                    }
                    DatePicker("", selection: $wantedDate, displayedComponents: [.date])
                        .labelsHidden()
                    Button {
                        wantedDate = Calendar.current.date(byAdding: .day, value: 1, to: wantedDate)!
                        
                    } label: {
                        Image(systemName: "arrowshape.right.fill")
                    }
                }
                VStack(spacing: 1) {
                    
                    Chart(pCatagories) { category in
                        SectorMark(
                            angle: .value(Text(verbatim: category.category), category.hours), innerRadius: .ratio(0.5),
                            angularInset: 2
                        )
                        
                        .foregroundStyle(by: .value(Text(verbatim: category.category), category.category))
                        .annotation(position: .overlay) {
                            Text("\(String(format: "%.0f", category.hours * 100/24))% (\(String(format: "%.1f", category.hours))h)")
                                .foregroundStyle(.white)
                                .font(.system(size:12))
                    }
            
                    }
                    .padding(.bottom, -10)
                }
                .padding(35)
                
                    /*
                     List(todayData) { entry in
                         Text("Hours: \(String(format: "%.1f", entry.hours))")
                     Text("Date: \(entry.date?.formatted() ?? "Unknown")")
                     }
                     */
                
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
    let context = PersistenceController.preview.container.viewContext
    
    let sample = Screentime(context: context)
    let sample2 = Screentime(context: context)
    let components = DateComponents(year: 2025, month: 7, day: 23)
    sample.date = Date()
    sample.hours = Double(5)
    sample2.date = Calendar.current.date(from: components)!
    sample2.hours = Double(10)
       
    return HomeView()
           .environment(\.managedObjectContext, context)
}
