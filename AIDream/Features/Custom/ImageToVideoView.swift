import SwiftUI

struct ImageToVideoView: View {
    @State private var promptText: String = ""
    @State private var selectedDuration: String = "5s"
    @State private var selectedQuality: String = "Standard"

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    imageToVideoContent

                    promptSection

                    videoOptions

                    Spacer(minLength: 120)
                }
                .padding(.horizontal, 16)
                .padding(.top, 20)
            }

            bottomActionSection
        }
        .background(Color(hex: "#0c0c0c"))
    }

    // MARK: - Components

    private var imageToVideoContent: some View {
        VStack(spacing: 16) {
            HStack(spacing: 12) {
                // Start Frame
                frameContainer(title: "Start", image: "portrait_placeholder") {
                    // Action to remove/change image
                }

                // End Frame
                frameContainer(title: "End", image: nil) {
                    // Action to add image
                }
            }
            .frame(maxWidth: .infinity)

            Text("Source Image (Optional)")
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.4))
        }
    }

    private func frameContainer(title: String, image: String?, action: @escaping () -> Void) -> some View {
        ZStack(alignment: .topLeading) {
            if let imageName = image {
                Image(imageName)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(maxWidth: .infinity)
                    .frame(height: 180)
                    .cornerRadius(20)
                    .clipped()
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color.white.opacity(0.05), lineWidth: 1)
                    )

                Button(action: action) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.white.opacity(0.7))
                }
                .padding(8)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
            } else {
                Button(action: action) {
                    VStack(spacing: 8) {
                        Image(systemName: "plus")
                            .font(.system(size: 24))
                        Text("Add \(title) Frame")
                            .font(.system(size: 12))
                    }
                    .foregroundColor(.white.opacity(0.4))
                    .frame(maxWidth: .infinity)
                    .frame(height: 180)
                    .background(Color.white.opacity(0.05))
                    .cornerRadius(20)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(style: StrokeStyle(lineWidth: 1, dash: [5]))
                            .foregroundColor(.white.opacity(0.2))
                    )
                }
            }

            Text(title)
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(.white)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.black.opacity(0.5))
                .cornerRadius(8)
                .padding(8)
        }
    }

    private var promptSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("prompt")
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.4))
                .padding(.leading, 6)

            ZStack(alignment: .bottomTrailing) {
                ZStack(alignment: .topLeading) {
                    TextEditor(text: $promptText)
                        .frame(height: 140)
                        .padding(12)
                        .scrollContentBackground(.hidden)
                        .background(Color.white.opacity(0.05))
                        .cornerRadius(20)
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(Color.white.opacity(0.05), lineWidth: 1)
                        )

                    if promptText.isEmpty {
                        Text("Describe the scene, action, and style...")
                            .font(.system(size: 15))
                            .foregroundColor(.white.opacity(0.2))
                            .padding(.leading, 16)
                            .padding(.top, 20)
                            .allowsHitTesting(false)
                    }
                }

                HStack(spacing: 4) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 12))
                    Text("AI Expand")
                        .font(.system(size: 12, weight: .bold))

                    Text("SVIP")
                        .font(.system(size: 8, weight: .black))
                        .padding(.horizontal, 4)
                        .padding(.vertical, 1)
                        .background(Color(hex: "#fcff00"))
                        .foregroundColor(.black)
                        .cornerRadius(4)
                        .offset(y: -8)
                }
                .foregroundColor(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.white.opacity(0.1))
                .cornerRadius(16)
                .padding(8)
            }
        }
    }

    private var videoOptions: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 10) {
                optionHeader(title: "Duration", showSVIP: true)
                HStack(spacing: 12) {
                    selectorButton(title: "5s", isSelected: selectedDuration == "5s") { selectedDuration = "5s" }
                    selectorButton(title: "10s", isSelected: selectedDuration == "10s") { selectedDuration = "10s" }
                }
            }

            VStack(alignment: .leading, spacing: 10) {
                optionHeader(title: "Quality", showSVIP: true)
                HStack(spacing: 8) {
                    selectorButton(title: "Standard", isSelected: selectedQuality == "Standard") { selectedQuality = "Standard" }
                    selectorButton(title: "High", isSelected: selectedQuality == "High") { selectedQuality = "High" }
                    selectorButton(title: "Ultra HD", isSelected: selectedQuality == "Ultra HD") { selectedQuality = "Ultra HD" }
                }
            }
        }
    }

    private func optionHeader(title: String, showSVIP: Bool) -> some View {
        HStack {
            Text(title)
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.4))
                .padding(.leading, 6)
            Spacer()
            if showSVIP {
                Text("SVIP")
                    .font(.system(size: 10, weight: .bold))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color(hex: "#fcff00"))
                    .foregroundColor(.black)
                    .cornerRadius(4)
            }
        }
    }

    private func selectorButton(title: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 14, weight: isSelected ? .bold : .regular))
                .foregroundColor(isSelected ? .white : .white.opacity(0.6))
                .frame(maxWidth: .infinity)
                .frame(height: 44)
                .background(isSelected ? Color(hex: "#7032d6") : Color.white.opacity(0.05))
                .cornerRadius(22)
                .overlay(
                    RoundedRectangle(cornerRadius: 22)
                        .stroke(Color.white.opacity(0.05), lineWidth: 1)
                )
        }
    }

    private var bottomActionSection: some View {
        VStack(spacing: 16) {
            HStack(spacing: 4) {
                Text("Want faster generation?")
                    .foregroundColor(.white.opacity(0.4))
                Text("Get SVIP (50% OFF).")
                    .foregroundColor(Color(hex: "#fcff00"))
                    .font(.system(size: 14, weight: .bold))
            }
            .font(.system(size: 12))

            Button(action: {}) {
                VStack(spacing: 2) {
                    Text("Generate Video")
                        .font(.system(size: 18, weight: .bold))

                    HStack(spacing: 4) {
                        Image(systemName: "diamond.fill")
                            .font(.system(size: 12))
                        Text("200")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(Color(hex: "#fcff00"))
                    }
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 60)
                .background(
                    LinearGradient(colors: [Color(hex: "#c260f5"), Color(hex: "#6034e4")], startPoint: .topLeading, endPoint: .bottomTrailing)
                )
                .cornerRadius(22)
                .shadow(color: Color(hex: "#7032d6").opacity(0.3), radius: 10, y: 5)
                .overlay(
                    RoundedRectangle(cornerRadius: 22)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
            }

            HStack(spacing: 6) {
                Image(systemName: "checkmark.shield.fill")
                    .foregroundColor(.purple)
                Text("Failed task? 100% Refund.")
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.6))
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
        .padding(.bottom, 20)
        .background(
            Color(hex: "#252428").opacity(0.6)
                .background(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.5), radius: 20, y: -10)
        )
    }
}
