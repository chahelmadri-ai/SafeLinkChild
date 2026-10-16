import SwiftUI

private enum SafeLinkStyle {
    static let background = Color(red: 0.035, green: 0.055, blue: 0.11)
    static let panel = Color(red: 0.085, green: 0.115, blue: 0.19)
    static let panelAlt = Color(red: 0.11, green: 0.15, blue: 0.24)
    static let accent = Color(red: 1.0, green: 0.62, blue: 0.26)
    static let mint = Color(red: 0.40, green: 0.85, blue: 0.71)
    static let muted = Color(red: 0.63, green: 0.68, blue: 0.79)
}

private enum SafeLinkConfig {
    static let projectURL = URL(string: "https://ahbqzkxjooneovhorkri.supabase.co")!
}

struct ContentView: View {
    @AppStorage("safelink.publishableKey") private var publishableKey = ""
    @AppStorage("safelink.childDeviceID") private var childDeviceID = UUID().uuidString.lowercased()
    @AppStorage("safelink.childLabel") private var savedChildLabel = "Child iPhone"
    @AppStorage("safelink.paired") private var isPaired = false

    @State private var pairingCode = ""
    @State private var childLabel = "Child iPhone"
    @State private var status = "Enter the one-time code provided by your parent."
    @State private var statusIsError = false
    @State private var isBusy = false
    @State private var showingApproval = false
    @State private var showingSettings = false

    private var normalizedCode: String {
        pairingCode.uppercased().filter { $0.isLetter || $0.isNumber }
    }

    private var canReview: Bool {
        normalizedCode.count == 12 && !publishableKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !isBusy && !isPaired
    }

    var body: some View {
        ZStack {
            SafeLinkStyle.background.ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    header
                    if isPaired {
                        pairedCard
                    } else {
                        intro
                        pairingCard
                    }
                    statusCard
                    privacyFooter
                }
                .padding(.horizontal, 20)
                .padding(.top, 18)
                .padding(.bottom, 30)
                .frame(maxWidth: 520)
                .frame(maxWidth: .infinity)
            }
        }
        .preferredColorScheme(.dark)
        .confirmationDialog(
            "Approve device pairing?",
            isPresented: $showingApproval,
            titleVisibility: .visible
        ) {
            Button("Approve Pairing") {
                Task { await approvePairing() }
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This links this iPhone to the parent account associated with the code. It does not start microphone sharing or record audio.")
        }
        .sheet(isPresented: $showingSettings) {
            settingsSheet
        }
        .onAppear {
            if savedChildLabel != "Child iPhone" { childLabel = savedChildLabel }
            if isPaired { status = "This iPhone is paired. No microphone session is active." }
        }
    }

    private var header: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 15).fill(SafeLinkStyle.accent)
                    .frame(width: 48, height: 48)
                Text("S")
                    .font(.system(size: 27, weight: .black, design: .rounded))
                    .foregroundStyle(SafeLinkStyle.background)
            }
            VStack(alignment: .leading, spacing: 3) {
                Text("SafeLink Child")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                Text("Family safety • Device pairing")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(SafeLinkStyle.muted)
            }
            Spacer()
            Button { showingSettings = true } label: {
                Image(systemName: "gearshape.fill")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(SafeLinkStyle.accent)
                    .frame(width: 42, height: 42)
                    .background(SafeLinkStyle.panelAlt, in: Circle())
            }
            .accessibilityLabel("Settings")
        }
    }

    private var intro: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Pair this iPhone")
                .font(.system(size: 26, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
            Text("Enter the one-time pairing code from the parent device. Review the request before approving it.")
                .font(.system(size: 14))
                .foregroundStyle(SafeLinkStyle.muted)
                .lineSpacing(4)
        }
    }

    private var pairingCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label("Device details", systemImage: "iphone")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(.white)

            VStack(alignment: .leading, spacing: 7) {
                Text("ONE-TIME PAIRING CODE")
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .tracking(1.2)
                    .foregroundStyle(SafeLinkStyle.muted)
                TextField("12-character code", text: $pairingCode)
                    .textInputAutocapitalization(.characters)
                    .autocorrectionDisabled()
                    .font(.system(size: 20, weight: .bold, design: .monospaced))
                    .tracking(2)
                    .padding(14)
                    .background(SafeLinkStyle.background, in: RoundedRectangle(cornerRadius: 13))
                    .overlay(RoundedRectangle(cornerRadius: 13).stroke(SafeLinkStyle.panelAlt, lineWidth: 1))
                    .onChange(of: pairingCode) { value in
                        pairingCode = String(value.uppercased().filter { $0.isLetter || $0.isNumber }.prefix(12))
                    }
            }

            VStack(alignment: .leading, spacing: 7) {
                Text("DEVICE NAME")
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .tracking(1.2)
                    .foregroundStyle(SafeLinkStyle.muted)
                TextField("Child iPhone", text: $childLabel)
                    .textInputAutocapitalization(.words)
                    .autocorrectionDisabled()
                    .padding(13)
                    .background(SafeLinkStyle.background, in: RoundedRectangle(cornerRadius: 13))
                    .overlay(RoundedRectangle(cornerRadius: 13).stroke(SafeLinkStyle.panelAlt, lineWidth: 1))
            }

            Button {
                showingApproval = true
            } label: {
                HStack(spacing: 9) {
                    Image(systemName: "checkmark.shield.fill")
                    Text("Review & Approve Pairing")
                }
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(SafeLinkStyle.background)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(SafeLinkStyle.accent, in: RoundedRectangle(cornerRadius: 14))
            }
            .disabled(!canReview)
            .opacity(canReview ? 1 : 0.5)

            Text("Only approve a code for a parent you recognize. Pairing does not enable microphone access.")
                .font(.system(size: 12))
                .foregroundStyle(SafeLinkStyle.muted)
                .lineSpacing(3)
        }
        .padding(18)
        .background(SafeLinkStyle.panel, in: RoundedRectangle(cornerRadius: 22))
    }

    private var pairedCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("This iPhone is paired", systemImage: "checkmark.seal.fill")
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(SafeLinkStyle.mint)
            Text("Device: \(savedChildLabel)")
                .foregroundStyle(.white)
            Text("Pairing is complete. Microphone sharing is off. No audio is being captured or transmitted by this app.")
                .font(.system(size: 13))
                .foregroundStyle(SafeLinkStyle.muted)
            Button("Reset pairing on this iPhone", role: .destructive) {
                isPaired = false
                pairingCode = ""
                status = "Pairing reset locally. If the backend link remains, revoke it from the parent/backend before pairing again."
            }
            .font(.system(size: 13, weight: .semibold))
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(SafeLinkStyle.panel, in: RoundedRectangle(cornerRadius: 22))
    }

    private var statusCard: some View {
        VStack(alignment: .leading, spacing: 7) {
            Text("STATUS")
                .font(.system(size: 10, weight: .bold, design: .rounded))
                .tracking(1.2)
                .foregroundStyle(SafeLinkStyle.mint)
            if isBusy { ProgressView().tint(SafeLinkStyle.accent) }
            Text(status)
                .font(.system(size: 12))
                .foregroundStyle(statusIsError ? Color.red.opacity(0.95) : .white)
                .lineSpacing(3)
        }
        .padding(15)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(SafeLinkStyle.panelAlt, in: RoundedRectangle(cornerRadius: 16))
    }

    private var privacyFooter: some View {
        Text("Privacy-first prototype • No microphone access, recording, or live audio is implemented in this pairing build.")
            .font(.system(size: 11))
            .foregroundStyle(SafeLinkStyle.muted)
            .lineSpacing(3)
    }

    private var settingsSheet: some View {
        NavigationStack {
            Form {
                Section("Supabase connection") {
                    LabeledContent("Project URL") {
                        Text(SafeLinkConfig.projectURL.absoluteString)
                            .font(.system(size: 11, design: .monospaced))
                            .textSelection(.enabled)
                    }
                    TextField("sb_publishable_…", text: $publishableKey, axis: .vertical)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                    Text("Paste only your Supabase publishable key. Never enter a secret or service_role key here.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                Section("About") {
                    LabeledContent("Pairing API", value: "approve-pairing-code")
                    LabeledContent("Device ID", value: String(childDeviceID.prefix(8)) + "…")
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { showingSettings = false }
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    @MainActor
    private func approvePairing() async {
        guard !publishableKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            status = "Open Settings and add the Supabase publishable key first."
            statusIsError = true
            return
        }
        guard normalizedCode.count == 12 else {
            status = "Enter the complete 12-character pairing code."
            statusIsError = true
            return
        }

        isBusy = true
        statusIsError = false
        status = "Verifying the one-time code…"
        defer { isBusy = false }

        let endpoint = URL(string: SafeLinkConfig.projectURL.absoluteString + "/functions/v1/approve-pairing-code")!
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.timeoutInterval = 20
        request.setValue(publishableKey.trimmingCharacters(in: .whitespacesAndNewlines), forHTTPHeaderField: "apikey")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        let safeLabel = String(childLabel.trimmingCharacters(in: .whitespacesAndNewlines).prefix(60))
        let payload: [String: Any] = [
            "code": normalizedCode,
            "child_device_id": childDeviceID,
            "child_label": safeLabel.isEmpty ? "Child iPhone" : safeLabel,
            "approved": true
        ]

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: payload)
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse else {
                throw PairingError.message("The server returned an invalid response.")
            }
            let json = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any] ?? [:]
            if !(200...299).contains(http.statusCode) {
                let serverMessage = (json["error"] as? String) ?? (json["message"] as? String) ?? "Request failed (HTTP \(http.statusCode))."
                throw PairingError.message(serverMessage)
            }
            guard json["paired"] as? Bool == true else {
                throw PairingError.message("The server did not confirm pairing.")
            }
            savedChildLabel = safeLabel.isEmpty ? "Child iPhone" : safeLabel
            isPaired = true
            pairingCode = ""
            status = "Pairing approved and linked. Microphone sharing remains off."
            statusIsError = false
        } catch {
            status = error.localizedDescription
            statusIsError = true
        }
    }
}

private enum PairingError: LocalizedError {
    case message(String)
    var errorDescription: String? {
        switch self {
        case .message(let text): return text
        }
    }
}

#Preview {
    ContentView()
}
