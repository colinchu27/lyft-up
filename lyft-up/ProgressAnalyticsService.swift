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
                print("ProgressAnalytics: Sessions: \(sessions.map { "\($0.routineName) - \($0.isCompleted)" })")
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
        
        // Calculate duration metrics
        progressMetrics.totalDurationThisWeek = calculateTotalDuration(completedSessions, days: 7)
        progressMetrics.totalDurationThisMonth = calculateTotalDuration(completedSessions, days: 30)
        
        // Calculate exercise-specific progress
        progressMetrics.exerciseProgress = calculateExerciseProgress(completedSessions)
        
        // Calculate weekly progress for charts
        weeklyProgress = calculateWeeklyProgress(completedSessions)
        
        // Group exercise progress by exercise name
        exerciseProgress = Dictionary(grouping: progressMetrics.exerciseProgress) { $0.exerciseName }
        
        print("ProgressAnalytics: Updated metrics - Weekly: \(progressMetrics.weeklyWorkouts), Monthly: \(progressMetrics.monthlyWorkouts), Total: \(progressMetrics.totalWorkouts)")
        print("ProgressAnalytics: Volume this week: \(progressMetrics.totalVolumeThisMonth), this month: \(progressMetrics.totalVolumeThisMonth)")
        print("ProgressAnalytics: Total completed sessions: \(completedSessions.count)")
        
        // Debug: Print session details
        for (index, session) in completedSessions.enumerated() {
            print("Session \(index + 1): \(session.routineName) - \(session.startTime) - Completed: \(session.isCompleted)")
        }
        
        // Sync calculated stats to Firebase
        syncStatsToFirebase(completedSessions: completedSessions)
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
        
        Task {
            // Try loading multiple times to handle Firebase consistency
            for attempt in 1...3 {
                print("ProgressAnalytics: Loading attempt \(attempt)")
                await sessionStorage.loadSessionsFromFirebaseAsync()
                
                // Wait a moment for Firebase consistency
                try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
            }
            
            await MainActor.run {
                print("ProgressAnalytics: Final recalculation with \(self.sessionStorage.sessions.count) sessions")
                self.calculateProgress(from: self.sessionStorage.sessions)
            }
        }
    }
    
    // Get chart data for the dashboard
    func getChartData(for timeRange: TimeRange, metric: ChartMetric) -> [ChartDataPoint] {
        let calendar = Calendar.current
        let now = Date()
        
        let completedSessions: [WorkoutSession]
        
        // Filter sessions based on time range using the same logic as our metrics
        switch timeRange {
        case .week:
            // For weekly view, show previous 7 days (rolling window)
            let cutoffDate = calendar.date(byAdding: .day, value: -7, to: now) ?? now
            
            completedSessions = sessionStorage.sessions.filter { session in
                session.isCompleted && session.startTime >= cutoffDate
            }
            
        case .month:
            // For monthly view, show current month (1st to last day)
            let monthStart = calendar.dateInterval(of: .month, for: now)?.start ?? now
            let startOfMonth = calendar.startOfDay(for: monthStart)
            let monthEnd = calendar.dateInterval(of: .month, for: now)?.end ?? now
            let endOfMonth = calendar.date(byAdding: .day, value: -1, to: monthEnd) ?? now
            
            completedSessions = sessionStorage.sessions.filter { session in
                session.isCompleted && session.startTime >= startOfMonth && session.startTime <= endOfMonth
            }
            
        case .threeMonths:
            // For 3-month view, show last 90 days
            let cutoffDate = calendar.date(byAdding: .day, value: -timeRange.days, to: now) ?? now
            completedSessions = sessionStorage.sessions.filter { session in
                session.isCompleted && session.startTime >= cutoffDate
            }
        }
        
        print("ProgressAnalytics: getChartData called for \(timeRange.rawValue)")
        print("ProgressAnalytics: Total sessions: \(sessionStorage.sessions.count)")
        print("ProgressAnalytics: Completed sessions in range: \(completedSessions.count)")
        
        // Use different aggregation strategies based on time range
        let chartData: [ChartDataPoint]
        
        switch timeRange {
        case .week:
            chartData = aggregateByDay(completedSessions, metric: metric)
        case .month:
            chartData = aggregateByMonth(completedSessions, metric: metric)
        case .threeMonths:
            chartData = aggregateByMonthFIFO(completedSessions, metric: metric)
        }
        
        let sortedData = chartData.sorted { $0.date < $1.date }
        print("ProgressAnalytics: Returning \(sortedData.count) chart data points")
        return sortedData
    }
    
    // MARK: - Chart Data Aggregation Methods
    
    private func aggregateByDay(_ sessions: [WorkoutSession], metric: ChartMetric) -> [ChartDataPoint] {
        let calendar = Calendar.current
        let today = Date()
        var dailyData: [Date: (volume: Double, duration: TimeInterval, count: Int)] = [:]
        
        // Initialize last 7 days
        for i in 0..<7 {
            if let date = calendar.date(byAdding: .day, value: -i, to: today) {
                let startOfDay = calendar.startOfDay(for: date)
                dailyData[startOfDay] = (0, 0, 0)
            }
        }
        
        // Fill in actual data
        for session in sessions {
            let startOfDay = calendar.startOfDay(for: session.startTime)
            if dailyData[startOfDay] != nil {
                let volume = session.exercises.reduce(0.0) { exerciseTotal, exercise in
                    exerciseTotal + exercise.sets.reduce(0.0) { setTotal, set in
                        setTotal + (set.weight * Double(set.reps))
                    }
                }
                
                let duration = session.endTime?.timeIntervalSince(session.startTime) ?? 0
                
                let current = dailyData[startOfDay] ?? (0, 0, 0)
                dailyData[startOfDay] = (
                    current.volume + volume,
                    current.duration + duration,
                    current.count + 1
                )
            }
        }
        
        return dailyData.sorted { $0.key < $1.key }.map { date, data in
            let value = metric == .volume ? data.volume : (data.count > 0 ? data.duration / Double(data.count) / 60 : 0)
            let label = metric == .volume ? "Total Weight (lbs)" : "Duration (min)"
            return ChartDataPoint(date: date, value: value, label: label)
        }
    }
    
    private func aggregateByWeek(_ sessions: [WorkoutSession], metric: ChartMetric) -> [ChartDataPoint] {
        let calendar = Calendar.current
        var weeklyData: [Date: (volume: Double, duration: TimeInterval, count: Int)] = [:]
        
        // Group sessions by week
        for session in sessions {
            let weekStart = calendar.dateInterval(of: .weekOfYear, for: session.startTime)?.start ?? session.startTime
            let startOfWeek = calendar.startOfDay(for: weekStart)
            
            let volume = session.exercises.reduce(0.0) { exerciseTotal, exercise in
                exerciseTotal + exercise.sets.reduce(0.0) { setTotal, set in
                    setTotal + (set.weight * Double(set.reps))
                }
            }
            
            let duration = session.endTime?.timeIntervalSince(session.startTime) ?? 0
            
            let current = weeklyData[startOfWeek] ?? (0, 0, 0)
            weeklyData[startOfWeek] = (
                current.volume + volume,
                current.duration + duration,
                current.count + 1
            )
        }
        
        return weeklyData.sorted { $0.key < $1.key }.map { date, data in
            let value = metric == .volume ? data.volume : (data.count > 0 ? data.duration / Double(data.count) / 60 : 0)
            let label = metric == .volume ? "Total Weight (lbs)" : "Duration (min)"
            return ChartDataPoint(date: date, value: value, label: label)
        }
    }
    
    private func aggregateByMonth(_ sessions: [WorkoutSession], metric: ChartMetric) -> [ChartDataPoint] {
        let calendar = Calendar.current
        let now = Date()
        
        // For monthly view, we want to show the current month as a single data point
        // Get the start of the current month
        let monthStart = calendar.dateInterval(of: .month, for: now)?.start ?? now
        let startOfMonth = calendar.startOfDay(for: monthStart)
        
        // Calculate total volume and duration for the current month
        var totalVolume: Double = 0
        var totalDuration: TimeInterval = 0
        var sessionCount = 0
        
        for session in sessions {
            totalVolume += session.exercises.reduce(0.0) { exerciseTotal, exercise in
                exerciseTotal + exercise.sets.reduce(0.0) { setTotal, set in
                    setTotal + (set.weight * Double(set.reps))
                }
            }
            
            if let endTime = session.endTime {
                totalDuration += endTime.timeIntervalSince(session.startTime)
            }
            sessionCount += 1
        }
        
        // Create a single data point for the current month
        let value = metric == .volume ? totalVolume : (sessionCount > 0 ? totalDuration / Double(sessionCount) / 60 : 0)
        let label = metric == .volume ? "Total Weight (lbs)" : "Duration (min)"
        
        return [ChartDataPoint(date: startOfMonth, value: value, label: label)]
    }
    
    private func aggregateByMonthFIFO(_ sessions: [WorkoutSession], metric: ChartMetric) -> [ChartDataPoint] {
        let calendar = Calendar.current
        var monthlyData: [Date: (volume: Double, duration: TimeInterval, count: Int)] = [:]
        
        // Group sessions by month
        for session in sessions {
            let monthStart = calendar.dateInterval(of: .month, for: session.startTime)?.start ?? session.startTime
            let startOfMonth = calendar.startOfDay(for: monthStart)
            
            let volume = session.exercises.reduce(0.0) { exerciseTotal, exercise in
                exerciseTotal + exercise.sets.reduce(0.0) { setTotal, set in
                    setTotal + (set.weight * Double(set.reps))
                }
            }
            
            let duration = session.endTime?.timeIntervalSince(session.startTime) ?? 0
            
            let current = monthlyData[startOfMonth] ?? (0, 0, 0)
            monthlyData[startOfMonth] = (
                current.volume + volume,
                current.duration + duration,
                current.count + 1
            )
        }
        
        // Sort by date and take the most recent 3 months (FIFO approach)
        let sortedMonths = monthlyData.sorted { $0.key < $1.key }
        let recentMonths = Array(sortedMonths.suffix(3)) // Get last 3 months
        
        return recentMonths.map { date, data in
            let value = metric == .volume ? data.volume : (data.count > 0 ? data.duration / Double(data.count) / 60 : 0)
            let label = metric == .volume ? "Total Weight (lbs)" : "Duration (min)"
            return ChartDataPoint(date: date, value: value, label: label)
        }
    }
    
    private func getWorkoutsInTimeRange(_ sessions: [WorkoutSession], days: Int) -> Int {
        let calendar = Calendar.current
        let now = Date()
        
        if days == 7 {
            // For weekly workouts, calculate from Monday of current week to Sunday
            // Get the start of the current week (Monday)
            let weekStart = calendar.dateInterval(of: .weekOfYear, for: now)?.start ?? now
            let startOfWeek = calendar.startOfDay(for: weekStart)
            
            // Get the end of the current week (Sunday)
            let endOfWeek = calendar.date(byAdding: .day, value: 6, to: startOfWeek) ?? now
            
            return sessions.filter { session in
                let sessionDate = calendar.startOfDay(for: session.startTime)
                return sessionDate >= startOfWeek && sessionDate <= endOfWeek
            }.count
        } else if days == 30 {
            // For monthly workouts, calculate from the 1st of current month to last day of month
            // Get the start of the current month (1st day)
            let monthStart = calendar.dateInterval(of: .month, for: now)?.start ?? now
            let startOfMonth = calendar.startOfDay(for: monthStart)
            
            // Get the end of the current month (last day)
            let monthEnd = calendar.dateInterval(of: .month, for: now)?.end ?? now
            let endOfMonth = calendar.date(byAdding: .day, value: -1, to: monthEnd) ?? now
            
            return sessions.filter { session in
                let sessionDate = calendar.startOfDay(for: session.startTime)
                return sessionDate >= startOfMonth && sessionDate <= endOfMonth
            }.count
        } else {
            // For other time ranges, use the original logic
            let cutoffDate = calendar.date(byAdding: .day, value: -days, to: now) ?? now
            return sessions.filter { $0.startTime >= cutoffDate }.count
        }
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
        let calendar = Calendar.current
        let now = Date()
        
        let filteredSessions: [WorkoutSession]
        
        if days == 7 {
            // For weekly volume, calculate from Monday of current week to Sunday
            let weekStart = calendar.dateInterval(of: .weekOfYear, for: now)?.start ?? now
            let startOfWeek = calendar.startOfDay(for: weekStart)
            let endOfWeek = calendar.date(byAdding: .day, value: 6, to: startOfWeek) ?? now
            
            filteredSessions = sessions.filter { session in
                let sessionDate = calendar.startOfDay(for: session.startTime)
                return sessionDate >= startOfWeek && sessionDate <= endOfWeek
            }
        } else if days == 30 {
            // For monthly volume, calculate from the 1st of current month to last day of month
            let monthStart = calendar.dateInterval(of: .month, for: now)?.start ?? now
            let startOfMonth = calendar.startOfDay(for: monthStart)
            
            let monthEnd = calendar.dateInterval(of: .month, for: now)?.end ?? now
            let endOfMonth = calendar.date(byAdding: .day, value: -1, to: monthEnd) ?? now
            
            filteredSessions = sessions.filter { session in
                let sessionDate = calendar.startOfDay(for: session.startTime)
                return sessionDate >= startOfMonth && sessionDate <= endOfMonth
            }
        } else {
            // For other time ranges, use the original logic
            let cutoffDate = calendar.date(byAdding: .day, value: -days, to: now) ?? now
            filteredSessions = sessions.filter { $0.startTime >= cutoffDate }
        }
        
        return filteredSessions.reduce(0.0) { total, session in
            total + session.exercises.reduce(0.0) { exerciseTotal, exercise in
                exerciseTotal + exercise.sets.reduce(0.0) { setTotal, set in
                    setTotal + (set.weight * Double(set.reps))
                }
            }
        }
    }
    
    private func calculateTotalDuration(_ sessions: [WorkoutSession], days: Int) -> TimeInterval {
        let calendar = Calendar.current
        let now = Date()
        
        let filteredSessions: [WorkoutSession]
        
        if days == 7 {
            // For weekly duration, calculate from Monday of current week to Sunday
            let weekStart = calendar.dateInterval(of: .weekOfYear, for: now)?.start ?? now
            let startOfWeek = calendar.startOfDay(for: weekStart)
            let endOfWeek = calendar.date(byAdding: .day, value: 6, to: startOfWeek) ?? now
            
            filteredSessions = sessions.filter { session in
                let sessionDate = calendar.startOfDay(for: session.startTime)
                return sessionDate >= startOfWeek && sessionDate <= endOfWeek
            }
        } else if days == 30 {
            // For monthly duration, calculate from the 1st of current month to last day of month
            let monthStart = calendar.dateInterval(of: .month, for: now)?.start ?? now
            let startOfMonth = calendar.startOfDay(for: monthStart)
            
            let monthEnd = calendar.dateInterval(of: .month, for: now)?.end ?? now
            let endOfMonth = calendar.date(byAdding: .day, value: -1, to: monthEnd) ?? now
            
            filteredSessions = sessions.filter { session in
                let sessionDate = calendar.startOfDay(for: session.startTime)
                return sessionDate >= startOfMonth && sessionDate <= endOfMonth
            }
        } else {
            // For other time ranges, use the original logic
            let cutoffDate = calendar.date(byAdding: .day, value: -days, to: now) ?? now
            filteredSessions = sessions.filter { $0.startTime >= cutoffDate }
        }
        
        return filteredSessions.reduce(0.0) { total, session in
            guard let endTime = session.endTime else { return total }
            return total + endTime.timeIntervalSince(session.startTime)
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
    
    // Sync calculated stats to Firebase
    private func syncStatsToFirebase(completedSessions: [WorkoutSession]) {
        Task {
            do {
                let firebaseService = FirebaseService.shared
                
                // Calculate total weight lifted
                let totalWeightLifted = completedSessions.reduce(0.0) { total, session in
                    total + session.exercises.reduce(0.0) { exerciseTotal, exercise in
                        exerciseTotal + exercise.sets.reduce(0.0) { setTotal, set in
                            setTotal + (set.weight * Double(set.reps))
                        }
                    }
                }
                
                let lastWorkoutDate = completedSessions.max(by: { $0.startTime < $1.startTime })?.startTime
                
                print("ProgressAnalytics: Syncing to Firebase - Workouts: \(completedSessions.count), Weight: \(totalWeightLifted) lbs")
                
                // Update user profile with calculated stats
                if var userProfile = firebaseService.userProfile {
                    userProfile.totalWorkouts = completedSessions.count
                    userProfile.totalWeightLifted = totalWeightLifted
                    userProfile.lastWorkoutDate = lastWorkoutDate
                    
                    try await firebaseService.saveUserProfile(userProfile)
                    
                    await MainActor.run {
                        firebaseService.userProfile = userProfile
                    }
                    
                    print("ProgressAnalytics: Successfully synced stats to Firebase")
                } else {
                    print("ProgressAnalytics: No user profile found to sync stats")
                }
            } catch {
                print("ProgressAnalytics: Error syncing stats to Firebase: \(error)")
            }
        }
    }
}

enum ChartMetric: String, CaseIterable {
    case volume = "Volume"
    case duration = "Duration"
}
