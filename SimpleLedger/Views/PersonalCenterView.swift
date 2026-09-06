import SwiftUI
import UniformTypeIdentifiers

struct PersonalCenterView: View {
    @EnvironmentObject private var store: LedgerStore
    @State private var exportDocument: LedgerBackupDocument?
    @State private var showingExporter = false
    @State private var showingImporter = false
    @State private var pendingBackup: LedgerBackup?
    @State private var showingImportConfirmation = false
    @State private var showingDeleteConfirmation = false
    @State private var message: StatusMessage?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    accountCard
                    dataSection
                    safetyNote
                }
                .padding(16)
                .padding(.bottom, 20)
            }
            .background(Color.appBackground)
            .navigationTitle("个人中心")
        }
        .fileExporter(
            isPresented: $showingExporter,
            document: exportDocument,
            contentType: .json,
            defaultFilename: backupFilename
        ) { result in
            switch result {
            case .success:
                message = StatusMessage(title: "导出完成", detail: "请妥善保存备份文件，更换签名后可从这里恢复。")
            case .failure(let error):
                message = StatusMessage(title: "导出失败", detail: error.localizedDescription)
            }
            exportDocument = nil
        }
        .fileImporter(
            isPresented: $showingImporter,
            allowedContentTypes: [.json, .data]
        ) { result in
            // 先关闭系统文件选择器，再解析安全作用域内的文件。
            showingImporter = false
            readImportResult(result)
        }
        .sheet(isPresented: $showingImportConfirmation, onDismiss: {
            pendingBackup = nil
        }) {
            if let pendingBackup {
                ImportBackupSheet(backup: pendingBackup) {
                    confirmImport()
                }
                .presentationDetents([.height(300)])
                .presentationDragIndicator(.visible)
            }
        }
        .confirmationDialog(
            "确定删除所有本地数据？",
            isPresented: $showingDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("永久删除", role: .destructive) {
                store.deleteAllLocalData()
                message = StatusMessage(title: "已清空", detail: "本机账单和自定义分类已全部删除。")
            }
            Button("取消", role: .cancel) { }
        } message: {
            Text("此操作无法撤销，建议删除前先导出备份。")
        }
        .alert(item: $message) { message in
            Alert(title: Text(message.title), message: Text(message.detail), dismissButton: .default(Text("知道了")))
        }
    }

    private var accountCard: some View {
        HStack(spacing: 16) {
            Image(systemName: "person.crop.circle.fill")
                .font(.system(size: 54))
                .foregroundStyle(Color.brandBlue)
            VStack(alignment: .leading, spacing: 5) {
                Text("我的账本")
                    .font(.title3.weight(.bold))
                Text("\(store.transactions.count) 笔账单 · \(customCategoryCount) 个自定义分类")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding(20)
        .background(.background, in: RoundedRectangle(cornerRadius: 20))
    }

    private var dataSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("数据管理")
                .font(.headline)
                .padding(.horizontal, 18)
                .padding(.vertical, 14)

            Divider().padding(.leading, 18)

            actionRow(
                title: "导出数据",
                detail: "保存全部账单与分类",
                symbol: "square.and.arrow.up",
                color: .brandBlue
            ) {
                exportDocument = LedgerBackupDocument(backup: store.makeBackup())
                showingExporter = true
            }

            Divider().padding(.leading, 66)

            actionRow(
                title: "导入数据",
                detail: "选择 JSON 后点击右上角“打开”",
                symbol: "square.and.arrow.down",
                color: .incomeGreen
            ) {
                showingImporter = true
            }

            Divider().padding(.leading, 66)

            actionRow(
                title: "删除所有数据",
                detail: "清空全部账单和自定义分类",
                symbol: "trash",
                color: .expenseCoral
            ) {
                showingDeleteConfirmation = true
            }
        }
        .background(.background, in: RoundedRectangle(cornerRadius: 20))
    }

    private var safetyNote: some View {
        HStack(alignment: .top, spacing: 11) {
            Image(systemName: "lock.shield.fill")
                .foregroundStyle(Color.brandBlue)
            Text("数据仅保存在本机。自签证书到期或重新安装应用前，请先导出备份；使用新签名安装后，再通过“导入数据”恢复。")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .background(Color.brandBlue.opacity(0.08), in: RoundedRectangle(cornerRadius: 16))
    }

    private func actionRow(title: String, detail: String, symbol: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Image(systemName: symbol)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(color)
                    .frame(width: 36, height: 36)
                    .background(color.opacity(0.11), in: RoundedRectangle(cornerRadius: 10))
                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(.body.weight(.medium))
                        .foregroundStyle(title == "删除所有数据" ? Color.expenseCoral : Color.primary)
                    Text(detail)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.tertiary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func readImportResult(_ result: Result<URL, Error>) {
        do {
            let url = try result.get()
            let accessed = url.startAccessingSecurityScopedResource()
            defer { if accessed { url.stopAccessingSecurityScopedResource() } }
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            pendingBackup = try decoder.decode(LedgerBackup.self, from: data)
            showingImportConfirmation = true
        } catch {
            message = StatusMessage(title: "无法导入", detail: error.localizedDescription)
        }
    }

    private func confirmImport() {
        guard let pendingBackup else { return }
        do {
            try store.importBackup(pendingBackup)
            message = StatusMessage(title: "恢复成功", detail: "已恢复 \(pendingBackup.transactions.count) 笔账单。")
        } catch {
            message = StatusMessage(title: "无法导入", detail: error.localizedDescription)
        }
        self.pendingBackup = nil
        showingImportConfirmation = false
    }

    private var customCategoryCount: Int { store.categories.filter(\.isCustom).count }

    private var backupFilename: String {
        "简账备份-" + Date().formatted(.dateTime.year().month().day())
    }
}

private struct StatusMessage: Identifiable {
    let id = UUID()
    let title: String
    let detail: String
}

struct LedgerBackupDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.json] }
    let backup: LedgerBackup

    init(backup: LedgerBackup) {
        self.backup = backup
    }

    init(configuration: ReadConfiguration) throws {
        guard let data = configuration.file.regularFileContents else {
            throw LedgerBackupError.invalidData
        }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        backup = try decoder.decode(LedgerBackup.self, from: data)
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        return FileWrapper(regularFileWithContents: try encoder.encode(backup))
    }
}

private struct ImportBackupSheet: View {
    @Environment(\.dismiss) private var dismiss
    let backup: LedgerBackup
    let onConfirm: () -> Void

    var body: some View {
        VStack(spacing: 18) {
            Image(systemName: "arrow.down.doc.fill")
                .font(.system(size: 34))
                .foregroundStyle(Color.incomeGreen)
            Text("确认导入备份？")
                .font(.title3.weight(.bold))
            Text("此备份包含 \(backup.transactions.count) 笔账单和 \(backup.categories.filter(\.isCustom).count) 个自定义分类。导入后会覆盖当前本地数据。")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 18)
            HStack(spacing: 12) {
                Button("取消") { dismiss() }
                    .buttonStyle(.bordered)
                    .frame(maxWidth: .infinity)
                Button("覆盖并导入") {
                    onConfirm()
                }
                .buttonStyle(.borderedProminent)
                .tint(Color.brandBlue)
                .frame(maxWidth: .infinity)
            }
        }
        .padding(22)
    }
}
