import SwiftUI

struct CategoryManagementView: View {
    @EnvironmentObject private var store: LedgerStore
    @State private var kind: TransactionKind = .expense
    @State private var editingCategory: LedgerCategory?
    @State private var editingName = ""
    @State private var pendingDeletion: LedgerCategory?
    @State private var showingDeleteConfirmation = false
    @State private var message: CategoryStatusMessage?

    private var categories: [LedgerCategory] { store.categories(for: kind) }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    Picker("分类类型", selection: $kind) {
                        ForEach(TransactionKind.allCases) { Text($0.rawValue).tag($0) }
                    }
                    .pickerStyle(.segmented)

                    VStack(alignment: .leading, spacing: 0) {
                        HStack {
                            Text("我的" + kind.rawValue + "分类")
                                .font(.headline)
                            Spacer()
                            Text("共 " + String(categories.count) + " 个")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.horizontal, 18)
                        .padding(.vertical, 14)

                        Divider().padding(.leading, 18)

                        if categories.isEmpty {
                            VStack(spacing: 12) {
                                Image(systemName: "square.grid.2x2")
                                    .font(.system(size: 34, weight: .light))
                                    .foregroundStyle(.tertiary)
                                Text("还没有" + kind.rawValue + "分类")
                                    .font(.subheadline)
                                Text("在记账时点击“新增分类”创建")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 52)
                        } else {
                            ForEach(categories) { category in
                                HStack(spacing: 12) {
                                    Image(systemName: category.symbol)
                                        .foregroundStyle(kind.color)
                                        .frame(width: 36, height: 36)
                                        .background(kind.color.opacity(0.11), in: Circle())
                                    Text(category.name)
                                        .font(.body.weight(.medium))
                                    Spacer()
                                    Button("修改") {
                                        editingCategory = category
                                        editingName = category.name
                                    }
                                    .font(.subheadline)
                                    Button(role: .destructive) {
                                        pendingDeletion = category
                                        showingDeleteConfirmation = true
                                    } label: {
                                        Image(systemName: "trash")
                                    }
                                    .buttonStyle(.borderless)
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 11)
                                if category.id != categories.last?.id {
                                    Divider().padding(.leading, 64)
                                }
                            }
                        }
                    }
                    .background(.background, in: RoundedRectangle(cornerRadius: 20))

                    Text("已被账单使用的分类不能删除。请先在明细中修改关联账单的分类。")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 4)
                }
                .padding(16)
                .padding(.bottom, 20)
            }
            .background(Color.appBackground)
            .navigationTitle("分类管理")
        }
        .confirmationDialog(
            deleteTitle,
            isPresented: $showingDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("删除分类", role: .destructive) {
                guard let pendingDeletion else { return }
                if !store.deleteCategory(id: pendingDeletion.id) {
                    message = CategoryStatusMessage(title: "无法删除", detail: "该分类已被账单使用，请先修改关联账单的分类。")
                }
                self.pendingDeletion = nil
            }
            Button("取消", role: .cancel) { pendingDeletion = nil }
        } message: {
            Text("删除后无法撤销。")
        }
        .alert("修改分类名称", isPresented: Binding(
            get: { editingCategory != nil },
            set: { if !$0 { editingCategory = nil } }
        )) {
            TextField("分类名称", text: $editingName)
            Button("取消", role: .cancel) { editingCategory = nil }
            Button("保存") {
                guard let editingCategory else { return }
                if !store.updateCategory(id: editingCategory.id, name: editingName) {
                    message = CategoryStatusMessage(title: "无法修改", detail: "名称不能为空，且不能与同类分类重复。")
                }
                self.editingCategory = nil
            }
        } message: {
            Text("修改后，历史账单中的分类名称也会同步更新。")
        }
        .alert(item: $message) { message in
            Alert(title: Text(message.title), message: Text(message.detail), dismissButton: .default(Text("知道了")))
        }
    }

    private var deleteTitle: String {
        "确定删除分类“" + (pendingDeletion?.name ?? "") + "”？"
    }
}

private struct CategoryStatusMessage: Identifiable {
    let id = UUID()
    let title: String
    let detail: String
}
