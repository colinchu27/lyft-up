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
                ExerciseProgressChart(data: progressData, timeRange: selectedTimeRange)
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
    let timeRange: TimeRange
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Max Weight Progress")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Text("\(Int(maxWeight)) lbs max")
                    .font(.caption)
                    .foregroundColor(.lyftTextSecondary)
            }
            
            if aggregatedData.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .font(.system(size: 30))
                        .foregroundColor(.gray.opacity(0.5))
                    
                    Text("No data for this time range")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                .frame(height: 120)
                .frame(maxWidth: .infinity)
            } else {
                // Chart area
                VStack(spacing: 8) {
                    // Y-axis labels
                    HStack {
                        VStack(alignment: .leading, spacing: 0) {
                            ForEach(yAxisLabels, id: \.self) { label in
                                Text(label)
                                    .font(.caption2)
                                    .foregroundColor(.gray)
                                    .frame(height: 20)
                            }
                        }
                        .frame(width: 40)
                        
                        // Chart bars
                        HStack(alignment: .bottom, spacing: chartSpacing) {
                            ForEach(Array(aggregatedData.enumerated()), id: \.offset) { index, item in
                                VStack(spacing: 4) {
                                    // Bar
                                    Rectangle()
                                        .fill(Color.lyftRed.opacity(0.8))
                                        .frame(height: max(4, CGFloat(item.value / maxWeight) * 100))
                                        .cornerRadius(2)
                                        .overlay(
                                            // Value label on hover
                                            Text("\(Int(item.value))")
                                                .font(.caption2)
                                                .foregroundColor(.white)
                                                .fontWeight(.medium)
                                                .opacity(item.value > 0 ? 1 : 0)
                                        )
                                    
                                    // X-axis label
                                    Text(item.label)
                                        .font(.caption2)
                                        .foregroundColor(.gray)
                                        .rotationEffect(.degrees(-45))
                                        .offset(y: 8)
                                }
                            }
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
                .frame(height: 140)
            }
        }
    }
    
    private var aggregatedData: [ChartDataPoint] {
        switch timeRange {
        case .week:
            return aggregateByDay(data)
        case .month:
            return aggregateByWeek(data)
        case .threeMonths:
            return aggregateByWeek(data)
        }
    }
    
    private var maxWeight: Double {
        aggregatedData.map { $0.value }.max() ?? 1
    }
    
    private var yAxisLabels: [String] {
        let max = maxWeight
        let step = max / 4
        return (0...4).map { i in
            "\(Int(max - (step * Double(i))))"
        }
    }
    
    private var chartSpacing: CGFloat {
        switch timeRange {
        case .week:
            return 4
        case .month:
            return 2
        case .threeMonths:
            return 1
        }
    }
    
    private func aggregateByDay(_ data: [ExerciseProgress]) -> [ChartDataPoint] {
        let calendar = Calendar.current
        let today = Date()
        var dailyData: [Date: Double] = [:]
        
        // Initialize last 7 days
        for i in 0..<7 {
            if let date = calendar.date(byAdding: .day, value: -i, to: today) {
                let startOfDay = calendar.startOfDay(for: date)
                dailyData[startOfDay] = 0
            }
        }
        
        // Fill in actual data
        for progress in data {
            let startOfDay = calendar.startOfDay(for: progress.date)
            if dailyData[startOfDay] != nil {
                dailyData[startOfDay] = max(dailyData[startOfDay] ?? 0, progress.maxWeight)
            }
        }
        
        return dailyData.sorted { $0.key < $1.key }.map { date, weight in
            ChartDataPoint(
                date: date,
                value: weight,
                label: formatDayLabel(date)
            )
        }
    }
    
    private func aggregateByWeek(_ data: [ExerciseProgress]) -> [ChartDataPoint] {
        let calendar = Calendar.current
        let cutoffDate = calendar.date(byAdding: .day, value: -30, to: Date()) ?? Date()
        
        // Group workouts by the actual workout date (not week boundaries)
        var workoutDates: [Date: Double] = [:]
        
        for progress in data {
            if progress.date >= cutoffDate {
                let workoutDate = calendar.startOfDay(for: progress.date)
                workoutDates[workoutDate] = max(workoutDates[workoutDate] ?? 0, progress.maxWeight)
            }
        }
        
        // Sort by date and take the most recent workouts
        let sortedWorkouts = workoutDates.sorted { $0.key < $1.key }
        let recentWorkouts = Array(sortedWorkouts.suffix(4)) // Show last 4 workout dates
        
        return recentWorkouts.map { date, weight in
            ChartDataPoint(
                date: date,
                value: weight,
                label: formatWeekLabel(date)
            )
        }
    }
    

    
    private func formatDayLabel(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "E"
        return formatter.string(from: date)
    }
    
    private func formatWeekLabel(_ date: Date) -> String {
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
