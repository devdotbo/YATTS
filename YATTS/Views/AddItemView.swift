import SwiftUI
import SwiftData

struct AddItemView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query private var settings: [Settings]
    @StateObject private var viewModel = AddItemViewModel()
    @FocusState private var isTextFieldFocused: Bool
    
    private var currentSettings: Settings? {
        settings.first
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if viewModel.isProcessing {
                    VStack(spacing: 20) {
                        ProgressView()
                            .scaleEffect(1.5)
                        Text("Generating audio...")
                            .font(.headline)
                        Text("This may take a moment")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView {
                        TextEditor(text: $viewModel.text)
                            .focused($isTextFieldFocused)
                            .font(.body)
                            .scrollContentBackground(.hidden)
                            .padding(12)
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                            .frame(minHeight: 300)
                            .padding()
                    }
                    
                    VStack(spacing: 12) {
                        Divider()
                        
                        HStack {
                            Text(viewModel.characterCount)
                                .font(.caption)
                                .foregroundStyle(viewModel.isOverLimit ? .red : .secondary)
                                .fontWeight(viewModel.isOverLimit ? .semibold : .regular)
                            
                            Spacer()
                            
                            Button("Paste") {
                                if let string = UIPasteboard.general.string {
                                    viewModel.text = string
                                }
                            }
                            .font(.caption)
                            .buttonStyle(.bordered)
                            
                            Button("Clear") {
                                viewModel.text = ""
                            }
                            .font(.caption)
                            .buttonStyle(.bordered)
                            .disabled(viewModel.text.isEmpty)
                        }
                        .padding(.horizontal)
                        
                        if viewModel.isOverLimit {
                            Text("Text exceeds the maximum limit of \(OpenAIService.maxCharacterLimit) characters")
                                .font(.caption)
                                .foregroundStyle(.red)
                                .padding(.horizontal)
                        }
                        
                        Button {
                            generateAudio()
                        } label: {
                            Label("Generate Audio", systemImage: "waveform")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                        .disabled(!viewModel.canGenerate)
                        .padding(.horizontal)
                        .padding(.bottom)
                    }
                    .background(Color(.systemBackground))
                }
            }
            .navigationTitle("New Audio")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .disabled(viewModel.isProcessing)
                }
            }
            .interactiveDismissDisabled(viewModel.isProcessing)
            .alert("Error", isPresented: $viewModel.showError) {
                Button("OK") { }
            } message: {
                Text(viewModel.errorMessage ?? "An error occurred")
            }
            .onAppear {
                isTextFieldFocused = true
            }
        }
    }
    
    private func generateAudio() {
        guard let settings = currentSettings else {
            viewModel.errorMessage = "Please configure your OpenAI API key in Settings"
            viewModel.showError = true
            return
        }
        
        guard !settings.openAIAPIKey.isEmpty else {
            viewModel.errorMessage = "Please configure your OpenAI API key in Settings"
            viewModel.showError = true
            return
        }
        
        Task {
            await viewModel.generateAudio(settings: settings, context: modelContext)
            if viewModel.errorMessage == nil {
                dismiss()
            }
        }
    }
}