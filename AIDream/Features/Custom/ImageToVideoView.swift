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

    // 状态反馈提示
    @State private var toastMessage: String?
    @State private var showToast = false

    @ObservedObject private var videoGenerator = AIVideoGenerator.shared

    var body: some View {
        ZStack {
            AppTheme.bgPrimary.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 32) {
                    imageUploadSection.padding(.top, 20)
                    promptSection

                    VStack(spacing: 24) {
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

                    Spacer(minLength: 220)
                }
                .padding(.horizontal, 20)
            }

            VStack {
                Spacer()
                if !isGenerating {
                    bottomActionSection
                }
            }
            .ignoresSafeArea(.keyboard)

            if isGenerating {
                GeneratingView(
                    progress: currentProgress,
                    onBackToHome: { videoGenerator.cancelGeneration() }
                )
                .transition(.opacity)
                .zIndex(10)
            }

            // Toast 提示
            if showToast, let msg = toastMessage {
                VStack {
                    Spacer()
                    Text(msg)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(BlurView(style: .systemUltraThinMaterialDark).clipShape(Capsule()))
                        .padding(.bottom, 150)
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .fullScreenCover(isPresented: completionBinding) {
            if case .completed(let url) = videoGenerator.state {
                VideoCompletionView(
                    media: .video(url),
                    onClose:    { videoGenerator.cancelGeneration() },
                    onRetake:   { videoGenerator.cancelGeneration() },
                    onDownload: { saveVideo(url: url) },
                    onShare:    { shareVideo(url: url) }
                )
                .onAppear {
                    // 修正：参数名需匹配 CreationService 的 url
                    CreationService.shared.addCreation(prompt: promptText, url: url)
                }
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
            .presentationDetents([.height(280)])
        }
        .sheet(isPresented: $isShowingCamera) {
            CameraPicker { image in
                applySelectedImage(image)
            }
            .ignoresSafeArea()
        }
    }

    // MARK: - UI Components
    private var imageUploadSection: some View {
        HStack(spacing: 16) {
            imageCard(title: "Start Frame", image: startImage) { openImagePicker(for: .start) }
            imageCard(title: "End Frame", image: endImage) { openImagePicker(for: .end) }
        }
    }

    private func imageCard(title: String, image: UIImage?, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 12) {
                ZStack {
                    if let image = image {
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(height: 140)
                            .clipShape(RoundedRectangle(cornerRadius: 22))
                    } else {
                        VStack(spacing: 8) {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 28))
                                .foregroundStyle(AppTheme.accentGrad)
                            Text("Upload")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(AppTheme.textSecondary)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 140)
                        .glassStyle(cornerRadius: 22)
                    }
                }
                .primaryBorder(cornerRadius: 22, active: image != nil)

                Text(title)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(image != nil ? .white : AppTheme.textMuted)
            }
        }
        .buttonStyle(.plain)
    }

    private var promptSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Creative Prompt", systemImage: "sparkles")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(AppTheme.accentSecondary)

            ZStack(alignment: .topLeading) {
                TextEditor(text: $promptText)
                    .frame(height: 120)
                    .padding(16)
                    .scrollContentBackground(.hidden)
                    .glassStyle(cornerRadius: 20)
                    .font(.system(size: 15))
                    .foregroundColor(.white)

                if promptText.isEmpty {
                    Text("Describe the motion, atmosphere, and cinematic style...")
                        .font(.system(size: 14))
                        .foregroundColor(AppTheme.textMuted)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 22)
                        .allowsHitTesting(false)
                }
            }
        }
    }

    private func optionRow(title: String, options: [String], selection: Binding<String>, proOptions: [String]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title.uppercased())
                .font(.system(size: 11, weight: .bold))
                .tracking(1.5)
                .foregroundColor(AppTheme.textMuted)

            HStack(spacing: 10) {
                ForEach(options, id: \.self) { opt in
                    Button { selection.wrappedValue = opt } label: {
                        HStack(spacing: 4) {
                            Text(opt)
                                .font(.system(size: 14, weight: selection.wrappedValue == opt ? .bold : .medium))
                            if proOptions.contains(opt) {
                                Image(systemName: "crown.fill").font(.system(size: 10))
                            }
                        }
                        .frame(maxWidth: .infinity).frame(height: 46)
                        .background(selection.wrappedValue == opt ? AppTheme.accentPrimary.opacity(0.15) : Color.white.opacity(0.05))
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .overlay(RoundedRectangle(cornerRadius: 14).stroke(selection.wrappedValue == opt ? AppTheme.accentPrimary : Color.clear, lineWidth: 1.5))
                    }
                    .foregroundColor(selection.wrappedValue == opt ? .white : AppTheme.textSecondary)
                }
            }
        }
    }

    private var aspectRatioSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("ASPECT RATIO")
                .font(.system(size: 11, weight: .bold))
                .tracking(1.5)
                .foregroundColor(AppTheme.textMuted)

            HStack(spacing: 12) {
                ratioButton(label: "9:16", icon: "iphone.gen3", isSelected: selectedRatio == "9:16") { selectedRatio = "9:16" }
                ratioButton(label: "1:1",  icon: "square", isSelected: selectedRatio == "1:1")  { selectedRatio = "1:1" }
            }
        }
    }

    private func ratioButton(label: String, icon: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon).font(.system(size: 18))
                Text(label).font(.system(size: 15, weight: isSelected ? .bold : .medium))
            }
            .frame(maxWidth: .infinity).frame(height: 56)
            .background(isSelected ? AppTheme.accentPrimary.opacity(0.1) : Color.white.opacity(0.05))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(RoundedRectangle(cornerRadius: 16).stroke(isSelected ? AppTheme.accentPrimary : Color.white.opacity(0.1), lineWidth: isSelected ? 1.5 : 1))
        }
        .foregroundColor(isSelected ? .white : AppTheme.textSecondary)
    }

    private var bottomActionSection: some View {
        VStack(spacing: 16) {
            Button {
                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                videoGenerator.generateVideo(
                    prompt: promptText,
                    image: startImage,
                    endImage: endImage,
                    duration: selectedDuration,
                    quality: selectedQuality,
                    ratio: selectedRatio
                )
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: "wand.and.rays").font(.system(size: 20, weight: .bold))
                    Text("Generate Creation").font(.system(size: 17, weight: .bold))
                    Spacer()
                    HStack(spacing: 4) {
                        Image(systemName: "bolt.fill")
                        Text("200")
                    }
                    .font(.system(size: 14, weight: .bold))
                    .padding(.horizontal, 10).padding(.vertical, 4)
                    .background(Color.black.opacity(0.2)).clipShape(Capsule())
                }
                .padding(.horizontal, 24).frame(maxWidth: .infinity).frame(height: 64)
                .background(AppTheme.accentGradH).foregroundColor(.white)
                .clipShape(RoundedRectangle(cornerRadius: 22))
                .shadow(color: AppTheme.accentGlow, radius: 15, y: 8)
            }

            HStack(spacing: 6) {
                Image(systemName: "checkmark.seal.fill").foregroundColor(AppTheme.accentSecondary)
                Text("Quality Guaranteed · Refundable").font(.system(size: 12, weight: .medium)).foregroundColor(AppTheme.textMuted)
            }
        }
        .padding(.horizontal, 20).padding(.top, 20)
        .padding(.bottom, 140)
        .background(
            LinearGradient(colors: [AppTheme.bgPrimary.opacity(0), AppTheme.bgPrimary], startPoint: .top, endPoint: .bottom)
        )
    }

    // MARK: - Actions
    private func saveVideo(url: URL) {
        Task {
            do {
                showToast(message: "Downloading video...")
                let (tempData, _) = try await URLSession.shared.data(from: url)
                let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".mp4")
                try tempData.write(to: tempURL)

                UISaveVideoAtPathToSavedPhotosAlbum(tempURL.path, nil, nil, nil)
                showToast(message: "Video saved to gallery")
            } catch {
                print("Save error: \(error)")
                showToast(message: "Failed to save video")
            }
        }
    }

    private func shareVideo(url: URL) {
        let av = UIActivityViewController(activityItems: [url], applicationActivities: nil)
        if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootVC = scene.windows.first?.rootViewController {
            rootVC.present(av, animated: true)
        }
    }

    private func showToast(message: String) {
        toastMessage = message
        withAnimation { showToast = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            withAnimation { showToast = false }
        }
    }

    // MARK: - Helpers
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

    private func openImagePicker(for target: ImageFrameTarget) {
        activeImageTarget = target
        isShowingImagePicker = true
    }

    private func openCamera() {
        isShowingImagePicker = false
        isShowingCamera = true
    }

    private func applySelectedImage(_ image: UIImage) {
        if activeImageTarget == .start { startImage = image } else { endImage = image }
    }
}

private enum ImageFrameTarget { case start, end }
