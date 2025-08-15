//
//  WorkoutSessionView.swift
//  lyft-up
//
//  Created by Colin Chu on 8/1/25.
//

import SwiftUI

struct WorkoutSessionView: View {
    let routine: Routine
    @StateObject private var sessionStorage = WorkoutSessionStorage.shared
    @StateObject private var statsStorage = WorkoutStatsStorage.shared
    @StateObject private var firebaseService = FirebaseService.shared
    @Environment(\.dismiss) private var dismiss
    
    @State private var currentSession: WorkoutSession
    @State private var showingEndWorkout = false
    @State private var showingSummary = false
    @State private var exerciseSessions: [String: [WorkoutSet]] = [:]
    @State private var deletedExercises: Set<String> = []
    @State private var addedExercises: [RoutineExercise] = []
    @State private var showingAddExercise = false
    @State private var completedSession: WorkoutSession?
    
    init(routine: Routine) {
        self.routine = routine
        self._currentSession = State(initialValue: WorkoutSession(routineName: routine.name))
    }
    
    var body: some View {
        NavigationView {
            workoutContent
        }
        .onAppear {
            initializeSession()
        }
    }
    
    private var workoutContent: some View {
        VStack(spacing: 0) {
            workoutHeader
            exercisesList
            Spacer()
            endWorkoutButton
        }
        .navigationTitle("Workout Session")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: { showingAddExercise = true }) {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                }
            }
            
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("End") {
                    showingEndWorkout = true
                }
            }
        }
        .alert("End Workout", isPresented: $showingEndWorkout) {
            Button("Cancel", role: .cancel) { }
            Button("End Workout", role: .destructive) {
                endWorkout()
            }
        } message: {
            Text("Are you sure you want to end this workout session?")
        }
        .fullScreenCover(isPresented: $showingSummary) {
            summaryView
        }
        .sheet(isPresented: $showingAddExercise) {
            AddExerciseToWorkoutView { exercise in
                addedExercises.append(exercise)
                showingAddExercise = false
            }
        }
    }
    
    private var summaryView: some View {
        Group {
            if let session = completedSession {
                WorkoutSummaryView(session: session) {
                    dismiss()
                }
            }
        }
    }
    
    private var workoutHeader: some View {
        VStack(spacing: 8) {
            Text(routine.name)
                .font(.title2)
                .fontWeight(.bold)
            
            Text("\(activeExerciseCount) exercises")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Text("Started at \(currentSession.startTime, style: .time)")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemGray6))
    }
    
    private var activeExerciseCount: Int {
        let routineExercises = routine.exercises.filter { !deletedExercises.contains($0.name) }.count
        return routineExercises + addedExercises.count
    }
    
    private var exercisesList: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                // Routine exercises
                ForEach(routine.exercises.indices, id: \.self) { index in
                    let exercise = routine.exercises[index]
                    if !deletedExercises.contains(exercise.name) {
                        exerciseCard(for: index)
                    }
                }
                
                // Added exercises
                ForEach(addedExercises.indices, id: \.self) { index in
                    addedExerciseCard(for: index)
                }
            }
            .padding()
        }
    }
    
    private func exerciseCard(for index: Int) -> some View {
        WorkoutExerciseCard(
            exercise: routine.exercises[index],
            sessionStorage: sessionStorage,
            onSetsChanged: { sets in
                exerciseSessions[routine.exercises[index].name] = sets
            },
            onDelete: {
                deletedExercises.insert(routine.exercises[index].name)
                // Remove from exercise sessions if it exists
                exerciseSessions.removeValue(forKey: routine.exercises[index].name)
            }
        )
    }
    
    private func addedExerciseCard(for index: Int) -> some View {
        WorkoutExerciseCard(
            exercise: addedExercises[index],
            sessionStorage: sessionStorage,
            onSetsChanged: { sets in
                exerciseSessions[addedExercises[index].name] = sets
            },
            onDelete: {
                // Remove from added exercises and exercise sessions
                let exerciseName = addedExercises[index].name
                addedExercises.remove(at: index)
                exerciseSessions.removeValue(forKey: exerciseName)
            }
        )
    }
    
    private var endWorkoutButton: some View {
        Button(action: { showingEndWorkout = true }) {
            HStack {
                Image(systemName: "stop.circle.fill")
                Text("End Workout")
            }
            .font(.headline)
            .fontWeight(.semibold)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(Color.red)
            .cornerRadius(12)
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 20)
    }
    
    private func initializeSession() {
        // Create session exercises from routine
        var session = WorkoutSession(routineName: routine.name)
        session.exercises = routine.exercises.map { routineExercise in
            WorkoutSessionExercise(exerciseName: routineExercise.name, numberOfSets: routineExercise.defaultSets)
        }
        currentSession = session
    }
    
    private func endWorkout() {
        var session = currentSession
        session.endTime = Date()
        session.isCompleted = true
        
        print("Exercise sessions data: \(exerciseSessions)")
        
        // Convert exercise sessions to WorkoutSessionExercise format
        session.exercises = exerciseSessions.map { exerciseName, sets in
            print("Processing exercise: \(exerciseName) with \(sets.count) sets")
            sets.forEach { set in
                print("  Set \(set.setNumber): \(set.weight) lbs x \(set.reps) reps")
            }
            
            // Create a new exercise with the actual sets data
            var sessionExercise = WorkoutSessionExercise(exerciseName: exerciseName, numberOfSets: 0)
            sessionExercise.sets = sets
            return sessionExercise
        }
        
        print("Deleted exercises: \(deletedExercises)")
        print("Final session exercises: \(session.exercises.count)")
        
        // Save the session
        sessionStorage.saveSession(session)
        
        // Calculate total weight lifted for this session
        let sessionTotalWeight = session.exercises.reduce(0.0) { total, exercise in
            total + exercise.sets.reduce(0.0) { setTotal, set in
                setTotal + (set.weight * Double(set.reps))
            }
        }
        
        // Increment total workouts counter and add weight lifted
        statsStorage.incrementTotalWorkouts()
        statsStorage.addWeightLifted(sessionTotalWeight)
        
        // Store completed session and show summary
        completedSession = session
        showingSummary = true
    }
    

}

struct WorkoutExerciseCard: View {
    let exercise: RoutineExercise
    let sessionStorage: WorkoutSessionStorage
    let onSetsChanged: ([WorkoutSet]) -> Void
    let onDelete: () -> Void
    @State private var sets: [WorkoutSet] = []
    @State private var showingAddSet = false
    @State private var showingDeleteAlert = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            exerciseHeader
            setsList
            addSetButton
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
        .onAppear {
            initializeSets()
        }
        .alert("Remove Exercise", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Remove", role: .destructive) {
                onDelete()
            }
        } message: {
            Text("Remove '\(exercise.name)' from this workout? This won't affect your routine.")
        }
    }
    
    private var exerciseHeader: some View {
        HStack {
            Text(exercise.name)
                .font(.title3)
                .fontWeight(.semibold)
            
            Spacer()
            
            lastWorkoutReference
            
            Button(action: { showingDeleteAlert = true }) {
                Image(systemName: "minus.circle.fill")
                    .foregroundColor(.red)
                    .font(.title3)
            }
        }
    }
    
    private var lastWorkoutReference: some View {
        Group {
            if let lastData = sessionStorage.getLastWorkoutData(for: exercise.name) {
                VStack(alignment: .trailing, spacing: 2) {
                    Text("Last: \(Int(lastData.weight)) lbs")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(lastData.reps) reps")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
    
    private var setsList: some View {
        VStack(spacing: 12) {
            ForEach(sets.indices, id: \.self) { setIndex in
                WorkoutSetRow(
                    set: $sets[setIndex],
                    setNumber: setIndex + 1,
                    lastWeight: sessionStorage.getLastWorkoutData(for: exercise.name)?.weight ?? 0,
                    lastReps: sessionStorage.getLastWorkoutData(for: exercise.name)?.reps ?? 0,
                    isLastSet: setIndex == sets.count - 1,
                    onComplete: {
                        if setIndex == sets.count - 1 {
                            addNewSet()
                        }
                        onSetsChanged(sets)
                    },
                    onDelete: {
                        if sets.count > 1 {
                            sets.remove(at: setIndex)
                            onSetsChanged(sets)
                        }
                    },
                    onDataChanged: {
                        onSetsChanged(sets)
                    }
                )
            }
        }
    }
    
    private var addSetButton: some View {
        Button(action: addNewSet) {
            HStack {
                Image(systemName: "plus.circle.fill")
                Text("Add Set")
            }
            .font(.subheadline)
            .foregroundColor(.blue)
        }
        .padding(.top, 8)
    }
    
    private func initializeSets() {
        // Initialize with default number of sets from routine
        sets = (1...exercise.defaultSets).map { setNumber in
            WorkoutSet(setNumber: setNumber)
        }
    }
    
    private func addNewSet() {
        let newSet = WorkoutSet(setNumber: sets.count + 1)
        sets.append(newSet)
        onSetsChanged(sets)
    }
}

struct WorkoutSetRow: View {
    @Binding var set: WorkoutSet
    let setNumber: Int
    let lastWeight: Double
    let lastReps: Int
    let isLastSet: Bool
    let onComplete: () -> Void
    let onDelete: () -> Void
    let onDataChanged: () -> Void
    
    @State private var weightText: String = ""
    @State private var repsText: String = ""
    @FocusState private var isWeightFocused: Bool
    @FocusState private var isRepsFocused: Bool
    
    var body: some View {
        mainContent
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background(backgroundColor)
            .cornerRadius(8)
            .onAppear {
                initializeTextFields()
            }
    }
    
    private var mainContent: some View {
        HStack(spacing: 12) {
            setNumberSection
            weightInputSection
            repsInputSection
            Spacer()
            completionButton
        }
    }
    
    private var backgroundColor: Color {
        return set.isCompleted ? Color.green.opacity(0.1) : Color.clear
    }
    
    private var setNumberSection: some View {
        HStack(spacing: 8) {
            Text("Set \(setNumber)")
                .font(.subheadline)
                .fontWeight(.medium)
                .frame(width: 50, alignment: .leading)
            
            if !set.isCompleted {
                Button(action: onDelete) {
                    Image(systemName: "minus.circle.fill")
                        .foregroundColor(.red)
                        .font(.caption)
                }
            }
        }
    }
    
    private var weightInputSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Weight (lbs)")
                .font(.caption)
                .foregroundColor(.secondary)
            
            weightTextField
        }
        .frame(width: 90)
    }
    
    private var weightTextField: some View {
        TextField("0", text: $weightText)
            .textFieldStyle(RoundedBorderTextFieldStyle())
            .keyboardType(.decimalPad)
            .frame(width: 90)
            .focused($isWeightFocused)
            .onChange(of: weightText) { newValue in
                updateWeight(newValue)
            }
            .onSubmit {
                isWeightFocused = false
                isRepsFocused = true
            }
            .overlay(weightPlaceholder)
    }
    
    private var weightPlaceholder: some View {
        Group {
            if weightText.isEmpty && lastWeight > 0 {
                Text("\(Int(lastWeight))")
                    .foregroundColor(.secondary.opacity(0.6))
                    .padding(.leading, 8)
                    .allowsHitTesting(false)
            }
        }
    }
    
    private var repsInputSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Reps")
                .font(.caption)
                .foregroundColor(.secondary)
            
            repsTextField
        }
        .frame(width: 90)
    }
    
    private var repsTextField: some View {
        TextField("0", text: $repsText)
            .textFieldStyle(RoundedBorderTextFieldStyle())
            .keyboardType(.numberPad)
            .frame(width: 90)
            .focused($isRepsFocused)
            .onChange(of: repsText) { newValue in
                updateReps(newValue)
            }
            .onSubmit {
                isRepsFocused = false
                completeSet()
            }
            .overlay(repsPlaceholder)
    }
    
    private var repsPlaceholder: some View {
        Group {
            if repsText.isEmpty && lastReps > 0 {
                Text("\(lastReps)")
                    .foregroundColor(.secondary.opacity(0.6))
                    .padding(.leading, 8)
                    .allowsHitTesting(false)
            }
        }
    }
    
    private var completionButton: some View {
        Button(action: completeSet) {
            Image(systemName: set.isCompleted ? "checkmark.circle.fill" : "circle")
                .foregroundColor(set.isCompleted ? .green : .gray)
                .font(.title3)
        }
    }
    
    private func initializeTextFields() {
        weightText = set.weight > 0 ? String(Int(set.weight)) : ""
        repsText = set.reps > 0 ? String(set.reps) : ""
    }
    
    private func updateWeight(_ newValue: String) {
        if newValue.isEmpty {
            set.weight = 0.0
        } else if let weight = Double(newValue) {
            set.weight = weight
        }
        onDataChanged()
    }
    
    private func updateReps(_ newValue: String) {
        if let reps = Int(newValue) {
            set.reps = reps
        }
        onDataChanged()
    }
    
    private func completeSet() {
        // Only complete if we have valid data
        if set.weight > 0 && set.reps > 0 {
            set.isCompleted = true
            onComplete()
            
            // Auto-focus next set if this is the last set
            if isLastSet {
                // Small delay to allow UI to update
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    isWeightFocused = true
                }
            }
        }
    }
}

#Preview {
    let sampleRoutine = Routine(name: "Sample Routine")
    WorkoutSessionView(routine: sampleRoutine)
}
