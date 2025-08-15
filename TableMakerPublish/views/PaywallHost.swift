import SwiftUI
#if canImport(RevenueCat)
import RevenueCat
#endif
#if canImport(RevenueCatUI)
import RevenueCatUI
#endif

struct PaywallHost: View {
    @ObservedObject var rc = RevenueCatManager.shared
    @Binding var isPresented: Bool

    var body: some View {
        Group {
            #if canImport(RevenueCatUI)
            if let offering = rc.offering {
                // Render the paywall; rely on onDisappear to close host
                PaywallView(offering: offering)
                    .onDisappear { isPresented = false }
            } else {
                VStack(spacing: 16) {
                    ProgressView("Loading…")
                    Button("Retry") { RevenueCatManager.shared.refreshOfferings() }
                    Button("Close") { isPresented = false }
                }
            }
            #else
            // Native lightweight fallback when RevenueCatUI isn't present
            FallbackPaywall(isPresented: $isPresented)
            #endif
        }
    }
}

#if !canImport(RevenueCatUI)
struct FallbackPaywall: View {
    @ObservedObject var rc = RevenueCatManager.shared
    @Binding var isPresented: Bool
    @State private var isPurchasing: Bool = false
    @State private var purchaseError: String? = nil
    var body: some View {
        VStack(spacing: 20) {
            Text("Seat Maker Pro")
                .font(.title2).bold()
            Text("Unlock unlimited features and remove limits.")
                .foregroundColor(.secondary)

            #if canImport(RevenueCat)
            if let offering = rc.offering {
                VStack(spacing: 12) {
                    ForEach(offering.availablePackages, id: \.identifier) { pkg in
                        Button(action: { purchase(pkg) }) {
                            Text(isPurchasing ? "Processing…" : "Buy \(pkg.storeProduct.localizedTitle) – \(pkg.storeProduct.localizedPriceString)")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(RoundedRectangle(cornerRadius: 14).fill(Color.blue))
                                .foregroundColor(.white)
                        }
                        .disabled(isPurchasing)
                    }
                }
            } else {
                VStack(spacing: 12) {
                    ProgressView("Loading products…")
                    Button("Retry") { RevenueCatManager.shared.refreshOfferings() }
                }
            }
            #else
            Text("Purchases framework unavailable in this build.")
            #endif

            HStack(spacing: 12) {
                Button("Restore") { RevenueCatManager.shared.restore { _ in } }
                Button("Close") { isPresented = false }
            }
            .padding(.top, 4)

            if let err = purchaseError {
                Text(err)
                    .font(.footnote)
                    .foregroundColor(.red)
            }
        }
        .padding()
    }
    #if canImport(RevenueCat)
    private func purchase(_ pkg: Package) {
        isPurchasing = true
        purchaseError = nil
        Purchases.shared.purchase(package: pkg) { _, info, error, userCancelled in
            DispatchQueue.main.async {
                RevenueCatManager.shared.state.update(from: info)
                isPurchasing = false
                if RevenueCatManager.shared.state.unlimitedFeatures {
                    isPresented = false
                } else if let error = error, !userCancelled {
                    purchaseError = error.localizedDescription
                }
            }
        }
    }
    #endif
}
#endif


