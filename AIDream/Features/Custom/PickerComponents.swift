import SwiftUI
import PhotosUI

// MARK: - 全局唯一的图片来源选择器
struct ImageSourcePickerView: View {
    var onClose: () -> Void
    var onPickCamera: () -> Void
    var onImageSelected: (UIImage) -> Void
    @State private var selectedPhotoItem: PhotosPickerItem?

    var body: some View {
        ZStack {
            AppTheme.bgSecondary.ignoresSafeArea()
            VStack(spacing: 24) {
                Capsule().fill(Color.white.opacity(0.1)).frame(width: 40, height: 4).padding(.top, 10)
                HStack {
                    Text("Source").font(.system(size: 20, weight: .bold)).foregroundColor(.white)
                    Spacer()
                    Button(action: onClose) {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(AppTheme.textMuted)
                    }
                }.padding(.horizontal, 24)

                HStack(spacing: 16) {
                    pickerTile(icon: "camera.fill", title: "Camera", action: onPickCamera)
                    PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                        pickerTile(icon: "photo.on.rectangle.angled", title: "Library", action: {})
                    }.buttonStyle(.plain)
                }.padding(.horizontal, 24)
                Spacer()
            }
        }
        .onChange(of: selectedPhotoItem) { item in
            guard let item = item else { return }
            Task {
                if let data = try? await item.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {
                    await MainActor.run { onImageSelected(image) }
                }
            }
        }
    }

    private func pickerTile(icon: String, title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 12) {
                Image(systemName: icon).font(.system(size: 28)).foregroundStyle(AppTheme.accentGrad)
                Text(title).font(.system(size: 15, weight: .bold)).foregroundColor(.white)
            }
            .frame(maxWidth: .infinity).frame(height: 120)
            .background(Color.white.opacity(0.05)).clipShape(RoundedRectangle(cornerRadius: 24))
            .overlay(RoundedRectangle(cornerRadius: 24).stroke(Color.white.opacity(0.1), lineWidth: 1))
        }
    }
}

// MARK: - 全局唯一的相机拍摄器
struct CameraPicker: UIViewControllerRepresentable {
    var onImageSelected: (UIImage) -> Void
    @Environment(\.dismiss) private var dismiss

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ ui: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(onImageSelected: onImageSelected, dismiss: dismiss)
    }

    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let onImageSelected: (UIImage) -> Void
        let dismiss: DismissAction

        init(onImageSelected: @escaping (UIImage) -> Void, dismiss: DismissAction) {
            self.onImageSelected = onImageSelected
            self.dismiss = dismiss
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let image = info[.originalImage] as? UIImage {
                onImageSelected(image)
            }
            dismiss()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            dismiss()
        }
    }
}
