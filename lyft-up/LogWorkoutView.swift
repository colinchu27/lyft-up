//
//  LogWorkoutView.swift
//  lyft-up
//
//  Created by Colin Chu on 8/1/25.
//

import SwiftUI

struct LogWorkoutView: View {
    @State private var exercises: [Exercise] = []
    @State private var newExerciseName: String = ""
    @EnvironmentObject var workoutStorage: WorkoutStorage
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Add Exercise Section
                VStack(spacing: 16) {
                    HStack {
                        TextField("Exercise name", text: $newExerciseName)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .font(.system(size: 16, weight: .medium))
                        
                        Button(action: addExercise) {
                            Image(systemName: "plus.circle.fill")
                                .font(.title2)
                                .foregroundColor(.blue)
                        }
                        .disabled(newExerciseName.isEmpty)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                }
                
                // Exercises List
                if exercises.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "dumbbell")
                            .font(.system(size: 50))
                            .foregroundColor(.gray.opacity(0.5))
                        Text("No exercises added yet")
                            .font(.title3)
                            .foregroundColor(.secondary)
                        Text("Add your first exercise to start tracking")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(exercises.indices, id: \.self) { index in
                                ExerciseCard(exercise: $exercises[index])
                                    .onTapGesture {
                                        // Optional: Add edit functionality
                                    }
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
                    }
                }
                
                Spacer()
                
                // Save Button
                VStack {
                    Button(action: saveWorkout) {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.title3)
                            Text("Save Workout")
                                .font(.headline)
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            exercises.isEmpty ? 
                            LinearGradient(gradient: Gradient(colors: [Color.gray.opacity(0.3), Color.gray.opacity(0.3)]), startPoint: .leading, endPoint: .trailing) : 
                            LinearGradient(gradient: Gradient(colors: [.blue, .blue.opacity(0.8)]), startPoint: .leading, endPoint: .trailing)
                        )
                        .cornerRadius(12)
                    }
                    .disabled(exercises.isEmpty)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
                }
            }
            .navigationTitle("Log Workout")
        }
    }
    
    private func addExercise() {
        if !newExerciseName.isEmpty {
            exercises.append(Exercise(name: newExerciseName))
            newExerciseName = ""
        }
    }
    
    private func deleteExercise(offsets: IndexSet) {
        exercises.remove(atOffsets: offsets)
    }
    
    private func saveWorkout() {
        // Save each exercise as a separate workout
        for exercise in exercises {
            let workout = Workout(
                exerciseName: exercise.name,
                sets: exercise.sets,
                reps: exercise.reps,
                weight: exercise.weight,
                date: Date()
            )
            workoutStorage.saveWorkout(workout)
        }
        
        // Clear the exercises list after saving
        exercises.removeAll()
        
        // Show success feedback (you can add a toast or alert here)
        print("Saved \(exercises.count) workouts successfully!")
    }
}

struct ExerciseCard: View {
    @Binding var exercise: Exercise
    @EnvironmentObject var workoutStorage: WorkoutStorage
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Exercise Name Header
            HStack {
                Text(exercise.name)
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Button(action: {
                    // TODO: Add delete functionality
                }) {
                    Image(systemName: "trash")
                        .foregroundColor(.red)
                        .font(.caption)
                }
            }
            
            // Input Fields
            HStack(spacing: 12) {
                // Sets
                VStack(alignment: .leading, spacing: 8) {
                    Text("Sets")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                    
                    TextField("0", value: $exercise.sets, format: .number)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .frame(width: 80)
                }
                
                // Reps
                VStack(alignment: .leading, spacing: 8) {
                    Text("Reps")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                    
                    TextField("0", value: $exercise.reps, format: .number)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .frame(width: 80)
                }
                
                // Weight
                VStack(alignment: .leading, spacing: 8) {
                    Text("Weight (lbs)")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                    
                    TextField("0", value: $exercise.weight, format: .number)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .frame(width: 100)
                }
                
                Spacer()
            }
            
            // Last Workout Info
            if let lastWorkout = workoutStorage.getLastWorkout(for: exercise.name) {
                HStack {
                    Image(systemName: "clock.arrow.circlepath")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("Last time: \(lastWorkout.sets) sets × \(lastWorkout.reps) reps @ \(Int(lastWorkout.weight)) lbs")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .italic()
                    
                    Spacer()
                }
                .padding(.top, 4)
            }
        }
        .padding(16)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
}

#Preview {
    LogWorkoutView()
        .environmentObject(WorkoutStorage())
}
