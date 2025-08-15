//
//  ProgressAnalyticsService.swift
//  lyft-up
//
//  Created by Colin Chu on 8/1/25.
//

import Foundation
import SwiftUI
import Combine

class ProgressAnalyticsService: ObservableObject {
    static let shared = ProgressAnalyticsService()
    
    @Published var progressMetrics: ProgressMetrics = ProgressMetrics()
    @Published var weeklyProgress: [WeeklyProgress] = []
    @Published var exerciseProgress: [String: [ExerciseProgress]] = [:]
    
    var sessionStorage: WorkoutSessionStorage
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        // Use the shared WorkoutSessionStorage instance that's connected to Firebase
        self.sessionStorage = WorkoutSessionStorage.shared
        setupSessionListener()
    }
    
    private func setupSessionListener() {
        sessionStorage.$sessions
            .sink { [weak self] sessions in
                print("ProgressAnalytics: Session storage updated with \(sessions.count) sessions")
                self?.calculateProgress(from: sessions)
            }
            .store(in: &cancellables)
    }
    
    func calculateProgress(from sessions: [WorkoutSession]) {
        let completedSessions = sessions.filter { $0.isCompleted }
        
        print("ProgressAnalytics: Calculating progress from \(sessions.count) total sessions, \(completedSessions.count) completed")
        
        // Calculate basic metrics
        progressMetrics.weeklyWorkouts = getWorkoutsInTimeRange(completedSessions, days: 7)
        progressMetrics.monthlyWorkouts = getWorkoutsInTimeRange(completedSessions, days: 30)
        progressMetrics.totalWorkouts = completedSessions.count
        progressMetrics.streakDays = calculateStreakDays(completedSessions)
        progressMetrics.averageWorkoutDuration = calculateAverageDuration(completedSessions)
        
        // Calculate volume metrics
        progressMetrics.totalVolumeThisWeek = calculateTotalVolume(completedSessions, days: 7)
        progressMetrics.totalVolumeThisMonth = calculateTotalVolume(completedSessions, days: 30)
        
        // Calculate exercise-specific progress
        progressMetrics.exerciseProgress = calculateExerciseProgress(completedSessions)
        
        // Calculate weekly progress for charts
        weeklyProgress = calculateWeeklyProgress(completedSessions)
        
        // Group exercise progress by exercise name
        exerciseProgress = Dictionary(grouping: progressMetrics.exerciseProgress) { $0.exerciseName }
        
        print("ProgressAnalytics: Updated metrics - Weekly: \(progressMetrics.weeklyWorkouts), Monthly: \(progressMetrics.monthlyWorkouts), Total: \(progressMetrics.totalWorkouts)")
        print("ProgressAnalytics: Volume this week: \(progressMetrics.totalVolumeThisWeek), this month: \(progressMetrics.totalVolumeThisMonth)")
    }
    
    // Manual trigger for testing
    func refreshProgress() {
        print("ProgressAnalytics: Manual refresh triggered")
        print("ProgressAnalytics: Current sessions count: \(sessionStorage.sessions.count)")
        calculateProgress(from: sessionStorage.sessions)
    }
    
    // Force reload from Firebase
    func reloadFromFirebase() {
        print("ProgressAnalytics: Forcing reload from Firebase")
        sessionStorage.loadSessionsFromFirebase()
    }
    
    // Get chart data for the dashboard
    func getChartData(for timeRange: TimeRange, metric: ChartMetric) -> [WeeklyProgress] {
        switch timeRange {
        case .week:
            return Array(weeklyProgress.suffix(7))
        case .month:
            return Array(weeklyProgress.suffix(30))
        case .threeMonths:
            return Array(weeklyProgress.suffix(90))
        case .year:
            return weeklyProgress
        }
    }
    
    private func getWorkoutsInTimeRange(_ sessions: [WorkoutSession], days: Int) -> Int {
        let cutoffDate = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()
        return sessions.filter { $0.startTime >= cutoffDate }.count
    }
    
    private func calculateStreakDays(_ sessions: [WorkoutSession]) -> Int {
        let sortedSessions = sessions.sorted { $0.startTime > $1.startTime }
        guard !sortedSessions.isEmpty else { return 0 }
        
        let calendar = Calendar.current
        var currentDate = Date()
        var streak = 0
        
        // Check if today has a workout
        let todaySessions = sortedSessions.filter { calendar.isDate($0.startTime, inSameDayAs: currentDate) }
        if todaySessions.isEmpty {
            // If no workout today, start from yesterday
            currentDate = calendar.date(byAdding: .day, value: -1, to: currentDate) ?? currentDate
        }
        
        while true {
            let daySessions = sortedSessions.filter { calendar.isDate($0.startTime, inSameDayAs: currentDate) }
            if daySessions.isEmpty {
                break
            }
            streak += 1
            currentDate = calendar.date(byAdding: .day, value: -1, to: currentDate) ?? currentDate
        }
        
        return streak
    }
    
    private func calculateAverageDuration(_ sessions: [WorkoutSession]) -> TimeInterval {
        let sessionsWithDuration = sessions.compactMap { session -> TimeInterval? in
            guard let endTime = session.endTime else { return nil }
            return endTime.timeIntervalSince(session.startTime)
        }
        
        guard !sessionsWithDuration.isEmpty else { return 0 }
        return sessionsWithDuration.reduce(0, +) / Double(sessionsWithDuration.count)
    }
    
    private func calculateTotalVolume(_ sessions: [WorkoutSession], days: Int) -> Double {
        let cutoffDate = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()
        let recentSessions = sessions.filter { $0.startTime >= cutoffDate }
        
        return recentSessions.reduce(0.0) { total, session in
            total + session.exercises.reduce(0.0) { exerciseTotal, exercise in
                exerciseTotal + exercise.sets.reduce(0.0) { setTotal, set in
                    setTotal + (set.weight * Double(set.reps))
                }
            }
        }
    }
    
    private func calculateExerciseProgress(_ sessions: [WorkoutSession]) -> [ExerciseProgress] {
        var progress: [ExerciseProgress] = []
        
        for session in sessions {
            for exercise in session.exercises {
                let maxWeight = exercise.sets.map { $0.weight }.max() ?? 0
                let maxReps = exercise.sets.map { $0.reps }.max() ?? 0
                let totalVolume = exercise.sets.reduce(0.0) { $0 + ($1.weight * Double($1.reps)) }
                
                let exerciseProgress = ExerciseProgress(
                    exerciseName: exercise.exerciseName,
                    date: session.startTime,
                    maxWeight: maxWeight,
                    maxReps: maxReps,
                    totalVolume: totalVolume,
                    sets: exercise.sets.count
                )
                progress.append(exerciseProgress)
            }
        }
        
        return progress
    }
    
    private func calculateWeeklyProgress(_ sessions: [WorkoutSession]) -> [WeeklyProgress] {
        let calendar = Calendar.current
        let now = Date()
        var weeklyData: [Date: (workouts: Int, volume: Double, duration: TimeInterval)] = [:]
        
        // Initialize last 12 weeks
        for i in 0..<12 {
            if let weekStart = calendar.date(byAdding: .weekOfYear, value: -i, to: now) {
                let weekStartOfWeek = calendar.dateInterval(of: .weekOfYear, for: weekStart)?.start ?? weekStart
                weeklyData[weekStartOfWeek] = (0, 0, 0)
            }
        }
        
        // Process sessions
        for session in sessions {
            guard let endTime = session.endTime else { continue }
            
            let weekStart = calendar.dateInterval(of: .weekOfYear, for: session.startTime)?.start ?? session.startTime
            
            if var weekData = weeklyData[weekStart] {
                weekData.workouts += 1
                weekData.volume += session.exercises.reduce(0.0) { total, exercise in
                    total + exercise.sets.reduce(0.0) { setTotal, set in
                        setTotal + (set.weight * Double(set.reps))
                    }
                }
                weekData.duration += endTime.timeIntervalSince(session.startTime)
                weeklyData[weekStart] = weekData
            }
        }
        
        return weeklyData.map { weekStart, data in
            WeeklyProgress(
                weekStart: weekStart,
                workouts: data.workouts,
                totalVolume: data.volume,
                averageDuration: data.workouts > 0 ? data.duration / Double(data.workouts) : 0
            )
        }.sorted { $0.weekStart < $1.weekStart }
    }
    
    // MARK: - Public Methods
    
    func getExerciseProgress(for exerciseName: String, timeRange: TimeRange) -> [ExerciseProgress] {
        let cutoffDate = Calendar.current.date(byAdding: .day, value: -timeRange.days, to: Date()) ?? Date()
        return progressMetrics.exerciseProgress.filter { 
            $0.exerciseName.lowercased() == exerciseName.lowercased() && $0.date >= cutoffDate 
        }.sorted { $0.date < $1.date }
    }
    
    func getChartData(for timeRange: TimeRange, metric: ChartMetric) -> [ChartDataPoint] {
        let cutoffDate = Calendar.current.date(byAdding: .day, value: -timeRange.days, to: Date()) ?? Date()
        
        switch metric {
        case .volume:
            return weeklyProgress
                .filter { $0.weekStart >= cutoffDate }
                .map { ChartDataPoint(date: $0.weekStart, value: $0.totalVolume, label: "Total Weight (lbs)") }
        case .duration:
            return weeklyProgress
                .filter { $0.weekStart >= cutoffDate }
                .map { ChartDataPoint(date: $0.weekStart, value: $0.averageDuration / 60, label: "Duration (min)") }
        }
    }
    
    func getPersonalRecord(for exerciseName: String) -> (weight: Double, reps: Int, date: Date)? {
        let exerciseData = progressMetrics.exerciseProgress.filter { 
            $0.exerciseName.lowercased() == exerciseName.lowercased() 
        }
        
        guard let maxWeightRecord = exerciseData.max(by: { $0.maxWeight < $1.maxWeight }) else {
            return nil
        }
        
        return (weight: maxWeightRecord.maxWeight, reps: maxWeightRecord.maxReps, date: maxWeightRecord.date)
    }
    
    // Get total volume across all time
    func getTotalVolume() -> Double {
        let completedSessions = sessionStorage.sessions.filter { $0.isCompleted }
        return completedSessions.reduce(0.0) { total, session in
            total + session.exercises.reduce(0.0) { exerciseTotal, exercise in
                exerciseTotal + exercise.sets.reduce(0.0) { setTotal, set in
                    setTotal + (set.weight * Double(set.reps))
                }
            }
        }
    }
    
    // Get last workout date
    func getLastWorkoutDate() -> Date? {
        let completedSessions = sessionStorage.sessions.filter { $0.isCompleted }
        return completedSessions.max(by: { $0.startTime < $1.startTime })?.startTime
    }
    
    // Get last workout info (date and title)
    func getLastWorkoutInfo() -> (date: Date, title: String)? {
        let completedSessions = sessionStorage.sessions.filter { $0.isCompleted }
        guard let lastSession = completedSessions.max(by: { $0.startTime < $1.startTime }) else {
            return nil
        }
        return (date: lastSession.startTime, title: lastSession.routineName)
    }
}

enum ChartMetric: String, CaseIterable {
    case volume = "Volume"
    case duration = "Duration"
}
