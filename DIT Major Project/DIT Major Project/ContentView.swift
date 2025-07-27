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
    @State var showAlert = false
    @State var hoursAsleep = 8
    @State var minutesAsleep = 0
    
    private var sleepPicker: some View {
        HStack {
            Picker("", selection: $hoursAsleep){
                ForEach(0..<25) {
                    Text("\($0) hours")
                }
            }
            if hoursAsleep < 24 {
                Picker("",selection: $minutesAsleep){
                    ForEach(0..<60){
                        Text("\($0) minutes")
                    }
                }
            } else {
                Picker("",selection: $minutesAsleep){
                        Text("0 minutes")
                    }
                }
            }
        .pickerStyle(.wheel)
            .clipped()
            .frame(height: 80)
    }
    
    var tooManyHours: Bool {
        if (Double(time) ?? 0) > 24 || (Double(time) ?? 0) < 0 {
            return true
        } else {
            return false
        }
    }
    
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
                    }
                    Section ("Other") {
                        HStack{
                        LabeledContent(content: { sleepPicker }, label: { Text("Sleep") })
                        }
                    }
                    Button {
                        if !tooManyHours {
                            selectedTab = 1
                            addData()
                        } else {
                            showAlert = true
                        }
                    } label: {
                        Text("Confirm")
                    }.frame(maxWidth: .infinity)
                }
                .navigationTitle("Input Data")
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .toolbar{ mainToolbar()}
            }
            .alert("Invalid Hours", isPresented: $showAlert) {
                Button("Ok", role: .cancel) {}
            } message: {
                Text("Please enter a valid value")
            }
        }
    }
    func addData() {
        let totalTimeAsleep = Double(hoursAsleep) + Double(minutesAsleep)/60
            let newData = DailyData(context: viewContext)
            newData.date = selectedDate
            newData.screentime = Double(time) ?? 0
            newData.sleeptime = totalTimeAsleep
            do {
                try viewContext.save()
            } catch {
                
            }
        }
}


struct mainToolbar: ToolbarContent {
    var body: some ToolbarContent {
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

struct pChartData: Identifiable {
    var id = UUID()
    var category: String
    var hours: Double
}

struct DataView: View {
    @Environment(\.managedObjectContext) private var viewContext
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \DailyData.date, ascending: true)]
    ) var allData: FetchedResults<DailyData>
    @State private var wantedDate = Date()
    
    
    var body: some View {
        var todayData: [DailyData] {
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
        
        var screenTimeToday: [DailyData] {
            return todayData.filter { data in
                return data.screentime > 0
            }
        }
        
        var screenTimeDouble: Double {
            var total: Double = 0
               for entry in screenTimeToday {
                   total += entry.screentime
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
                .toolbar{mainToolbar()}
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
    
    let sample = DailyData(context: context)
    let sample2 = DailyData(context: context)
    let components = DateComponents(year: 2025, month: 7, day: 23)
    sample.date = Date()
    sample.screentime = Double(5)
    sample2.date = Calendar.current.date(from: components)!
    sample2.screentime = Double(10)
       
    return HomeView()
           .environment(\.managedObjectContext, context)
}
