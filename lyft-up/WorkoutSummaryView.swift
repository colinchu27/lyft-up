//
//  WorkoutSummaryView.swift
//  lyft-up
//
//  Created by Colin Chu on 8/1/25.
//

import SwiftUI

struct WorkoutSummaryView: View {
    let session: WorkoutSession
    let onSave: () -> Void
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    workoutHeader
                    
                    // Volume Summary
                    volumeSummaryCard
                    
                    // Exercise Details
                    exerciseDetailsList
                    
                    Spacer(minLength: 20)
                }
                .padding()
            }
            .navigationTitle("Workout Summary")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        onSave()
                        dismiss()
                    }
                }
            }
        }
    }
    
    private var workoutHeader: some View {
        VStack(spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 60))
                .foregroundColor(.green)
            
            Text("Workout Complete!")
                .font(.title2)
                .fontWeight(.bold)
            
            Text(session.routineName)
                .font(.headline)
                .foregroundColor(.secondary)
            
            HStack(spacing: 20) {
                VStack {
                    Text("\(session.exercises.count)")
                        .font(.title3)
                        .fontWeight(.semibold)
                    Text("Exercises")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                VStack {
                    Text("\(totalSets)")
                        .font(.title3)
                        .fontWeight(.semibold)
                    Text("Sets")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                VStack {
                    Text(formatDuration())
                        .font(.title3)
                        .fontWeight(.semibold)
                    Text("Duration")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.top, 8)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(16)
    }
    
    private var volumeSummaryCard: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "dumbbell.fill")
                    .foregroundColor(.blue)
                Text("Total Volume")
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
            }
            
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(totalVolume, specifier: "%.0f")")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.blue)
                    Text("lbs lifted")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("\(totalReps)")
                        .font(.title2)
                        .fontWeight(.semibold)
                    Text("total reps")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
    
    private var exerciseDetailsList: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Exercise Details")
                .font(.headline)
                .fontWeight(.semibold)
            
            ForEach(session.exercises) { exercise in
                ExerciseSummaryCard(exercise: exercise)
            }
        }
    }
    
    // MARK: - Computed Properties
    
    private var totalVolume: Double {
        session.exercises.flatMap { exercise in
            exercise.sets.map { set in
                set.weight * Double(set.reps)
            }
        }.reduce(0, +)
    }
    
    private var totalReps: Int {
        session.exercises.flatMap { exercise in
            exercise.sets.map { $0.reps }
        }.reduce(0, +)
    }
    
    private var totalSets: Int {
        session.exercises.flatMap { $0.sets }.count
    }
    
    private func formatDuration() -> String {
        guard let endTime = session.endTime else { return "N/A" }
        let duration = endTime.timeIntervalSince(session.startTime)
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

struct ExerciseSummaryCard: View {
    let exercise: WorkoutSessionExercise
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Exercise Header
            HStack {
                Text(exercise.exerciseName)
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(exercise.sets.count) sets")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Text("\(exerciseVolume, specifier: "%.0f") lbs")
                        .font(.caption)
                        .foregroundColor(.blue)
                }
            }
            
            // Sets List
            VStack(spacing: 8) {
                ForEach(exercise.sets) { set in
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("Set \(set.setNumber)")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .frame(width: 60, alignment: .leading)
                            
                            Text("\(Int(set.weight)) lbs")
                                .font(.subheadline)
                                .frame(width: 70, alignment: .leading)
                            
                            Text("× \(set.reps) reps")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            Spacer()
                            
                            Text("\(Int(set.weight * Double(set.reps))) lbs")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.blue)
                        }
                        
                        if !set.notes.isEmpty {
                            Text(set.notes)
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .padding(.leading, 60)
                        }
                    }
                    .padding(.vertical, 4)
                    .padding(.horizontal, 8)
                    .background(set.isCompleted ? Color.green.opacity(0.1) : Color.clear)
                    .cornerRadius(6)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
    
    private var exerciseVolume: Double {
        exercise.sets.map { set in
            set.weight * Double(set.reps)
        }.reduce(0, +)
    }
}

#Preview {
    let sampleSession = WorkoutSession(routineName: "Sample Workout")
    WorkoutSummaryView(session: sampleSession, onSave: {
        print("Workout saved!")
    })
}
