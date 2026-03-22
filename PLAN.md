# Add Audio File Upload & Analysis

**Features**
- Upload an audio file (M4A, WAV, MP3, AAC, CAF) from your device's Files app
- The app analyzes the uploaded file the same way it analyzes a live recording
- Silent files and files that are too short or too long are rejected with a clear message
- Temporary copies of uploaded files are cleaned up after analysis

**Design**
- An "or" divider appears below the waveform area, separating live recording from file upload
- A subtle "Upload Audio File" button with an upload icon sits below the divider
- When analyzing an uploaded file, a spinner shows the file name being analyzed
- The button is disabled while recording or analyzing

**Changes**
1. **New: Audio File Analyzer service** — Reads an audio file, calculates duration, average loudness, and peak loudness using the same metrics as live recording
2. **New: Audio File Picker** — A native iOS file picker that lets you browse and select audio files from your device
3. **Updated: Listen screen logic** — Adds a new function to analyze a picked file, validate it, send it for cry analysis, and save the result to history
4. **Updated: Listen screen layout** — Adds the "or" divider and upload button below the waveform, plus a file-specific analyzing indicator