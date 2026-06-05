import SwiftUI
import UIKit
import PhotosUI

struct ReferenceVideoView: View {
    @State private var promptText: String = ""
    @State private var selectedDuration: String = "6s"
    @State private var selectedQuality: String = "Standard"
    @State private var selectedRatio: String = "9:16"
    @State private var referenceImages: [UIImage?] = Array(repeating: nil, count: 3)
    @State private var activeReferenceIndex: Int?
    @State private var isShowingImagePicker = false
    @State private var isShowingCamera = false
    @State private var imageSelectionError: String?

    @ObservedObject private var videoGenerator = AIVideoGenerator.shared

    var body: some View {
        ZStack {
            AppTheme.bgPrimary.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 32) {
                    referenceImageUploadSection.padding(.top, 24)

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

                    Spacer(minLength: 180)
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
            .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $isShowingCamera) {
            CameraPicker { image in
                applySelectedImage(image)
            }
            .ignoresSafeArea()
        }
    }

    // MARK: - Modern Components

    private var referenceImageUploadSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label("Visual References", systemImage: "photo.stack.fill")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(AppTheme.accentSecondary)

            HStack(spacing: 12) {
                ForEach(0..<3) { index in
                    referenceCard(index: index)
                }
            }

            Text("Add 1–3 images to guide the AI's visual style.")
                .font(.system(size: 12))
                .foregroundColor(AppTheme.textMuted)
                .padding(.leading, 4)
        }
    }

    private func referenceCard(index: Int) -> some View {
        let image = referenceImages[index]
        return Button { openImagePicker(for: index) } label: {
            ZStack {
                if let image = image {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(maxWidth: .infinity)
                        .frame(height: 110)
                        .clipShape(RoundedRectangle(cornerRadius: 18))
                } else {
                    VStack(spacing: 8) {
                        Image(systemName: index == 0 ? "plus.viewfinder" : "plus")
                            .font(.system(size: 20, weight: .semibold))
                        Text(index == 0 ? "Key Frame" : "Add")
                            .font(.system(size: 10, weight: .bold))
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 110)
                    .glassStyle(cornerRadius: 18)
                }
            }
            .primaryBorder(cornerRadius: 18, active: image != nil || index == 0)
        }
        .buttonStyle(.plain)
        .foregroundColor(image != nil ? .white : AppTheme.textMuted)
    }

    private var promptSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Evolution Description", systemImage: "sparkles")
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
                    Text("How should the images transform? Describe the flow...")
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
                        .frame(maxWidth: .infinity)
                        .frame(height: 46)
                        .background(selection.wrappedValue == opt ? AppTheme.accentPrimary.opacity(0.15) : Color.white.opacity(0.05))
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(selection.wrappedValue == opt ? AppTheme.accentPrimary : Color.clear, lineWidth: 1.5)
                        )
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
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(isSelected ? AppTheme.accentPrimary.opacity(0.1) : Color.white.opacity(0.05))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? AppTheme.accentPrimary : Color.white.opacity(0.1), lineWidth: isSelected ? 1.5 : 1)
            )
        }
        .foregroundColor(isSelected ? .white : AppTheme.textSecondary)
    }

    private var bottomActionSection: some View {
        VStack(spacing: 16) {
            Button {
                videoGenerator.generateVideo(
                    prompt: promptText,
                    image: referenceImages.compactMap{$0}.first,
                    endImage: referenceImages.compactMap{$0}.dropFirst().last,
                    duration: selectedDuration,
                    quality: selectedQuality,
                    ratio: selectedRatio
                )
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: "film.fill")
                        .font(.system(size: 20, weight: .bold))
                    Text("Sync & Generate")
                        .font(.system(size: 17, weight: .bold))

                    Spacer()

                    HStack(spacing: 4) {
                        Image(systemName: "bolt.fill")
                        Text("200")
                    }
                    .font(.system(size: 14, weight: .bold))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Color.black.opacity(0.2))
                    .clipShape(Capsule())
                }
                .padding(.horizontal, 24)
                .frame(maxWidth: .infinity)
                .frame(height: 64)
                .background(AppTheme.accentGradH)
                .foregroundColor(.white)
                .clipShape(RoundedRectangle(cornerRadius: 22))
                .shadow(color: AppTheme.accentGlow, radius: 15, y: 8)
            }

            Text("Syncing multiple references may take longer")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(AppTheme.textMuted)
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
        .padding(.bottom, 30)
        .background(
            LinearGradient(colors: [AppTheme.bgPrimary.opacity(0), AppTheme.bgPrimary], startPoint: .top, endPoint: .bottom)
        )
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

    private func openImagePicker(for index: Int) {
        activeReferenceIndex = index
        isShowingImagePicker = true
    }

    private func openCamera() {
        isShowingImagePicker = false
        isShowingCamera = true
    }

    private func applySelectedImage(_ image: UIImage) {
        if let index = activeReferenceIndex { referenceImages[index] = image }
    }

    private func saveVideo(url: URL) {}
    private func shareVideo(url: URL) {}
}
