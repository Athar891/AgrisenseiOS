# 🤖 Live AI Assistant (Krishi AI)

Comprehensive documentation for the Krishi AI - AgriSense's revolutionary voice-powered AI assistant with continuous listening capabilities.

---

## 📋 Overview

Krishi AI is the crown jewel of AgriSense, featuring advanced continuous listening, real-time interruption support, multi-modal intelligence, and seamless voice interactions. Built on Google's Gemini 2.0 Flash Experimental model with intelligent fallback chains.

### Key Features

- ✅ **Continuous Listening** - Never stops listening, always ready
- ✅ **Wake Word Detection** - Activate with "Krishi AI"
- ✅ **Real-time Interruption** - Interrupt AI while speaking
- ✅ **Multi-modal Intelligence** - Voice, camera, screen sharing
- ✅ **Context Awareness** - Maintains conversation history
- ✅ **Multi-language Support** - 5 languages supported
- ✅ **Auto-processing** - Detects silence automatically
- ✅ **Subtitle Support** - Real-time transcription display

---

## 🏗 Architecture

### State Machine

```
┌──────────────┐
│   STANDBY    │◄─────────────────┐
└──────┬───────┘                  │
       │ Wake word detected       │
       ↓                          │
┌──────────────┐                  │
│  LISTENING   │                  │
└──────┬───────┘                  │
       │ Silence detected         │
       ↓                          │
┌──────────────┐                  │
│   THINKING   │                  │
└──────┬───────┘                  │
       │ AI response ready        │
       ↓                          │
┌──────────────┐                  │
│  RESPONDING  │──────────────────┘
└──────────────┘  Response complete
```

### Component Architecture

```
┌─────────────────────────────────────────────────────┐
│                   LiveAIView                         │
│  (Main UI - SwiftUI)                                │
└─────────────────┬───────────────────────────────────┘
                  │
                  ↓
┌─────────────────────────────────────────────────────┐
│               LiveAIService                          │
│  (Orchestration & State Management)                 │
└─────┬─────────┬─────────┬─────────┬────────────────┘
      │         │         │         │
      ↓         ↓         ↓         ↓
┌─────────┐ ┌──────┐ ┌──────┐ ┌──────────┐
│ Wake    │ │Voice │ │Camera│ │ Screen   │
│ Word    │ │Trans-│ │Serv- │ │Recording │
│Detection│ │crip- │ │ice   │ │Service   │
│         │ │tion  │ │      │ │          │
└─────────┘ └──┬───┘ └──┬───┘ └────┬─────┘
               │        │          │
               ↓        ↓          ↓
┌──────────────────────────────────────────────────┐
│            GeminiAIService                        │
│  (AI Processing & Response Generation)           │
└──────────────────┬───────────────────────────────┘
                   │
                   ↓
┌──────────────────────────────────────────────────┐
│          EnhancedTTSService                       │
│  (Text-to-Speech with Interruption)              │
└──────────────────────────────────────────────────┘
```

---

## 🎯 Core Services

### 1. LiveAIService

**Purpose**: Orchestrates the entire AI assistant workflow

**Key Responsibilities**:
- State management (standby, listening, thinking, responding)
- Coordinate all services
- Handle user interruptions
- Manage conversation history
- Process voice input

**Code Example**:

```swift
@MainActor
class LiveAIService: ObservableObject {
    // Published states
    @Published var currentState: AIState = .standby
    @Published var transcribedText: String = ""
    @Published var isListening: Bool = false
    @Published var audioLevel: Float = 0.0
    
    // Services
    private let geminiService: GeminiAIService
    private let ttsService: EnhancedTTSService
    private let transcriptionService: VoiceTranscriptionService
    private let wakeWordService: WakeWordDetectionService
    
    // State
    private var conversationHistory: [Message] = []
    private var silenceTimer: Timer?
    private let silenceThreshold: TimeInterval = 1.2
    
    func startContinuousListening() {
        wakeWordService.startListening { [weak self] in
            self?.activateVoiceInput()
        }
    }
    
    func activateVoiceInput() {
        currentState = .listening
        transcriptionService.startTranscription { [weak self] text in
            self?.handleTranscription(text)
        }
    }
    
    private func handleTranscription(_ text: String) {
        transcribedText = text
        resetSilenceTimer()
    }
    
    private func resetSilenceTimer() {
        silenceTimer?.invalidate()
        silenceTimer = Timer.scheduledTimer(
            withTimeInterval: silenceThreshold,
            repeats: false
        ) { [weak self] _ in
            self?.processFinalInput()
        }
    }
    
    private func processFinalInput() async {
        guard !transcribedText.isEmpty else { return }
        
        currentState = .thinking
        
        do {
            let response = try await geminiService.generateResponse(
                prompt: transcribedText,
                conversationHistory: conversationHistory
            )
            
            await speakResponse(response)
        } catch {
            handleError(error)
        }
    }
    
    private func speakResponse(_ text: String) async {
        currentState = .responding
        
        await ttsService.speak(text) { [weak self] in
            self?.currentState = .standby
        }
    }
    
    func interrupt() {
        ttsService.stop()
        transcriptionService.stopTranscription()
        silenceTimer?.invalidate()
        currentState = .standby
    }
}
```

### 2. WakeWordDetectionService

**Purpose**: Detects "Krishi AI" wake word to activate assistant

**Implementation**:

```swift
class WakeWordDetectionService: NSObject, ObservableObject {
    private let speechRecognizer: SFSpeechRecognizer?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()
    
    private let wakeWords = ["krishi ai", "krishna ai", "krishi"]
    private var onWakeWordDetected: (() -> Void)?
    
    override init() {
        speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
        super.init()
    }
    
    func startListening(onDetected: @escaping () -> Void) {
        self.onWakeWordDetected = onDetected
        
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        
        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { 
            [weak self] buffer, _ in
            self?.recognitionRequest?.append(buffer)
        }
        
        audioEngine.prepare()
        try? audioEngine.start()
        
        recognitionTask = speechRecognizer?.recognitionTask(
            with: recognitionRequest!
        ) { [weak self] result, error in
            guard let result = result else { return }
            
            let transcription = result.bestTranscription.formattedString.lowercased()
            
            if self?.containsWakeWord(transcription) == true {
                self?.onWakeWordDetected?()
            }
        }
    }
    
    private func containsWakeWord(_ text: String) -> Bool {
        wakeWords.contains { text.contains($0) }
    }
    
    func stopListening() {
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()
    }
}
```

### 3. VoiceTranscriptionService

**Purpose**: Real-time speech-to-text conversion

**Features**:
- Real-time transcription
- Noise filtering
- Multi-language support
- Audio level monitoring

**Implementation**:

```swift
class VoiceTranscriptionService: NSObject, ObservableObject {
    @Published var currentTranscription: String = ""
    @Published var audioLevel: Float = 0.0
    
    private let speechRecognizer: SFSpeechRecognizer?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()
    
    private var onTranscriptionUpdate: ((String) -> Void)?
    
    init(locale: Locale = .current) {
        speechRecognizer = SFSpeechRecognizer(locale: locale)
        super.init()
    }
    
    func startTranscription(onUpdate: @escaping (String) -> Void) {
        self.onTranscriptionUpdate = onUpdate
        
        // Request authorization
        SFSpeechRecognizer.requestAuthorization { status in
            guard status == .authorized else { return }
            
            DispatchQueue.main.async {
                self.startRecording()
            }
        }
    }
    
    private func startRecording() {
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        recognitionRequest?.shouldReportPartialResults = true
        
        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        
        // Install tap for audio level monitoring
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { 
            [weak self] buffer, _ in
            self?.recognitionRequest?.append(buffer)
            self?.updateAudioLevel(buffer: buffer)
        }
        
        audioEngine.prepare()
        try? audioEngine.start()
        
        recognitionTask = speechRecognizer?.recognitionTask(
            with: recognitionRequest!
        ) { [weak self] result, error in
            guard let result = result else { return }
            
            let transcription = result.bestTranscription.formattedString
            self?.currentTranscription = transcription
            self?.onTranscriptionUpdate?(transcription)
        }
    }
    
    private func updateAudioLevel(buffer: AVAudioPCMBuffer) {
        guard let channelData = buffer.floatChannelData?[0] else { return }
        let frames = buffer.frameLength
        
        var sum: Float = 0
        for i in 0..<Int(frames) {
            sum += abs(channelData[i])
        }
        
        let average = sum / Float(frames)
        
        DispatchQueue.main.async {
            self.audioLevel = average
        }
    }
    
    func stopTranscription() {
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()
        
        recognitionTask = nil
        recognitionRequest = nil
    }
}
```

### 4. GeminiAIService

**Purpose**: Interface with Google Gemini AI API

**Features**:
- Multiple model support with fallback
- Context building
- Multi-modal input (text, images)
- Web search integration

**Models & Fallback Chain**:

```swift
enum AIModel: String {
    case flash2Experimental = "gemini-2.0-flash-exp"
    case flash2Thinking = "gemini-2.0-flash-thinking-exp-1219"
    case flash15 = "gemini-1.5-flash"
    case pro15 = "gemini-1.5-pro"
}

class GeminiAIService {
    private let apiKey: String
    private let modelPriority: [AIModel] = [
        .flash2Experimental,
        .flash2Thinking,
        .flash15,
        .pro15
    ]
    
    func generateResponse(
        prompt: String,
        conversationHistory: [Message],
        images: [UIImage]? = nil,
        screenContent: String? = nil
    ) async throws -> String {
        
        // Build context
        let context = AIContextBuilder.build(
            prompt: prompt,
            history: conversationHistory,
            images: images,
            screenContent: screenContent
        )
        
        // Try models with fallback
        return try await executeWithFallback(context: context)
    }
    
    private func executeWithFallback(context: AIContext) async throws -> String {
        var lastError: Error?
        
        for model in modelPriority {
            do {
                return try await execute(model: model, context: context)
            } catch {
                lastError = error
                print("Model \(model.rawValue) failed: \(error)")
                continue
            }
        }
        
        throw AIError.allModelsFailed(lastError: lastError)
    }
    
    private func execute(
        model: AIModel,
        context: AIContext
    ) async throws -> String {
        let url = URL(string: "https://generativelanguage.googleapis.com/v1/models/\(model.rawValue):generateContent?key=\(apiKey)")!
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let payload = buildPayload(context: context)
        request.httpBody = try JSONEncoder().encode(payload)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw AIError.invalidResponse
        }
        
        let result = try JSONDecoder().decode(GeminiResponse.self, from: data)
        return result.candidates.first?.content.parts.first?.text ?? ""
    }
}
```

### 5. EnhancedTTSService

**Purpose**: Text-to-speech with interruption support

**Features**:
- High-quality voice synthesis
- Interruption handling
- Speed and pitch control
- Multi-language voices

**Implementation**:

```swift
class EnhancedTTSService: NSObject, ObservableObject, AVSpeechSynthesizerDelegate {
    @Published var isSpeaking = false
    
    private let synthesizer = AVSpeechSynthesizer()
    private var currentUtterance: AVSpeechUtterance?
    private var onComplete: (() -> Void)?
    
    override init() {
        super.init()
        synthesizer.delegate = self
    }
    
    func speak(
        _ text: String,
        language: String = "en-US",
        rate: Float = 0.5,
        onComplete: (() -> Void)? = nil
    ) async {
        self.onComplete = onComplete
        
        await stop() // Stop any current speech
        
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: language)
        utterance.rate = rate
        utterance.pitchMultiplier = 1.0
        utterance.volume = 1.0
        
        currentUtterance = utterance
        
        await MainActor.run {
            isSpeaking = true
            synthesizer.speak(utterance)
        }
    }
    
    func stop() async {
        await MainActor.run {
            if synthesizer.isSpeaking {
                synthesizer.stopSpeaking(at: .immediate)
            }
            isSpeaking = false
        }
    }
    
    func pause() {
        synthesizer.pauseSpeaking(at: .word)
    }
    
    func resume() {
        synthesizer.continueSpeaking()
    }
    
    // MARK: - AVSpeechSynthesizerDelegate
    
    func speechSynthesizer(
        _ synthesizer: AVSpeechSynthesizer,
        didFinish utterance: AVSpeechUtterance
    ) {
        DispatchQueue.main.async {
            self.isSpeaking = false
            self.onComplete?()
        }
    }
}
```

---

## 🎨 UI Components

### LiveAIView

Main interface for AI assistant:

```swift
struct LiveAIView: View {
    @StateObject private var aiService = LiveAIService()
    @State private var showSubtitles = false
    
    var body: some View {
        ZStack {
            // Background gradient
            backgroundGradient
            
            VStack {
                // Status indicator
                statusIndicator
                
                Spacer()
                
                // Voice indicator
                VoiceIndicatorView(
                    isListening: aiService.isListening,
                    audioLevel: aiService.audioLevel
                )
                
                // Transcript
                if showSubtitles {
                    TranscriptView(text: aiService.transcribedText)
                }
                
                Spacer()
                
                // Controls
                controlButtons
            }
        }
        .onAppear {
            aiService.startContinuousListening()
        }
    }
    
    private var statusIndicator: some View {
        HStack {
            Circle()
                .fill(statusColor)
                .frame(width: 12, height: 12)
            
            Text(statusText)
                .font(.headline)
        }
    }
    
    private var statusColor: Color {
        switch aiService.currentState {
        case .standby: return .gray
        case .listening: return .blue
        case .thinking: return .yellow
        case .responding: return .green
        }
    }
    
    private var controlButtons: some View {
        HStack(spacing: 30) {
            // Interrupt button
            Button(action: { aiService.interrupt() }) {
                Image(systemName: "stop.circle.fill")
                    .font(.system(size: 44))
            }
            
            // Subtitles toggle
            Button(action: { showSubtitles.toggle() }) {
                Image(systemName: showSubtitles ? "captions.bubble.fill" : "captions.bubble")
                    .font(.system(size: 44))
            }
        }
    }
}
```

### VoiceIndicatorView

Visual feedback for voice input:

```swift
struct VoiceIndicatorView: View {
    let isListening: Bool
    let audioLevel: Float
    
    var body: some View {
        ZStack {
            // Outer pulse
            Circle()
                .fill(Color.blue.opacity(0.3))
                .frame(width: 200, height: 200)
                .scaleEffect(isListening ? 1.2 : 1.0)
                .animation(.easeInOut(duration: 1).repeatForever(), value: isListening)
            
            // Inner circle
            Circle()
                .fill(Color.blue)
                .frame(width: 150, height: 150)
                .scaleEffect(1.0 + CGFloat(audioLevel) * 0.5)
                .animation(.spring(), value: audioLevel)
            
            // Microphone icon
            Image(systemName: "mic.fill")
                .font(.system(size: 60))
                .foregroundColor(.white)
        }
    }
}
```

---

## 🌍 Multi-language Support

### Supported Languages

- 🇬🇧 English (en)
- 🇮🇳 Hindi (hi)
- 🇮🇳 Bengali (bn)
- 🇮🇳 Tamil (ta)
- 🇮🇳 Telugu (te)

### Implementation

```swift
class LocalizationManager: ObservableObject {
    @Published var currentLanguage: String = "en"
    
    func setLanguage(_ code: String) {
        currentLanguage = code
        updateServices()
    }
    
    private func updateServices() {
        // Update TTS voice
        // Update speech recognition locale
        // Update UI language
    }
}
```

---

## 🔧 Configuration

### Settings

```swift
struct AIAssistantSettings {
    // Wake word
    var wakeWordEnabled = true
    var wakeWord = "Krishi AI"
    
    // Voice
    var voiceLanguage = "en-US"
    var speechRate: Float = 0.5
    var speechPitch: Float = 1.0
    
    // Behavior
    var silenceThreshold: TimeInterval = 1.2
    var autoProcessEnabled = true
    var subtitlesEnabled = false
    
    // AI Model
    var preferredModel: AIModel = .flash2Experimental
    var enableFallback = true
}
```

---

## 📊 Performance Metrics

### Latency Targets

- **Wake Word Detection**: < 500ms
- **Speech Recognition**: < 200ms (real-time)
- **AI Response**: < 2s
- **TTS Start**: < 300ms

### Optimization Techniques

1. **Pre-warming Services**
   ```swift
   func warmUpServices() {
       aiService.initialize()
       ttsService.warmUp()
       transcriptionService.prepare()
   }
   ```

2. **Streaming Responses**
   - Stream AI responses as they generate
   - Start TTS before full response received

3. **Caching**
   - Cache common responses
   - Pre-load voice assets

---

## 🐛 Debugging

### Enable Logging

```swift
AIDebugLogger.enabled = true
AIDebugLogger.logLevel = .verbose
```

### Common Issues

**Issue**: Wake word not detected
**Solution**: Check microphone permissions, verify wake word pronunciation

**Issue**: Interruption doesn't work
**Solution**: Ensure TTS service implements interruption properly

**Issue**: High latency
**Solution**: Check network connection, optimize context building

---

## 🧪 Testing

### Unit Tests

```swift
class LiveAIServiceTests: XCTestCase {
    var sut: LiveAIService!
    
    override func setUp() {
        sut = LiveAIService()
    }
    
    func testStateTransition() {
        sut.activateVoiceInput()
        XCTAssertEqual(sut.currentState, .listening)
    }
    
    func testInterruption() {
        sut.interrupt()
        XCTAssertEqual(sut.currentState, .standby)
    }
}
```

### Integration Tests

Test full flow from wake word to response.

---

## 🚀 Future Enhancements

- [ ] Emotion detection in voice
- [ ] Speaker identification
- [ ] Contextual follow-up questions
- [ ] Offline mode support
- [ ] Custom wake words
- [ ] Voice cloning

---

## 📚 Related Documentation

- [Services Architecture](Services-Architecture.md)
- [AI & ML Integration](AI-ML-Integration.md)
- [Performance Guide](Performance.md)

---

**Questions?** Check [FAQ](FAQ.md) or [create an issue](https://github.com/Athar891/AgrisenseiOS/issues).
