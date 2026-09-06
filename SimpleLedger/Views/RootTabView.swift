import SwiftUI

struct RootTabView: View {
    @State private var selection = 0
    @State private var previousSelection = 0
    @State private var showingEntry = false

    var body: some View {
        ZStack(alignment: .bottom) {
            TabView(selection: $selection) {
                DetailView()
                    .tag(0)
                    .tabItem { Label("明细", systemImage: "list.bullet.rectangle") }

                Color.clear
                    .tag(1)
                    .tabItem { Label("记一笔", systemImage: "plus") }

                OverviewView()
                    .tag(2)
                    .tabItem { Label("总览", systemImage: "chart.bar.fill") }
            }
            .onChange(of: selection) { newValue in
                if newValue == 1 {
                    selection = previousSelection
                    showingEntry = true
                } else {
                    previousSelection = newValue
                }
            }

            Button {
                showingEntry = true
            } label: {
                Image(systemName: "plus")
                    .font(.system(size: 25, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 58, height: 58)
                    .background(Color.brandBlue, in: Circle())
                    .shadow(color: Color.brandBlue.opacity(0.32), radius: 12, y: 6)
            }
            .accessibilityLabel("记一笔")
            .padding(.bottom, 26)
        }
        .sheet(isPresented: $showingEntry) {
            TransactionEntryView()
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
    }
}
