//
//  ProgressDashboardView.swift
//  lyft-up
//
//  Created by Colin Chu on 8/1/25.
//

import SwiftUI

struct ProgressDashboardView: View {
    @StateObject private var analyticsService = ProgressAnalyticsService.shared
    @State private var selectedTimeRange: TimeRange = .month
    @State private var selectedMetric: ChartMetric = .volume
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header Stats
                    statsOverview
                    
                    // Chart Section
                    chartSection
                    
                    // Exercise Progress
                    exerciseProgressSection
                    
                    // Achievements
                    achievementsSection
                }
                .padding()
            }
            .navigationTitle("Progress")
            .navigationBarTitleDisplayMode(.large)
            .refreshable {
                analyticsService.refreshProgress()
            }
            .onAppear {
                print("ProgressDashboardView: Appeared")
                print("ProgressDashboardView: Analytics service sessions count: \(analyticsService.sessionStorage.sessions.count)")
                // Force reload from Firebase when view appears
                analyticsService.reloadFromFirebase()
            }
        }
    }
    
    private var statsOverview: some View {
        VStack(spacing: 16) {
            Text("Your Progress")
                .font(.title2)
                .fontWeight(.bold)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                // Weekly Workouts
                ProgressStatCard(
                    title: "This Week",
                    value: "\(analyticsService.progressMetrics.weeklyWorkouts)",
                    subtitle: "workouts",
                    icon: "flame.fill",
                    color: .lyftRed
                )
                .onAppear {
                    print("ProgressView - Weekly workouts: \(analyticsService.progressMetrics.weeklyWorkouts)")
                    print("ProgressView - Total workouts: \(analyticsService.progressMetrics.totalWorkouts)")
                }
                
                // Monthly Workouts
                ProgressStatCard(
                    title: "This Month",
                    value: "\(analyticsService.progressMetrics.monthlyWorkouts)",
                    subtitle: "workouts",
                    icon: "calendar",
                    color: .blue
                )
                
                // Current Streak
                ProgressStatCard(
                    title: "Streak",
                    value: "\(analyticsService.progressMetrics.streakDays)",
                    subtitle: "days",
                    icon: "bolt.fill",
                    color: .orange
                )
                
                // Total Duration This Week
                ProgressStatCard(
                    title: "This Week",
                    value: formatDuration(analyticsService.progressMetrics.totalDurationThisWeek),
                    subtitle: "total time",
                    icon: "clock.fill",
                    color: .green
                )
            }
        }
    }
    
    private var chartSection: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Progress Charts")
                    .font(.title2)
                    .fontWeight(.bold)
                Spacer()
                
                // Time Range Picker
                Picker("Time Range", selection: $selectedTimeRange) {
                    ForEach(TimeRange.allCases, id: \.self) { range in
                        Text(range.rawValue).tag(range)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .frame(width: 200)
            }
            
            // Metric Picker
            Picker("Metric", selection: $selectedMetric) {
                ForEach(ChartMetric.allCases, id: \.self) { metric in
                    Text(metric.rawValue).tag(metric)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
            
            // Chart
            ProgressChartView(
                data: analyticsService.getChartData(for: selectedTimeRange, metric: selectedMetric),
                metric: selectedMetric,
                timeRange: selectedTimeRange
            )
            .frame(height: 200)
            .padding()
            .background(Color.white)
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
            .onChange(of: selectedTimeRange) { newValue in
                print("ProgressDashboardView: Time range changed to \(newValue.rawValue)")
                print("ProgressDashboardView: Chart data points: \(analyticsService.getChartData(for: newValue, metric: selectedMetric).count)")
            }
            .onChange(of: selectedMetric) { newValue in
                print("ProgressDashboardView: Metric changed to \(newValue.rawValue)")
                print("ProgressDashboardView: Chart data points: \(analyticsService.getChartData(for: selectedTimeRange, metric: newValue).count)")
            }
        }
    }
    
    private var exerciseProgressSection: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Exercise Progress")
                    .font(.title2)
                    .fontWeight(.bold)
                Spacer()
                
                NavigationLink("View All", destination: ExerciseProgressView())
                    .font(.subheadline)
                    .foregroundColor(.lyftRed)
            }
            
            // Show top 3 exercises by recent activity
            let topExercises = Array(analyticsService.exerciseProgress.keys.prefix(3))
            
            ForEach(topExercises, id: \.self) { exerciseName in
                ExerciseProgressRow(
                    exerciseName: exerciseName,
                    progress: analyticsService.exerciseProgress[exerciseName] ?? []
                )
            }
        }
    }
    
    private var achievementsSection: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Achievements")
                    .font(.title2)
                    .fontWeight(.bold)
                Spacer()
            }
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                AchievementBadge(
                    title: "100 Workouts",
                    icon: "flame.fill",
                    isUnlocked: analyticsService.progressMetrics.totalWorkouts >= 100,
                    color: .orange,
                    progress: min(Double(analyticsService.progressMetrics.totalWorkouts) / 100.0, 1.0),
                    showProgress: analyticsService.progressMetrics.totalWorkouts < 100
                )
                
                // Only show 250 workouts achievement if 100 workouts is completed
                if analyticsService.progressMetrics.totalWorkouts >= 100 {
                    AchievementBadge(
                        title: "250 Workouts",
                        icon: "flame.fill",
                        isUnlocked: analyticsService.progressMetrics.totalWorkouts >= 250,
                        color: .red,
                        progress: min(Double(analyticsService.progressMetrics.totalWorkouts - 100) / 150.0, 1.0),
                        showProgress: analyticsService.progressMetrics.totalWorkouts < 250
                    )
                }
                
                AchievementBadge(
                    title: "500K lbs",
                    icon: "dumbbell.fill",
                    isUnlocked: analyticsService.getTotalVolume() >= 500000,
                    color: .blue,
                    progress: min(analyticsService.getTotalVolume() / 500000.0, 1.0),
                    showProgress: analyticsService.getTotalVolume() < 500000
                )
                
                // Only show 1M lbs achievement if 500K lbs is completed
                if analyticsService.getTotalVolume() >= 500000 {
                    AchievementBadge(
                        title: "1M lbs",
                        icon: "dumbbell.fill",
                        isUnlocked: analyticsService.getTotalVolume() >= 1000000,
                        color: .green,
                        progress: min((analyticsService.getTotalVolume() - 500000) / 500000.0, 1.0),
                        showProgress: analyticsService.getTotalVolume() < 1000000
                    )
                }
                
                AchievementBadge(
                    title: "7-Day Streak",
                    icon: "bolt.fill",
                    isUnlocked: analyticsService.progressMetrics.streakDays >= 7,
                    color: .purple,
                    progress: min(Double(analyticsService.progressMetrics.streakDays) / 7.0, 1.0),
                    showProgress: analyticsService.progressMetrics.streakDays < 7
                )
            }
        }
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let totalSeconds = Int(duration)
        let totalMinutes = totalSeconds / 60
        let hours = totalMinutes / 60
        let minutes = totalMinutes % 60
        let seconds = totalSeconds % 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else if minutes > 0 {
            return "\(minutes)m \(seconds)s"
        } else {
            return "\(seconds)s"
        }
    }
}

struct ProgressStatCard: View {
    let title: String
    let value: String
    let subtitle: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.1))
                    .frame(width: 50, height: 50)
                
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(color)
            }
            
            VStack(spacing: 4) {
                Text(value)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.lyftText)
                
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.lyftTextSecondary)
            }
            
            Text(title)
                .font(.caption)
                .foregroundColor(.lyftTextSecondary)
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}

struct ProgressChartView: View {
    let data: [ChartDataPoint]
    let metric: ChartMetric
    let timeRange: TimeRange
    
    var body: some View {
        VStack {
            if data.isEmpty {
                emptyChartView
            } else {
                chartContent
            }
        }
        .onAppear {
            print("ProgressChartView: Appeared with \(data.count) data points")
        }
        .onChange(of: data.count) { newCount in
            print("ProgressChartView: Data count changed to \(newCount)")
        }
    }
    
    private var emptyChartView: some View {
        VStack(spacing: 12) {
            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.system(size: 40))
                .foregroundColor(.gray.opacity(0.5))
            
            Text("No data available")
                .font(.subheadline)
                .foregroundColor(.gray)
        }
    }
    
    private var chartContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(metric.rawValue)
                    .font(.headline)
                    .fontWeight(.semibold)
                
                // Debug info
                Text("\(data.count) points")
                    .font(.caption)
                    .foregroundColor(.gray)
                
                Spacer()
                
                // Summary stats
                VStack(alignment: .trailing, spacing: 2) {
                    Text(summaryValue)
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundColor(chartColor)
                    
                    Text(summaryLabel)
                        .font(.caption)
                        .foregroundColor(.lyftTextSecondary)
                }
            }
            
            // Bar chart with numerical values
            HStack(alignment: .bottom, spacing: 4) {
                ForEach(data) { point in
                    let _ = print("ProgressChartView: Data point - \(formatDate(point.date)): \(point.value)")
                    VStack(spacing: 4) {
                        // Numerical value above bar
                        Text(formatValue(point.value))
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.lyftText)
                        
                        // Bar
                        Rectangle()
                            .fill(chartColor)
                            .frame(height: max(20, CGFloat(point.value / maxValue) * 150))
                            .cornerRadius(4)
                        
                        // Date below bar
                        Text(formatDate(point.date))
                            .font(.caption2)
                            .foregroundColor(.gray)
                    }
                }
            }
        }
    }
    
    private var summaryValue: String {
        switch metric {
        case .volume:
            let total = data.reduce(0) { $0 + $1.value }
            return "\(Int(total)) lbs"
        case .duration:
            let average = data.isEmpty ? 0 : data.reduce(0) { $0 + $1.value } / Double(data.count)
            return "\(Int(average)) min"
        }
    }
    
    private var summaryLabel: String {
        switch metric {
        case .volume:
            return "Total"
        case .duration:
            return "Average"
        }
    }
    
    private var chartColor: Color {
        switch metric {
        case .volume:
            return .lyftRed
        case .duration:
            return .blue
        }
    }
    
    private func formatValue(_ value: Double) -> String {
        switch metric {
        case .volume:
            return "\(Int(value)) lbs"
        case .duration:
            return "\(Int(value)) min"
        }
    }
    
    private var maxValue: Double {
        data.map { $0.value }.max() ?? 1
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        
        // For month view, show only month name
        if timeRange == .month {
            formatter.dateFormat = "MMM"
        } else {
            formatter.dateFormat = "MMM dd"
        }
        
        return formatter.string(from: date)
    }
}

struct ExerciseProgressRow: View {
    let exerciseName: String
    let progress: [ExerciseProgress]
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(exerciseName)
                    .font(.headline)
                    .fontWeight(.semibold)
                
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
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}

struct AchievementBadge: View {
    let title: String
    let icon: String
    let isUnlocked: Bool
    let color: Color
    let progress: Double
    let showProgress: Bool
    
    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(isUnlocked ? color.opacity(0.1) : Color.gray.opacity(0.1))
                    .frame(width: 50, height: 50)
                
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(isUnlocked ? color : .gray)
            }
            
            Text(title)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(isUnlocked ? .lyftText : .gray)
                .multilineTextAlignment(.center)
            
            if showProgress && !isUnlocked {
                ProgressView(value: progress)
                    .progressViewStyle(LinearProgressViewStyle(tint: color))
                    .frame(height: 4)
                    .padding(.horizontal, 8)
                
                Text("\(Int(progress * 100))%")
                    .font(.caption2)
                    .foregroundColor(.lyftTextSecondary)
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}

#Preview {
    ProgressDashboardView()
}
