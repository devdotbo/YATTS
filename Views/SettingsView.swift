import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var settings: [Settings]
    @State private var apiKey = ""
    @State private var selectedVoice = "alloy"
    @State private var selectedModel = "tts-1"
    @State private var isValidating = false
    @State private var showValidationResult = false
    @State private var validationMessage = ""
    
    private var currentSettings: Settings? {
        settings.first
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    SecureField("API Key", text: $apiKey)
                        .textContentType(.password)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                    
                    Button {
                        validateAPIKey()
                    } label: {
                        HStack {
                            Text("Validate API Key")
                            if isValidating {
                                Spacer()
                                ProgressView()
                                    .scaleEffect(0.8)
                            }
                        }
                    }
                    .disabled(apiKey.isEmpty || isValidating)
                } header: {
                    Text("OpenAI Configuration")
                } footer: {
                    Text("Your API key is stored locally and never shared")
                        .font(.caption)
                }
                
                Section("Voice Selection") {
                    Picker("Voice", selection: $selectedVoice) {
                        ForEach(Settings.supportedVoices, id: \.self) { voice in
                            Text(voice.capitalized).tag(voice)
                        }
                    }
                }
                
                Section("Model Selection") {
                    Picker("Model", selection: $selectedModel) {
                        Text("Standard (tts-1)").tag("tts-1")
                        Text("HD Quality (tts-1-hd)").tag("tts-1-hd")
                    }
                } footer: {
                    Text("HD quality provides better audio but costs more")
                        .font(.caption)
                }
                
                Section("Storage") {
                    HStack {
                        Text("Total Storage Used")
                        Spacer()
                        Text(FileStorageService.shared.totalStorageUsed().formatted(.byteCount(style: .file)))
                            .foregroundStyle(.secondary)
                    }
                }
                
                Section {
                    Button(role: .destructive) {
                        clearAllData()
                    } label: {
                        Text("Clear All Data")
                    }
                }
            }
            .navigationTitle("Settings")
            .onAppear {
                loadSettings()
            }
            .onChange(of: apiKey) { _, _ in saveSettings() }
            .onChange(of: selectedVoice) { _, _ in saveSettings() }
            .onChange(of: selectedModel) { _, _ in saveSettings() }
            .alert("API Key Validation", isPresented: $showValidationResult) {
                Button("OK") { }
            } message: {
                Text(validationMessage)
            }
        }
    }
    
    private func loadSettings() {
        if let settings = currentSettings {
            apiKey = settings.openAIAPIKey
            selectedVoice = settings.selectedVoice
            selectedModel = settings.selectedModel
        } else {
            let newSettings = Settings()
            modelContext.insert(newSettings)
            try? modelContext.save()
        }
    }
    
    private func saveSettings() {
        if let settings = currentSettings {
            settings.openAIAPIKey = apiKey
            settings.selectedVoice = selectedVoice
            settings.selectedModel = selectedModel
        } else {
            let newSettings = Settings(
                openAIAPIKey: apiKey,
                selectedVoice: selectedVoice,
                selectedModel: selectedModel
            )
            modelContext.insert(newSettings)
        }
        try? modelContext.save()
    }
    
    private func validateAPIKey() {
        isValidating = true
        Task {
            let service = OpenAIService()
            let isValid = await service.validateAPIKey(apiKey)
            
            await MainActor.run {
                validationMessage = isValid ? 
                    "API key is valid and working!" : 
                    "Invalid API key. Please check and try again."
                showValidationResult = true
                isValidating = false
            }
        }
    }
    
    private func clearAllData() {
        do {
            try modelContext.delete(model: AudioItem.self)
            try modelContext.save()
            
            if let audioDir = try? FileManager.default.url(
                for: .documentDirectory,
                in: .userDomainMask,
                appropriateFor: nil,
                create: false
            ).appendingPathComponent("AudioFiles") {
                try? FileManager.default.removeItem(at: audioDir)
            }
        } catch {
            print("Failed to clear data: \(error)")
        }
    }
}