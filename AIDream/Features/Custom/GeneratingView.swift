import SwiftUI

struct GeneratingView: View {
    var progress: Double
    var onBackToHome: () -> Void

    var body: some View {
        ZStack {
            Color(hex: "#090909").ignoresSafeArea()
            // Subtle radial gold glow in background
            RadialGradient(
                colors: [Color(hex: "#D4A82A").opacity(0.08), .clear],
                center: .center,
                startRadius: 20,
                endRadius: 300
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                // Center card
                ZStack {
                    // Card background
                    RoundedRectangle(cornerRadius: 32)
                        .fill(Color(hex: "#17171F"))
                        .frame(width: 240, height: 427)
                        .overlay(
                            // Gold gradient border
                            RoundedRectangle(cornerRadius: 32)
                                .stroke(
                                    LinearGradient(
                                        colors: [
                                            Color(hex: "#F6C842"),
                                            Color(hex: "#8B6A14"),
                                            Color(hex: "#F6C842").opacity(0.3)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 1.5
                                )
                        )

                    VStack(spacing: 28) {
                        LottieView(name: "ai_generating_a")
                            .frame(width: 150, height: 150)

                        VStack(spacing: 10) {
                            // Gold progress percentage
                            Text("\(Int(progress * 100))%")
                                .font(.system(size: 36, weight: .bold))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [Color(hex: "#F6C842"), Color(hex: "#C9920A")],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )

                            Text("Generating…")
                                .font(.system(size: 15, weight: .medium))
                                .foregroundColor(Color.white.opacity(0.55))
                        }
                    }
                }
                .shadow(color: Color(hex: "#D4A82A").opacity(0.2), radius: 30, x: 0, y: 15)

                Spacer()

                // Bottom actions
                VStack(spacing: 14) {
                    Button(action: onBackToHome) {
                        HStack(spacing: 8) {
                            Image(systemName: "arrow.left")
                                .font(.system(size: 14, weight: .semibold))
                            Text("Back to Home")
                                .font(.system(size: 16, weight: .semibold))
                        }
                        .foregroundColor(.white.opacity(0.85))
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(Color.white.opacity(0.07))
                        .cornerRadius(18)
                        .overlay(
                            RoundedRectangle(cornerRadius: 18)
                                .stroke(Color(hex: "#28282E"), lineWidth: 0.5)
                        )
                    }
                    .padding(.horizontal, 20)

                    Text("You can leave safely. We'll notify you when it's done.")
                        .font(.system(size: 12))
                        .foregroundColor(Color.white.opacity(0.3))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }
                .padding(.bottom, 48)
            }
        }
    }
}
