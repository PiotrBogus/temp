import SwiftUI

struct SplashErrorView: View {
    let title: String
    let message: String?
    let retryAction: () -> Void
    
    @State private var appear = false

    var body: some View {
        ZStack {
            // Background
            LinearGradient(colors: [Color.red.opacity(0.8), Color.orange.opacity(0.7)],
                           startPoint: .topLeading,
                           endPoint: .bottomTrailing)
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                // Icon
                Image(systemName: "exclamationmark.triangle.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 80, height: 80)
                    .foregroundColor(.white)
                    .shadow(radius: 10)
                    .scaleEffect(appear ? 1.0 : 0.8)
                    .opacity(appear ? 1.0 : 0.0)
                    .animation(.spring(response: 0.6, dampingFraction: 0.7), value: appear)

                // Title
                Text(title)
                    .font(.system(size: 26, weight: .bold))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .opacity(appear ? 1.0 : 0.0)
                    .animation(.easeIn(duration: 0.3).delay(0.1), value: appear)

                // Message
                if let message {
                    Text(message)
                        .font(.system(size: 16))
                        .foregroundColor(.white.opacity(0.9))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                        .opacity(appear ? 1.0 : 0.0)
                        .animation(.easeIn(duration: 0.3).delay(0.2), value: appear)
                }

                // Retry button
                Button(action: retryAction) {
                    Text("Try Again")
                        .font(.headline)
                        .padding(.horizontal, 32)
                        .padding(.vertical, 12)
                        .background(.white)
                        .foregroundColor(.red)
                        .clipShape(Capsule())
                        .shadow(radius: 6)
                }
                .padding(.top, 10)
                .opacity(appear ? 1.0 : 0.0)
                .animation(.easeIn(duration: 0.3).delay(0.3), value: appear)
            }
            .padding()
        }
        .onAppear { appear = true }
    }
}
