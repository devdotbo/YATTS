import SwiftUI
import SwiftData

struct AudioListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \AudioItem.createdAt, order: .reverse) private var audioItems: [AudioItem]
    @StateObject private var viewModel = AudioListViewModel()
    @State private var showingAddItem = false
    @State private var selectedItem: AudioItem?
    
    var body: some View {
        NavigationStack {
            Group {
                if audioItems.isEmpty {
                    ContentUnavailableView(
                        "No Audio Items",
                        systemImage: "speaker.wave.2",
                        description: Text("Tap the + button to create your first audio")
                    )
                } else {
                    List {
                        ForEach(audioItems) { item in
                            AudioItemRow(item: item)
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    selectedItem = item
                                }
                                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                    Button(role: .destructive) {
                                        viewModel.confirmDelete(item)
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                        }
                        
                        HStack {
                            Text("Total Storage:")
                                .foregroundStyle(.secondary)
                            Spacer()
                            Text(viewModel.getTotalStorageUsed())
                                .foregroundStyle(.secondary)
                        }
                        .font(.caption)
                        .listRowBackground(Color.clear)
                    }
                }
            }
            .navigationTitle("YATTS")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingAddItem = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddItem) {
                AddItemView()
            }
            .sheet(item: $selectedItem) { item in
                AudioPlayerView(audioItem: item)
            }
            .alert("Delete Audio?", isPresented: $viewModel.showDeleteAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) {
                    if let item = viewModel.itemToDelete {
                        viewModel.deleteItem(item, from: modelContext)
                    }
                }
            } message: {
                Text("This will permanently delete the audio file and cannot be undone.")
            }
        }
    }
}

struct AudioItemRow: View {
    let item: AudioItem
    @StateObject private var viewModel = AudioListViewModel()
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(item.title)
                .font(.headline)
                .lineLimit(1)
            
            HStack {
                Label(viewModel.formatDuration(item.totalDuration), systemImage: "clock")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                if item.isChunked {
                    Label("\(item.downloadedChunks)/\(item.totalChunks) chunks", systemImage: "square.stack.3d.up")
                        .font(.caption)
                        .foregroundStyle(item.isFullyDownloaded ? .secondary : .orange)
                }
                
                Spacer()
                
                Text(viewModel.formatFileSize(item.fileSize))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                Text(item.createdAt.formatted(date: .abbreviated, time: .omitted))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            if item.lastPlaybackPosition > 0 && item.lastPlaybackPosition < item.duration {
                ProgressView(value: item.lastPlaybackPosition, total: item.duration)
                    .tint(.blue)
            }
        }
        .padding(.vertical, 4)
    }
}