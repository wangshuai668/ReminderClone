import SwiftUI
import SwiftData
import PhotosUI

/// 事项日志 — 文字记录 + 照片上传
struct JournalEntryView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    let item: TodoItem
    
    @State private var newText = ""
    @State private var selectedPhotos: [PhotosPickerItem] = []
    @State private var newPhotoData: [Data] = []
    @State private var showingPhotoPicker = false
    @State private var entryDate: Date = Date()
    
    var body: some View {
        NavigationStack {
            List {
                // 已有日志
                if item.journalEntries.isEmpty {
                    ContentUnavailableView(
                        "暂无记录",
                        systemImage: "bookmark",
                        description: Text("添加文字或照片来记录进度")
                    )
                }
                
                ForEach(item.journalEntries.sorted(by: { $0.date > $1.date })) { entry in
                    VStack(alignment: .leading, spacing: 8) {
                        // 日期
                        Text(entry.date.formatted(date: .abbreviated, time: .shortened))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        
                        // 文字
                        if !entry.text.isEmpty {
                            Text(entry.text)
                                .font(.body)
                        }
                        
                        // 照片
                        if !entry.photoDataList.isEmpty {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    ForEach(entry.photoDataList.indices, id: \.self) { i in
                                        if let uiImage = UIImage(data: entry.photoDataList[i]) {
                                            Image(uiImage: uiImage)
                                                .resizable()
                                                .scaledToFill()
                                                .frame(width: 120, height: 120)
                                                .clipShape(RoundedRectangle(cornerRadius: 8))
                                        }
                                    }
                                }
                            }
                        }
                    }
                    .padding(.vertical, 4)
                }
                .onDelete { indexSet in
                    for i in indexSet {
                        let sorted = item.journalEntries.sorted(by: { $0.date > $1.date })
                        modelContext.delete(sorted[i])
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("记录")
            .safeAreaInset(edge: .bottom) {
                // 新增记录区
                VStack(spacing: 12) {
                    HStack {
                        DatePicker("日期", selection: $entryDate, displayedComponents: .date)
                            .labelsHidden()
                        Spacer()
                        PhotosPicker(selection: $selectedPhotos,
                                     maxSelectionCount: 9,
                                     matching: .images) {
                            Label("照片", systemImage: "photo.on.rectangle")
                        }
                    }
                    
                    HStack(spacing: 8) {
                        TextField("记录文字...", text: $newText, axis: .vertical)
                            .textFieldStyle(.roundedBorder)
                            .lineLimit(1...3)
                        
                        Button(action: addEntry) {
                            Image(systemName: "arrow.up.circle.fill")
                                .font(.title2)
                                .foregroundStyle(.blue)
                        }
                        .disabled(newText.trimmingCharacters(in: .whitespaces).isEmpty && selectedPhotos.isEmpty)
                    }
                }
                .padding()
                .background(Color(.systemGroupedBackground))
            }
            .onChange(of: selectedPhotos) { _, items in
                loadPhotos(from: items)
            }
        }
    }
    
    private func loadPhotos(from items: [PhotosPickerItem]) {
        Task {
            var datas: [Data] = []
            for item in items {
                if let data = try? await item.loadTransferable(type: Data.self) {
                    // 压缩图片到 500KB 以内
                    if let image = UIImage(data: data),
                       let compressed = image.jpegData(compressionQuality: 0.6) {
                        datas.append(compressed)
                    } else {
                        datas.append(data)
                    }
                }
            }
            newPhotoData = datas
        }
    }
    
    private func addEntry() {
        let entry = JournalEntry(
            todoItem: item,
            date: entryDate,
            text: newText.trimmingCharacters(in: .whitespaces),
            photoDataList: newPhotoData,
            list: item.list
        )
        modelContext.insert(entry)
        item.journalEntries.append(entry)
        
        newText = ""
        newPhotoData = []
        selectedPhotos = []
    }
}
