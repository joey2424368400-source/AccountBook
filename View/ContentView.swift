import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        TabView {
            NavigationStack {
                HomeView()
            }
            .tabItem {
                Label("首页", systemImage: "house.fill")
            }

            NavigationStack {
                TransactionListView()
            }
            .tabItem {
                Label("账单", systemImage: "list.bullet")
            }

            NavigationStack {
                StatisticsView()
            }
            .tabItem {
                Label("统计", systemImage: "chart.pie.fill")
            }

            NavigationStack {
                SettingsView()
            }
            .tabItem {
                Label("我的", systemImage: "gearshape")
            }
        }
        .tint(.blue)
    }
}
