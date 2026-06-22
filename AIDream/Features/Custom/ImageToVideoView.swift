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
    @State private var showErrorBanner = false
    @State private var showInsufficientDiamondsAlert = false

    // 统一弹窗管理
    enum ActiveSheet: Identifiable {
        case generating
        case completion(URL)
        case premium
        case diamondStore
        case imagePicker(target: ImageFrameTarget)

        var id: String {
            switch self {
            case .generating: return "generating"
            case .completion: return "completion"
            case .premium: return "premium"
            case .diamondStore: return "diamondStore"
            case .imagePicker(let target): return "imagePicker_\(target == .start ? "start" : "end")"
            }
        }
    }
    @State private var activeSheet: ActiveSheet? = nil

    @ObservedObject private var videoGenerator = AIVideoGenerator.shared
    @ObservedObject private var userService = UserService.shared

    private let generationCost = 300 // 每次以图生成视频 消耗300砖石

    private var isInputValid: Bool {
        let hasPrompt = !promptText.trimmingCharacters(in: .whitespaces).isEmpty
        let hasImage = startImage != nil
        return hasPrompt && hasImage
    }

    var body: some View {
        ZStack {
            AppTheme.bgPrimary.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 32) {
                    imageUploadSection.padding(.top, 20)
                    promptSection

                    VStack(spacing: 24) {
                        optionRow(title: NSLocalizedString("label_duration", comment: ""),
                                  options: ["6s", "10s"],
                                  selection: $selectedDuration,
                                  proOptions: ["10s"])

                        optionRow(title: NSLocalizedString("label_quality", comment: ""),
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
                if activeSheet == nil {
                    bottomActionSection
                }
            }
            .ignoresSafeArea(.keyboard)

            // 生成失败提示
            if showErrorBanner, case .failed(let msg) = videoGenerator.state {
                VStack {
                    Spacer()
                    HStack(spacing: 12) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(AppTheme.error)
                        Text(msg)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(AppTheme.error)
                        Button(NSLocalizedString("btn_retry", comment: "")) { handleGenerate() }
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(AppTheme.accentSecondary)
                    }
                    .padding(16)
                    .glassStyle(cornerRadius: 16)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 200)
                }
                .transition(.opacity)
                .zIndex(5)
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
                        .glassStyle(cornerRadius: 25)
                        .padding(.bottom, 150)
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .fullScreenCover(item: Binding(
            get: {
                if case .imagePicker = activeSheet { return nil }
                return activeSheet
            },
            set: { activeSheet = $0 }
        )) { sheet in
            switch sheet {
            case .generating:
                GeneratingView(
                    progress: currentProgress,
                    onBackToHome: { videoGenerator.cancelGeneration(); activeSheet = nil }
                )
            case .completion(let url):
                VideoCompletionView(
                    media: .video(url),
                    onClose:    { videoGenerator.cancelGeneration(); activeSheet = nil },
                    onRetake:   { videoGenerator.cancelGeneration(); activeSheet = nil },
                    onDownload: { saveVideo(url: url) },
                    onShare:    { shareVideo(url: url) }
                )
                .onAppear {
                    CreationService.shared.addCreation(prompt: promptText, url: url)
                }
            case .premium:
                PremiumView()
            case .diamondStore:
                DiamondStoreView()
            case .imagePicker:
                EmptyView() // 已移动到 .sheet
            }
        }
        .sheet(item: Binding(
            get: {
                if case .imagePicker = activeSheet { return activeSheet }
                return nil
            },
            set: { activeSheet = $0 }
        )) { sheet in
            if case .imagePicker = sheet {
                ImageSourcePickerView(
                    onClose: { activeSheet = nil },
                    onPickCamera: { openCamera() },
                    onImageSelected: { image in
                        applySelectedImage(image)
                        activeSheet = nil
                    }
                )
                .presentationDetents([.height(280)])
                .presentationDragIndicator(.visible)
            }
        }
        .onChange(of: videoGenerator.state) { newState in
            switch newState {
            case .completed(let url):
                activeSheet = nil
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                    activeSheet = .completion(url)
                }
            case .failed:
                activeSheet = nil
                withAnimation { showErrorBanner = true }
                DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
                    withAnimation { showErrorBanner = false }
                }
            case .uploading, .generating:
                showErrorBanner = false
                if activeSheet == nil { activeSheet = .generating }
            case .idle:
                if case .generating = activeSheet { activeSheet = nil }
            }
        }
        .sheet(isPresented: $isShowingCamera) {
            CameraPicker { image in
                applySelectedImage(image)
            }
            .ignoresSafeArea()
        }
        .alert(NSLocalizedString("alert_insufficient_diamonds", comment: ""), isPresented: $showInsufficientDiamondsAlert) {
            if userService.isPremium {
                Button(NSLocalizedString("btn_get_diamonds", comment: "")) { activeSheet = .diamondStore }
            } else {
                Button(NSLocalizedString("btn_upgrade_pro", comment: "")) { activeSheet = .premium }
            }
            Button(NSLocalizedString("btn_cancel", comment: ""), role: .cancel) {}
        } message: {
            if userService.isPremium {
                Text(String(format: NSLocalizedString("alert_recharge_msg", comment: ""), generationCost))
            } else {
                Text(String(format: NSLocalizedString("alert_subscribe_pro_msg", comment: ""), generationCost))
            }
        }
    }

    // MARK: - UI Components
    private var imageUploadSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label(NSLocalizedString("label_animate_vision", comment: ""), systemImage: "photo.on.rectangle.angled")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(AppTheme.accentSecondary)

            HStack(spacing: 16) {
                imageCard(title: NSLocalizedString("label_start_frame", comment: ""), image: startImage) { openImagePicker(for: .start) }
                imageCard(title: NSLocalizedString("label_end_frame", comment: ""), image: endImage) { openImagePicker(for: .end) }
            }
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
                            Text(NSLocalizedString("btn_upload", comment: ""))
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
        VStack(alignment: .leading, spacing: 16) {
            Label(NSLocalizedString("label_imagination_prompt", comment: ""), systemImage: "sparkles")
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
                    Text(NSLocalizedString("placeholder_image_to_video", comment: ""))
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
        VStack(alignment: .leading, spacing: 16) {
            Text(title.uppercased())
                .font(.system(size: 11, weight: .bold))
                .tracking(1.5)
                .foregroundColor(AppTheme.textMuted)

            HStack(spacing: 10) {
                ForEach(options, id: \.self) { opt in
                    Button {
                        if proOptions.contains(opt) && !userService.isPremium {
                            activeSheet = .premium
                        } else {
                            selection.wrappedValue = opt
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Text(opt)
                                .font(.system(size: 14, weight: selection.wrappedValue == opt ? .bold : .medium))
                            if proOptions.contains(opt) {
                                Image(systemName: "crown.fill").font(.system(size: 10))
                                    .foregroundColor(userService.isPremium ? AppTheme.vipGold : AppTheme.textMuted)
                            }
                        }
                        .frame(maxWidth: .infinity).frame(height: 46)
                        .background(selection.wrappedValue == opt ? AppTheme.accentPrimary.opacity(0.15) : Color.white.opacity(0.05))
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .overlay(RoundedRectangle(cornerRadius: 14).stroke(selection.wrappedValue == opt ? AppTheme.accentPrimary : Color.white.opacity(0.1), lineWidth: selection.wrappedValue == opt ? 1.5 : 0.5))
                    }
                    .foregroundColor(selection.wrappedValue == opt ? .white : AppTheme.textSecondary)
                }
            }
        }
    }

    private var aspectRatioSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(NSLocalizedString("label_aspect_ratio", comment: ""))
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
            .overlay(RoundedRectangle(cornerRadius: 16).stroke(isSelected ? AppTheme.accentPrimary : Color.white.opacity(0.1), lineWidth: isSelected ? 1.5 : 0.5))
        }
        .foregroundColor(isSelected ? .white : AppTheme.textSecondary)
    }

    private var bottomActionSection: some View {
        VStack(spacing: 16) {
            Button {
                handleGenerate()
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: "wand.and.rays").font(.system(size: 20, weight: .bold))
                    Text(NSLocalizedString("btn_generate_creation", comment: ""))
                        .font(.system(size: 17, weight: .bold))
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                    Spacer()
                    HStack(spacing: 4) {
                        Text("💎")
                        Text("\(generationCost)")
                    }
                    .font(.system(size: 14, weight: .bold))
                    .padding(.horizontal, 10).padding(.vertical, 4)
                    .background(Color.black.opacity(0.2)).clipShape(Capsule())
                }
                .padding(.horizontal, 24).frame(maxWidth: .infinity).frame(height: 64)
                .background(isInputValid ? AnyShapeStyle(AppTheme.accentGradH) : AnyShapeStyle(Color(white: 0.15)))
                .foregroundColor(isInputValid ? .white : AppTheme.textMuted)
                .clipShape(RoundedRectangle(cornerRadius: 22))
                .shadow(color: isInputValid ? AppTheme.accentGlow : Color.clear, radius: 15, y: 8)
            }
            .disabled(!isInputValid)

            HStack(spacing: 6) {
                Image(systemName: "checkmark.seal.fill").foregroundColor(AppTheme.accentSecondary)
                Text(NSLocalizedString("label_quality_guaranteed", comment: "")).font(.system(size: 12, weight: .medium)).foregroundColor(AppTheme.textMuted)
            }
        }
        .padding(.horizontal, 20).padding(.top, 32)
        .padding(.bottom, 140)
        .background(
            LinearGradient(
                colors: [
                    AppTheme.bgPrimary.opacity(0),
                    AppTheme.bgPrimary.opacity(0.7),
                    AppTheme.bgPrimary.opacity(0.95),
                    AppTheme.bgPrimary
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
        )
    }

    // MARK: - Actions
    private func handleGenerate() {
        showErrorBanner = false
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)

        // Check Pro requirement for current selections
        let proOptionsInEffect = (["10s"].contains(selectedDuration)) || (["High", "Ultra HD"].contains(selectedQuality))
        if proOptionsInEffect && !userService.isPremium {
            activeSheet = .premium
            return
        }

        if userService.consumeDiamonds(generationCost, reason: "Image to Video") {
            videoGenerator.generateVideo(
                prompt: promptText,
                image: startImage,
                endImage: endImage,
                duration: selectedDuration,
                quality: selectedQuality,
                ratio: selectedRatio
            )
        } else {
            showInsufficientDiamondsAlert = true
        }
    }

    private func saveVideo(url: URL) {
        Task {
            do {
                showToast(message: NSLocalizedString("state_downloading", comment: ""))
                var request = URLRequest(url: url)
                if url.absoluteString.contains("openrouter.ai") {
                    request.setValue("Bearer \(AIConfig.shared.openRouterApiKey)", forHTTPHeaderField: "Authorization")
                }

                let (tempData, response) = try await URLSession.shared.data(for: request)
                if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode != 200 {
                    throw NSError(domain: "DownloadError", code: httpResponse.statusCode)
                }

                let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".mp4")
                try tempData.write(to: tempURL)

                DispatchQueue.main.async {
                    UISaveVideoAtPathToSavedPhotosAlbum(tempURL.path, nil, nil, nil)
                    showToast(message: NSLocalizedString("state_completed", comment: ""))
                }
            } catch {
                print("Save failed: \(error)")
                showToast(message: NSLocalizedString("err_creation_failed", comment: ""))
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
        case .uploading, .generating(_): return true
        default: return false
        }
    }

    private var currentProgress: Double {
        if case .generating(let p) = videoGenerator.state { return p }
        return 0.05
    }

    private var generatingBinding: Binding<Bool> {
        Binding(
            get: {
                switch videoGenerator.state {
                case .uploading, .generating(_): return true
                default: return false
                }
            },
            set: { if !$0 { videoGenerator.cancelGeneration() } }
        )
    }

    private var completionBinding: Binding<Bool> {
        Binding(
            get: { if case .completed(_) = videoGenerator.state { return true } else { return false } },
            set: { if !$0 { videoGenerator.cancelGeneration() } }
        )
    }

    private func openImagePicker(for target: ImageFrameTarget) {
        activeImageTarget = target
        activeSheet = .imagePicker(target: target)
    }

    private func openCamera() {
        activeSheet = nil
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            isShowingCamera = true
        }
    }

    private func applySelectedImage(_ image: UIImage) {
        if activeImageTarget == .start {
            startImage = image
        } else {
            endImage = image
        }
    }

    enum ImageFrameTarget {
        case start, end
    }
}
