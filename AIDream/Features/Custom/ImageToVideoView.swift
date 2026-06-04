import SwiftUI
import PhotosUI
import UIKit

struct ImageToVideoView: View {
    @State private var promptText: String = ""
    @State private var selectedDuration: String = "6s"
    @State private var selectedQuality: String = "Standard"
    @State private var selectedRatio: String = "9:16"
    @State private var activeImageTarget: ImageFrameTarget?
    @State private var isShowingImagePicker = false
    @State private var isShowingCamera = false
    @State private var startImage: UIImage?
    @State private var endImage: UIImage?
    @State private var imageSelectionError: String?

    @ObservedObject private var videoGenerator = AIVideoGenerator.shared

    var body: some View {
        ZStack {
            AppTheme.bgPrimary.ignoresSafeArea()

            // ── 滚动内容区 ──
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 28) {
                    imageUploadSection.padding(.top, 16)
                    promptSection
                    VStack(spacing: 22) {
                        optionRow(title: "Duration",
                                  options: ["6s", "10s"],
                                  selection: $selectedDuration,
                                  proOptions: ["10s"])
                        optionRow(title: "Quality",
                                  options: ["Standard", "High", "Ultra HD"],
                                  selection: $selectedQuality,
                                  proOptions: ["High", "Ultra HD"])
                        aspectRatioSection
                    }
                    Spacer(minLength: 140)   // 为底部操作栏留出空间
                }
                .padding(.horizontal, 16)
            }

            // ── 底部操作栏（固定在底部）──
            VStack {
                Spacer()
                if !isGenerating {
                    bottomActionSection
                }
            }

            // ── 生成中全屏遮罩 ──
            if isGenerating {
                GeneratingView(
                    progress: currentProgress,
                    onBackToHome: { videoGenerator.cancelGeneration() }
                )
                .transition(.opacity)
                .zIndex(10)
            }
        }
        // ── 生成完成全屏展示 ──
        .fullScreenCover(isPresented: completionBinding) {
            if case .completed(let url) = videoGenerator.state {
                VideoCompletionView(
                    media: .video(url),
                    onClose:    { videoGenerator.cancelGeneration() },
                    onRetake:   { videoGenerator.cancelGeneration() },
                    onDownload: { saveVideo(url: url) },
                    onShare:    { shareVideo(url: url) }
                )
            }
        }
        .sheet(isPresented: $isShowingImagePicker) {
            ImageSourcePickerView(
                onClose: { isShowingImagePicker = false },
                onPickCamera: { openCamera() },
                onImageSelected: { image in
                    applySelectedImage(image)
                    isShowingImagePicker = false
                }
            )
            .presentationDetents([.height(260)])
            .presentationDragIndicator(.hidden)
            .presentationCornerRadius(26)
        }
        .sheet(isPresented: $isShowingCamera) {
            CameraPicker { image in
                applySelectedImage(image)
            }
            .ignoresSafeArea()
        }
        .animation(.easeInOut(duration: 0.3), value: isGenerating)
    }

    // MARK: - Bindings / Helpers

    private var isGenerating: Bool {
        switch videoGenerator.state {
        case .uploading, .generating: return true
        default: return false
        }
    }

    private var currentProgress: Double {
        if case .generating(let p) = videoGenerator.state { return p }
        return 0.05
    }

    private var completionBinding: Binding<Bool> {
        Binding(
            get: { if case .completed = videoGenerator.state { return true } else { return false } },
            set: { if !$0 { videoGenerator.cancelGeneration() } }
        )
    }

    private func saveVideo(url: URL) {
        // TODO: 保存到相册
        print("[ImageToVideo] Save video: \(url)")
    }

    private func shareVideo(url: URL) {
        let vc = UIActivityViewController(activityItems: [url], applicationActivities: nil)
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first?.windows.first?.rootViewController?
            .present(vc, animated: true)
    }

    // MARK: - 图片上传区

    private var imageUploadSection: some View {
        VStack(spacing: 14) {
            HStack(spacing: 12) {
                imageCard(
                    title: "Start",
                    selectedImage: startImage,
                    placeholderText: "Add Start Frame"
                ) {
                    openImagePicker(for: .start)
                }
                imageCard(
                    title: "End",
                    selectedImage: endImage,
                    placeholderText: "Add End Frame"
                ) {
                    openImagePicker(for: .end)
                }
            }
            Text("Source Image (Optional)")
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(AppTheme.textSecondary)
                .padding(.leading, 4)
            if let imageSelectionError {
                Text(imageSelectionError)
                    .font(.system(size: 12))
                    .foregroundColor(.red.opacity(0.85))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.leading, 4)
            }
        }
    }

    private func imageCard(
        title: String,
        selectedImage: UIImage?,
        placeholderText: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            ZStack(alignment: .topLeading) {
                if let selectedImage {
                    Image(uiImage: selectedImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 106, height: 136)
                        .cornerRadius(18)
                        .clipped()
                        .goldBorder(cornerRadius: 18, active: true)
                } else {
                    VStack(spacing: 10) {
                        Image(systemName: "plus")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundStyle(AppTheme.goldGrad)
                        Text(placeholderText)
                            .font(.system(size: 11))
                            .foregroundColor(AppTheme.textMuted)
                            .multilineTextAlignment(.center)
                    }
                    .frame(width: 106, height: 136)
                    .background(AppTheme.bgCard)
                    .cornerRadius(18)
                    .goldBorder(cornerRadius: 18, active: false)
                }

                Text(title)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color.black.opacity(0.55))
                    .clipShape(Capsule())
                    .padding(8)
            }
        }
        .buttonStyle(.plain)
    }

    private func openImagePicker(for target: ImageFrameTarget) {
        activeImageTarget = target
        imageSelectionError = nil
        isShowingImagePicker = true
    }

    private func openCamera() {
        guard UIImagePickerController.isSourceTypeAvailable(.camera) else {
            imageSelectionError = "Camera is unavailable on this device."
            isShowingImagePicker = false
            return
        }

        isShowingImagePicker = false
        isShowingCamera = true
    }

    private func applySelectedImage(_ image: UIImage) {
        switch activeImageTarget {
        case .start:
            startImage = image
        case .end:
            endImage = image
        case .none:
            startImage = image
        }
        imageSelectionError = nil
    }

    // MARK: - Prompt

    private var promptSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("PROMPT")
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(AppTheme.textMuted)
                .tracking(1.2)
                .padding(.leading, 4)

            ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: 18)
                    .fill(AppTheme.bgCard)
                    .frame(height: 140)
                    .overlay(RoundedRectangle(cornerRadius: 18)
                        .stroke(AppTheme.borderSubtle, lineWidth: 0.5))

                TextEditor(text: $promptText)
                    .frame(height: 140)
                    .padding(12)
                    .scrollContentBackground(.hidden)
                    .font(.system(size: 15))
                    .foregroundColor(.white)

                if promptText.isEmpty {
                    Text("Describe the scene, action and style…")
                        .font(.system(size: 14))
                        .foregroundColor(AppTheme.textMuted)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 20)
                        .allowsHitTesting(false)
                }
            }
        }
    }

    // MARK: - Options

    private func optionRow(
        title: String,
        options: [String],
        selection: Binding<String>,
        proOptions: [String]
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title.uppercased())
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(AppTheme.textMuted)
                .tracking(1.2)
                .padding(.leading, 4)

            HStack(spacing: 8) {
                ForEach(options, id: \.self) { opt in
                    Button { selection.wrappedValue = opt } label: {
                        HStack(spacing: 5) {
                            Text(opt)
                                .font(.system(size: 14,
                                    weight: selection.wrappedValue == opt ? .bold : .regular))
                                .foregroundColor(.white)
                            if proOptions.contains(opt) { proTag }
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .optionStyle(selected: selection.wrappedValue == opt)
                    }
                }
            }
        }
    }

    private var proTag: some View {
        Text("PRO")
            .font(.system(size: 9, weight: .bold))
            .padding(.horizontal, 5).padding(.vertical, 2)
            .foregroundColor(Color(hex: "#0A0A0A"))
            .background(AppTheme.goldGradH)
            .clipShape(Capsule())
    }

    private var aspectRatioSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("ASPECT RATIO")
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(AppTheme.textMuted)
                .tracking(1.2)
                .padding(.leading, 4)

            HStack(spacing: 8) {
                ratioButton(label: "9:16", icon: "iphone",
                            isSelected: selectedRatio == "9:16") { selectedRatio = "9:16" }
                ratioButton(label: "1:1",  icon: "square",
                            isSelected: selectedRatio == "1:1")  { selectedRatio = "1:1" }
            }
        }
    }

    private func ratioButton(label: String, icon: String,
                              isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 6) {
                ZStack(alignment: .topTrailing) {
                    Image(systemName: icon).font(.system(size: 20))
                    proTag.offset(x: 12, y: -8)
                }
                Text(label).font(.system(size: 13, weight: isSelected ? .bold : .regular))
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity).frame(height: 64)
            .optionStyle(selected: isSelected, cornerRadius: 18)
        }
    }

    // MARK: - 底部操作栏

    private var bottomActionSection: some View {
        VStack(spacing: 14) {
            HStack(spacing: 5) {
                Text("Want faster generation?").foregroundColor(AppTheme.textMuted)
                Text("Get SVIP (50% OFF)")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(AppTheme.goldGradH)
            }
            .font(.system(size: 12))

            Button {
                videoGenerator.generateVideo(
                    prompt: promptText,
                    image: startImage,
                    endImage: endImage,
                    duration: selectedDuration,
                    quality: selectedQuality,
                    ratio: selectedRatio
                )
            } label: {
                VStack(spacing: 4) {
                    Text("Generate Video")
                        .font(.system(size: 17, weight: .bold))
                    HStack(spacing: 4) {
                        Image(systemName: "diamond.fill").font(.system(size: 11))
                        Text("200").font(.system(size: 13, weight: .bold))
                    }
                    .foregroundColor(Color(hex: "#0A0A0A"))
                }
                .foregroundColor(Color(hex: "#0A0A0A"))
                .frame(maxWidth: .infinity).frame(height: 60)
                .background(AppTheme.goldGradH)
                .cornerRadius(22)
                .shadow(color: AppTheme.goldGlow, radius: 12, y: 5)
            }

            HStack(spacing: 5) {
                Image(systemName: "checkmark.shield.fill").foregroundStyle(AppTheme.goldGradH)
                Text("Failed task? 100% Refund.").foregroundColor(AppTheme.textSecondary)
            }
            .font(.system(size: 12))
        }
        .padding(20).padding(.bottom, 20)
        .background(
            ZStack {
                AppTheme.bgSecondary
                Color.white.opacity(0.015)
            }
            .overlay(Rectangle().fill(AppTheme.borderSubtle).frame(height: 0.5), alignment: .top)
        )
    }

}

private enum ImageFrameTarget {
    case start
    case end
}

struct ImageSourcePickerView: View {
    var onClose: () -> Void
    var onPickCamera: () -> Void
    var onImageSelected: (UIImage) -> Void

    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var photoLoadError: String?

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(hex: "#141416"),
                    Color(hex: "#1C181B"),
                    Color(hex: "#171421")
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 16) {
                Capsule()
                    .fill(Color.white.opacity(0.24))
                    .frame(width: 58, height: 6)
                    .padding(.top, 12)

                HStack {
                    Text("Choose Image")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.white)

                    Spacer()

                    Button(action: onClose) {
                        Image(systemName: "xmark")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(width: 42, height: 42)
                            .background(
                                Circle()
                                    .fill(Color.white.opacity(0.10))
                                    .overlay(Circle().stroke(Color.white.opacity(0.18), lineWidth: 1))
                            )
                    }
                }

                HStack(spacing: 12) {
                    Button(action: onPickCamera) {
                        sourceActionTile(icon: "camera.fill", title: "Camera")
                    }
                    .buttonStyle(.plain)

                    PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                        sourceActionTile(icon: "photo.on.rectangle.angled", title: "Photos")
                    }
                    .buttonStyle(.plain)
                }

                if let photoLoadError {
                    Text(photoLoadError)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.red.opacity(0.9))
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                Spacer(minLength: 0)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 18)
        }
        .onChange(of: selectedPhotoItem) { item in
            loadPhoto(from: item)
        }
    }

    private func sourceActionTile(icon: String, title: String) -> some View {
        VStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 34, weight: .regular))
                .symbolRenderingMode(.palette)
                .foregroundStyle(Color(hex: "#F0CF7B"), Color.white.opacity(0.75))
            Text(title)
                .font(.system(size: 17, weight: .bold))
                .foregroundColor(.white.opacity(0.90))
        }
        .frame(maxWidth: .infinity)
        .frame(height: 112)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white.opacity(0.07))
        )
    }

    private func loadPhoto(from item: PhotosPickerItem?) {
        guard let item else { return }
        photoLoadError = nil

        Task {
            do {
                guard let data = try await item.loadTransferable(type: Data.self),
                      let image = UIImage(data: data) else {
                    throw ImageSelectionError.invalidImage
                }
                await MainActor.run {
                    onImageSelected(image)
                }
            } catch {
                await MainActor.run {
                    photoLoadError = "Failed to load selected photo."
                }
            }
        }
    }

    private enum ImageSelectionError: Error {
        case invalidImage
    }
}

struct CameraPicker: UIViewControllerRepresentable {
    var onImageSelected: (UIImage) -> Void

    @Environment(\.dismiss) private var dismiss

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let controller = UIImagePickerController()
        controller.sourceType = .camera
        controller.delegate = context.coordinator
        controller.allowsEditing = false
        return controller
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(onImageSelected: onImageSelected, dismiss: dismiss)
    }

    final class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        private let onImageSelected: (UIImage) -> Void
        private let dismiss: DismissAction

        init(onImageSelected: @escaping (UIImage) -> Void, dismiss: DismissAction) {
            self.onImageSelected = onImageSelected
            self.dismiss = dismiss
        }

        func imagePickerController(
            _ picker: UIImagePickerController,
            didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
        ) {
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
