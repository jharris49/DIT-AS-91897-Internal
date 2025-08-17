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
    @State private var alertMessage = ""
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
    
    var totalTimeAsleep: Double {
        Double(hoursAsleep) + Double(minutesAsleep)/60
    }
    
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \DailyData.date, ascending: true)]
    ) var allData: FetchedResults<DailyData>
    @State private var wantedDate = Date()
    
    var todayData: [DailyData] {
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: selectedDate)
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
            return data.screentime > -1
        }
    }
    
    var sleepTimeToday: [DailyData] {
        return todayData.filter { data in
            return data.sleeptime > -1
        }
    }
    
    var body: some View {
        
        var isData: Bool {
            if screenTimeToday.isEmpty && sleepTimeToday.isEmpty {
                return false
            }
            return true
        }
        
        var notDigit: Bool {
            for character in time {
                if character.isNumber || character == "."{
                    continue
                }
                return true
            }
            return false
        }
        
        var invalidHours: Bool {
            if (Double(time) ?? 0) > 24 || (Double(time) ?? 0) < 0 {
                return true
            } else if (Double(time) ?? 0) + totalTimeAsleep > 24 {
                return true
            } else if notDigit {
                return true
            } else if time.isEmpty {
                return true
            } else {
                return false
            }
        }
        
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
                            if isData {
                                alertMessage = "There is already data saved to this day"
                                showErrorAlert = true
                            }else if !invalidHours {
                                showConfirmAlert = true
                            } else {
                                showErrorAlert = true
                                alertMessage = "Invalid Hours"
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
                .alert(alertMessage, isPresented: $showErrorAlert) {
                    Button("Ok", role: .cancel) {}
                } message: {
                    Text("Please enter a valid value")
                }
                if confirmBanner {
                    VStack{
                        Spacer()
                        ZStack{
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.gray.opacity(0.199))
                                .frame(width: 130, height: 100)
                                .padding()
                            VStack {
                                Text("Data Saved")
                                    .foregroundStyle(.gray)
                                Image(systemName: "checkmark.icloud.fill")
                                    .foregroundStyle(.gray)
                            }
                        }
                        .padding(80)
                    }
                }
            }
        }
    }
    func addData() {
            let newData = DailyData(context: viewContext)
            newData.date = selectedDate
            newData.screentime = Double(time) ?? -1
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
    var dailyHours: Double
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
    @Environment(\.managedObjectContext) private var viewContext
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \DailyData.date, ascending: true)]
    ) var allData: FetchedResults<DailyData>
    @State private var wantedDate = Date()
    
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
    
    var allScreentime: [DailyData]{
        allData.filter {screentimeEntry in
            screentimeEntry.screentime > 0
        }
    }
    
    var dailyAverage: Double {
        var counter = 0
        var total: Double = 0
        
        for entry in allScreentime {
            counter += 1
            total += entry.screentime
        }
        return total / Double(counter)
    }
    
    //Dictionary ranges and items for fun facts were made with AI
    let funFacts: [ClosedRange<Double>: [String]] = [
        0.0...0.59: [
                "You barely spend any time on your device, well done!"
            ],
            0.6...1.49: [
                "year you’ll have spent about 600–700 hours — similar to the time [Chad Hurley and Steve Chen](https://en.wikipedia.org/wiki/YouTube) spent building the first prototype of YouTube in 2005.",
                "year you’ll have spent about 550–650 hours — about the time [Rob Kalin](https://en.wikipedia.org/wiki/Etsy) spent creating the first version of Etsy before launch in 2005.",
                "year you’ll have spent about 600 hours — comparable to the side‑project work [Stewart Butterfield](https://en.wikipedia.org/wiki/Slack_(software)) put into Slack while it was still part of Tiny Speck’s internal tools."
            ],
            1.5...2.99: [
                "year and a half, you will have spent about as much time as it took to build the base version of [Airbnb](https://en.wikipedia.org/wiki/Brian_Chesky) — roughly 1,300–1,400 hours.",
                "year you’ll have spent about 839 hours — roughly the time [Kevin Systrom](https://fr.wikipedia.org/wiki/Kevin_Systrom) spent developing Burbn (later Instagram) during 2010 while working full‑time at Nextstop.",
                "year you’ll have spent about 839 hours — about the time [Ben Silbermann](https://en.wikipedia.org/wiki/Pinterest) spent building Pinterest from mid‑2009 to mid‑2010 before raising seed funding.",
                "year you’ll have spent about 770 hours — similar to the time [Ryan Hoover](https://www.producthunt.com/@rrhoover) put into launching Product Hunt as an email list and early site."
            ],
            3.0...4.99: [
                "year you’ll have spent about 1,640 hours — roughly how much time [Reed Hastings](https://en.wikipedia.org/wiki/Reed_Hastings) spent iterating Netflix’s streaming platform in its first year.",
                "year you’ll have spent about 1,277 hours — similar to how [Jack Dorsey](https://en.wikipedia.org/wiki/Jack_Dorsey) prototyped Twitter at Odeo over ~12 months before traction.",
                "year you’ll have spent about 1,460 hours — close to [Evan Williams](https://en.wikipedia.org/wiki/Evan_Williams_(Internet_entrepreneur))’s effort building Blogger while managing other projects.",
                "year you’ll have spent about 1,200–1,300 hours — comparable to the early [Dropbox](https://en.wikipedia.org/wiki/Dropbox_(service)) MVP development before YC."
            ],
            5.0...7.99: [
                "year you’ll have spent about 2,190 hours — comparable to [Jeff Bezos](https://en.wikipedia.org/wiki/Jeff_Bezos)’s grind launching Amazon from his garage in its first year.",
                "year you’ll have spent about 2,373 hours — roughly the early dev hours [Twitter](https://en.wikipedia.org/wiki/Twitter) team spent building scaling features in its first public year.",
                "year you’ll have spent about 2,555 hours — akin to the energy [Mark Zuckerberg](https://en.wikipedia.org/wiki/Mark_Zuckerberg) put into Facebook’s Harvard dorm‑room year.",
                "year you’ll have spent about 2,117 hours — comparable to [Jack Dorsey](https://en.wikipedia.org/wiki/Jack_Dorsey)’s early [Square](https://en.wikipedia.org/wiki/Square,_Inc.) prototypes."
            ],
            8.0...11.99: [
                "year you’ll have spent about 3,102 hours — close to [Shigeru Miyamoto](https://en.wikipedia.org/wiki/Shigeru_Miyamoto)’s Nintendo team development of *The Legend of Zelda: Ocarina of Time* (Nintendo 64, 1998).",
                "year you’ll have spent about 3,285 hours — similar to [J.K. Rowling](https://en.wikipedia.org/wiki/J._K._Rowling)’s full‑time drafting of *Harry Potter and the Philosopher’s Stone*.",
                "year you’ll have spent about 3,650 hours — comparable to core development for a AAA game like [Grand Theft Auto V](https://en.wikipedia.org/wiki/Grand_Theft_Auto_V).",
                "year you’ll have spent about 4,015 hours — similar to Apple’s [iPhone](https://en.wikipedia.org/wiki/IPhone) first‑year development sprint."
            ],
            12.0...15.99: [
                "year you’ll have spent about 4,745 hours — like the intense crunch period of a [Triple‑A game](https://en.wikipedia.org/wiki/Video_game_development) in production.",
                "year you’ll have spent about 5,110 hours — similar to the founder grind scaling [Uber](https://en.wikipedia.org/wiki/Uber) pre‑Series A.",
                "year you’ll have spent about 4,928 hours — close to the hours devoted by [SpaceX](https://en.wikipedia.org/wiki/SpaceX) engineers during Falcon 1 development.",
                "year you’ll have spent about 4,453 hours — akin to the [Apple Macintosh](https://en.wikipedia.org/wiki/Macintosh) team’s sprint before launch."
            ],
            16.0...20.0: [
                "year you’ll have spent about 6,205 hours — similar to [Travis Kalanick](https://en.wikipedia.org/wiki/Travis_Kalanick)’s 24/7 startup grind scaling Uber early on.",
                "year you’ll have spent about 6,570 hours — comparable to [Steve Jobs](https://en.wikipedia.org/wiki/Steve_Jobs)’s late‑night sprints finishing the first Macintosh.",
                "year you’ll have spent about 6,935 hours — akin to Amazon’s all‑hands‑on‑deck push for Prime shipping rollout.",
                "year you’ll have spent about 6,388 hours — comparable to [Reddit](https://en.wikipedia.org/wiki/Reddit) founders’ intense first‑year iteration and scaling."
            ]
]
    var body: some View {
        let randomFact = funFacts.first(where:{ $0.key.contains(dailyAverage)})?.value.randomElement() ?? "Nothing found"
            
        VStack{
            
            Text(.init("If you continue averaging \(dailyAverage) hours of screen time per day for the next " + randomFact))
        }
        .navigationTitle("Fun Facts")
    }
}

struct lifetimeUsageData: Identifiable {
    let id = UUID()
    let graphDate: String
    let rawDate: Date
    let hours: Double
}


struct DataTrends: View{
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \DailyData.date, ascending: true)]
    ) var allData: FetchedResults<DailyData>
    
    @State var startDate = Calendar.current.date(byAdding: .day, value: -7, to: Date())!
    @State var endDate = Calendar.current.date(byAdding: .day, value: 7, to: Date())!
    
    var wantedData: [DailyData] {
        allData.filter { data in
            return data.screentime > -1 && data.date != nil
        }
    }
    
    var lineChartData: [lifetimeUsageData]{
        let df = DateFormatter()
        df.dateFormat = "d MMM"
        return wantedData.map {
            lifetimeUsageData(graphDate: df.string(from: $0.date!), rawDate: $0.date!, hours: $0.screentime)
        }
    }
    
    var filteredData: [lifetimeUsageData]{
        lineChartData.filter {entry in
            entry.rawDate >= startDate && entry.rawDate <= endDate
        }
    }
    
    var body: some View {
        VStack {
                DatePicker("Start Date",
                           selection: $startDate ,
                           displayedComponents: [.date])
                .padding(5)
                DatePicker("End Date",
                           selection: $endDate,
                           displayedComponents: [.date])
                .padding(5)
                Chart {
                    ForEach(filteredData) { data in
                        LineMark(
                            x: .value("Day", data.graphDate as String),
                            y: .value("Hours", data.hours)
                        )
                        AreaMark( x: .value("Day", data.graphDate as String),
                                  y: .value("Hours", data.hours)
                        )
                        .foregroundStyle(.blue.opacity(0.2))
                        PointMark(
                            x: .value("Day", data.graphDate as String),
                            y: .value("Hours", data.hours)
                        )
                    }
                }
                .chartYScale(domain: 0...24)
            }
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
                return data.screentime > -1
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
                return data.sleeptime > -1
            }
        }
        
        var sleepTimeDouble: Double {
            var total: Double = 0
            for entry in sleepTimeToday {
                total += entry.sleeptime
            }
            return Double(total)
        }
        
        var otherHours: Double {
            let other = 24 - screenTimeDouble - sleepTimeDouble - averageNecessities
            
            if other < 0 {
                return 0.0
            }
            return other
        }
        
        var averageNecessities: Double {
            let hours = sleepTimeDouble + screenTimeDouble + 2.5
            
            if hours >= 24 {
                return 0.0
            }
            return 2.5
        }
        
        var pCatagories: [pChartData] { [
            .init(category: "Screentime", dailyHours: screenTimeDouble),
            .init(category: "Sleep", dailyHours: sleepTimeDouble),
            .init(category: "Necessities", dailyHours: averageNecessities),
            .init(category: "Other", dailyHours: otherHours)
        ]
        }
        
        var isData: Bool {
            if screenTimeToday.isEmpty && sleepTimeToday.isEmpty {
                return false
            }
            return true
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
                Spacer()
                if isData {
                Chart(pCatagories) { category in
                    SectorMark(
                        angle: .value(Text(verbatim: category.category), category.dailyHours), innerRadius: .ratio(0.5),
                        angularInset: 2
                    )
                    
                    .foregroundStyle(by: .value(Text(verbatim: category.category), category.category))
                    .annotation(position: .overlay) {
                        if category.dailyHours > 0 {
                            Text("\(String(format: "%.0f", category.dailyHours * 100/24))% (\(String(format: "%.1f", category.dailyHours))h)")
                                .foregroundStyle(.white)
                                .font(.system(size:12))
                        }
                        
                    }
                }
                .padding(.bottom, -10)
            }
                else {
                    ZStack{
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.gray.opacity(0.199))
                            .frame(width: 200, height: 150)
                            .padding()
                        VStack {
                            Text("No Data Found")
                                .foregroundStyle(.gray)
                                .padding(5)
                            Image(systemName: "exclamationmark.arrow.triangle.2.circlepath")
                                .foregroundStyle(.gray)
                                .font(.system(size: 30))
                        }
                        .font(.title3)
                    }
                }
                Spacer()
        }
            .padding(35)
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
    let components = DateComponents(year: 2025, month: 8, day: 20)
    sample.date = Date()
    sample.screentime = Double(5)
    sample2.date = Calendar.current.date(from: components)!
    sample2.screentime = Double(10)
       
    return HomeView()
           .environment(\.managedObjectContext, context)
}
