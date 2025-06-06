import SwiftUI

struct FlashcardView: View {
    @Binding var word: Word
    var onSwipe: (LearningState) -> Void
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
                
                // Buttons with absolute positioning
                VStack {
                    Spacer()
                    HStack {
                        Button(action: {
                            handleLearned()  // Using the same handler for now
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

struct FlashcardSessionView: View {
    let initialWords: [Word]
    @State private var words: [Word]
    @State private var currentIndex = 0
    @State private var learnedWords = 0
    @State private var isCompleting = false
    @State private var isTransitioning = false
    @State private var viewKey = UUID()
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
                Spacer()
                if isCompleting {
                    Text("Next")
                        .font(.system(size: 40))
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .onTapGesture {
                            dismiss()
                        }
                }
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
        print("Current state - Index: \(currentIndex), Words count: \(words.count)")
        
        if newState == .learned {
            print("Before increment - learnedWords: \(learnedWords), total: \(initialWords.count)")
            withAnimation(.easeInOut(duration: 0.3)) {
                learnedWords += 1
            }
            print("After increment - learnedWords: \(learnedWords), total: \(initialWords.count)")
            print("Progress should be: \(Double(learnedWords) / Double(initialWords.count))")
            
            // Remove the current word from the deck
            words.remove(at: currentIndex)
            print("Removed word at index \(currentIndex). New words count: \(words.count)")
            
            // Check if we've learned all words
            if learnedWords == initialWords.count {
                print("All words learned, completing session")
                // Animate progress bar to completion before showing completion screen
                withAnimation(.easeInOut(duration: 0.5)) {
                    learnedWords = initialWords.count
                }
                // Delay the completion screen to allow progress bar animation to finish
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    withAnimation {
                        isCompleting = true
                    }
                }
                return
            }
            
            // If we removed the last word, go back one index
            if currentIndex >= words.count {
                currentIndex = max(0, words.count - 1)
                print("Adjusted current index to: \(currentIndex)")
            }
        } else {
            // For learning state (left swipe)
            let currentWord = words.remove(at: currentIndex)
            print("Removed current word: \(currentWord.text)")
            
            if words.isEmpty {
                // If no more words, just reinsert the current word
                words.append(currentWord)
                currentIndex = 0
                print("No more words, reinserted at index 0")
            } else {
                // Store the next card's index before modifying the deck
                let nextCardIndex = currentIndex
                
                // Randomly insert the current word into the remaining deck
                // Exclude the current position to avoid inserting before the next card
                let randomIndex = Int.random(in: (currentIndex + 1)...words.count)
                words.insert(currentWord, at: randomIndex)
                print("Reinserted word at random index: \(randomIndex)")
                
                // Keep showing the previous next card
                currentIndex = nextCardIndex
                print("Keeping previous next card at index: \(currentIndex)")
            }
        }
        
        // Force view update by creating a new array and updating the view key
        DispatchQueue.main.async {
            print("Updating view state - Current index: \(currentIndex), Words count: \(words.count)")
            let newWords = Array(words)
            words = newWords
            viewKey = UUID()
            print("View state updated - New index: \(currentIndex), New words count: \(newWords.count)")
        }
        
        print("Remaining words in deck: \(words.count)")
    }
}