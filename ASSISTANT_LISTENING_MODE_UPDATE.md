# Assistant Listening Mode Update

## Summary
Updated the AssistantView to implement a simplified, elegant listening mode with automatic speech detection and transcription.

## Changes Made

### 1. Voice Service Integration
- Added `@StateObject` for `VoiceTranscriptionService` to handle speech recognition
- Integrated with existing voice transcription infrastructure

### 2. Listening Mode State Management
- Added `isListening` state to track when the microphone is actively listening
- Added `silenceTimer` to detect when user has finished speaking
- Added `lastTranscriptionLength` to track changes in transcription

### 3. New ListeningAnimationView Component
A clean, minimalist overlay that appears during voice input featuring:
- **Semi-transparent background** overlay
- **Pulsing animation** with three concentric circles that expand outward
- **Central microphone icon** in a green circle
- **Text indicators**: "Listening..." and "Speak now, I'm listening"
- **Dismissal hint**: "Tap anywhere to stop"
- **Smooth animations** with spring effects for appearing/disappearing

### 4. Automatic Speech Detection
The system automatically detects when the user has finished speaking:
- **Silence detection timer** checks every 0.5 seconds
- **Smart stopping**: If transcription text hasn't changed for 1.5 seconds, automatically stops
- **Text population**: Transcribed text is automatically placed in the chatbox
- **Clean state management**: Properly resets transcription service after use

### 5. Updated MessageInputView
- Modified microphone button to show current state:
  - **Normal state**: `mic.fill` icon in secondary color
  - **Listening state**: `stop.circle.fill` icon in red color
- Button now works as a toggle (tap to start/stop recording)
- Added `isListening` parameter to track and display current state

### 6. User Interaction Flow
1. User taps microphone button
2. System requests permissions (if needed)
3. Listening animation overlay appears with pulsing effect
4. User speaks their query
5. System monitors for silence (1.5 seconds of no speech change)
6. Automatically stops listening and places transcribed text in chatbox
7. User can review and edit text before sending
8. Alternative: User can tap anywhere on screen to manually stop listening

## Technical Details

### Permissions
- Automatically requests speech recognition permission
- Requests microphone access permission
- Handles permission denial gracefully with error messages

### Timer Management
- Uses `Timer.scheduledTimer` for silence detection
- Properly invalidates timer when stopping
- Prevents memory leaks by cleaning up timers

### Animation Details
- **Spring animation** for smooth appearance (response: 0.3, damping: 0.7)
- **Pulsing circles**: Three layers with staggered delays (0, 0.2, 0.4 seconds)
- **Continuous animation**: Uses `.repeatForever(autoreverses: true)`
- **Scale effect**: Ranges from 1.0 to 1.3 for subtle pulsing
- **Opacity fade**: From 0.6 to 0.0 for smooth visual effect

### State Synchronization
- Voice service transcription updates are monitored in real-time
- Text field automatically populated when listening stops
- Keyboard dismissed during voice input for better UX
- Focus state properly managed

## Benefits

1. **Simplified UI**: No complex controls, just a clean animated overlay
2. **Automatic Detection**: No manual stop button needed in most cases
3. **Better UX**: User can focus on speaking rather than UI interaction
4. **Visual Feedback**: Clear indication that system is listening
5. **Flexible**: User can still manually stop by tapping anywhere
6. **Smooth Transitions**: Professional animations enhance experience
7. **Error Handling**: Graceful permission handling and error messages

## Files Modified
- `/Agrisense/Views/Assistant/AssistantView.swift`

## Dependencies
- Uses existing `VoiceTranscriptionService` from `/Agrisense/Services/VoiceTranscriptionService.swift`
- Requires Speech framework
- Requires AVFoundation framework

## Testing Recommendations
1. Test with actual device (simulator may have limited microphone access)
2. Verify permission requests work correctly
3. Test silence detection with various speech patterns
4. Verify transcription accuracy
5. Test manual stop by tapping overlay
6. Verify text appears correctly in chatbox after transcription
7. Test rapid start/stop scenarios
8. Verify animation performance on different devices

## Future Enhancements
- Add volume level visualization (waveform)
- Add language selection for multilingual support
- Add haptic feedback when listening starts/stops
- Add voice commands for common actions
- Add transcript history/correction features
