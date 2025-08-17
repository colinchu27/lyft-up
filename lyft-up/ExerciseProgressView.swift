//
//  ExerciseProgressView.swift
//  lyft-up
//
//  Created by Colin Chu on 8/1/25.
//

import SwiftUI

struct ExerciseProgressView: View {
    @StateObject private var analyticsService = ProgressAnalyticsService.shared
    @State private var selectedExercise: String = ""
    @State private var selectedTimeRange: TimeRange = .month
    
    var body: some View {
        NavigationView {
            VStack {
                if analyticsService.exerciseProgress.isEmpty {
                    emptyStateView
                } else {
                    exerciseProgressContent
                }
            }
            .navigationTitle("Exercise Progress")
            .navigationBarTitleDisplayMode(.large)
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "dumbbell.fill")
                .font(.system(size: 60))
                .foregroundColor(.gray.opacity(0.5))
            
            Text("No Exercise Data")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Complete some workouts to see your exercise progress")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground))
    }
    
    private var exerciseProgressContent: some View {
        ZStack {
            ScrollView {
                VStack(spacing: 24) {
                    // All Exercises List
                    allExercisesList
                }
                .padding()
            }
            
            // Selected Exercise Details Overlay
            if !selectedExercise.isEmpty {
                selectedExerciseOverlay
            }
        }
    }
    
    private var exerciseSelector: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Select Exercise")
                .font(.headline)
                .fontWeight(.semibold)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(Array(analyticsService.exerciseProgress.keys.sorted()), id: \.self) { exerciseName in
                        ExerciseSelectorButton(
                            exerciseName: exerciseName,
                            isSelected: selectedExercise == exerciseName,
                            onTap: {
                                selectedExercise = exerciseName
                            }
                        )
                    }
                }
                .padding(.horizontal)
            }
        }
    }
    
    private var selectedExerciseOverlay: some View {
        ZStack {
            // Semi-transparent background
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture {
                    selectedExercise = ""
                }
            
            // Exercise details card
            VStack(spacing: 0) {
                // Header with close button
                HStack {
                    Text(selectedExercise)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.lyftText)
                    
                    Spacer()
                    
                    Button(action: {
                        selectedExercise = ""
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundColor(.gray)
                    }
                }
                .padding()
                .background(Color.white)
                
                // Content
                ScrollView {
                    VStack(spacing: 20) {
                        // Personal Records
                        personalRecordsSection
                        
                        // Progress Chart
                        progressChartSection
                        
                        // Recent Sessions
                        recentSessionsSection
                    }
                    .padding()
                }
                .background(Color.white)
            }
            .background(Color.white)
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.2), radius: 20, x: 0, y: 10)
            .padding(.horizontal, 20)
            .padding(.vertical, 40)
        }
        .transition(.opacity.combined(with: .scale))
        .animation(.easeInOut(duration: 0.3), value: selectedExercise)
    }
    
    private var selectedExerciseDetails: some View {
        VStack(spacing: 20) {
            // Personal Records
            personalRecordsSection
            
            // Progress Chart
            progressChartSection
            
            // Recent Sessions
            recentSessionsSection
        }
    }
    
    private var personalRecordsSection: some View {
        VStack(spacing: 16) {
            Text("Personal Records")
                .font(.title2)
                .fontWeight(.bold)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            if let pr = analyticsService.getPersonalRecord(for: selectedExercise) {
                HStack(spacing: 20) {
                    // Max Weight PR
                    VStack(spacing: 8) {
                        Text("\(Int(pr.weight))")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(.lyftRed)
                        
                        Text("lbs")
                            .font(.subheadline)
                            .foregroundColor(.lyftTextSecondary)
                        
                        Text("Max Weight")
                            .font(.caption)
                            .foregroundColor(.lyftTextSecondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.white)
                    .cornerRadius(12)
                    .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
                    
                    // Max Reps PR
                    VStack(spacing: 8) {
                        Text("\(pr.reps)")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(.blue)
                        
                        Text("reps")
                            .font(.subheadline)
                            .foregroundColor(.lyftTextSecondary)
                        
                        Text("Max Reps")
                            .font(.caption)
                            .foregroundColor(.lyftTextSecondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.white)
                    .cornerRadius(12)
                    .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
                }
                
                Text("Achieved on \(formatDate(pr.date))")
                    .font(.caption)
                    .foregroundColor(.lyftTextSecondary)
            } else {
                Text("No personal records yet")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .padding()
            }
        }
    }
    
    private var progressChartSection: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Progress Over Time")
                    .font(.title2)
                    .fontWeight(.bold)
                Spacer()
                
                Picker("Time Range", selection: $selectedTimeRange) {
                    ForEach(TimeRange.allCases, id: \.self) { range in
                        Text(range.rawValue).tag(range)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .frame(width: 150)
            }
            
            let progressData = analyticsService.getExerciseProgress(for: selectedExercise, timeRange: selectedTimeRange)
            
            if progressData.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .font(.system(size: 40))
                        .foregroundColor(.gray.opacity(0.5))
                    
                    Text("No data for selected time range")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                .frame(height: 150)
                .frame(maxWidth: .infinity)
                .background(Color.white)
                .cornerRadius(12)
                .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
            } else {
                ExerciseProgressChart(data: progressData)
                    .frame(height: 200)
                    .padding()
                    .background(Color.white)
                    .cornerRadius(12)
                    .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
            }
        }
    }
    
    private var recentSessionsSection: some View {
        VStack(spacing: 16) {
            Text("Recent Sessions")
                .font(.title2)
                .fontWeight(.bold)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            let recentProgress = analyticsService.exerciseProgress[selectedExercise] ?? []
            let sortedProgress = recentProgress.sorted { $0.date > $1.date }
            
            ForEach(Array(sortedProgress.prefix(5)), id: \.id) { progress in
                ExerciseSessionRow(progress: progress)
            }
        }
    }
    
    private var allExercisesList: some View {
        VStack(spacing: 16) {
            Text("All Exercises")
                .font(.title2)
                .fontWeight(.bold)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            ForEach(Array(analyticsService.exerciseProgress.keys.sorted()), id: \.self) { exerciseName in
                ExerciseSummaryRow(
                    exerciseName: exerciseName,
                    progress: analyticsService.exerciseProgress[exerciseName] ?? [],
                    isSelected: selectedExercise == exerciseName,
                    onTap: {
                        selectedExercise = exerciseName
                    }
                )
            }
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}

struct ExerciseSelectorButton: View {
    let exerciseName: String
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            Text(exerciseName)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(isSelected ? .white : .lyftText)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? Color.lyftRed : Color.white)
                .cornerRadius(20)
                .shadow(color: .black.opacity(0.05), radius: 3, x: 0, y: 1)
        }
    }
}

struct ExerciseProgressChart: View {
    let data: [ExerciseProgress]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Max Weight Progress")
                .font(.headline)
                .fontWeight(.semibold)
            
            // Simple line chart
            HStack(alignment: .bottom, spacing: 8) {
                ForEach(data) { progress in
                    VStack {
                        Rectangle()
                            .fill(Color.lyftRed)
                            .frame(height: max(20, CGFloat(progress.maxWeight / maxWeight) * 150))
                            .cornerRadius(4)
                        
                        Text(formatDate(progress.date))
                            .font(.caption2)
                            .foregroundColor(.gray)
                    }
                }
            }
        }
    }
    
    private var maxWeight: Double {
        data.map { $0.maxWeight }.max() ?? 1
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM dd"
        return formatter.string(from: date)
    }
}

struct ExerciseSessionRow: View {
    let progress: ExerciseProgress
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(formatDate(progress.date))
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text("\(progress.sets) sets")
                    .font(.caption)
                    .foregroundColor(.lyftTextSecondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text("\(Int(progress.maxWeight)) lbs")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.lyftRed)
                
                Text("\(progress.maxReps) reps")
                    .font(.caption)
                    .foregroundColor(.lyftTextSecondary)
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}

struct ExerciseSummaryRow: View {
    let exerciseName: String
    let progress: [ExerciseProgress]
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(exerciseName)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(isSelected ? .lyftRed : .lyftText)
                    
                    if let maxWeight = progress.map({ $0.maxWeight }).max() {
                        Text("Max: \(Int(maxWeight)) lbs")
                            .font(.subheadline)
                            .foregroundColor(.lyftTextSecondary)
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("\(progress.count)")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.lyftRed)
                    
                    Text("sessions")
                        .font(.caption)
                        .foregroundColor(.lyftTextSecondary)
                }
            }
            .padding()
            .background(isSelected ? Color.lyftRed.opacity(0.1) : Color.white)
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.lyftRed : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    ExerciseProgressView()
}
