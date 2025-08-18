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
        #if canImport(RevenueCatUI)
        contentWithRevenueCatUI
        #else
        // Native lightweight fallback when RevenueCatUI isn't present
        FallbackPaywall(isPresented: $isPresented)
        #endif
    }

    #if canImport(RevenueCatUI)
    @ViewBuilder
    private var contentWithRevenueCatUI: some View {
        if let offering = rc.offering {
            // Render RC paywall with robust dismissal handling
            PaywallView(offering: offering)
                .onRequestedDismissal {
                    RevenueCatManager.shared.refreshCustomerInfo()
                    isPresented = false
                }
        } else if !rc.fallbackProducts.isEmpty {
            // When no offerings available, show direct product list fallback even if RC UI is available
            VStack(spacing: 12) {
                ForEach(rc.fallbackProducts, id: \.productIdentifier) { product in
                    Button(action: { purchaseDirect(product) }) {
                        Text("Buy \(product.localizedTitle) – \(product.localizedPriceString)")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(RoundedRectangle(cornerRadius: 14).fill(Color.blue))
                            .foregroundColor(.white)
                    }
                }
                HStack(spacing: 12) {
                    Button("Restore") { RevenueCatManager.shared.restore { _ in } }
                    Button("Close") { isPresented = false }
                }
            }
            .padding()
        } else {
            VStack(spacing: 16) {
                ProgressView("Loading…")
                Button("Retry") { RevenueCatManager.shared.refreshOfferings() }
                Button("Close") { isPresented = false }
            }
            .padding()
        }
    }
    #if canImport(RevenueCat)
    private func purchaseDirect(_ product: StoreProduct) {
        Purchases.shared.purchase(product: product) { _, info, error, userCancelled in
            DispatchQueue.main.async {
                RevenueCatManager.shared.applyCustomerInfo(info)
                if RevenueCatManager.shared.state.unlimitedFeatures {
                    isPresented = false
                } else if let error = error, !userCancelled {
                    // no-op here; RC UI path doesn't show inline errors
                    print("RC purchase error:", error.localizedDescription)
                }
            }
        }
    }
    #endif
    #endif
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
            } else if !rc.fallbackProducts.isEmpty {
                VStack(spacing: 12) {
                    ForEach(rc.fallbackProducts, id: \.productIdentifier) { product in
                        Button(action: { purchaseDirect(product) }) {
                            Text(isPurchasing ? "Processing…" : "Buy \(product.localizedTitle) – \(product.localizedPriceString)")
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
                RevenueCatManager.shared.applyCustomerInfo(info)
                isPurchasing = false
                if RevenueCatManager.shared.state.unlimitedFeatures {
                    isPresented = false
                } else if let error = error, !userCancelled {
                    purchaseError = error.localizedDescription
                }
            }
        }
    }

    private func purchaseDirect(_ product: StoreProduct) {
        isPurchasing = true
        purchaseError = nil
        Purchases.shared.purchase(product: product) { _, info, error, userCancelled in
            DispatchQueue.main.async {
                RevenueCatManager.shared.applyCustomerInfo(info)
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


