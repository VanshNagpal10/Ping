//
//  EpilogueView.swift
//  Ping
//

import SwiftUI

// MARK: - Main Epilogue View
struct EpilogueView: View {
    let stats: JourneyStats
    let onReplay: () -> Void


    private let accent   = Color(red: 0.0, green: 0.82, blue: 0.88)
    private let mint     = Color(red: 0.3, green: 0.95, blue: 0.85)
    private let warmGold = Color(red: 1.0, green: 0.82, blue: 0.36)
    private let coral    = Color(red: 1.0, green: 0.42, blue: 0.42)
    private let success  = Color(red: 0.3, green: 0.86, blue: 0.46)

    @State private var showContent = false
    @State private var showTitle = false
    @State private var showSubtitle = false
    @State private var gridScroll: CGFloat = 0
    @State private var selectedTab: ResultTab = .overview

    private enum ResultTab: String, CaseIterable {
        case overview = "Overview"
        case concepts = "Concepts"
        case quiz = "Quiz Review"
    }

    var body: some View {
        GeometryReader { geo in
            ZStack {
                // Background
                LinearGradient(
                    colors: [
                        Color(red: 0.04, green: 0.05, blue: 0.10),
                        Color(red: 0.06, green: 0.08, blue: 0.16),
                        Color(red: 0.04, green: 0.06, blue: 0.12)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                .accessibilityHidden(true)

                // Subtle grid
                EpilogueCyberGrid(scroll: gridScroll, color: accent)
                    .opacity(showContent ? 0.12 : 0)
                    .accessibilityHidden(true)

                // Soft glow orbs
                Circle()
                    .fill(accent.opacity(0.08))
                    .frame(width: 500, height: 500)
                    .blur(radius: 120)
                    .offset(x: -geo.size.width * 0.3, y: -geo.size.height * 0.15)
                    .opacity(showContent ? 1 : 0)
                    .accessibilityHidden(true)

                Circle()
                    .fill(mint.opacity(0.06))
                    .frame(width: 400, height: 400)
                    .blur(radius: 100)
                    .offset(x: geo.size.width * 0.25, y: geo.size.height * 0.2)
                    .opacity(showContent ? 1 : 0)
                    .accessibilityHidden(true)

                // Main scrollable content
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 0) {
                        heroSection(geo: geo)

                        if showContent {
                            tabPicker
                                .padding(.top, 24)
                                .transition(.opacity.combined(with: .move(edge: .bottom)))

                            Group {
                                switch selectedTab {
                                case .overview:  overviewTab
                                case .concepts:  conceptsTab
                                case .quiz:      quizReviewTab
                                }
                            }
                            .transition(.opacity)
                            .animation(.easeInOut(duration: 0.3), value: selectedTab)
                            .padding(.horizontal, 28)
                            .padding(.top, 20)

                            replayButton
                                .padding(.top, 32)
                                .padding(.bottom, 60)
                        }
                    }
                }

                // CRT scanlines (decorative only)
                EpilogueScanLines()
                    .opacity(0.03)
                    .allowsHitTesting(false)
                    .ignoresSafeArea()
                    .accessibilityHidden(true)
            }
        }
        .onAppear { startEpilogue() }
    }

    // MARK: - Hero Section
    @ViewBuilder
    private func heroSection(geo: GeometryProxy) -> some View {
        VStack(spacing: 20) {
            Spacer().frame(height: 60)

            if showTitle {
                ZStack {
                    Circle()
                        .stroke(accent.opacity(0.2), lineWidth: 2)
                        .frame(width: 100, height: 100)
                    Circle()
                        .fill(accent.opacity(0.08))
                        .frame(width: 100, height: 100)
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 56))
                        .foregroundStyle(
                            LinearGradient(colors: [accent, mint], startPoint: .topLeading, endPoint: .bottomTrailing)
                        )
                        .shadow(color: mint.opacity(0.4), radius: 15, x: 0, y: 0)
                }
                .transition(.scale(scale: 0.5).combined(with: .opacity))
                .padding(.bottom, 8)
                .accessibilityHidden(true)

                VStack(spacing: 12) {
                    Text("Mission Complete")
                        .font(ScaledFont.scaledFont(size: 46, weight: .heavy, design: .rounded))
                        .foregroundColor(.white)
                        .shadow(color: accent.opacity(0.3), radius: 10, y: 4)
                        .accessibilityAddTraits(.isHeader)
                    Text("Payload delivered in 114ms")
                        .font(ScaledFont.scaledFont(size: 20, weight: .semibold, design: .rounded))
                        .foregroundColor(.white.opacity(0.7))
                        .tracking(0.5)
                }
                .transition(.opacity.combined(with: .move(edge: .bottom)))
            }

            if showSubtitle {
                Text("To the user, it was instant.\nTo you, it was an epic journey.")
                    .font(ScaledFont.scaledFont(size: 18, weight: .medium, design: .rounded))
                    .foregroundColor(accent.opacity(0.9))
                    .multilineTextAlignment(.center)
                    .lineSpacing(6)
                    .padding(.top, 16)
                    .transition(.opacity)
            }

            Spacer().frame(height: 10)
        }
        .frame(minHeight: 320)
    }

    // MARK: - Tab Picker
    private var tabPicker: some View {
        HStack(spacing: 4) {
            ForEach(ResultTab.allCases, id: \.self) { tab in
                Button {
                    withAnimation(.easeInOut(duration: 0.25)) { selectedTab = tab }
                } label: {
                    Text(tab.rawValue)
                        .font(ScaledFont.scaledFont(size: 13, weight: selectedTab == tab ? .semibold : .medium, design: .rounded))
                        .foregroundColor(selectedTab == tab ? .white : .white.opacity(0.45))
                        .padding(.horizontal, 18)
                        .padding(.vertical, 10)
                        .background(Capsule().fill(selectedTab == tab ? accent.opacity(0.2) : Color.clear))
                        .overlay(Capsule().stroke(selectedTab == tab ? accent.opacity(0.4) : Color.white.opacity(0.08), lineWidth: 1))
                }
                .buttonStyle(.plain)
                .accessibilityLabel(tab.rawValue)
                .accessibilityAddTraits(selectedTab == tab ? [.isButton, .isSelected] : .isButton)
            }
        }
        .padding(.horizontal, 28)
    }

    // MARK: - Overview Tab
    private var overviewTab: some View {
        VStack(spacing: 16) {
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                EpilogueStatCard(icon: "clock.fill", value: stats.formattedDuration, label: "Time", color: accent)
                EpilogueStatCard(icon: "book.closed.fill", value: "\(stats.termsLearned.count)", label: "Concepts Learned", color: warmGold)
                EpilogueStatCard(icon: "person.2.fill", value: "\(stats.npcsSpokenTo.count)", label: "NPCs Met", color: mint)
                EpilogueStatCard(icon: "map.fill", value: "\(stats.scenesVisited.count)", label: "Places Visited", color: Color(red: 0.65, green: 0.55, blue: 1.0))
            }

            routeCard

            if !stats.choicesMade.isEmpty {
                decisionsCard
            }
        }
    }

    // MARK: - Route Card
    private var routeCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label("Route Taken", systemImage: "point.topleft.down.to.point.bottomright.curvepath.fill")
                .font(ScaledFont.scaledFont(size: 13, weight: .semibold, design: .rounded))
                .foregroundColor(.white.opacity(0.6))

            let uniqueScenes = stats.scenesVisited.reduce(into: [StoryScene]()) { result, scene in
                if !result.contains(scene) { result.append(scene) }
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 0) {
                    ForEach(Array(uniqueScenes.enumerated()), id: \.element) { i, scene in
                        HStack(spacing: 0) {
                            VStack(spacing: 6) {
                                ZStack {
                                    Circle()
                                        .fill(scene.accentColor.opacity(0.15))
                                        .frame(width: 36, height: 36)
                                    Image(systemName: sceneIcon(for: scene))
                                        .font(.system(size: 14))
                                        .foregroundColor(scene.accentColor)
                                }
                                Text(scene.displayName)
                                    .font(ScaledFont.scaledFont(size: 9, weight: .medium, design: .rounded))
                                    .foregroundColor(.white.opacity(0.5))
                                    .lineLimit(1)
                                    .frame(width: 60)
                            }
                            .accessibilityElement(children: .combine)
                            .accessibilityLabel("Stop \(i + 1): \(scene.displayName)")
                            if i < uniqueScenes.count - 1 {
                                Rectangle()
                                    .fill(
                                        LinearGradient(
                                            colors: [scene.accentColor.opacity(0.5), uniqueScenes[i+1].accentColor.opacity(0.5)],
                                            startPoint: .leading, endPoint: .trailing
                                        )
                                    )
                                    .frame(width: 28, height: 2)
                                    .padding(.bottom, 20)
                                    .accessibilityHidden(true)
                            }
                        }
                    }
                }
                .padding(.horizontal, 4)
            }
        }
        .padding(18)
        .background(cardBackground)
    }

    // MARK: - Decisions Card
    private var decisionsCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label("Your Decisions", systemImage: "arrow.triangle.branch")
                .font(ScaledFont.scaledFont(size: 13, weight: .semibold, design: .rounded))
                .foregroundColor(.white.opacity(0.6))

            HStack(spacing: 12) {
                decisionPill(
                    icon: stats.chosenProtocol == .udp ? "bolt.fill" : "checkmark.shield.fill",
                    label: "Protocol", value: stats.chosenProtocol.rawValue,
                    color: stats.chosenProtocol == .udp ? .orange : success
                )
                decisionPill(
                    icon: stats.upgradedToSSL ? "lock.fill" : "lock.open.fill",
                    label: "Security", value: stats.upgradedToSSL ? "SSL/TLS" : "None",
                    color: stats.upgradedToSSL ? success : coral
                )
                decisionPill(
                    icon: stats.lostPacketData ? "exclamationmark.triangle.fill" : "checkmark.circle.fill",
                    label: "Data", value: stats.lostPacketData ? "Lost" : "Intact",
                    color: stats.lostPacketData ? coral : success
                )
            }
        }
        .padding(18)
        .background(cardBackground)
    }

    @ViewBuilder
    private func decisionPill(icon: String, label: String, value: String, color: Color) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(color)
            Text(value)
                .font(ScaledFont.scaledFont(size: 14, weight: .bold, design: .rounded))
                .foregroundColor(.white)
            Text(label)
                .font(ScaledFont.scaledFont(size: 10, weight: .medium, design: .rounded))
                .foregroundColor(.white.opacity(0.4))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(color.opacity(0.06))
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(color.opacity(0.15), lineWidth: 1))
        )
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(label): \(value)")
    }

    // MARK: - Concepts Tab
    private var conceptsTab: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("\(stats.termsLearned.count) Concepts Learned")
                    .font(ScaledFont.scaledFont(size: 15, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)
                Spacer()
                Text("\(stats.termsLearned.count)/\(EncyclopediaTerm.allTerms.count) total")
                    .font(ScaledFont.scaledFont(size: 12, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.4))
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4).fill(Color.white.opacity(0.08))
                    RoundedRectangle(cornerRadius: 4)
                        .fill(LinearGradient(colors: [accent, mint], startPoint: .leading, endPoint: .trailing))
                        .frame(width: geo.size.width * CGFloat(stats.termsLearned.count) / CGFloat(max(EncyclopediaTerm.allTerms.count, 1)))
                }
            }
            .frame(height: 6)
            .accessibilityLabel("\(stats.termsLearned.count) of \(EncyclopediaTerm.allTerms.count) concepts discovered")

            let grouped = Dictionary(grouping: stats.termsLearned) { $0.category }
            let sortedCategories = EncyclopediaTerm.TermCategory.allCases.filter { grouped[$0] != nil }

            ForEach(sortedCategories, id: \.self) { category in
                VStack(alignment: .leading, spacing: 10) {
                    Text(category.rawValue.uppercased())
                        .font(ScaledFont.scaledFont(size: 11, weight: .bold, design: .rounded))
                        .foregroundColor(categoryColor(category).opacity(0.7))
                        .tracking(2)
                        .padding(.top, 8)
                        .accessibilityAddTraits(.isHeader)

                    ForEach(grouped[category] ?? [], id: \.id) { term in
                        ConceptCard(term: term, color: categoryColor(category))
                    }
                }
            }

            let undiscovered = EncyclopediaTerm.allTerms.filter { term in
                !stats.termsLearned.contains(where: { $0.id == term.id })
            }
            if !undiscovered.isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    Text("UNDISCOVERED")
                        .font(ScaledFont.scaledFont(size: 11, weight: .bold, design: .rounded))
                        .foregroundColor(.white.opacity(0.3))
                        .tracking(2)
                        .padding(.top, 8)
                        .accessibilityAddTraits(.isHeader)

                    ForEach(undiscovered, id: \.id) { term in
                        HStack(spacing: 12) {
                            Image(systemName: "lock.fill")
                                .font(.system(size: 14))
                                .foregroundColor(.white.opacity(0.2))
                                .frame(width: 32, height: 32)
                                .background(Circle().fill(Color.white.opacity(0.05)))
                            VStack(alignment: .leading, spacing: 2) {
                                Text(term.term)
                                    .font(ScaledFont.scaledFont(size: 14, weight: .medium, design: .rounded))
                                    .foregroundColor(.white.opacity(0.3))
                                Text("Play again to discover")
                                    .font(ScaledFont.scaledFont(size: 11, design: .rounded))
                                    .foregroundColor(.white.opacity(0.2))
                            }
                            Spacer()
                        }
                        .padding(12)
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(Color.white.opacity(0.02))
                                .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.white.opacity(0.04), lineWidth: 1))
                        )
                        .accessibilityElement(children: .combine)
                        .accessibilityLabel("\(term.term). Undiscovered. Play again to discover.")
                    }
                }
            }
        }
    }

    // MARK: - Quiz Review Tab
    private var quizReviewTab: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Score summary
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .stroke(Color.white.opacity(0.08), lineWidth: 6)
                        .frame(width: 64, height: 64)
                    Circle()
                        .trim(from: 0, to: stats.quizResults.isEmpty ? 0 : stats.quizAccuracy)
                        .stroke(
                            stats.quizAccuracy >= 0.8 ? success : stats.quizAccuracy >= 0.5 ? warmGold : coral,
                            style: StrokeStyle(lineWidth: 6, lineCap: .round)
                        )
                        .frame(width: 64, height: 64)
                        .rotationEffect(.degrees(-90))
                    Text("\(Int(stats.quizAccuracy * 100))%")
                        .font(ScaledFont.scaledFont(size: 18, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("\(Int(stats.quizAccuracy * 100)) percent accuracy")

                VStack(alignment: .leading, spacing: 4) {
                    Text("Quiz Accuracy")
                        .font(ScaledFont.scaledFont(size: 15, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)
                    let correct = stats.quizResults.filter(\.wasCorrect).count
                    let total = stats.quizResults.count
                    Text("\(correct) of \(total) questions correct")
                        .font(ScaledFont.scaledFont(size: 13, weight: .medium, design: .rounded))
                        .foregroundColor(.white.opacity(0.5))
                    Text(quizGrade)
                        .font(ScaledFont.scaledFont(size: 12, weight: .semibold, design: .rounded))
                        .foregroundColor(stats.quizAccuracy >= 0.8 ? success : stats.quizAccuracy >= 0.5 ? warmGold : coral)
                }
                Spacer()
            }
            .padding(18)
            .background(cardBackground)

            if stats.quizResults.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "questionmark.circle")
                        .font(.system(size: 36))
                        .foregroundColor(.white.opacity(0.2))
                    Text("No quizzes completed")
                        .font(ScaledFont.scaledFont(size: 14, weight: .medium, design: .rounded))
                        .foregroundColor(.white.opacity(0.4))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
                .accessibilityElement(children: .combine)
                .accessibilityLabel("No quizzes completed")
            } else {
                let grouped = Dictionary(grouping: stats.quizResults) { $0.scene }
                let orderedScenes = stats.scenesVisited.reduce(into: [StoryScene]()) { result, scene in
                    if !result.contains(scene) && grouped[scene] != nil { result.append(scene) }
                }

                ForEach(orderedScenes, id: \.self) { scene in
                    VStack(alignment: .leading, spacing: 10) {
                        HStack(spacing: 8) {
                            Image(systemName: sceneIcon(for: scene))
                                .font(.system(size: 12))
                                .foregroundColor(scene.accentColor)
                            Text(scene.displayName)
                                .font(ScaledFont.scaledFont(size: 13, weight: .bold, design: .rounded))
                                .foregroundColor(scene.accentColor)
                            Spacer()
                            let sceneResults = grouped[scene] ?? []
                            let sceneCorrect = sceneResults.filter(\.wasCorrect).count
                            Text("\(sceneCorrect)/\(sceneResults.count)")
                                .font(ScaledFont.scaledFont(size: 12, weight: .medium, design: .rounded))
                                .foregroundColor(.white.opacity(0.4))
                        }
                        .accessibilityElement(children: .combine)
                        .accessibilityLabel("\(scene.displayName): \((grouped[scene] ?? []).filter(\.wasCorrect).count) of \((grouped[scene] ?? []).count) correct")
                        .accessibilityAddTraits(.isHeader)

                        ForEach(Array((grouped[scene] ?? []).enumerated()), id: \.offset) { idx, result in
                            QuizResultCard(result: result, index: idx + 1, success: success, coral: coral)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Replay Button
    private var replayButton: some View {
        Button {
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            onReplay()
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "arrow.counterclockwise")
                    .font(ScaledFont.scaledFont(size: 15, weight: .semibold))
                Text("Replay Journey")
                    .font(ScaledFont.scaledFont(size: 16, weight: .semibold, design: .rounded))
            }
            .foregroundColor(.black)
            .padding(.horizontal, 40)
            .padding(.vertical, 16)
            .background(
                Capsule().fill(
                    LinearGradient(colors: [accent, mint], startPoint: .leading, endPoint: .trailing)
                )
            )
            .shadow(color: accent.opacity(0.35), radius: 20, y: 6)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Replay journey")
        .accessibilityHint("Restarts the game from the beginning")
    }

    // MARK: - Shared Card Background
    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: 16)
            .fill(Color.white.opacity(0.04))
            .background(RoundedRectangle(cornerRadius: 16).fill(.ultraThinMaterial).opacity(0.3))
            .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.08), lineWidth: 1))
    }

    // MARK: - Helpers
    private var quizGrade: String {
        if stats.quizAccuracy >= 1.0 { return "Perfect Score!" }
        if stats.quizAccuracy >= 0.8 { return "Excellent!" }
        if stats.quizAccuracy >= 0.6 { return "Good effort!" }
        if stats.quizAccuracy >= 0.4 { return "Keep learning!" }
        return "Try again to improve"
    }

    private func categoryColor(_ category: EncyclopediaTerm.TermCategory) -> Color {
        switch category {
        case .basics:         return accent
        case .protocols:      return mint
        case .infrastructure: return warmGold
        case .security:       return Color(red: 0.65, green: 0.55, blue: 1.0)
        }
    }

    private func sceneIcon(for scene: StoryScene) -> String {
        switch scene {
        case .prologue:       return "flag.checkered"
        case .cpuCity:        return "cpu.fill"
        case .wifiAntenna:    return "antenna.radiowaves.left.and.right"
        case .routerStation:  return "arrow.triangle.branch"
        case .oceanCable:     return "water.waves"
        case .dnsLibrary:     return "book.closed.fill"
        case .returnJourney:  return "arrow.turn.up.left"
        case .feedLoaded:     return "checkmark.circle.fill"
        }
    }

    // MARK: - Cinematic Timeline
    private func startEpilogue() {
        SoundManager.shared.playAmbientSound(for: .cpuCity)

        withAnimation(.linear(duration: 25).repeatForever(autoreverses: false)) {
            gridScroll = 1
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            SoundManager.shared.playMissionCompleteSound()
            withAnimation(.spring(response: 0.7, dampingFraction: 0.75)) { showTitle = true }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation(.easeIn(duration: 0.6)) { showSubtitle = true }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            SoundManager.shared.playPortalSound()
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) { showContent = true }
        }
    }
}

// MARK: - Stat Card
struct EpilogueStatCard: View {
    let icon: String
    let value: String
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: 10) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(color)
                Spacer()
            }
            HStack {
                Text(value)
                    .font(ScaledFont.scaledFont(size: 26, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                Spacer()
            }
            HStack {
                Text(label)
                    .font(ScaledFont.scaledFont(size: 11, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.4))
                Spacer()
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(color.opacity(0.05))
                .overlay(RoundedRectangle(cornerRadius: 16).stroke(color.opacity(0.12), lineWidth: 1))
        )
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(label): \(value)")
    }
}

// MARK: - Concept Card (Expandable)
struct ConceptCard: View {
    let term: EncyclopediaTerm
    let color: Color
    @State private var expanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button {
                withAnimation(.easeInOut(duration: 0.25)) { expanded.toggle() }
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: term.icon)
                        .font(.system(size: 16))
                        .foregroundColor(color)
                        .frame(width: 36, height: 36)
                        .background(Circle().fill(color.opacity(0.1)))
                    Text(term.term)
                        .font(ScaledFont.scaledFont(size: 15, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)
                    Spacer()
                    Image(systemName: expanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.white.opacity(0.3))
                        .accessibilityHidden(true)
                }
                .padding(14)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            if expanded {
                Text(term.definition)
                    .font(ScaledFont.scaledFont(size: 13, weight: .regular, design: .rounded))
                    .foregroundColor(.white.opacity(0.7))
                    .lineSpacing(4)
                    .padding(.horizontal, 14)
                    .padding(.bottom, 14)
                    .padding(.leading, 48)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(color.opacity(0.04))
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(color.opacity(0.1), lineWidth: 1))
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(term.term)\(expanded ? ". \(term.definition)" : "")")
        .accessibilityHint(expanded ? "Double tap to collapse" : "Double tap to see definition")
        .accessibilityAddTraits(.isButton)
    }
}

// MARK: - Quiz Result Card (Expandable)
struct QuizResultCard: View {
    let result: QuizResult
    let index: Int
    let success: Color
    let coral: Color
    @State private var showDetails = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button {
                withAnimation(.easeInOut(duration: 0.25)) { showDetails.toggle() }
            } label: {
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(result.wasCorrect ? success.opacity(0.12) : coral.opacity(0.12))
                            .frame(width: 32, height: 32)
                        Image(systemName: result.wasCorrect ? "checkmark" : "xmark")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(result.wasCorrect ? success : coral)
                    }

                    VStack(alignment: .leading, spacing: 3) {
                        Text("Q\(index)")
                            .font(ScaledFont.scaledFont(size: 10, weight: .bold, design: .rounded))
                            .foregroundColor(.white.opacity(0.3))
                        Text(result.questionText)
                            .font(ScaledFont.scaledFont(size: 13, weight: .medium, design: .rounded))
                            .foregroundColor(.white.opacity(0.85))
                            .lineLimit(showDetails ? nil : 2)
                            .multilineTextAlignment(.leading)
                    }

                    Spacer()

                    Image(systemName: showDetails ? "chevron.up" : "chevron.down")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.white.opacity(0.25))
                        .accessibilityHidden(true)
                }
                .padding(14)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            if showDetails {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(Array(result.options.enumerated()), id: \.offset) { i, option in
                        HStack(spacing: 10) {
                            let isCorrect = i == result.correctIndex
                            let isSelected = i == result.selectedIndex

                            Text(["A", "B", "C", "D"][min(i, 3)])
                                .font(ScaledFont.scaledFont(size: 11, weight: .bold, design: .rounded))
                                .foregroundColor(isCorrect ? success : isSelected ? coral : .white.opacity(0.3))
                                .frame(width: 22, height: 22)
                                .background(
                                    Circle().fill(
                                        isCorrect ? success.opacity(0.12) :
                                        isSelected ? coral.opacity(0.12) :
                                        Color.white.opacity(0.04)
                                    )
                                )

                            Text(option)
                                .font(ScaledFont.scaledFont(size: 12, weight: isCorrect ? .semibold : .regular, design: .rounded))
                                .foregroundColor(isCorrect ? success : isSelected ? coral.opacity(0.7) : .white.opacity(0.5))

                            Spacer()

                            if isCorrect {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 13))
                                    .foregroundColor(success)
                            } else if isSelected && !result.wasCorrect {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.system(size: 13))
                                    .foregroundColor(coral)
                            }
                        }
                    }

                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "lightbulb.fill")
                            .font(.system(size: 12))
                            .foregroundColor(.yellow.opacity(0.7))
                            .padding(.top, 2)
                        Text(result.explanation)
                            .font(ScaledFont.scaledFont(size: 12, weight: .regular, design: .rounded))
                            .foregroundColor(.white.opacity(0.6))
                            .lineSpacing(3)
                    }
                    .padding(.top, 6)
                }
                .padding(.horizontal, 14)
                .padding(.bottom, 14)
                .padding(.leading, 44)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(result.wasCorrect ? success.opacity(0.03) : coral.opacity(0.03))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(result.wasCorrect ? success.opacity(0.1) : coral.opacity(0.1), lineWidth: 1)
                )
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Question \(index): \(result.questionText). \(result.wasCorrect ? "Correct" : "Incorrect")")
        .accessibilityHint(showDetails ? "Double tap to collapse" : "Double tap to see details")
        .accessibilityAddTraits(.isButton)
    }
}

// MARK: - Epilogue Cyber Grid
struct EpilogueCyberGrid: View {
    let scroll: CGFloat
    let color: Color

    var body: some View {
        GeometryReader { geo in
            Canvas { context, size in
                let lineColor = color.opacity(0.25)
                let horizon: CGFloat = size.height * 0.42
                let lineCount = 18
                for i in 0..<lineCount {
                    let t = CGFloat(i) / CGFloat(lineCount)
                    let adjusted = t + scroll.truncatingRemainder(dividingBy: 1.0 / CGFloat(lineCount))
                    let y = horizon + pow(adjusted, 1.8) * (size.height - horizon)
                    var path = Path()
                    path.move(to: CGPoint(x: 0, y: y))
                    path.addLine(to: CGPoint(x: size.width, y: y))
                    context.stroke(path, with: .color(lineColor), lineWidth: 0.6)
                }
                let vCount = 14
                let vanishX = size.width / 2
                for i in 0...vCount {
                    let t = CGFloat(i) / CGFloat(vCount)
                    let bottomX = t * size.width
                    let topX = vanishX + (bottomX - vanishX) * 0.15
                    var path = Path()
                    path.move(to: CGPoint(x: topX, y: horizon))
                    path.addLine(to: CGPoint(x: bottomX, y: size.height))
                    context.stroke(path, with: .color(lineColor), lineWidth: 0.5)
                }
            }
        }
        .accessibilityHidden(true)
    }
}

// MARK: - Epilogue Scan Lines
struct EpilogueScanLines: View {
    var body: some View {
        Canvas { context, size in
            for y in stride(from: 0, to: size.height, by: 3) {
                var path = Path()
                path.move(to: CGPoint(x: 0, y: y))
                path.addLine(to: CGPoint(x: size.width, y: y))
                context.stroke(path, with: .color(.black.opacity(0.3)), lineWidth: 1)
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

#Preview {
    EpilogueView(stats: JourneyStats(), onReplay: {})
}
