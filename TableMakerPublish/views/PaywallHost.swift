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
        // Always present our custom replica so the design matches across builds
        ReplicaPaywallView(isPresented: $isPresented)
    }

    #if canImport(RevenueCatUI)
    @ViewBuilder
    private var contentWithRevenueCatUI: some View {
        if let offering = rc.offering {
            // Render RC paywall with robust dismissal handling
            PaywallView(offering: offering)
                .scrollDisabled(true)
                .onRequestedDismissal {
                    AdsManager.shared.cancelPendingCompletion()
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

// MARK: - Custom replica paywall matching the provided mock
private struct ReplicaPaywallView: View {
    @ObservedObject var rc = RevenueCatManager.shared
    @Binding var isPresented: Bool

    private enum PlanType { case unlimited, removeAds }

    @State private var selectedPlan: PlanType? = nil
    @State private var isProcessing: Bool = false
    @State private var inlineError: String? = nil

    var body: some View {
        ZStack(alignment: .topTrailing) {
            // Move the blue header outside of the scroll content so it can extend to the very top
            headerBackground
            ScrollView {
                VStack(spacing: 20) {
                    logoArtwork
                        .frame(maxWidth: .infinity)
                        .padding(.bottom, 6)
                    VStack(alignment: .center, spacing: 6) {
                        Text("Seat Maker Pro").font(.system(size: 28, weight: .bold))
                        Text("Pay once. Unlock Seat Maker forever.")
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .multilineTextAlignment(.center)
                    ratingRow
                    planCards
                    continueButton
                    if let err = inlineError {
                        Text(err).font(.footnote).foregroundColor(.red)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 24)
            }
            .scrollDisabled(true)

            Button(action: {
                AdsManager.shared.cancelPendingCompletion()
                isPresented = false
            }) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(Color(.secondaryLabel))
                    .padding(14)
            }
        }
        // Anchor the footer on the bottom safe area as in the screenshot
        .safeAreaInset(edge: .bottom) { footerBar }
        .onAppear {
            if selectedPlan == nil {
                #if canImport(RevenueCat)
                if resolvePlan(.unlimited) != nil { selectedPlan = .unlimited }
                else if resolvePlan(.removeAds) != nil { selectedPlan = .removeAds }
                #endif
            }
        }
        .onChange(of: rc.state.hasPro) { hasPro in
            if hasPro {
                AdsManager.shared.cancelPendingCompletion()
                isPresented = false
            }
        }
        .onChange(of: rc.state.hasRemoveAds) { hasRA in
            if hasRA {
                AdsManager.shared.cancelPendingCompletion()
                isPresented = false
            }
        }
    }

    // MARK: - UI components
    private var headerBackground: some View {
        CurvedTopHeader()
            .fill(
                LinearGradient(
                    colors: [Color(UIColor.systemBlue).opacity(0.2), Color(UIColor.systemBlue).opacity(0.12)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .frame(height: 260)
            .frame(maxWidth: .infinity, alignment: .top)
            .ignoresSafeArea(edges: .top)
            .offset(y: 30)
    }

    private var logoArtwork: some View {
        Circle()
            .fill(Color(UIColor.systemBlue).opacity(0.12))
            .frame(width: 150, height: 150)
            .overlay(
                Circle().stroke(Color(UIColor.systemBlue).opacity(0.35), lineWidth: 4)
            )
            .overlay(
                Image(systemName: "person.3.fill")
                    .resizable()
                    .scaledToFit()
                    .padding(30)
                    .foregroundColor(Color(UIColor.systemBlue))
            )
            .offset(y: 18)
    }

    private var ratingRow: some View {
        VStack(spacing: 6) {
            Text("4.7 stars").font(.subheadline).bold().multilineTextAlignment(.center)
            HStack(spacing: 2) {
                ForEach(0..<5, id: \.self) { _ in
                    Image(systemName: "star.fill").foregroundColor(.yellow)
                }
            }
        }
        .frame(maxWidth: .infinity)
    }

    private var planCards: some View {
        VStack(spacing: 14) {
            #if canImport(RevenueCat)
            if let unlimited = resolvePlan(.unlimited) {
                PlanCard(
                    title: "Unlimited",
                    price: unlimited.priceString,
                    features: ["Unlimited Tables", "Unlimited Guests", "All Themes", "No ads"],
                    badge: "Best Selling",
                    isSelected: selectedPlan == .unlimited,
                    showsLeadingIndicator: true,
                    indicatorSelectedColor: .blue,
                    onTap: { selectedPlan = .unlimited }
                )
            }
            if let remove = resolvePlan(.removeAds) {
                CompactPlanRow(
                    title: "Remove Ads",
                    price: remove.priceString,
                    isSelected: selectedPlan == .removeAds,
                    onTap: { selectedPlan = .removeAds }
                )
            }
            #else
            Text("Purchases framework unavailable in this build.")
            #endif
        }
    }

    private var continueButton: some View {
        #if canImport(RevenueCat)
        let enabled = selectedPlan != nil && !isProcessing
        #else
        let enabled = false
        #endif
        return Button(action: { continueTapped() }) {
            Text(isProcessing ? "Processing…" : "Continue")
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    LinearGradient(
                        colors: enabled ? [Color.blue, Color.purple] : [Color.gray.opacity(0.4), Color.gray.opacity(0.4)],
                        startPoint: .leading, endPoint: .trailing
                    )
                )
                .foregroundColor(.white)
                .cornerRadius(14)
                .shadow(color: (enabled ? Color.purple.opacity(0.6) : Color.clear), radius: (enabled ? 22 : 0), x: 0, y: 10)
        }
        .disabled(!enabled)
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: selectedPlan)
    }

    private var footerBar: some View {
        HStack(spacing: 12) {
            Text("One-time purchase. Restore anytime.")
                .foregroundColor(.secondary)
            Spacer()
            Button("Restore") { restorePurchases() }
                .font(.footnote)
            if let privacy = URL(string: "https://www.seatmakerapp.com/privacy") {
                Link("Privacy", destination: privacy)
                    .font(.footnote)
            }
            if let terms = URL(string: "https://www.seatmakerapp.com/terms") {
                Link("Terms", destination: terms)
                    .font(.footnote)
            }
        }
        .font(.footnote)
        .padding(.horizontal, 20)
        .padding(.vertical, 8)
        .background(Color.clear)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Text("One-time purchase. Restore, Privacy Policy, Terms of Use"))
    }

    // MARK: - Actions
    private func continueTapped() {
        #if canImport(RevenueCat)
        guard let selectedPlan else { return }
        inlineError = nil
        isProcessing = true
        switch selectedPlan {
        case .unlimited:
            if let target = resolvePlan(.unlimited) { purchase(target) }
        case .removeAds:
            if let target = resolvePlan(.removeAds) { purchase(target) }
        }
        #endif
    }

    private func restorePurchases() {
        RevenueCatManager.shared.restore { result in
            switch result {
            case .success:
                if rc.state.hasPro || rc.state.hasRemoveAds { isPresented = false }
            case .failure(let err):
                inlineError = err.localizedDescription
            }
        }
    }

    #if canImport(RevenueCat)
    private enum PlanTarget {
        case package(Package)
        case product(StoreProduct)

        var priceString: String {
            switch self {
            case .package(let pkg): return pkg.storeProduct.localizedPriceString
            case .product(let p): return p.localizedPriceString
            }
        }
    }

    private func purchase(_ target: PlanTarget) {
        switch target {
        case .package(let pkg):
            Purchases.shared.purchase(package: pkg) { _, info, error, userCancelled in
                DispatchQueue.main.async {
                    RevenueCatManager.shared.applyCustomerInfo(info)
                    RevenueCatManager.shared.refreshCustomerInfo()
                    isProcessing = false
                    if rc.state.hasPro || rc.state.hasRemoveAds { isPresented = false }
                    if let error, !userCancelled { inlineError = error.localizedDescription }
                }
            }
        case .product(let product):
            Purchases.shared.purchase(product: product) { _, info, error, userCancelled in
                DispatchQueue.main.async {
                    RevenueCatManager.shared.applyCustomerInfo(info)
                    RevenueCatManager.shared.refreshCustomerInfo()
                    isProcessing = false
                    if rc.state.hasPro || rc.state.hasRemoveAds { isPresented = false }
                    if let error, !userCancelled { inlineError = error.localizedDescription }
                }
            }
        }
    }

    private func resolvePlan(_ type: PlanType) -> PlanTarget? {
        if let offering = rc.offering {
            if let pkg = offering.availablePackages.first(where: { matches(type: type, package: $0) }) {
                return .package(pkg)
            }
        }
        if let prod = rc.fallbackProducts.first(where: { matches(type: type, product: $0) }) {
            return .product(prod)
        }
        return nil
    }

    private func matches(type: PlanType, package: Package) -> Bool {
        let pid = package.storeProduct.productIdentifier.lowercased()
        let id = package.identifier.lowercased()
        switch type {
        case .unlimited:
            return pid.contains("pro") || pid.contains("unlimited") || (id.contains("lifetime") && !pid.contains("remove"))
        case .removeAds:
            return pid.contains("removeads") || pid.contains("remove_ads") || id.contains("remove")
        }
    }

    private func matches(type: PlanType, product: StoreProduct) -> Bool {
        let id = product.productIdentifier.lowercased()
        switch type {
        case .unlimited:
            return id.contains("pro") || id.contains("unlimited") || id.contains("lifetime_pro") || id == "com.seatmaker.pro.lifetime"
        case .removeAds:
            return id.contains("removeads") || id.contains("remove_ads") || id == "com.seatmaker.removeads_lifetime"
        }
    }
    #endif
}

// MARK: - Subviews used by replica
private struct CurvedTopHeader: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let curveHeight: CGFloat = min(80, rect.height * 0.35)
        p.move(to: CGPoint(x: 0, y: 0))
        p.addLine(to: CGPoint(x: rect.maxX, y: 0))
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
        // Bottom curve
        p.addQuadCurve(
            to: CGPoint(x: 0, y: rect.midY),
            control: CGPoint(x: rect.midX, y: rect.midY + curveHeight)
        )
        p.addLine(to: CGPoint(x: 0, y: 0))
        p.closeSubpath()
        return p
    }
}
private struct PlanCard: View {
    let title: String
    let price: String
    let features: [String]
    let badge: String?
    let isSelected: Bool
    let showsLeadingIndicator: Bool
    let indicatorSelectedColor: Color
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(alignment: .top, spacing: 12) {
                if showsLeadingIndicator {
                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .foregroundColor(isSelected ? indicatorSelectedColor : Color(UIColor.tertiaryLabel))
                        .padding(.top, 2)
                }
                VStack(alignment: .leading, spacing: 12) {
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(title).font(.headline)
                            Text(price).foregroundColor(.secondary)
                        }
                        Spacer()
                        if let badge {
                            HStack(spacing: 6) {
                                Image(systemName: "sparkles").font(.caption).foregroundColor(.white)
                                Text(badge).font(.caption).bold().foregroundColor(.white)
                            }
                            .padding(.horizontal, 10).padding(.vertical, 6)
                            .background(
                                Capsule().fill(
                                    LinearGradient(colors: [Color.blue, Color.purple], startPoint: .leading, endPoint: .trailing)
                                )
                            )
                            .overlay(
                                Capsule().stroke(Color.white.opacity(0.35), lineWidth: 0.5)
                            )
                            .shadow(color: Color.blue.opacity(0.2), radius: 6, x: 0, y: 3)
                        }
                    }
                    VStack(alignment: .leading, spacing: 10) {
                        ForEach(features, id: \.self) { feature in
                            HStack(spacing: 10) {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.blue)
                                Text(feature)
                            }
                        }
                    }
                }
            }
            .padding(18)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color(.secondarySystemBackground))
            )
            .overlay(
                ZStack {
                    if isSelected {
                        // Soft outer glow similar to RevenueCat
                        RoundedRectangle(cornerRadius: 22)
                            .stroke(LinearGradient(colors: [Color.blue.opacity(0.8), Color.purple.opacity(0.8)], startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 8)
                            .blur(radius: 14)
                            .opacity(0.6)
                    }
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(
                            isSelected
                            ? LinearGradient(colors: [Color.blue, Color.purple], startPoint: .topLeading, endPoint: .bottomTrailing)
                            : LinearGradient(colors: [Color(UIColor.quaternaryLabel), Color(UIColor.quaternaryLabel)], startPoint: .leading, endPoint: .trailing),
                            lineWidth: isSelected ? 3 : 1
                        )
                }
            )
            .shadow(color: isSelected ? Color.blue.opacity(0.15) : Color.black.opacity(0.03), radius: isSelected ? 16 : 6, x: 0, y: isSelected ? 10 : 4)
            .shadow(color: isSelected ? Color.purple.opacity(0.18) : .clear, radius: isSelected ? 22 : 0, x: 0, y: isSelected ? 12 : 0)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

private struct CompactPlanRow: View {
    let title: String
    let price: String
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isSelected ? Color.purple : Color(UIColor.tertiaryLabel))
                VStack(alignment: .leading, spacing: 2) {
                    Text(title).font(.headline)
                    Text(price).foregroundColor(.secondary)
                }
                Spacer()
            }
            .padding(16)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 18)
                    .stroke(isSelected ? Color.purple : Color(UIColor.separator), lineWidth: isSelected ? 2 : 1)
                    .background(RoundedRectangle(cornerRadius: 18).fill(Color(.secondarySystemBackground)))
            )
        }
        .buttonStyle(PlainButtonStyle())
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
                PackageList(offering: offering, isPresented: $isPresented)
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
        .scrollDisabled(true)
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

// MARK: - Highlighted package list used in fallback paywall
#if !canImport(RevenueCatUI) && canImport(RevenueCat)
private struct PackageList: View {
    let offering: Offering
    @Binding var isPresented: Bool
    @ObservedObject var rc = RevenueCatManager.shared
    @State private var selectedId: String?
    @State private var isPurchasing = false
    @State private var errorText: String?
    var body: some View {
        VStack(spacing: 16) {
            ForEach(offering.availablePackages, id: \.identifier) { pkg in
                let isSelected = selectedId == pkg.identifier
                Button(action: { selectedId = pkg.identifier }) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(pkg.storeProduct.localizedTitle)
                                .font(.headline)
                            Text(pkg.storeProduct.localizedPriceString)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        if isSelected { Image(systemName: "checkmark.circle.fill").foregroundColor(.blue) }
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(
                        ZStack {
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color(.secondarySystemBackground))
                            if isSelected {
                                RoundedRectangle(cornerRadius: 16)
                                    .strokeBorder(
                                        LinearGradient(
                                            colors: [Color.blue, Color.purple],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ),
                                        lineWidth: 3
                                    )
                                    .shadow(color: Color.blue.opacity(0.25), radius: 10, x: 0, y: 6)
                            }
                        }
                    )
                }
                .buttonStyle(PlainButtonStyle())
            }

            if let sel = selectedId, let pkg = offering.availablePackages.first(where: { $0.identifier == sel }) {
                Button(action: { purchase(pkg) }) {
                    Text(isPurchasing ? "Processing…" : "Continue")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            LinearGradient(
                                colors: [Color.blue, Color.purple],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(14)
                        .foregroundColor(.white)
                        .shadow(color: Color.purple.opacity(0.45), radius: 16, x: 0, y: 8)
                }
                .disabled(isPurchasing)
            } else {
                Button(action: {}) {
                    Text("Continue")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(RoundedRectangle(cornerRadius: 14).fill(Color.gray.opacity(0.3)))
                        .foregroundColor(.white)
                }
                .disabled(true)
            }

            HStack(spacing: 12) {
                Button("Restore") { RevenueCatManager.shared.restore { _ in } }
                Button("Close") { isPresented = false }
            }
            if let e = errorText { Text(e).foregroundColor(.red).font(.footnote) }
        }
        .padding()
        .scrollDisabled(true)
    }

    private func purchase(_ pkg: Package) {
        isPurchasing = true
        errorText = nil
        Purchases.shared.purchase(package: pkg) { _, info, error, userCancelled in
            DispatchQueue.main.async {
                RevenueCatManager.shared.applyCustomerInfo(info)
                isPurchasing = false
                if RevenueCatManager.shared.state.unlimitedFeatures { isPresented = false }
                else if let error = error, !userCancelled { errorText = error.localizedDescription }
            }
        }
    }
}
#endif
