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

                    Spacer(minLength: 100)
                }
                .padding(20)
            }

            bottomActionSection
        }
    }

    // MARK: - Components

    private var imageToVideoContent: some View {
        VStack(spacing: 12) {
            HStack(spacing: 16) {
                // Start Frame
                ZStack(alignment: .topLeading) {
                    Image("portrait_placeholder") // Replace with your resources
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 140, height: 180)
                        .cornerRadius(24)
                        .overlay(RoundedRectangle(cornerRadius: 24).stroke(Color.white.opacity(0.1), lineWidth: 1))

                    Text("Start")
                        .font(.system(size: 12, weight: .bold))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Color.black.opacity(0.4))
                        .cornerRadius(10)
                        .padding(10)

                    Button(action: {}) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.white.opacity(0.7))
                    }
                    .padding(10)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                }

                // End Frame
                Button(action: {}) {
                    VStack(spacing: 8) {
                        Image(systemName: "plus")
                            .font(.system(size: 24))
                        Text("Add End Frame")
                            .font(.system(size: 12))
                    }
                    .foregroundColor(.gray)
                    .frame(width: 140, height: 180)
                    .background(
                        RoundedRectangle(cornerRadius: 24)
                            .stroke(style: StrokeStyle(lineWidth: 1, dash: [5]))
                            .foregroundColor(.gray.opacity(0.5))
                    )
                }

                Text("End")
                    .font(.system(size: 12, weight: .bold))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Color.black.opacity(0.4))
                    .cornerRadius(10)
                    .offset(x: -148, y: -70)
            }
            .frame(maxWidth: .infinity)

            Text("Source Image (Optional)")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white)
        }
    }

    private var promptSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Prompt")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.gray)

            ZStack(alignment: .bottomTrailing) {
                TextEditor(text: $promptText)
                    .frame(height: 140)
                    .padding(12)
                    .scrollContentBackground(.hidden)
                    .background(Color(white: 0.12))
                    .cornerRadius(20)
                    .overlay(
                        Text(promptText.isEmpty ? "Describe the scene, action, and style..." : "")
                            .foregroundColor(.gray)
                            .padding(.leading, 16)
                            .padding(.top, 20)
                        , alignment: .topLeading
                    )

                HStack(spacing: 4) {
                    Image(systemName: "sparkles")
                    Text("AI Expand")

                    Text("SVIP")
                        .font(.system(size: 10, weight: .bold))
                        .padding(.horizontal, 4)
                        .padding(.vertical, 2)
                        .background(Color.yellow)
                        .foregroundColor(.black)
                        .cornerRadius(4)
                        .offset(y: -10)
                }
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color.white.opacity(0.1))
                .cornerRadius(20)
                .padding(10)
            }
        }
    }

    private var videoOptions: some View {
        VStack(alignment: .leading, spacing: 20) {
            optionHeader(title: "Duration", showSVIP: true)
            HStack(spacing: 12) {
                selectorButton(title: "5s", isSelected: selectedDuration == "5s") { selectedDuration = "5s" }
                selectorButton(title: "10s", isSelected: selectedDuration == "10s") { selectedDuration = "10s" }
            }

            optionHeader(title: "Quality", showSVIP: true)
            HStack(spacing: 12) {
                selectorButton(title: "Standard", isSelected: selectedQuality == "Standard") { selectedQuality = "Standard" }
                selectorButton(title: "High", isSelected: selectedQuality == "High") { selectedQuality = "High" }
                selectorButton(title: "Ultra HD", isSelected: selectedQuality == "Ultra HD") { selectedQuality = "Ultra HD" }
            }
        }
    }

    private var bottomActionSection: some View {
        VStack(spacing: 16) {
            HStack(spacing: 4) {
                Text("Want faster generation?")
                    .foregroundColor(.gray)
                Text("Get SVIP (50% OFF).")
                    .foregroundColor(.yellow)
            }
            .font(.system(size: 14))

            Button(action: {}) {
                VStack(spacing: 2) {
                    Text("Generate Video")
                        .font(.system(size: 18, weight: .bold))

                    HStack(spacing: 4) {
                        Image(systemName: "diamond.fill")
                            .font(.system(size: 14))
                        Text("200")
                            .font(.system(size: 16, weight: .bold))
                    }
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 64)
                .background(
                    LinearGradient(colors: [Color.purple, Color.blue], startPoint: .leading, endPoint: .trailing)
                )
                .cornerRadius(32)
                .shadow(color: .purple.opacity(0.3), radius: 10, y: 5)
            }

            HStack(spacing: 6) {
                Image(systemName: "checkmark.shield.fill")
                    .foregroundColor(.purple)
                Text("Failed task? 100% Refund.")
                    .font(.system(size: 12))
                    .foregroundColor(.gray)
            }
        }
        .padding(20)
        .background(
            Color(red: 18/255, green: 18/255, blue: 18/255)
                .shadow(color: .black.opacity(0.5), radius: 20, y: -10)
        )
    }

    private func optionHeader(title: String, showSVIP: Bool) -> some View {
        HStack {
            Text(title)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.gray)
            Spacer()
            if showSVIP {
                Text("SVIP")
                    .font(.system(size: 10, weight: .bold))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.yellow)
                    .foregroundColor(.black)
                    .cornerRadius(4)
            }
        }
    }

    private func selectorButton(title: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(isSelected ? .white : .gray)
                .frame(maxWidth: .infinity)
                .frame(height: 44)
                .background(isSelected ? Color.purple : Color(white: 0.15))
                .cornerRadius(22)
        }
    }
}
