import SwiftUI

struct FlashcardView: View {
    @Binding var word: Word
    var onSwipe: (LearningState) -> Void
    var onSkip: () -> Void
    var nextWord: Word?
    @State private var isLearned = false
    @State private var offset: CGSize = .zero
    @State private var isTransitioning = false
    @State private var currentCardOpacity: Double = 1.0
    @State private var isSkipPressed = false
    @State private var isLearnedPressed = false
    
    private let spring = Animation.interpolatingSpring(
        stiffness: 100,
        damping: 35
    )
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Card Stack
                VStack {
                    ZStack {
                        if let nextWord = nextWord {
                            CardView(word: nextWord)
                                .opacity(isTransitioning ? 1.0 : 0.0)
                                .onAppear {
                                    print("Displaying next word - ID: \(nextWord.id), Text: \(nextWord.text)")
                                }
                        }
                        
                        CardView(word: word)
                            .offset(offset)
                            .rotationEffect(.degrees(Double(offset.width / 20)))
                            .opacity(currentCardOpacity)
                            .onAppear {
                                print("Displaying current word - ID: \(word.id), Text: \(word.text)")
                            }
                            .highPriorityGesture(
                                DragGesture()
                                    .onChanged { value in
                                        offset = CGSize(width: value.translation.width, height: value.translation.height * 0.2)
                                    }
                                    .onEnded { value in
                                        let threshold: CGFloat = 100
                                        if abs(value.translation.width) > threshold {
                                            // Start showing next card immediately with slower fade-in
                                            withAnimation(.easeIn(duration: 0.15)) {
                                                isTransitioning = true
                                            }
                                            
                                            // Fade out current card more gradually
                                            withAnimation(.easeOut(duration: 0.6)) {
                                                currentCardOpacity = 0.0
                                                offset = CGSize(width: value.translation.width * 2, height: 0)
                                            } completion: {
                                                if value.translation.width > 0 {
                                                    onSwipe(.learned)
                                                } else {
                                                    onSwipe(.learning)
                                                }
                                            }
                                        } else {
                                            withAnimation(.easeInOut(duration: 0.25)) {
                                                offset = .zero
                                            }
                                        }
                                    }
                            )
                    }
                }
                .padding(.top, -40)  // Add negative top padding to move cards up
                
                // Buttons with absolute positioning
                VStack {
                    Spacer()
                    HStack {
                        Button(action: {
                            // Start showing next card immediately with slower fade-in
                            withAnimation(.easeIn(duration: 0.15)) {
                                isTransitioning = true
                            }
                            
                            // Slide the card to the right and fade out
                            withAnimation(.easeOut(duration: 0.6)) {
                                currentCardOpacity = 0.0
                                offset = CGSize(width: 500, height: 0)
                            } completion: {
                                onSkip()
                                // Reset the state
                                offset = .zero
                                currentCardOpacity = 1.0
                                isTransitioning = false
                            }
                        }) {
                            Text("Skip")
                                .font(.system(size: 20))
                                .foregroundColor(.black)
                        }
                        .padding(.leading, 42)
                        .scaleEffect(isSkipPressed ? 0.95 : 1.0)
                        .simultaneousGesture(
                            DragGesture(minimumDistance: 0)
                                .onChanged { _ in isSkipPressed = true }
                                .onEnded { _ in isSkipPressed = false }
                        )
                        .buttonStyle(.plain)
                        
                        Spacer()
                        
                        Button(action: {
                            handleLearned()
                        }) {
                            Text("Learned It")
                                .font(.system(size: 20))
                                .foregroundColor(.black)
                        }
                        .padding(.trailing, 42)
                        .scaleEffect(isLearnedPressed ? 0.95 : 1.0)
                        .simultaneousGesture(
                            DragGesture(minimumDistance: 0)
                                .onChanged { _ in isLearnedPressed = true }
                                .onEnded { _ in isLearnedPressed = false }
                        )
                        .buttonStyle(.plain)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.bottom, 40)  // Fixed distance from bottom
                }
            }
        }
    }
    
    private func handleLearned() {
        isLearned = true
        
        // Start showing next card immediately with slower fade-in
        withAnimation(.easeIn(duration: 0.15)) {
            isTransitioning = true
        }
        
        // Slide the card to the right and fade out
        withAnimation(.easeOut(duration: 0.6)) {
            currentCardOpacity = 0.0
            offset = CGSize(width: 500, height: 0)
        } completion: {
            onSwipe(.learned)
            // Reset the state
            offset = .zero
            currentCardOpacity = 1.0
            isTransitioning = false
            isLearned = false
        }
    }
}

struct DeckView: View {
    let currentWord: Word
    let nextWord: Word?
    let onSwipe: (LearningState) -> Void
    let spring: Animation
    
    @State private var offset: CGSize = .zero
    @State private var isDragging = false
    @State private var isTransitioning = false
    @State private var currentCardOpacity: Double = 1.0
    
    var body: some View {
        ZStack {
            if let nextWord = nextWord {
                CardView(word: nextWord)
                    .opacity(isTransitioning ? 1.0 : 0.0)
            }
            
            CardView(word: currentWord)
                .offset(offset)
                .rotationEffect(.degrees(Double(offset.width / 20)))
                .opacity(currentCardOpacity)
                .highPriorityGesture(
                    DragGesture()
                        .onChanged { value in
                            offset = CGSize(width: value.translation.width, height: value.translation.height * 0.2)
                        }
                        .onEnded { value in
                            let threshold: CGFloat = 100
                            if abs(value.translation.width) > threshold {
                                // Start showing next card immediately with slower fade-in
                                withAnimation(.easeIn(duration: 0.15)) {
                                    isTransitioning = true
                                }
                                
                                // Fade out current card more gradually
                                withAnimation(.easeOut(duration: 0.6)) {
                                    currentCardOpacity = 0.0
                                    offset = CGSize(width: value.translation.width * 2, height: 0)
                                } completion: {
                                    if value.translation.width > 0 {
                                        onSwipe(.learned)
                                    } else {
                                        onSwipe(.learning)
                                    }
                                }
                            } else {
                                withAnimation(.easeInOut(duration: 0.25)) {
                                    offset = .zero
                                }
                            }
                        }
                )
        }
        .transition(.asymmetric(
            insertion: .opacity.animation(.easeInOut(duration: 0.4)),
            removal: .opacity.animation(.easeOut(duration: 0.4))
        ))
    }
}
struct BracketView: View {
    var isLeft: Bool = true
    var width: CGFloat = 20
    var heightRatio: CGFloat = 0.8
    var lineWidth: CGFloat = 3
    var shortLineRatio: CGFloat = 0.4

    var body: some View {
        GeometryReader { geometry in
            Path { path in
                let height = geometry.size.height
                let width: CGFloat = geometry.size.width
                let bracketHeight: CGFloat = height * heightRatio
                let offsetY = (height - bracketHeight) / 2
                let shortLine: CGFloat = width * shortLineRatio

                if isLeft {
                    // ┌
                    path.move(to: CGPoint(x: width, y: offsetY))
                    path.addLine(to: CGPoint(x: shortLine, y: offsetY))
                    path.addLine(to: CGPoint(x: shortLine, y: offsetY + bracketHeight))
                    path.addLine(to: CGPoint(x: width, y: offsetY + bracketHeight))
                } else {
                    // ┐
                    path.move(to: CGPoint(x: 0, y: offsetY))
                    path.addLine(to: CGPoint(x: width - shortLine, y: offsetY))
                    path.addLine(to: CGPoint(x: width - shortLine, y: offsetY + bracketHeight))
                    path.addLine(to: CGPoint(x: 0, y: offsetY + bracketHeight))
                }
            }
            .stroke(Color.black, lineWidth: lineWidth)
        }
    }
}

struct CardView: View {
    let word: Word
    var horizontalPadding: CGFloat = 30
    
    var body: some View {
        HStack(spacing: 0) {
            BracketView(width: 30, heightRatio: 0.9, lineWidth: 4, shortLineRatio: 0.5)
                .frame(width: 30)
            
            VStack(spacing: 20) {
                Text(word.text)
                    .font(.largeTitle)
                    .bold()
                    .padding(.top)

                if let definition = word.definition {
                    Text(definition)
                        .font(.body)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }

                if let example = word.exampleSentence {
                    Text(example)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 10)
            
            BracketView(isLeft: false, width: 30, heightRatio: 0.9, lineWidth: 4, shortLineRatio: 0.5)
                .frame(width: 30)
        }
        .frame(height: 400)
        .padding(.horizontal, horizontalPadding)
    }
}

struct CircularProgressView: View {
    /// A value between 0 and 1 representing progress
    let progress: Double
    let size: CGFloat = 32

    var body: some View {
        ZStack {
            // Background circle (faint stroke)
            Circle()
                // .stroke(Color.black.opacity(0.3), lineWidth: 5)
                .fill(Color(red: 255/255, green: 184/255, blue: 121/255))
                .frame(width: size, height: size)

            // Foreground trimmed circle showing progress
            Circle()
                .trim(from: 0, to: min(max(progress, 0), 1))
                .stroke(Color.black, style: StrokeStyle(lineWidth: 5, lineCap: .round))
                .rotationEffect(.degrees(-90)) // Start at top
                .frame(width: size, height: size)
                .animation(.easeInOut(duration: 0.3), value: progress)
        }
        .frame(width: size, height: size)
    }
}

struct SessionCompletionView: View {
    let skippedWords: [Word]
    let allWords: [Word]
    let onDismiss: () -> Void

    var body: some View {
        VStack {
            Spacer().frame(height: 48)

            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 10) {
                    // 1) Your header text, bolded:
                    Text("Skipped")
                        .font(.system(size: 32))
                        .bold()
                        // 2) Overlay a Rectangle _just_ under the baseline:
                        .overlay(
                            Rectangle()
                                .frame(height: 2)          // thickness you want
                                .offset(y: 6)            // tweak until it sits right under the letters
                                .foregroundColor(.primary) // same color as text
                            ,
                            alignment: .bottomLeading
                        )
                        .padding(.bottom, 16)

                    if !skippedWords.isEmpty {
                        ForEach(skippedWords) { word in
                            Text(word.text)
                                .font(.system(size: 20))
                        }
                    }
                }

                let learnedWords = allWords.filter { word in
                    !skippedWords.contains(where: { $0.id == word.id })
                }

                VStack(alignment: .leading, spacing: 10) {
                    Text("Learned")
                        .font(.system(size: 32))
                        .bold()
                        .overlay(
                            Rectangle()
                                .frame(height: 2)
                                .offset(y: 6)
                                .foregroundColor(.primary)
                            ,
                            alignment: .bottomLeading
                        )
                        .padding(.top, 16)
                        .padding(.bottom, 16)

                    if !learnedWords.isEmpty {
                        ForEach(learnedWords) { word in
                            Text(word.text)
                                .font(.system(size: 20))
                        }
                    }
                }

                Button("Done") {
                    onDismiss()
                }
                .font(.system(size: 32))
                .bold()
                .buttonStyle(ScaleButtonStyle())
                .padding(.top, 20)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 40)

            Spacer()
        }
    }
}


struct FlashcardSessionView: View {
    let initialWords: [Word]
    @State private var words: [Word]
    @State private var currentIndex = 0
    @State private var learnedWords = 0
    @State private var isCompleting = false
    @State private var isTransitioning = false
    @State private var viewKey = UUID()
    @State private var skippedWords: [Word] = []
    @Environment(\.dismiss) private var dismiss
    @Environment(\.presentationMode) var presentationMode
    
    init(words: [Word]) {
        print("Initializing FlashcardSessionView with \(words.count) words")
        self.initialWords = Array(words.shuffled())
        self._words = State(initialValue: Array(words.shuffled()))
        for (index, word) in self.words.enumerated() {
            print("Word \(index + 1): \(word.text), Definition: \(word.definition ?? "nil"), Example: \(word.exampleSentence ?? "nil")")
        }
    }
    
    var body: some View {
        ZStack {
            VStack {
                if !isCompleting {
                    if !words.isEmpty && currentIndex < words.count {
                        FlashcardView(
                            word: Binding(
                                get: { 
                                    print("Getting word at index \(currentIndex): \(words[currentIndex].text)")
                                    return words[currentIndex] 
                                },
                                set: { _ in }
                            ),
                            onSwipe: { newState in
                                print("Swipe detected with state: \(newState)")
                                handleSwipe(newState)
                            },
                            onSkip: {
                                skippedWords.append(words[currentIndex])
                                handleSwipe(.learned)
                            },
                            nextWord: currentIndex + 1 < words.count ? words[currentIndex + 1] : nil
                        )
                        .onAppear {
                            print("Rendering flashcard for word: \(words[currentIndex].text)")
                        }
                        .onChange(of: currentIndex) { oldValue, newValue in
                            print("Current index changed from \(oldValue) to: \(newValue)")
                        }
                        .onChange(of: words.count) { oldValue, newValue in
                            print("Words array count changed from \(oldValue) to: \(newValue)")
                        }
                        .id(viewKey)
                    }
                }
            }

            VStack {
                HStack {
                    Spacer()
                    if !isCompleting {
                        let progress = Double(learnedWords) / Double(initialWords.count)
                        CircularProgressView(progress: progress)
                            .padding(.top, -28)
                            .padding(.trailing, 42)
                            .onAppear {
                                print("Progress view appeared with progress: \(progress)")
                            }
                            .onChange(of: progress) { oldValue, newValue in
                                print("Progress changed from \(oldValue) to: \(newValue) (learnedWords: \(learnedWords), total: \(initialWords.count))")
                            }
                    }
                }
                if isCompleting {
                    SessionCompletionView(
                        skippedWords: skippedWords,
                        allWords: initialWords,
                        onDismiss: {
                            dismiss()
                        }
                    )
                }
                Spacer()
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: {
                    presentationMode.wrappedValue.dismiss()
                }) {
                    Text("BACK")
                        .font(.system(size: 17, weight: .regular))
                        .foregroundColor(.black)
                }
            }
        }
        .onAppear {
            print("FlashcardSessionView appeared with \(words.count) total words")
        }
        .onDisappear {
            print("FlashcardSessionView disappeared")
        }
    }
    
    private func handleSwipe(_ newState: LearningState) {
        let currentWord = words[currentIndex]
        print("Handling swipe for word: \(currentWord.text) with state: \(newState)")
        
        if newState == .learned {
            learnedWords += 1
            // Remove the current word from the deck
            words.remove(at: currentIndex)
        } else {
            // For learning state, reinsert the word at a random position after the next word
            words.remove(at: currentIndex)
            
            // Calculate the range for random insertion
            let startIndex = currentIndex + 1
            let endIndex = words.count
            
            if startIndex < endIndex {
                // If there are words after the current position, insert randomly in that range
                let randomIndex = Int.random(in: startIndex..<endIndex)
                words.insert(currentWord, at: randomIndex)
            } else {
                // If this was the last word, append it
                words.append(currentWord)
            }
        }
        
        // Check if we've processed all words
        if words.isEmpty {
            print("All words processed, completing session")
            withAnimation {
                isCompleting = true
            }
            return
        }
        
        // If we removed the last word, go back one index
        if currentIndex >= words.count {
            currentIndex = max(0, words.count - 1)
        }
        
        // Force view update
        DispatchQueue.main.async {
            let newWords = Array(words)
            words = newWords
            viewKey = UUID()
        }
        
        print("Current state - Learned: \(learnedWords), Remaining: \(words.count)")
    }
}