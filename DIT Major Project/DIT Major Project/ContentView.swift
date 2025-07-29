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
    @State var showErrorAlert = false
    @State var showConfirmAlert = false
    @State var confirmBanner = false
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
    
    var invalidHours: Bool {
        if (Double(time) ?? 0) > 24 || (Double(time) ?? 0) < 0 {
            return true
        } else {
            return false
        }
    }
    
    var body: some View {
        NavigationStack{
            ZStack{
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
                            if !invalidHours {
                                showConfirmAlert = true
                            } else {
                                showErrorAlert = true
                            }
                        } label: {
                            Text("Confirm")
                        }.frame(maxWidth: .infinity)
                    }
                    .navigationTitle("Input Data")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .toolbar{ mainToolbar()}
                }
                .alert("Are you sure you want to save this data?", isPresented: $showConfirmAlert){
                    Button("No", role:.cancel){}
                    Button("Yes"){
                        addData()
                        confirmBanner = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                            confirmBanner = false
                            selectedTab = 1
                        }
                    }
                }
                .alert("Invalid Hours", isPresented: $showErrorAlert) {
                    Button("Ok", role: .cancel) {}
                } message: {
                    Text("Please enter a valid value")
                }
                if confirmBanner {
                    VStack{
                        ZStack{
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.gray.opacity(0.199))
                                .frame(width: 130, height: 100)
                            VStack {
                                Text("Data Saved")
                                    .foregroundStyle(.gray)
                                Image(systemName: "checkmark.icloud.fill")
                                    .foregroundStyle(.gray)
                            }
                        }
                    }
                }
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
        ToolbarItem(placement: .navigationBarLeading) {
            NavigationLink(
            destination: SettingsView()){
                Image(systemName: "gear")
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
    var body: some View {
        NavigationStack{
            Form{
                Section{
                    LabeledContent {
                        NavigationLink(destination: DailyAnalysis()){}
                    } label: {
                        Text("Daily Analysis")
                            .font(.title2)
                        // Image(systemName: "24.circle.fill")
                    }
                }
                .frame(height: 150)
                
                Section{
                    LabeledContent {
                        NavigationLink(destination: DataTrends()){}
                    } label: {
                        Text("Lifetime Usage")
                            .font(.title2)
                        // Image(systemName: "24.circle.fill")
                    }
                }
                .frame(height: 150)
                
                Section{
                    LabeledContent {
                        NavigationLink(destination: FunFacts()){}
                    } label: {
                        Text("Fun Facts")
                            .font(.title2)
                        // Image(systemName: "24.circle.fill")
                    }
                }
                .frame(height: 150)
            }
            .navigationTitle("View Data")
            .toolbar{ mainToolbar()}
        }
    }
}


struct FunFacts: View{
    var body: some View{
        Text("Fun facts coming")
    }
}

struct DataTrends: View{
    var body: some View{
        Text("Trends coming")
    }
}


struct DailyAnalysis: View {
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
        
        var sleepTimeToday: [DailyData] {
            return todayData.filter { data in
                return data.sleeptime > 0
            }
        }
        
        var sleepTimeDouble: Double {
            var total: Double = 0
            for entry in sleepTimeToday {
                total += entry.sleeptime
            }
            return Double(total)
        }
        
        var averageNecessities: Double = 2.5
        
        var pCatagories: [pChartData] { [
            .init(category: "Screentime", hours: screenTimeDouble),
            .init(category: "Sleep", hours: sleepTimeDouble),
            .init(category: "Necessities", hours: averageNecessities),
            .init(category: "Other", hours: 24 - screenTimeDouble - sleepTimeDouble - averageNecessities)
        ]
        }
        
        return VStack {
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
            
            .navigationTitle("Daily Insights")
        }
    }
}


struct SettingsView: View {
    var body: some View {
        VStack{
            Text("")
            .navigationTitle("Settings")
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
    let components = DateComponents(year: 2025, month: 7, day: 29)
    sample.date = Date()
    sample.screentime = Double(5)
    sample2.date = Calendar.current.date(from: components)!
    sample2.screentime = Double(10)
       
    return HomeView()
           .environment(\.managedObjectContext, context)
}
