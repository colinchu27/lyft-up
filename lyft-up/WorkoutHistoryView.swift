//
//  WorkoutHistoryView.swift
//  lyft-up
//
//  Created by Colin Chu on 8/1/25.
//

import SwiftUI

struct WorkoutHistoryView: View {
    @StateObject private var sessionStorage = WorkoutSessionStorage()
    @State private var selectedSession: WorkoutSession?
    @State private var showingSessionDetail = false
    
    var body: some View {
        NavigationView {
            VStack {
                if sessionStorage.sessions.isEmpty {
                    emptyStateView
                } else {
                    sessionsList
                }
            }
            .navigationTitle("Workout History")
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showingSessionDetail) {
                if let session = selectedSession {
                    WorkoutSessionDetailView(session: session)
                }
            }
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "clock.arrow.circlepath")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            Text("No Workout History")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Complete your first workout to see it here")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground))
    }
    
    private var sessionsList: some View {
        List {
            ForEach(groupedSessions.keys.sorted(by: >), id: \.self) { date in
                Section(header: Text(formatDate(date))) {
                    ForEach(groupedSessions[date] ?? [], id: \.id) { session in
                        WorkoutHistoryRow(session: session) {
                            selectedSession = session
                            showingSessionDetail = true
                        }
                    }
                }
            }
        }
        .listStyle(InsetGroupedListStyle())
    }
    
    private var groupedSessions: [Date: [WorkoutSession]] {
        let sessions = sessionStorage.sessions
        return Dictionary(grouping: sessions) { session in
            Calendar.current.startOfDay(for: session.startTime)
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}

struct WorkoutHistoryRow: View {
    let session: WorkoutSession
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(session.routineName)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    Text("\(session.exercises.count) exercises • \(totalSets) sets")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Text(formatDuration())
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text(formatTime(session.startTime))
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    if session.isCompleted {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                            .font(.caption)
                    }
                }
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var totalSets: Int {
        session.exercises.reduce(0) { total, exercise in
            total + exercise.sets.count
        }
    }
    
    private func formatDuration() -> String {
        guard let endTime = session.endTime else { return "In progress" }
        let duration = endTime.timeIntervalSince(session.startTime)
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return "\(minutes)m \(seconds)s"
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

struct WorkoutSessionDetailView: View {
    let session: WorkoutSession
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    sessionHeader
                    volumeSummary
                    exercisesList
                }
                .padding()
            }
            .navigationTitle("Session Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private var sessionHeader: some View {
        VStack(spacing: 12) {
            Text(session.routineName)
                .font(.title2)
                .fontWeight(.bold)
            
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
            
            Text("Completed on \(formatDate(session.startTime))")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private var volumeSummary: some View {
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
    
    private var exercisesList: some View {
        VStack(spacing: 16) {
            ForEach(session.exercises, id: \.exerciseName) { exercise in
                ExerciseDetailCard(exercise: exercise)
            }
        }
    }
    
    private var totalSets: Int {
        session.exercises.reduce(0) { total, exercise in
            total + exercise.sets.count
        }
    }
    
    private var totalVolume: Double {
        session.exercises.reduce(0.0) { total, exercise in
            total + exercise.sets.reduce(0.0) { setTotal, set in
                setTotal + (set.weight * Double(set.reps))
            }
        }
    }
    
    private var totalReps: Int {
        session.exercises.reduce(0) { total, exercise in
            total + exercise.sets.reduce(0) { setTotal, set in
                setTotal + set.reps
            }
        }
    }
    
    private func formatDuration() -> String {
        guard let endTime = session.endTime else { return "In progress" }
        let duration = endTime.timeIntervalSince(session.startTime)
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return "\(minutes)m \(seconds)s"
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

struct ExerciseDetailCard: View {
    let exercise: WorkoutSessionExercise
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(exercise.exerciseName)
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 8) {
                ForEach(exercise.sets.indices, id: \.self) { index in
                    let set = exercise.sets[index]
                    HStack {
                        Text("Set \(index + 1)")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .frame(width: 60, alignment: .leading)
                        
                        Text("\(Int(set.weight)) lbs")
                            .font(.subheadline)
                            .frame(width: 80, alignment: .leading)
                        
                        Text("\(set.reps) reps")
                            .font(.subheadline)
                        
                        Spacer()
                        
                        if set.isCompleted {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                                .font(.caption)
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
}

#Preview {
    WorkoutHistoryView()
}
