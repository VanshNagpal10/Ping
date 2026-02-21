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
    
    var filteredTerms: [EncyclopediaTerm] {
        if let category = selectedCategory {
            return terms.filter { $0.category == category }
        }
        return terms
    }
    
    var body: some View {
        ZStack {
            // Dimmed background
            Color.black.opacity(0.8)
                .onTapGesture { onClose() }
            
            HStack(spacing: 0) {
                Spacer()
                
                // Encyclopedia panel
                VStack(spacing: 0) {
                    // Header
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            HStack(spacing: 8) {
                                Image(systemName: "book.closed.fill")
                                    .font(.title)
                                    .foregroundColor(.cyan)
                                Text("DAEMON'S ENCYCLOPEDIA")
                                    .font(.system(size: 18, weight: .bold, design: .monospaced))
                                    .foregroundColor(.cyan)
                            }
                            
                            Text("\(terms.count) terms collected")
                                .font(.system(size: 12, design: .rounded))
                                .foregroundColor(.gray)
                        }
                        
                        Spacer()
                        
                        Button(action: onClose) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.title)
                                .foregroundColor(.gray)
                        }
                    }
                    .padding(20)
                    .background(Color.black.opacity(0.5))
                    
                    // Category filter
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            CategoryPill(
                                title: "All",
                                isSelected: selectedCategory == nil,
                                color: .cyan
                            ) {
                                selectedCategory = nil
                            }
                            
                            ForEach(EncyclopediaTerm.TermCategory.allCases, id: \.self) { category in
                                CategoryPill(
                                    title: category.rawValue,
                                    isSelected: selectedCategory == category,
                                    color: categoryColor(category)
                                ) {
                                    selectedCategory = category
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                    }
                    .background(Color.black.opacity(0.3))
                    
                    if terms.isEmpty {
                        // Empty state
                        VStack(spacing: 16) {
                            Spacer()
                            
                            Image(systemName: "book.closed")
                                .font(.system(size: 50))
                                .foregroundColor(.gray.opacity(0.5))
                            
                            Text("No terms collected yet")
                                .font(.system(size: 16, design: .rounded))
                                .foregroundColor(.gray)
                            
                            Text("Talk to NPCs to learn networking concepts!")
                                .font(.system(size: 12, design: .rounded))
                                .foregroundColor(.gray.opacity(0.7))
                            
                            Spacer()
                        }
                    } else {
                        // Terms list
                        ScrollView {
                            LazyVStack(spacing: 12) {
                                ForEach(filteredTerms) { term in
                                    TermCard(term: term, isExpanded: selectedTerm == term)
                                        .onTapGesture {
                                            withAnimation(.spring()) {
                                                if selectedTerm == term {
                                                    selectedTerm = nil
                                                } else {
                                                    selectedTerm = term
                                                }
                                            }
                                        }
                                }
                            }
                            .padding(20)
                        }
                    }
                }
                .frame(width: 350)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color(red: 0.08, green: 0.08, blue: 0.12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(
                                    LinearGradient(
                                        colors: [.cyan.opacity(0.5), .purple.opacity(0.3)],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    ),
                                    lineWidth: 1
                                )
                        )
                )
                .padding(20)
            }
        }
        .ignoresSafeArea()
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
                .font(.system(size: 12, weight: isSelected ? .bold : .medium, design: .rounded))
                .foregroundColor(isSelected ? .black : color)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(isSelected ? color : color.opacity(0.2))
                )
        }
    }
}

// MARK: - Term Card
struct TermCard: View {
    let term: EncyclopediaTerm
    let isExpanded: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: term.icon)
                    .font(.title2)
                    .foregroundColor(.cyan)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(term.term)
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)
                    
                    Text(term.category.rawValue)
                        .font(.system(size: 10, design: .rounded))
                        .foregroundColor(categoryBadgeColor)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(
                            Capsule()
                                .fill(categoryBadgeColor.opacity(0.2))
                        )
                }
                
                Spacer()
                
                Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                    .foregroundColor(.gray)
            }
            
            if isExpanded {
                Text(term.definition)
                    .font(.system(size: 14, design: .rounded))
                    .foregroundColor(.gray)
                    .lineSpacing(4)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(isExpanded ? categoryBadgeColor.opacity(0.5) : Color.clear, lineWidth: 1)
                )
        )
    }
    
    private var categoryBadgeColor: Color {
        switch term.category {
        case .basics: return .cyan
        case .protocols: return .green
        case .infrastructure: return .orange
        case .security: return .red
        }
    }
}

// MARK: - Preview Encyclopedia with Sample Data
struct EncyclopediaView_Previews: PreviewProvider {
    static var previews: some View {
        EncyclopediaView(
            terms: [
                EncyclopediaTerm.term(for: "daemon")!,
                EncyclopediaTerm.term(for: "packet")!,
                EncyclopediaTerm.term(for: "dns")!,
                EncyclopediaTerm.term(for: "tcp")!
            ],
            onClose: {}
        )
    }
}
