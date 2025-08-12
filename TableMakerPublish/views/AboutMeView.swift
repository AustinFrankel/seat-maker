import SwiftUI

struct CreatorProfileView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedTab = 0
    @State private var aboutExpanded = false
    @State private var experienceExpanded = false
    @State private var passionExpanded = false
    @State private var cardScale: CGFloat = 0.95
    @State private var cardOpacity: Double = 0
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                Spacer().frame(height: 36)
                profileContent
            }
        }
        .background(Color(.systemGroupedBackground))
        .navigationBarHidden(true)
    }
    
    private var profileContent: some View {
        VStack(spacing: 24) {
            profileHeader
            profileSegmentedControl
            profileTabContent
            connectWithMeSection
        }
        .padding(.bottom, 32)
    }
    
    private var profileHeader: some View {
        VStack(spacing: 0) {
            HStack {
                Button(action: { dismiss() }) {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 18, weight: .semibold))
                        Text("Back")
                            .font(.system(size: 17, weight: .regular))
                    }
                    .foregroundColor(.blue)
                }
                Spacer()
            }
            .padding(.top, 3)
            .padding(.leading, 11)
            VStack(spacing: 12) {
                Image("profile_picture")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 110, height: 110)
                    .clipShape(Circle())
                    .overlay(
                        Circle()
                            .stroke(
                                LinearGradient(
                                    colors: [.blue, .purple],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 4
                            )
                    )
                    .shadow(color: Color.purple.opacity(0.2), radius: 10, x: 0, y: 4)
                Text("Austin Frankel")
                    .font(.system(size: 30, weight: .bold))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.blue, .purple],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                Text("Computer Science Student & iOS Developer")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.secondary)
            }
            .padding(.top, 8)
        }
    }
    
    private var profileSegmentedControl: some View {
        SegmentedControlView(selectedTab: $selectedTab)
            .padding(.horizontal)
    }
    
    private func segmentedButtons(tabTitles: [String]) -> some View {
        ForEach(tabTitles.indices, id: \.self) { idx in
            SegmentedButton(
                title: tabTitles[idx],
                isSelected: selectedTab == idx,
                color: .blue,
                action: { withAnimation { selectedTab = idx } }
            )
        }
    }
    
    private var profileTabContent: some View {
        VStack(spacing: 18) {
            if selectedTab == 0 {
                aboutCardSection
                experienceCardSection
                passionCardSection
            } else if selectedTab == 1 {
                MissionCard()
                    .frame(maxWidth: 340)
            } else if selectedTab == 2 {
                SkillsCard()
                    .frame(maxWidth: 340)
            }
        }
        .padding(.horizontal, 2)
    }
    
    private var aboutCardSection: some View {
        AboutCard(expanded: $aboutExpanded)
            .frame(maxWidth: 340)
            .scaleEffect(cardScale)
            .opacity(cardOpacity)
            .onAppear {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                    cardScale = 1
                    cardOpacity = 1
                }
            }
    }
    
    private var experienceCardSection: some View {
        ExperienceCard(expanded: $experienceExpanded)
            .frame(maxWidth: 340)
            .scaleEffect(cardScale)
            .opacity(cardOpacity)
            .onAppear {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.1)) {
                    cardScale = 1
                    cardOpacity = 1
                }
            }
    }
    
    private var passionCardSection: some View {
        PassionCard(expanded: $passionExpanded)
            .frame(maxWidth: 340)
            .scaleEffect(cardScale)
            .opacity(cardOpacity)
            .onAppear {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.2)) {
                    cardScale = 1
                    cardOpacity = 1
                }
            }
    }
    
    private var missionCardSection: some View {
        MissionCard()
    }
    
    private var skillsCardSection: some View {
        SkillsCard()
    }
    
    private var connectWithMeSection: some View {
        VStack(spacing: 10) {
            Text("Connect With Me")
                .font(.headline)
                .padding(.top, 8)
            HStack(spacing: 12) {
                Link(destination: URL(string: "https://www.linkedin.com/in/austin-frankel/")!) {
                    SocialButton(icon: "link", text: "LinkedIn")
                }
                Link(destination: URL(string: "https://www.instagram.com/austinfrankel1/")!) {
                    SocialButton(icon: "camera.fill", text: "Instagram")
                }
            }
            Link(destination: URL(string: "https://www.austinfrankel.info")!) {
                SocialButton(icon: "globe", text: "Website")
            }
        }
        .padding(.top, 8)
    }
}

private struct SegmentedControlView: View {
    @Binding var selectedTab: Int
    private let tabTitles = ["About", "Mission", "Skills"]
    private let tabColors: [Color] = [.blue, .green, .orange]
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(tabTitles.indices, id: \.self) { idx in
                SegmentedButton(
                    title: tabTitles[idx],
                    isSelected: selectedTab == idx,
                    color: tabColors[idx],
                    action: {
                        withAnimation(.spring(response: 0.45, dampingFraction: 0.85)) {
                            selectedTab = idx
                        }
                    }
                )
            }
        }
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(Color(.systemGray4), lineWidth: 1)
        )
        .padding(.horizontal, 16)
        .frame(height: 48)
    }
}

private struct SegmentedButton: View {
    let title: String
    let isSelected: Bool
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(isSelected ? color : Color(.systemGray))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(
                    Group {
                        if isSelected {
                            RoundedRectangle(cornerRadius: 20, style: .continuous)
                                .fill(color.opacity(0.10))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                                        .stroke(color, lineWidth: 2)
                                )
                        } else {
                            Color.clear
                        }
                    }
                )
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                .animation(.easeInOut(duration: 0.28), value: isSelected)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

private struct AboutCard: View {
    @Binding var expanded: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(LinearGradient(colors: [.blue.opacity(0.2), .purple.opacity(0.2)], startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(width: 36, height: 36)
                    Image(systemName: "lightbulb.fill")
                        .foregroundColor(.blue)
                        .font(.system(size: 20, weight: .bold))
                }
                Text("About Me").font(.headline)
            }
            if !expanded {
                Text("Hi! I'm Austin Frankel, a senior at Blind Brook High School in Rye Brook, New York. I'm passionate about technology, coding, and building apps that help people organize and connect. I enjoy learning new things and taking on creative projects.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .transition(.opacity)
            }
            Button(action: { withAnimation(.easeInOut(duration: 0.3)) { expanded.toggle() } }) {
                Text(expanded ? "Show Less" : "Read More")
                    .font(.subheadline)
                    .foregroundColor(.blue)
            }
            if expanded {
                Text("I'm currently a high school senior at Blind Brook High School. I love working on personal projects, especially in iOS development and design. My goal is to create apps that are both useful and enjoyable to use. Seat Maker is one of my favorite projects because it helps people plan events and bring people together. Outside of coding, I enjoy music, sports, and spending time with friends and family.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .transition(.opacity)
            }
        }
        .padding()
        .frame(maxWidth: 340)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color(.secondarySystemBackground))
                .shadow(color: Color.blue.opacity(0.1), radius: 15, x: 0, y: 8)
        )
        .frame(maxWidth: .infinity, alignment: .center)
    }
}

private struct ExperienceCard: View {
    @Binding var expanded: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(LinearGradient(colors: [.purple.opacity(0.2), .pink.opacity(0.2)], startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(width: 36, height: 36)
                    Image(systemName: "star.fill")
                        .foregroundColor(.purple)
                        .font(.system(size: 20, weight: .bold))
                }
                Text("Experience").font(.headline)
            }
            if !expanded {
                Text("High school senior with a passion for technology, coding, and building apps. Experienced in iOS development, Swift, and creative problem solving through personal projects.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .transition(.opacity)
            }
            Button(action: { withAnimation(.easeInOut(duration: 0.3)) { expanded.toggle() } }) {
                Text(expanded ? "Show Less" : "Read More")
                    .font(.subheadline)
                    .foregroundColor(.purple)
            }
            if expanded {
                VStack(alignment: .leading, spacing: 12) {
                    ExperienceItem(
                        role: "High School Senior",
                        company: "Blind Brook High School",
                        duration: "2020 - Present",
                        description: "Studying at Blind Brook High School in Rye Brook, NY. Focused on STEM, technology, and personal app development."
                    )
                    ExperienceItem(
                        role: "iOS Developer (Personal Projects)",
                        company: "Independent",
                        duration: "2022 - Present",
                        description: "Developing iOS applications using Swift and SwiftUI. Created Seat Maker to help people organize event seating arrangements."
                    )
                }
                .transition(.opacity)
            }
        }
        .padding()
        .frame(maxWidth: 340)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color(.secondarySystemBackground))
                .shadow(color: Color.purple.opacity(0.1), radius: 15, x: 0, y: 8)
        )
        .frame(maxWidth: .infinity, alignment: .center)
    }
}

private struct ExperienceItem: View {
    let role: String
    let company: String
    let duration: String
    let description: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(role)
                .font(.system(size: 15, weight: .semibold))
            HStack {
                Text(company)
                    .foregroundColor(.secondary)
                Text("•")
                    .foregroundColor(.secondary)
                Text(duration)
                    .foregroundColor(.secondary)
            }
            .font(.system(size: 14))
            Text(description)
                .font(.system(size: 14))
                .foregroundColor(.secondary)
                .padding(.top, 2)
        }
        .padding(.vertical, 4)
    }
}

private struct PassionCard: View {
    @Binding var expanded: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(LinearGradient(colors: [.pink.opacity(0.2), .orange.opacity(0.2)], startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(width: 36, height: 36)
                    Image(systemName: "heart.fill")
                        .foregroundColor(.pink)
                        .font(.system(size: 20, weight: .bold))
                }
                Text("Passion Projects").font(.headline)
            }
            if !expanded {
                Text("I love building apps and tools that help people in their daily lives. I'm especially interested in iOS development, design, and using technology to solve real-world problems. I also enjoy music, sports, and spending time with friends.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .transition(.opacity)
            }
            Button(action: { withAnimation(.easeInOut(duration: 0.3)) { expanded.toggle() } }) {
                Text(expanded ? "Show Less" : "Read More")
                    .font(.subheadline)
                    .foregroundColor(.pink)
            }
            if expanded {
                VStack(alignment: .leading, spacing: 12) {
                    PassionProject(
                        title: "Seat Maker",
                        description: "My first published iOS app for creating and managing seating arrangements. Built with SwiftUI to help people organize events more efficiently.",
                        technologies: ["SwiftUI", "Swift", "iOS Development"]
                    )
                    PassionProject(
                        title: "Learning & Growth",
                        description: "Always exploring new areas in technology, coding, and design. I enjoy taking on new challenges and learning from every project.",
                        technologies: ["Swift", "SwiftUI", "STEM", "Creativity"]
                    )
                }
                .transition(.opacity)
            }
        }
        .padding()
        .frame(maxWidth: 340)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color(.secondarySystemBackground))
                .shadow(color: Color.pink.opacity(0.1), radius: 15, x: 0, y: 8)
        )
        .frame(maxWidth: .infinity, alignment: .center)
    }
}

private struct PassionProject: View {
    let title: String
    let description: String
    let technologies: [String]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.system(size: 15, weight: .semibold))
            Text(description)
                .font(.system(size: 14))
                .foregroundColor(.secondary)
            HStack {
                ForEach(technologies, id: \.self) { tech in
                    Text(tech)
                        .font(.system(size: 12))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.secondary.opacity(0.1))
                        .cornerRadius(8)
                }
            }
            .padding(.top, 4)
        }
        .padding(.vertical, 4)
    }
}

private struct MissionCard: View {
    @State private var isAnimating = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(LinearGradient(colors: [.green.opacity(0.2), .blue.opacity(0.2)], startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(width: 36, height: 36)
                    Image(systemName: "target")
                        .foregroundColor(.green)
                        .font(.system(size: 20, weight: .bold))
                }
                Text("Mission").font(.headline)
            }
            Text("To create digital experiences that empower and inspire. I believe technology should enhance human connection, foster creativity, and make life more enjoyable. My goal is to build solutions that are not just functional, but truly meaningful.")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Divider().padding(.vertical, 4)
            
            ForEach(missionPoints, id: \.title) { point in
                MissionPoint(point: point)
                    .scaleEffect(isAnimating ? 1 : 0.9)
                    .opacity(isAnimating ? 1 : 0)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color(.secondarySystemBackground))
                .shadow(color: Color.green.opacity(0.1), radius: 15, x: 0, y: 8)
        )
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                isAnimating = true
            }
        }
    }
    
    private let missionPoints = [
        MissionPointData(
            icon: "person.3.fill",
            color: .green,
            title: "Foster Community",
            description: "Build tools that bring people together and strengthen connections"
        ),
        MissionPointData(
            icon: "sparkles",
            color: .blue,
            title: "Inspire Innovation",
            description: "Create solutions that push boundaries and spark creativity"
        ),
        MissionPointData(
            icon: "hand.raised.fill",
            color: .purple,
            title: "Ensure Accessibility",
            description: "Design with inclusivity at the forefront"
        )
    ]
}

private struct MissionPointData {
    let icon: String
    let color: Color
    let title: String
    let description: String
}

private struct MissionPoint: View {
    let point: MissionPointData
    
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(point.color.opacity(0.1))
                    .frame(width: 32, height: 32)
                Image(systemName: point.icon)
                    .foregroundColor(point.color)
                    .font(.system(size: 16, weight: .bold))
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(point.title)
                    .font(.subheadline)
                    .foregroundColor(.primary)
                Text(point.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

private struct SkillsCard: View {
    @State private var isAnimating = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(LinearGradient(colors: [.orange.opacity(0.2), .red.opacity(0.2)], startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(width: 36, height: 36)
                    Image(systemName: "star.fill")
                        .foregroundColor(.orange)
                        .font(.system(size: 20, weight: .bold))
                }
                Text("Skills").font(.headline)
            }
            
            ForEach(Array(skillCategories.enumerated()), id: \.offset) { index, category in
                SkillCategory(
                    category: category,
                    delay: Double(index) * 0.1
                )
                .scaleEffect(isAnimating ? 1 : 0.9)
                .opacity(isAnimating ? 1 : 0)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color(.secondarySystemBackground))
                .shadow(color: Color.orange.opacity(0.1), radius: 15, x: 0, y: 8)
        )
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                isAnimating = true
            }
        }
    }
    
    private let skillCategories = [
        SkillCategoryData(
            title: "Development",
            skills: ["Swift", "SwiftUI", "iOS Development", "Git"],
            icon: "swift",
            color: .blue
        ),
        SkillCategoryData(
            title: "Learning",
            skills: ["Computer Science", "Algorithms", "Data Structures", "Software Engineering"],
            icon: "book",
            color: .purple
        ),
        SkillCategoryData(
            title: "Tools & Methods",
            skills: ["Xcode", "GitHub", "iOS Simulator", "Debugging"],
            icon: "hammer",
            color: .orange
        )
    ]
}

private struct SkillCategoryData {
    let title: String
    let skills: [String]
    let icon: String
    let color: Color
}

private struct SkillCategory: View {
    let category: SkillCategoryData
    let delay: Double
    @State private var isAnimating = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: category.icon)
                    .foregroundColor(category.color)
                Text(category.title)
                    .font(.system(size: 15, weight: .semibold))
            }
            
            AboutFlowLayout(spacing: 8) {
                ForEach(category.skills, id: \.self) { skill in
                    Text(skill)
                        .font(.system(size: 14))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(category.color.opacity(0.1))
                        .cornerRadius(12)
                        .foregroundColor(category.color)
                }
            }
        }
        .padding(.vertical, 8)
        .opacity(isAnimating ? 1 : 0)
        .offset(y: isAnimating ? 0 : 20)
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7).delay(delay)) {
                isAnimating = true
            }
        }
    }
}

private struct AboutFlowLayout: Layout {
    var spacing: CGFloat = 8
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let rows = arrangeSubviews(proposal: proposal, subviews: subviews)
        return CGSize(
            width: proposal.width ?? .zero,
            height: rows.last?.maxY ?? .zero
        )
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let rows = arrangeSubviews(proposal: proposal, subviews: subviews)
        for row in rows {
            for element in row.elements {
                element.subview.place(
                    at: CGPoint(x: element.x + bounds.minX, y: row.y + bounds.minY),
                    proposal: ProposedViewSize(element.size)
                )
            }
        }
    }
    
    private func arrangeSubviews(proposal: ProposedViewSize, subviews: Subviews) -> [Row] {
        var rows: [Row] = []
        var currentRow = Row(y: 0)
        var x: CGFloat = 0
        let maxWidth = proposal.width ?? .zero
        
        for subview in subviews {
            let size = subview.sizeThatFits(ProposedViewSize(width: maxWidth, height: nil))
            if x + size.width > maxWidth, !currentRow.elements.isEmpty {
                rows.append(currentRow)
                currentRow = Row(y: currentRow.maxY + spacing)
                x = 0
            }
            
            currentRow.elements.append(Element(subview: subview, x: x, size: size))
            x += size.width + spacing
        }
        
        if !currentRow.elements.isEmpty {
            rows.append(currentRow)
        }
        
        return rows
    }
    
    private struct Row {
        var elements: [Element] = []
        var y: CGFloat
        
        var maxY: CGFloat {
            y + (elements.map { $0.size.height }.max() ?? 0)
        }
    }
    
    private struct Element {
        let subview: LayoutSubview
        let x: CGFloat
        let size: CGSize
    }
}

private struct SocialButton: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
            Text(text)
        }
        .font(.headline)
        .foregroundColor(.blue)
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.blue.opacity(0.1))
                .shadow(color: Color.blue.opacity(0.1), radius: 8, x: 0, y: 4)
        )
    }
} 
