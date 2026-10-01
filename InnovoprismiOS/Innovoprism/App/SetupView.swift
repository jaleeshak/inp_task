import SwiftUI

/// First-launch screen: asks for the Innovoprism server address.
struct SetupView: View {
    @EnvironmentObject private var settings: AppSettings
    @State private var address = ""
    @State private var errorText: String?

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("e.g. innovoprism.your-tailnet.ts.net", text: $address)
                        .keyboardType(.URL)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .submitLabel(.go)
                        .onSubmit(connect)
                } header: {
                    Text("Server address")
                } footer: {
                    Text("The same address you open in your browser. If the server is only on your Tailscale network, make sure the Tailscale app is connected on this iPhone.")
                }

                if let errorText {
                    Section {
                        Text(errorText).foregroundStyle(.red)
                    }
                }

                Section {
                    Button("Connect", action: connect)
                        .disabled(address.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .navigationTitle("Innovoprism")
            .onAppear {
                if address.isEmpty, let last = settings.lastServerURL {
                    address = last.absoluteString
                }
            }
        }
    }

    private func connect() {
        guard let url = AppSettings.normalize(address) else {
            errorText = "That doesn't look like a valid address."
            return
        }
        errorText = nil
        settings.serverURL = url
    }
}
