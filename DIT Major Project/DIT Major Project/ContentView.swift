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
    @State var showStoragePermissionAlert = false
    @AppStorage("storagePermission") var storagePermission = false
    @AppStorage("askedPermissionOnce") var askedPermissionOnce = false
    @AppStorage("darkMode") var darkMode = false
    
    var homeViewTabs: some View {
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
    var body: some View {
        VStack{
            if storagePermission || !askedPermissionOnce {
                homeViewTabs
            } else {
                BlockedView()
                }
        }
            .tint(.indigo)
            .onAppear{
                if  !askedPermissionOnce {
                    showStoragePermissionAlert = true
                }
            }
            .alert("Data Storage Permission", isPresented: $showStoragePermissionAlert){
                Button("Allow"){
                    storagePermission = true
                    askedPermissionOnce = true
                }
                Button("Deny"){
                    storagePermission = false
                    askedPermissionOnce = true
                }
            } message: {
                Text("Do you allow this app to store your screen time and sleep time data locally?")
            }
            .preferredColorScheme(darkMode ? .dark : .light)
        }
    }

struct BlockedView: View {
    @State var showSettings = false
    var body: some View {
        NavigationStack {
                ZStack(alignment: .top){
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.gray.opacity(0.199))
                    .frame(width: 350, height: 400)
                VStack{
                    Image(systemName: "exclamationmark.shield.fill")
                        .foregroundStyle(.gray)
                        .font(.system(size: 65, weight: .bold, design: .default))
                    Text("Sorry, this app cannot be used without this permission. Please go to settings and allow this app to access your device storage if you wish to use it.")
                        .multilineTextAlignment(.center)
                        .padding(.top, 3)
                        .padding(.horizontal, 50)
                        .font(.title3)
                        .foregroundStyle(.gray)
                    
                    Button("Open Settings Here"){
                        showSettings.toggle()
                    }
                    .font(.title2)
                    .padding(15)
                    .navigationDestination(isPresented: $showSettings) {
                        SettingsView()
                    }
                    Text("Or")
                        .multilineTextAlignment(.center)
                        .padding(.top, 3)
                        .padding(.horizontal, 50)
                        .font(.title3)
                        .foregroundStyle(.gray)
                    Button("Close the app"){
                        UIApplication.shared.perform(#selector(NSXPCConnection.suspend))
                    }
                    .font(.title2)
                    .foregroundStyle(.red)
                    .padding(15)
                }
                .frame(maxHeight: 550, alignment: .top)
            }
            .padding(.top, 20)
            Spacer()
        .navigationTitle("Permission Required")
        .toolbar{ mainToolbar()}
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
    @FocusState var keyBoardClosed: Bool
    
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
                                    .keyboardType(.decimalPad)
                                    .focused($keyBoardClosed)
                                    .submitLabel(.done)
                                    .onSubmit{
                                        keyBoardClosed = false
                                    }
                                    .toolbar {
                                        ToolbarItemGroup(placement: .keyboard)
                                        {
                                            Spacer()
                                            Button("Done") {
                                                keyBoardClosed = false
                                            }
                                        }
                                    }
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
                                keyBoardClosed = false
                            } else {
                                showErrorAlert = true
                                alertMessage = "Invalid Hours"
                            }
                        }
                        label: {
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
                    }
                }
                .frame(height: 150)
                
                Section{
                    LabeledContent {
                        NavigationLink(destination: DataTrends()){}
                    } label: {
                        Text("Lifetime Usage")
                            .font(.title2)
                    }
                }
                .frame(height: 150)
                
                Section{
                    LabeledContent {
                        NavigationLink(destination: FunFacts()){}
                    } label: {
                        Text("Fun Facts")
                            .font(.title2)
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
            "year you’ll have spent about **600–700 hours** — similar to the time [Chad Hurley and Steve Chen](https://en.wikipedia.org/wiki/YouTube) spent building the first prototype of YouTube in 2005.",
            "year you’ll have spent about **550–650 hours** — about the time [Rob Kalin](https://en.wikipedia.org/wiki/Etsy) spent creating the first version of Etsy before launch in 2005.",
            "year you’ll have spent about **600 hours** — comparable to the side‑project work [Stewart Butterfield](https://en.wikipedia.org/wiki/Slack_(software)) put into Slack while it was still part of Tiny Speck’s internal tools."
        ],
        1.5...2.99: [
            "year and a half, you will have spent about as much time as it took to build the base version of [Airbnb](https://en.wikipedia.org/wiki/Brian_Chesky) — roughly **1,300–1,400 hours**.",
            "year you’ll have spent about **839 hours** — roughly the time [Kevin Systrom](https://fr.wikipedia.org/wiki/Kevin_Systrom) spent developing Burbn (later Instagram) during 2010 while working full‑time at Nextstop.",
            "year you’ll have spent about **839 hours** — about the time [Ben Silbermann](https://en.wikipedia.org/wiki/Pinterest) spent building Pinterest from mid‑2009 to mid‑2010 before raising seed funding.",
            "year you’ll have spent about **770 hours** — similar to the time [Ryan Hoover](https://www.producthunt.com/@rrhoover) put into launching Product Hunt as an email list and early site."
        ],
        3.0...4.99: [
            "year you’ll have spent about **1,640 hours** — roughly how much time [Reed Hastings](https://en.wikipedia.org/wiki/Reed_Hastings) spent iterating Netflix’s streaming platform in its first year.",
            "year you’ll have spent about **1,277 hours** — similar to how [Jack Dorsey](https://en.wikipedia.org/wiki/Jack_Dorsey) prototyped Twitter at Odeo over ~12 months before traction.",
            "year you’ll have spent about **1,460 hours** — close to [Evan Williams](https://en.wikipedia.org/wiki/Evan_Williams_(Internet_entrepreneur))’s effort building Blogger while managing other projects.",
            "year you’ll have spent about **1,200–1,300 hours** — comparable to the early [Dropbox](https://en.wikipedia.org/wiki/Dropbox_(service)) MVP development before YC."
        ],
        5.0...7.99: [
            "year you’ll have spent about **2,190 hours** — comparable to [Jeff Bezos](https://en.wikipedia.org/wiki/Jeff_Bezos)’s grind launching Amazon from his garage in its first year.",
            "year you’ll have spent about **2,373 hours** — roughly the early dev hours [Twitter](https://en.wikipedia.org/wiki/Twitter) team spent building scaling features in its first public year.",
            "year you’ll have spent about **2,555 hours** — akin to the energy [Mark Zuckerberg](https://en.wikipedia.org/wiki/Mark_Zuckerberg) put into Facebook’s Harvard dorm‑room year.",
            "year you’ll have spent about **2,117 hours** — comparable to [Jack Dorsey](https://en.wikipedia.org/wiki/Jack_Dorsey)’s early [Square](https://en.wikipedia.org/wiki/Square,_Inc.) prototypes."
        ],
        8.0...11.99: [
            "year you’ll have spent about **3,102 hours** — close to [Shigeru Miyamoto](https://en.wikipedia.org/wiki/Shigeru_Miyamoto)’s Nintendo team development of *The Legend of Zelda: Ocarina of Time* (Nintendo 64, 1998).",
            "year you’ll have spent about **3,285 hours** — similar to [J.K. Rowling](https://en.wikipedia.org/wiki/J._K._Rowling)’s full‑time drafting of *Harry Potter and the Philosopher’s Stone*.",
            "year you’ll have spent about **3,650 hours** — comparable to core development for a AAA game like [Grand Theft Auto V](https://en.wikipedia.org/wiki/Grand_Theft_Auto_V).",
            "year you’ll have spent about **4,015 hours** — similar to Apple’s [iPhone](https://en.wikipedia.org/wiki/IPhone) first‑year development sprint."
        ],
        12.0...15.99: [
            "year you’ll have spent about **4,745 hours** — like the intense crunch period of a [Triple‑A game](https://en.wikipedia.org/wiki/Video_game_development) in production.",
            "year you’ll have spent about **5,110 hours** — similar to the founder grind scaling [Uber](https://en.wikipedia.org/wiki/Uber) pre‑Series A.",
            "year you’ll have spent about **4,928 hours** — close to the hours devoted by [SpaceX](https://en.wikipedia.org/wiki/SpaceX) engineers during Falcon 1 development.",
            "year you’ll have spent about **4,453 hours** — akin to the [Apple Macintosh](https://en.wikipedia.org/wiki/Macintosh) team’s sprint before launch."
        ],
        16.0...20.0: [
            "year you’ll have spent about **6,205 hours** — similar to [Travis Kalanick](https://en.wikipedia.org/wiki/Travis_Kalanick)’s 24/7 startup grind scaling Uber early on.",
            "year you’ll have spent about **6,570 hours** — comparable to [Steve Jobs](https://en.wikipedia.org/wiki/Steve_Jobs)’s late‑night sprints finishing the first Macintosh.",
            "year you’ll have spent about **6,935 hours** — akin to Amazon’s all‑hands‑on‑deck push for Prime shipping rollout.",
            "year you’ll have spent about **6,388 hours** — comparable to [Reddit](https://en.wikipedia.org/wiki/Reddit) founders’ intense first‑year iteration and scaling."
        ]
    ]
    var body: some View {
        let randomFact = funFacts.first(where:{ $0.key.contains(dailyAverage)})?.value.randomElement() ?? "Nothing found"

            ZStack{
                Form{
                    Section{
                        VStack {
                            Text("Did you know?")
                                .font(.system(size: 30, weight: .medium))
                            Image(systemName: "sparkles")
                                .font(.system(size: 45, weight: .semibold))
                                .foregroundColor(.indigo)
                                .padding(8)
                                .padding(.bottom, 15)
                            Text(.init("If you continue averaging **\(String(format:"%.1f",dailyAverage)) hours** of screen time per day for the next " + randomFact))
                                .foregroundStyle(.gray)
                                .padding(.horizontal, 10)
                        }
                    }
                    Section{
                        VStack{
                            Text("Based on your Average")
                                .font(.system(size: 30, weight: .medium))
                                .multilineTextAlignment(.center)
                            Image(systemName: "character.book.closed.fill")
                                .font(.system(size: 45, weight: .semibold))
                                .foregroundColor(.indigo)
                                .padding(8)
                                .padding(.bottom, 15)
                            Text("Over the next year you will end up spending exactly **\(String(format:"%.1f",dailyAverage * 365)) hours** on a screen.")
                                .foregroundStyle(.gray)
                                .padding(.horizontal, 10)
                        }
                    }
            }
            .navigationTitle("Fun Facts")
        }
    }
}

struct lifetimeUsageData: Identifiable {
    let id = UUID()
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
    
    var lineChartData: [lifetimeUsageData]{
        return allData.compactMap { entry in
            guard let date = entry.date, entry.screentime >= 0 else {
                return nil
            }
            
            guard date >= startDate && date <= endDate else {
                return nil
            }
            return lifetimeUsageData(rawDate: date, hours: entry.screentime)
        }
    }
    
    var rangeAverage: Double {
        var counter = 0
        var total: Double = 0
        
        for entry in lineChartData {
            counter += 1
            total += entry.hours
        }
        return total / Double(counter)
    }
    
    var body: some View {
        VStack {
            List{
                Section(""){
                    DatePicker("Start Date",
                               selection: $startDate ,
                               displayedComponents: [.date])
                    DatePicker("End Date",
                               selection: $endDate,
                               displayedComponents: [.date])
                    Button {
                        startDate = Calendar.current.date(byAdding: .day, value: -7, to: Date())!
                        endDate = Calendar.current.date(byAdding: .day, value: 7, to: Date())!
                    } label: {
                        Text("Reset to Default Range")
                    }
                    .frame(maxWidth: .infinity)
                }
                Section(""){
                    if !lineChartData.isEmpty {
                        Chart(lineChartData) { data in
                            LineMark(
                                x: .value("Day", data.rawDate),
                                y: .value("Hours", data.hours)
                            )
                            .interpolationMethod(.catmullRom)
                            AreaMark(x: .value("Day", data.rawDate),
                                     y: .value("Hours", data.hours)
                            )
                            .foregroundStyle(.indigo.opacity(0.2))
                            .interpolationMethod(.catmullRom)
                            PointMark(
                                x: .value("Day", data.rawDate),
                                y: .value("Hours", data.hours)
                            )
                            .symbolSize(25)
                            RuleMark(y: .value("avg", rangeAverage))
                                .lineStyle(StrokeStyle(lineWidth: 1, dash: [5]))
                                .foregroundStyle(.gray)
                                .annotation(alignment: .topLeading) {
                                    Text("avg: \(String(format: "%.1f",rangeAverage))")
                                            .font(.caption)
                                            .foregroundStyle(.gray)
                                    }
                        }
                        .frame(maxHeight: 600)
                        .aspectRatio(0.9, contentMode: .fit )
                        .chartYAxis {
                            AxisMarks(values: [0, 5, 10, 15, 20, 24]){ value in
                                AxisGridLine()
                                AxisValueLabel()
                            }
                        }
                        .chartXScale(domain: startDate...endDate)
                        .chartXAxisLabel(position: .bottom, alignment:.center){
                            Text("Date")
                                .font(.subheadline)
                        }
                        .chartYAxisLabel(position: .trailing, alignment:.center){
                            Text("Hours")
                                .font(.subheadline)
                        }
                    } else {
                        Text("No data to display. Please input some data.")
                            .foregroundStyle(.secondary)
                            .padding()
                    }
                }
            }
        }
        .navigationTitle("Lifetime Usage")
    }
}



struct DailyAnalysis: View {
    @Environment(\.managedObjectContext) private var viewContext
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \DailyData.date, ascending: true)]
    ) var allData: FetchedResults<DailyData>
    @State private var wantedDate = Date()
    
    @AppStorage("averageNecessitiesHours") var averageNecessitiesHours = 2.0
    @AppStorage("averageNecessitiesTenths") var averageNecessitiesTenths = 5.0
    
    var averageNecessitiesOverride: Double {
        averageNecessitiesHours + averageNecessitiesTenths/10
    }
    
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
            let hours = sleepTimeDouble + screenTimeDouble + averageNecessitiesOverride
            
            if hours >= 24 {
                return 0.0
            }
            return averageNecessitiesOverride
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
                            Text("\(String(format: "%.0f", category.dailyHours * 100/24))%\n(\(String(format: "%.1f", category.dailyHours))h)")
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
    @AppStorage("darkMode") var darkMode = false
    @AppStorage("averageNecessitiesHours") var averageNecessitiesHours = 2.0
    @AppStorage("averageNecessitiesTenths") var averageNecessitiesTenths = 5.0
    
    @AppStorage("storagePermission") var storagePermission = false
    
    var body: some View {
        VStack{
            Form {
                Section ("Appearence") {
                    Toggle("Dark Mode", isOn: $darkMode)
                }
                Section ("Daily Analysis") {
                    LabeledContent(content: {
                        HStack{
                            Picker("", selection: $averageNecessitiesHours){
                                ForEach(0..<25) { hour in
                                    Text("\(hour)").tag(Double(hour))
                                }
                            }
                            Text(".")
                            Picker("", selection: $averageNecessitiesTenths){
                                ForEach(0..<10) { tenth in
                                    Text("\(tenth)").tag(Double(tenth))
                                }
                            }
                        }
                    }, label: { Text("Daily Necessities")
                        Text("(average: 2.5 hours)")})
                    .pickerStyle(.wheel)
                    Button{
                        averageNecessitiesHours = 2.0
                        averageNecessitiesTenths = 5.0
                    } label: {
                        Text("Reset to Default")
                    }.frame(maxWidth: .infinity)
                }
                .preferredColorScheme(darkMode ? .dark : .light)
                Section("Permissions"){
                    Toggle("Device Storage", isOn: $storagePermission)
                }
            }
        }
        .navigationTitle("Settings")
    }
}


//The paragraphs and text in the help menu were created with AI, all of the code is made by me though.
struct HelpView: View {
    @AppStorage("showGettingStarted") var showGettingStarted = true
    var body: some View {
        NavigationStack {
            Form {
                DisclosureGroup("Getting Started", isExpanded: $showGettingStarted) {
                    Text("Enter data in the input data page to begin saving and then viewing insights. \n\nTo use this app, you need to allow local storage access. Without it, data cannot be saved. If you deny permission the first time, you can enable it later in Settings.")
                        .font(.body)
                }
                
                DisclosureGroup("Entering Data"){
                    Text("Enter your daily screen time in hours. You can also record your sleep using the hour/minute picker. Make sure the total of screen time and sleep doesn’t exceed 24 hours. You can't enter data twice for the same day. Be careful when saving data, you can't edit it once confirmed. Use the **Confirm** button to save.")
                        .font(.body)
                }
                
                DisclosureGroup("Daily Analysis"){
                    Text("This page shows a pie chart of your day split into Screen Time, Sleep, Necessities (set in Settings), and Other. Use the arrows or date picker to switch between days.")
                        .font(.body)
                }
                
                DisclosureGroup("Lifetime Insights"){
                    Text("See your screen time over a chosen date range. The graph includes an average line to help compare trends. Adjust the date range with the pickers or reset to the default one-week view.")
                        .font(.body)
                }
                
                DisclosureGroup("Fun Facts"){
                    Text("Based on your daily average, you’ll see a fun fact that correlates tou your expected screen time over the next x amount of time.")
                        .font(.body)
                }
                
                DisclosureGroup("Settings Menu"){
                    Text("• **Dark Mode**: Toggle between light and dark theme.\n• **Daily Necessities**: Set the average hours you spend on necessities (work, study, chores, bathroom). This affects the Daily Analysis pie chart.\n• **Device Storage**: Enable or disable permission to save your data.")
                        .font(.body)
                }
                DisclosureGroup("Other Tips"){
                    Text("• Enter data consistently for the best insights.\n• Use Daily Analysis to spot imbalances.\n• Compare long-term trends in Lifetime Usage.\n\nIf you experience issues, try resetting permissions in Settings or restarting the app. Or contact us")
                        .font(.body)
                }
                Section {
                } footer: {
                    Link("Contact Us", destination: URL(string: "mailto:22jharris@wakatipu.school.nz?subject=App%20Support")!)
                        .font(.footnote)
                        .frame(maxWidth: .infinity, alignment: .center)
                    
                }
            }
            .navigationTitle("Help")
        }
    }
}

#Preview {
    let context = PersistenceController.preview.container.viewContext
    let sample = DailyData(context: context)
    let sample2 = DailyData(context: context)
    let samplecomponents1 = DateComponents(year: 2025, month: 8, day: 19)
    sample.date = Date()
    sample.screentime = Double(5)
    sample2.date = Calendar.current.date(from: samplecomponents1)!
    sample2.screentime = Double(10)
       
    return HomeView()
           .environment(\.managedObjectContext, context)
}
