//
//  QuizView.swift
//  Ping - Packet World
//  Level-end quiz overlay — tests concepts taught in each scene
//

import SwiftUI

struct QuizOverlay: View {
    @ObservedObject var engine: GameEngine
    let scene: StoryScene
    
    @State private var currentQuestionIndex = 0
    @State private var selectedAnswer: Int? = nil
    @State private var showExplanation = false
    @State private var answeredCorrectly = false
    @State private var correctCount = 0
    @State private var totalAnswered = 0
    @State private var quizComplete = false
    @State private var appear = false
    @State private var progressPulse = false
    
    private var questions: [QuizQuestion] {
        LevelQuizzes.quiz(for: scene)
    }
    
    private var currentQuestion: QuizQuestion? {
        guard currentQuestionIndex < questions.count else { return nil }
        return questions[currentQuestionIndex]
    }
    
    var body: some View {
        ZStack {
            // Dim background
            Color.black.opacity(0.85)
                .ignoresSafeArea()
            
            // Subtle scan lines
            VStack(spacing: 3) {
                ForEach(0..<100, id: \.self) { _ in
                    Rectangle()
                        .fill(Color.white.opacity(0.015))
                        .frame(height: 1)
                    Spacer().frame(height: 2)
                }
            }
            .ignoresSafeArea()
            
            if quizComplete {
                quizResultsView
                    .transition(.scale.combined(with: .opacity))
            } else if let question = currentQuestion {
                questionView(question)
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .move(edge: .leading).combined(with: .opacity)
                    ))
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.5)) {
                appear = true
            }
        }
    }
    
    // MARK: - Question View
    @ViewBuilder
    private func questionView(_ question: QuizQuestion) -> some View {
        VStack(spacing: 0) {
            Spacer()
            
            VStack(spacing: 20) {
                // Header
                HStack(spacing: 8) {
                    Image(systemName: "brain.head.profile")
                        .font(.system(size: 18))
                        .foregroundColor(scene.accentColor)
                    
                    Text("KNOWLEDGE CHECK")
                        .font(.system(size: 13, weight: .bold, design: .monospaced))
                        .foregroundColor(scene.accentColor)
                        .tracking(3)
                    
                    Spacer()
                    
                    // Progress
                    Text("\(currentQuestionIndex + 1)/\(questions.count)")
                        .font(.system(size: 12, weight: .medium, design: .monospaced))
                        .foregroundColor(.white.opacity(0.5))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(
                            Capsule().fill(Color.white.opacity(0.1))
                        )
                }
                
                // Progress bar
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color.white.opacity(0.1))
                        
                        RoundedRectangle(cornerRadius: 2)
                            .fill(scene.accentColor)
                            .frame(width: geo.size.width * CGFloat(currentQuestionIndex + 1) / CGFloat(questions.count))
                            .animation(.spring(response: 0.4), value: currentQuestionIndex)
                    }
                }
                .frame(height: 3)
                
                // Question text
                Text(question.question)
                    .font(.system(size: 17, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, 4)
                
                // Answer options
                VStack(spacing: 10) {
                    ForEach(Array(question.options.enumerated()), id: \.offset) { index, option in
                        answerButton(index: index, text: option, question: question)
                    }
                }
                
                // Explanation (after answering)
                if showExplanation {
                    explanationBanner(question: question)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .padding(24)
            .frame(maxWidth: 520)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color(red: 0.06, green: 0.04, blue: 0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(scene.accentColor.opacity(0.3), lineWidth: 1.5)
                    )
                    .shadow(color: scene.accentColor.opacity(0.15), radius: 30)
            )
            .opacity(appear ? 1 : 0)
            .scaleEffect(appear ? 1 : 0.9)
            
            Spacer()
        }
        .padding(.horizontal, 40)
    }
    
    // MARK: - Answer Button
    @ViewBuilder
    private func answerButton(index: Int, text: String, question: QuizQuestion) -> some View {
        let isSelected = selectedAnswer == index
        let isCorrect = index == question.correctIndex
        let showResult = showExplanation
        
        let bgColor: Color = {
            if showResult && isCorrect { return .green.opacity(0.2) }
            if showResult && isSelected && !isCorrect { return .red.opacity(0.2) }
            if isSelected && !showResult { return scene.accentColor.opacity(0.15) }
            return Color.white.opacity(0.05)
        }()
        
        let borderColor: Color = {
            if showResult && isCorrect { return .green }
            if showResult && isSelected && !isCorrect { return .red }
            if isSelected && !showResult { return scene.accentColor }
            return Color.white.opacity(0.15)
        }()
        
        let labelLetter = ["A", "B", "C", "D"][min(index, 3)]
        
        Button {
            guard !showExplanation else { return }
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                selectedAnswer = index
            }
            
            // Brief delay then reveal answer
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                answeredCorrectly = index == question.correctIndex
                if answeredCorrectly {
                    correctCount += 1
                    SoundManager.shared.playQuizCorrectSound()
                } else {
                    SoundManager.shared.playQuizWrongSound()
                }
                totalAnswered += 1
                
                // Record result
                engine.recordQuizResult(QuizResult(
                    scene: scene,
                    questionText: question.question,
                    wasCorrect: answeredCorrectly
                ))
                
                withAnimation(.spring(response: 0.4)) {
                    showExplanation = true
                }
            }
        } label: {
            HStack(spacing: 12) {
                // Letter badge
                Text(labelLetter)
                    .font(.system(size: 13, weight: .bold, design: .monospaced))
                    .foregroundColor(showResult && isCorrect ? .green : .white.opacity(0.6))
                    .frame(width: 28, height: 28)
                    .background(
                        Circle()
                            .fill(borderColor.opacity(0.2))
                    )
                
                Text(text)
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.leading)
                
                Spacer()
                
                if showResult && isCorrect {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                        .transition(.scale)
                } else if showResult && isSelected && !isCorrect {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.red)
                        .transition(.scale)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(bgColor)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(borderColor, lineWidth: 1.2)
                    )
            )
        }
        .buttonStyle(.plain)
        .disabled(showExplanation)
    }
    
    // MARK: - Explanation Banner
    @ViewBuilder
    private func explanationBanner(question: QuizQuestion) -> some View {
        VStack(spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: answeredCorrectly ? "checkmark.circle.fill" : "info.circle.fill")
                    .foregroundColor(answeredCorrectly ? .green : .yellow)
                
                Text(answeredCorrectly ? "Correct!" : "Not quite!")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundColor(answeredCorrectly ? .green : .yellow)
                
                Spacer()
            }
            
            Text(question.explanation)
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundColor(.white.opacity(0.8))
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            // Continue button
            Button {
                advanceQuiz()
            } label: {
                HStack(spacing: 6) {
                    Text(currentQuestionIndex < questions.count - 1 ? "NEXT" : "CONTINUE")
                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                        .tracking(2)
                    Image(systemName: "arrow.right")
                        .font(.system(size: 11))
                }
                .foregroundColor(.black)
                .padding(.horizontal, 24)
                .padding(.vertical, 10)
                .background(
                    Capsule().fill(scene.accentColor)
                )
            }
            .buttonStyle(.plain)
            .frame(maxWidth: .infinity, alignment: .trailing)
            .padding(.top, 4)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.black.opacity(0.5))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(
                            (answeredCorrectly ? Color.green : Color.yellow).opacity(0.3),
                            lineWidth: 1
                        )
                )
        )
    }
    
    // MARK: - Quiz Results
    @ViewBuilder
    private var quizResultsView: some View {
        VStack(spacing: 24) {
            Spacer()
            
            VStack(spacing: 20) {
                // Score icon
                ZStack {
                    Circle()
                        .fill(scoreColor.opacity(0.15))
                        .frame(width: 70, height: 70)
                    
                    Circle()
                        .stroke(scoreColor.opacity(0.4), lineWidth: 2)
                        .frame(width: 70, height: 70)
                    
                    Image(systemName: scoreIcon)
                        .font(.system(size: 30))
                        .foregroundColor(scoreColor)
                }
                
                Text(scoreMessage)
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                
                // Score
                HStack(spacing: 4) {
                    Text("\(correctCount)")
                        .font(.system(size: 36, weight: .black, design: .rounded))
                        .foregroundColor(scoreColor)
                    Text("/")
                        .font(.system(size: 24, weight: .light))
                        .foregroundColor(.white.opacity(0.3))
                    Text("\(questions.count)")
                        .font(.system(size: 36, weight: .black, design: .rounded))
                        .foregroundColor(.white.opacity(0.5))
                }
                
                Text("from \(scene.displayName)")
                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                    .foregroundColor(.white.opacity(0.4))
                    .tracking(1)
                
                // Continue button
                Button {
                    engine.dismissQuiz()
                } label: {
                    HStack(spacing: 8) {
                        Text("CONTINUE JOURNEY")
                            .font(.system(size: 13, weight: .bold, design: .monospaced))
                            .tracking(2)
                        Image(systemName: "arrow.right.circle.fill")
                            .font(.system(size: 16))
                    }
                    .foregroundColor(.black)
                    .padding(.horizontal, 32)
                    .padding(.vertical, 14)
                    .background(
                        Capsule()
                            .fill(scene.accentColor)
                            .shadow(color: scene.accentColor.opacity(0.4), radius: 12)
                    )
                }
                .buttonStyle(.plain)
                .padding(.top, 8)
            }
            .padding(32)
            .frame(maxWidth: 400)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color(red: 0.06, green: 0.04, blue: 0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(scoreColor.opacity(0.3), lineWidth: 1.5)
                    )
                    .shadow(color: scoreColor.opacity(0.1), radius: 30)
            )
            
            Spacer()
        }
    }
    
    // MARK: - Helpers
    private func advanceQuiz() {
        withAnimation(.easeInOut(duration: 0.3)) {
            selectedAnswer = nil
            showExplanation = false
            answeredCorrectly = false
            
            if currentQuestionIndex < questions.count - 1 {
                currentQuestionIndex += 1
            } else {
                quizComplete = true
            }
        }
    }
    
    private var scoreColor: Color {
        let ratio = Double(correctCount) / Double(max(questions.count, 1))
        if ratio >= 0.8 { return .green }
        if ratio >= 0.5 { return .yellow }
        return .orange
    }
    
    private var scoreIcon: String {
        let ratio = Double(correctCount) / Double(max(questions.count, 1))
        if ratio >= 0.8 { return "star.fill" }
        if ratio >= 0.5 { return "hand.thumbsup.fill" }
        return "lightbulb.fill"
    }
    
    private var scoreMessage: String {
        let ratio = Double(correctCount) / Double(max(questions.count, 1))
        if ratio >= 1.0 { return "Perfect Score!" }
        if ratio >= 0.8 { return "Great Job!" }
        if ratio >= 0.5 { return "Good Effort!" }
        return "Keep Learning!"
    }
}
