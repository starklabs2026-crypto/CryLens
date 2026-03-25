import SwiftUI
import UniformTypeIdentifiers

struct AudioFilePicker: UIViewControllerRepresentable {
    var onFilePicked: (URL) -> Void
    var onCancel: () -> Void

    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: [
            UTType.audio,
            UTType.mp3,
            UTType.mpeg4Audio,
            UTType(filenameExtension: "m4a") ?? .audio,
            UTType(filenameExtension: "wav") ?? .audio,
            UTType(filenameExtension: "aac") ?? .audio,
            UTType(filenameExtension: "caf") ?? .audio
        ])
        picker.allowsMultipleSelection = false
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(onFilePicked: onFilePicked, onCancel: onCancel)
    }

    class Coordinator: NSObject, UIDocumentPickerDelegate {
        let onFilePicked: (URL) -> Void
        let onCancel: () -> Void

        init(onFilePicked: @escaping (URL) -> Void, onCancel: @escaping () -> Void) {
            self.onFilePicked = onFilePicked
            self.onCancel = onCancel
        }

        nonisolated func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            guard let url = urls.first else { return }
            guard url.startAccessingSecurityScopedResource() else { return }

            let tempURL = FileManager.default.temporaryDirectory
                .appendingPathComponent(url.lastPathComponent)
            try? FileManager.default.removeItem(at: tempURL)
            try? FileManager.default.copyItem(at: url, to: tempURL)
            url.stopAccessingSecurityScopedResource()

            Task { @MainActor in
                self.onFilePicked(tempURL)
            }
        }

        nonisolated func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
            Task { @MainActor in
                self.onCancel()
            }
        }
    }
}
