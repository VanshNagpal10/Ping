//
//  EncyclopediaView.swift
//  Ping - Packet World
//
//  The Daemon's Encyclopedia - collected journal of networking terms
//

import SwiftUI

struct EncyclopediaView: View {
    let terms: [EncyclopediaTerm]
    let onClose: () -> Void
    
    @State private var selectedCategory: EncyclopediaTerm.TermCategory? = nil
    @State private var selectedTerm: EncyclopediaTerm? = nil
    @State private var appear = false
    
    var filteredTerms: [EncyclopediaTerm] {
        if let category = selectedCategory {
            return terms.filter { $0.category == category }
        }
        return terms
    }
    
    var body: some View {
        ZStack {
            // Dark Blur Background
            Color.black.opacity(0.6)
                .ignoresSafeArea()
                .background(.ultraThinMaterial)
                .onTapGesture { onClose() }
            
            // Main Holographic Panel
            VStack(spacing: 0) {
                // Header (Tech Terminal Style)
                HStack {
                    Image(systemName: "server.rack")
                        .font(.system(size: 28))
                        .foregroundColor(.cyan)
                        .shadow(color: .cyan, radius: 5)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("SYSTEM_CODEX // ENCYCLOPEDIA")
                            .font(.system(size: 18, weight: .black, design: .monospaced))
                            .foregroundColor(.white)
                            .tracking(2)
                        
                        Text("DATA FRAGMENTS COLLECTED: \(terms.count)")
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                            .foregroundColor(.cyan.opacity(0.8))
                    }
                    
                    Spacer()
                    
                    Button(action: onClose) {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                            .padding(10)
                            .background(Circle().fill(Color.white.opacity(0.1)))
                    }
                    .buttonStyle(.plain)
                }
                .padding(24)
                .background(Color.black.opacity(0.4))
                
                // Glowing Divider
                Rectangle()
                    .fill(LinearGradient(colors: [.clear, .cyan.opacity(0.8), .clear], startPoint: .leading, endPoint: .trailing))
                    .frame(height: 2)
                    .shadow(color: .cyan, radius: 3)
                
                // Category Filter (Glowing Pills)
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        CategoryPill(
                            title: "ALL DATA",
                            isSelected: selectedCategory == nil,
                            color: .cyan
                        ) {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) { selectedCategory = nil }
                        }
                        
                        ForEach(EncyclopediaTerm.TermCategory.allCases, id: \.self) { category in
                            CategoryPill(
                                title: category.rawValue.uppercased(),
                                isSelected: selectedCategory == category,
                                color: categoryColor(category)
                            ) {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) { selectedCategory = category }
                            }
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 16)
                }
                .background(Color.black.opacity(0.2))
                
                // Content Area
                if terms.isEmpty {
                    // Futuristic Empty State
                    VStack(spacing: 16) {
                        Spacer()
                        Image(systemName: "magnifyingglass.circle")
                            .font(.system(size: 60, weight: .thin))
                            .foregroundColor(.cyan.opacity(0.4))
                        Text("NO DATA FRAGMENTS FOUND")
                            .font(.system(size: 16, weight: .bold, design: .monospaced))
                            .foregroundColor(.white.opacity(0.6))
                            .tracking(2)
                        Text("Interact with network entities to expand database.")
                            .font(.system(size: 12, design: .monospaced))
                            .foregroundColor(.gray)
                        Spacer()
                    }
                } else {
                    // Scrollable Grid/List
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(filteredTerms) { term in
                                TermCard(term: term, isExpanded: selectedTerm == term)
                                    .onTapGesture {
                                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                            selectedTerm = selectedTerm == term ? nil : term
                                        }
                                    }
                            }
                        }
                        .padding(24)
                    }
                }
            }
            .frame(width: 650, height: 550) // Wide, landscape-friendly modal
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(red: 0.05, green: 0.05, blue: 0.08).opacity(0.95))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(LinearGradient(colors: [.cyan.opacity(0.5), .purple.opacity(0.3)], startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 1.5)
            )
            .shadow(color: .cyan.opacity(0.15), radius: 40)
            .scaleEffect(appear ? 1 : 0.9)
            .opacity(appear ? 1 : 0)
        }
        .onAppear {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                appear = true
            }
        }
    }
    
    private func categoryColor(_ category: EncyclopediaTerm.TermCategory) -> Color {
        switch category {
        case .basics: return .cyan
        case .protocols: return .green
        case .infrastructure: return .orange
        case .security: return .red
        }
    }
}

// MARK: - Category Pill
struct CategoryPill: View {
    let title: String
    let isSelected: Bool
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 11, weight: .bold, design: .monospaced))
                .tracking(1)
                .foregroundColor(isSelected ? .black : color)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(isSelected ? color : color.opacity(0.1))
                )
                .overlay(
                    Capsule()
                        .stroke(color.opacity(isSelected ? 1.0 : 0.4), lineWidth: 1)
                )
                .shadow(color: isSelected ? color.opacity(0.6) : .clear, radius: 5)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Term Card
struct TermCard: View {
    let term: EncyclopediaTerm
    let isExpanded: Bool
    
    var categoryBadgeColor: Color {
        switch term.category {
        case .basics: return .cyan
        case .protocols: return .green
        case .infrastructure: return .orange
        case .security: return .red
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Main Row
            HStack(spacing: 16) {
                // Glowing Icon Box
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(categoryBadgeColor.opacity(0.15))
                        .frame(width: 44, height: 44)
                    
                    Image(systemName: term.icon)
                        .font(.system(size: 20))
                        .foregroundColor(categoryBadgeColor)
                        .shadow(color: categoryBadgeColor.opacity(0.5), radius: 3)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(term.term)
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    
                    Text(term.category.rawValue.uppercased())
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundColor(categoryBadgeColor)
                        .tracking(1)
                }
                
                Spacer()
                
                Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                    .foregroundColor(categoryBadgeColor.opacity(0.7))
                    .font(.system(size: 14, weight: .bold))
            }
            .padding(16)
            
            // Expanded Definition Area
            if isExpanded {
                VStack(alignment: .leading) {
                    Rectangle()
                        .fill(categoryBadgeColor.opacity(0.3))
                        .frame(height: 1)
                    
                    Text(term.definition)
                        .font(.system(size: 14, weight: .medium, design: .monospaced)) // Monospaced for tech feel
                        .foregroundColor(.gray)
                        .lineSpacing(6)
                        .padding(16)
                }
                .background(Color.black.opacity(0.3))
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(isExpanded ? 0.08 : 0.03))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isExpanded ? categoryBadgeColor.opacity(0.6) : Color.white.opacity(0.1), lineWidth: 1.5)
        )
        .shadow(color: isExpanded ? categoryBadgeColor.opacity(0.1) : .clear, radius: 10)
    }
}
