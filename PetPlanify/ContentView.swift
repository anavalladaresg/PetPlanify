import SwiftUI
import AuthenticationServices

struct ContentView: View {
    @Environment(PetPlanifyStore.self) private var store
    @Environment(AppNavigation.self) private var navigation
    @AppStorage("petplanify.apple.signedIn") private var signedIn = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    var body: some View {
        Group {
            if !signedIn { AppleSignInView { signedIn = true } }
            else if !store.isLoaded { PetPlanifyLoadingView() }
            else if store.cloudKitUnavailable { CloudKitRetryView() }
            else if !store.snapshot.onboarding.isComplete { OnboardingView() }
            else {
                #if os(macOS)
                MacAppShell()
                #else
                MobileAppShell()
                #endif
            }
        }
        .overlay(alignment: .top) {
            if let message = store.message {
                Text(message)
                    .font(.subheadline.weight(.medium))
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, 18)
                    .padding(.vertical, 12)
                    .frame(maxWidth: 520)
                    .background(.regularMaterial, in: Capsule())
                    .overlay(Capsule().stroke(AppTheme.border, lineWidth: 1))
                    .foregroundStyle(AppTheme.ink)
                    .shadow(color: .black.opacity(0.12), radius: 12, y: 5)
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                    .onTapGesture { store.message = nil }
                    .accessibilityAddTraits(.isStaticText)
            }
        }
        .preferredColorScheme(store.snapshot.preferences.appearance == .system ? nil : store.snapshot.preferences.appearance == .dark ? .dark : .light)
        .animation(reduceMotion ? nil : .easeInOut(duration: 0.45), value: store.snapshot.preferences.appearance)
        .task { if signedIn { await store.load() } }
        .onChange(of: signedIn) { _, value in
            if value { Task { await store.load() } }
        }
        .task(id: store.message) {
            guard let message = store.message else { return }
            try? await Task.sleep(nanoseconds: 4_000_000_000)
            if !Task.isCancelled, store.message == message { store.message = nil }
        }
        .onReceive(NotificationCenter.default.publisher(for: .petPlanifyOpenReminder)) { notification in
            if let rawFeature = notification.userInfo?["feature"] as? String,
               let context = ObservationContext(rawValue: rawFeature) {
                navigation.selection = AppSection(context: context)
            }
            if let rawID = notification.userInfo?["reminderID"] as? String {
                navigation.presentedReminderID = UUID(uuidString: rawID)
            }
        }
        .sheet(isPresented: Binding(
            get: { navigation.presentedReminderID != nil },
            set: { if !$0 { navigation.presentedReminderID = nil } }
        )) {
            CompactRemindersView(focusedReminderID: navigation.presentedReminderID)
        }
    }
}

private struct PetPlanifyLoadingView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var rotation = 0.0
    @State private var shimmer = false
    @State private var progress = 0.18

    var body: some View {
        ZStack {
            AppTheme.canvas
            Circle()
                .fill(AppTheme.greenSoft.opacity(0.42))
                .frame(width: 280, height: 280)
                .blur(radius: 10)
                .offset(x: 115, y: -180)
            Circle()
                .fill(AppTheme.peachSoft.opacity(0.36))
                .frame(width: 220, height: 220)
                .blur(radius: 8)
                .offset(x: -130, y: 210)
            VStack(spacing: 22) {
                ZStack {
                    RoundedRectangle(cornerRadius: 34, style: .continuous)
                        .fill(.regularMaterial)
                        .frame(width: 126, height: 126)
                        .overlay(RoundedRectangle(cornerRadius: 34, style: .continuous).stroke(AppTheme.green.opacity(0.28), lineWidth: 1))
                        .shadow(color: AppTheme.green.opacity(0.2), radius: 22)
                    Image("PetPlanifyLaunchLogo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 104, height: 104)
                        .rotationEffect(.degrees(reduceMotion ? 0 : rotation))
                        .accessibilityHidden(true)
                        .overlay {
                            RoundedRectangle(cornerRadius: 28, style: .continuous)
                                .fill(LinearGradient(colors: [.white.opacity(0.45), .clear, .white.opacity(0.2)], startPoint: shimmer ? .topLeading : .bottomTrailing, endPoint: shimmer ? .bottomTrailing : .topLeading))
                                .blendMode(.screen)
                        }
                }
                VStack(spacing: 8) {
                    Text("Abriendo PetPlanify")
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(AppTheme.ink)
                    ProgressView(value: progress, total: 1)
                        .tint(AppTheme.green)
                        .frame(width: 190)
                        .accessibilityLabel("Abriendo PetPlanify")
                        .accessibilityValue(progress.formatted(.percent))
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .appCanvas()
        .task {
            guard !reduceMotion else { return }
            withAnimation(.easeInOut(duration: 1.8).repeatForever(autoreverses: false)) { rotation = 360 }
            withAnimation(.easeInOut(duration: 1.4).repeatForever(autoreverses: true)) { shimmer = true }
            while !Task.isCancelled {
                try? await Task.sleep(for: .milliseconds(180))
                withAnimation(.easeOut(duration: 0.18)) { progress = min(progress + 0.018, 0.92) }
            }
        }
    }
}

private struct CloudKitRetryView: View {
    @Environment(PetPlanifyStore.self) private var store
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "icloud.and.arrow.down").font(.largeTitle).foregroundStyle(AppTheme.green)
            Text("No hemos podido cargar tus datos todavía.").font(.title3.weight(.semibold))
            Text("Tus datos de iCloud no se han borrado. Comprueba la conexión y vuelve a intentarlo.")
                .multilineTextAlignment(.center).foregroundStyle(AppTheme.secondaryInk)
            Button("Volver a intentar", systemImage: "arrow.clockwise") { Task { await store.retryCloudKitLoad() } }
                .buttonStyle(.borderedProminent).tint(AppTheme.green)
        }
        .padding(32).frame(maxWidth: 420).appCanvas()
    }
}

private struct AppleSignInView: View {
    var onSignedIn: () -> Void
    @AppStorage("petplanify.apple.displayName") private var displayName = ""
    @State private var errorMessage: String?

    var body: some View {
        ZStack {
            AppTheme.canvas.ignoresSafeArea()
            VStack(spacing: AppTheme.Space.xl) {
                Image("AppIcon-Horizontal")
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: 300, maxHeight: 100)
                    .accessibilityLabel("PetPlanify")
                Text("Tu cuidado, con calma.")
                    .font(.title3.weight(.semibold))
                Text("Inicia sesión para mantener tus mascotas y cuidados vinculados a tu identidad.")
                    .font(.body)
                    .foregroundStyle(AppTheme.secondaryInk)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 430)
                SignInWithAppleButton(.signIn) { request in
                    request.requestedScopes = [.fullName, .email]
                } onCompletion: { result in
                    switch result {
                    case .success(let authorization):
                        guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential else {
                            errorMessage = String(localized: "No se ha podido validar tu cuenta de Apple.")
                            return
                        }
                        UserDefaults.standard.set(credential.user, forKey: "petplanify.apple.userID")
                        if let name = credential.fullName,
                           let formatted = PersonNameComponentsFormatter().string(from: name).nilIfEmpty {
                            displayName = formatted.split(whereSeparator: { $0.isWhitespace }).first.map(String.init) ?? formatted
                        }
                        onSignedIn()
                    case .failure:
                        errorMessage = String(localized: "No se ha podido iniciar sesión con Apple. Vuelve a intentarlo.")
                    }
                }
                .signInWithAppleButtonStyle(.black)
                .frame(width: 280, height: 52)
                .accessibilityIdentifier("auth.signInWithApple")
                if let errorMessage {
                    Text(errorMessage)
                        .font(.footnote)
                        .foregroundStyle(AppTheme.orange)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: 360)
                }
                Text("Usaremos tu cuenta de Apple para identificar tu espacio. No necesitas crear otra contraseña.")
                    .font(.caption)
                    .foregroundStyle(AppTheme.secondaryInk)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 420)
            }
            .padding(AppTheme.Space.xxl)
            .appSurface(cornerRadius: AppTheme.heroRadius, elevated: true)
            .frame(maxWidth: 560)
            .padding(AppTheme.Space.xl)
        }
    }
}

private extension String {
    var nilIfEmpty: String? { isEmpty ? nil : self }
}

#Preview { ContentView().environment(PetPlanifyStore.preview()).environment(AppNavigation()) }
