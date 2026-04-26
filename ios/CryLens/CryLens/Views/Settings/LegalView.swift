import SwiftUI
import SafariServices

// MARK: - Legal Page enum

enum LegalPage {
    case privacy, terms, support

    var title: String {
        switch self {
        case .privacy: return "Privacy Policy"
        case .terms:   return "Terms of Use"
        case .support: return "Support"
        }
    }

    var url: URL? {
        switch self {
        case .privacy:
            return AppConfig.privacyPolicyURL
        case .terms:
            return AppConfig.termsOfUseURL
        case .support:
            return AppConfig.supportURL
        }
    }
}

// MARK: - LegalView

struct LegalView: View {
    let page: LegalPage

    var body: some View {
        if page == .support {
            List {
                Section {
                    Link(destination: URL(string: "mailto:\(AppConfig.supportEmail)")!) {
                        Label("Email Support", systemImage: "envelope.fill")
                    }
                    if let supportURL = AppConfig.supportURL {
                        Link(destination: supportURL) {
                        Label("Help Centre", systemImage: "safari.fill")
                        }
                    }
                }

                Section(header: Text("App Info")) {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle(page.title)
            .navigationBarTitleDisplayMode(.inline)
        } else if let url = page.url {
            SafariWebView(url: url)
                .navigationTitle(page.title)
                .navigationBarTitleDisplayMode(.inline)
                .ignoresSafeArea(edges: .bottom)
        }
    }
}

// MARK: - SFSafariViewController wrapper

struct SafariWebView: UIViewControllerRepresentable {
    let url: URL

    func makeUIViewController(context: Context) -> SFSafariViewController {
        let config = SFSafariViewController.Configuration()
        config.entersReaderIfAvailable = false
        return SFSafariViewController(url: url, configuration: config)
    }

    func updateUIViewController(_ vc: SFSafariViewController, context: Context) {}
}
