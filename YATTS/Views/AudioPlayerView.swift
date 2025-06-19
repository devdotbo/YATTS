import SwiftUI
import SwiftData

struct AudioPlayerView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var viewModel = AudioPlayerViewModel()
    let audioItem: AudioItem
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 30) {
                Spacer()
                
                Image(systemName: "waveform.circle.fill")
                    .font(.system(size: 120))
                    .foregroundStyle(.blue.gradient)
                    .symbolEffect(.bounce, value: viewModel.isPlaying)
                
                VStack(spacing: 8) {
                    Text(audioItem.title)
                        .font(.title2)
                        .fontWeight(.semibold)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    
                    HStack(spacing: 12) {
                        Text("\(audioItem.textContent.split(separator: " ").count) words")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        
                        if audioItem.isChunked && viewModel.audioService.totalChunks > 0 {
                            Text("•")
                                .foregroundStyle(.secondary)
                            Text("Chunk \(viewModel.audioService.currentChunkIndex + 1) of \(viewModel.audioService.totalChunks)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                
                VStack(spacing: 8) {
                    Slider(
                        value: Binding(
                            get: { viewModel.progress },
                            set: { viewModel.seek(to: $0) }
                        )
                    )
                    .tint(.blue)
                    
                    HStack {
                        Text(viewModel.formatTime(viewModel.currentTime))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .monospacedDigit()
                        
                        Spacer()
                        
                        Text(viewModel.formatTime(viewModel.duration))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .monospacedDigit()
                    }
                }
                .padding(.horizontal, 40)
                
                HStack(spacing: 40) {
                    Button {
                        viewModel.audioService.skip(seconds: -15)
                    } label: {
                        Image(systemName: "gobackward.15")
                            .font(.title)
                    }
                    
                    Button {
                        viewModel.togglePlayPause()
                    } label: {
                        Image(systemName: viewModel.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                            .font(.system(size: 72))
                    }
                    
                    Button {
                        viewModel.skip15Seconds()
                    } label: {
                        Image(systemName: "goforward.15")
                            .font(.title)
                    }
                }
                .foregroundStyle(.blue)
                
                Spacer()
                
                VStack(spacing: 16) {
                    ScrollView {
                        Text(audioItem.textContent)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.leading)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                    }
                    .frame(maxHeight: 150)
                }
                .padding(.horizontal)
                
                Spacer()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        viewModel.savePosition(for: audioItem, in: modelContext)
                        dismiss()
                    }
                }
            }
            .onAppear {
                viewModel.play(audioItem: audioItem)
            }
            .onDisappear {
                viewModel.savePosition(for: audioItem, in: modelContext)
                viewModel.audioService.stop()
            }
            .onChange(of: scenePhase) { _, newPhase in
                if newPhase == .background || newPhase == .inactive {
                    viewModel.savePosition(for: audioItem, in: modelContext)
                }
            }
        }
    }
}