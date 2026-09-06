import SwiftUI

struct TransactionEntryView: View {
    @EnvironmentObject private var store: LedgerStore
    @Environment(\.dismiss) private var dismiss
    @State private var kind: TransactionKind = .expense
    @State private var amountText = ""
    @State private var note = ""
    @State private var date = Date()
    @State private var selectedCategoryID: UUID?
    @State private var showingNewCategory = false
    @State private var newCategoryName = ""
    @FocusState private var amountFocused: Bool

    private var amount: Double? {
        Double(amountText.replacingOccurrences(of: ",", with: "."))
    }

    private var canSave: Bool {
        (amount ?? 0) > 0 && selectedCategoryID != nil
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    Picker("收支类型", selection: $kind) {
                        ForEach(TransactionKind.allCases) { type in
                            Text(type.rawValue).tag(type)
                        }
                    }
                    .pickerStyle(.segmented)

                    VStack(spacing: 8) {
                        Text(kind == .expense ? "支出金额" : "收入金额")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        HStack(alignment: .firstTextBaseline, spacing: 4) {
                            Text("¥")
                                .font(.title2.weight(.semibold))
                            TextField("0", text: $amountText)
                                .font(.system(size: 48, weight: .bold, design: .rounded))
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.center)
                                .focused($amountFocused)
                                .frame(maxWidth: 240)
                        }
                        .foregroundStyle(kind.color)
                    }
                    .padding(.vertical, 8)

                    VStack(alignment: .leading, spacing: 14) {
                        HStack {
                            Text("选择分类")
                                .font(.headline)
                            Spacer()
                            Button("新增分类") { showingNewCategory = true }
                                .font(.subheadline)
                        }

                        if store.categories(for: kind).isEmpty {
                            Button { showingNewCategory = true } label: {
                                VStack(spacing: 10) {
                                    Image(systemName: "folder.badge.plus")
                                        .font(.system(size: 28, weight: .light))
                                    Text("还没有\(kind.rawValue)分类，点击新增")
                                        .font(.subheadline)
                                }
                                .foregroundStyle(kind.color)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 24)
                                .background(kind.color.opacity(0.07), in: RoundedRectangle(cornerRadius: 16))
                            }
                            .buttonStyle(.plain)
                        } else {
                            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 4), spacing: 16) {
                                ForEach(store.categories(for: kind)) { category in
                                    CategoryChoice(category: category, isSelected: selectedCategoryID == category.id, color: kind.color) {
                                        selectedCategoryID = category.id
                                    }
                                }
                            }
                        }
                    }

                    VStack(spacing: 0) {
                        HStack {
                            Image(systemName: "text.bubble")
                                .foregroundStyle(.secondary)
                            TextField("添加备注（选填）", text: $note)
                        }
                        .padding(.vertical, 15)
                        Divider()
                        DatePicker("日期", selection: $date, displayedComponents: [.date, .hourAndMinute])
                            .padding(.vertical, 12)
                    }
                    .padding(.horizontal, 16)
                    .background(.background, in: RoundedRectangle(cornerRadius: 18))

                    Button {
                        guard let amount, let selectedCategoryID else { return }
                        store.addTransaction(kind: kind, amount: amount, categoryID: selectedCategoryID, note: note, date: date)
                        dismiss()
                    } label: {
                        Text("完成")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .foregroundStyle(.white)
                            .background(canSave ? kind.color : Color.gray.opacity(0.35), in: RoundedRectangle(cornerRadius: 16))
                    }
                    .disabled(!canSave)
                }
                .padding(20)
            }
            .background(Color.appBackground)
            .navigationTitle("记一笔")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
            }
            .onAppear {
                selectFirstCategory()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { amountFocused = true }
            }
            .onChange(of: kind) { _ in selectFirstCategory() }
            .alert("新增\(kind.rawValue)分类", isPresented: $showingNewCategory) {
                TextField("分类名称", text: $newCategoryName)
                Button("取消", role: .cancel) { newCategoryName = "" }
                Button("添加") {
                    if let category = store.addCategory(name: newCategoryName, kind: kind) {
                        selectedCategoryID = category.id
                    }
                    newCategoryName = ""
                }
            } message: {
                Text("分类会保存在本机，下次记账时仍可使用。")
            }
        }
    }

    private func selectFirstCategory() {
        selectedCategoryID = store.categories(for: kind).first?.id
    }
}

private struct CategoryChoice: View {
    let category: LedgerCategory
    let isSelected: Bool
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 7) {
                Image(systemName: category.symbol)
                    .font(.system(size: 20, weight: .medium))
                    .frame(width: 46, height: 46)
                    .foregroundStyle(isSelected ? .white : color)
                    .background(isSelected ? color : color.opacity(0.12), in: Circle())
                Text(category.name)
                    .font(.caption)
                    .lineLimit(1)
                    .foregroundStyle(.primary)
            }
        }
        .buttonStyle(.plain)
    }
}
