import SwiftUI

struct RootTabView: View {
    @State private var selection = 0
    @State private var showingEntry = false

    var body: some View {
        Group {
            switch selection {
            case 2: OverviewView()
            case 3: PersonalCenterView()
            default: DetailView()
            }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            LedgerTabBar(selection: $selection, showingEntry: $showingEntry)
        }
        .sheet(isPresented: $showingEntry) {
            TransactionEntryView()
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
    }
}

private struct LedgerTabBar: View {
    @Binding var selection: Int
    @Binding var showingEntry: Bool

    var body: some View {
        HStack(spacing: 0) {
            tabButton(title: "明细", symbol: "list.bullet.rectangle", value: 0)

            Button { showingEntry = true } label: {
                VStack(spacing: 3) {
                    Image(systemName: "plus")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(width: 48, height: 48)
                        .background(Color.brandBlue, in: Circle())
                        .shadow(color: Color.brandBlue.opacity(0.28), radius: 8, y: 4)
                    Text("记一笔")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            .buttonStyle(.plain)
            .accessibilityLabel("记一笔")
            .frame(maxWidth: .infinity)

            tabButton(title: "总览", symbol: "chart.bar.fill", value: 2)
            tabButton(title: "我的", symbol: "person.crop.circle", value: 3)
        }
        .padding(.top, 8)
        .padding(.bottom, 4)
        .background(.ultraThinMaterial)
        .overlay(alignment: .top) { Divider() }
    }

    private func tabButton(title: String, symbol: String, value: Int) -> some View {
        Button { selection = value } label: {
            VStack(spacing: 4) {
                Image(systemName: symbol)
                    .font(.system(size: 19, weight: selection == value ? .semibold : .regular))
                Text(title).font(.caption2)
            }
            .foregroundStyle(selection == value ? Color.brandBlue : Color.secondary)
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
