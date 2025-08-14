//
//  FriendRoutineViews.swift
//  lyft-up
//
//  Created by Colin Chu on 8/1/25.
//

import SwiftUI

struct FriendRoutineRow: View {
    let routine: Routine
    @State private var showingRoutineDetail = false
    
    var body: some View {
        Button(action: {
            showingRoutineDetail = true
        }) {
            HStack(spacing: 16) {
                // Routine icon
                Circle()
                    .fill(Color.lyftRed.opacity(0.1))
                    .frame(width: 50, height: 50)
                    .overlay(
                        Image(systemName: "list.bullet.clipboard")
                            .font(.system(size: 20))
                            .foregroundColor(.lyftRed)
                    )
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(routine.name)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.lyftText)
                    
                    Text("\(routine.exercises.count) exercises")
                        .font(.system(size: 14))
                        .foregroundColor(.lyftText.opacity(0.6))
                    
                    Text(formatRoutineDate(routine.createdAt))
                        .font(.system(size: 12))
                        .foregroundColor(.lyftText.opacity(0.5))
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 12))
                    .foregroundColor(.lyftText.opacity(0.4))
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
        .sheet(isPresented: $showingRoutineDetail) {
            FriendRoutineDetailView(routine: routine)
        }
    }
    
    private func formatRoutineDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}

struct FriendRoutineDetailView: View {
    let routine: Routine
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Routine Header
                    VStack(spacing: 16) {
                        Circle()
                            .fill(Color.lyftRed.opacity(0.1))
                            .frame(width: 80, height: 80)
                            .overlay(
                                Image(systemName: "list.bullet.clipboard")
                                    .font(.system(size: 32))
                                    .foregroundColor(.lyftRed)
                            )
                        
                        VStack(spacing: 8) {
                            Text(routine.name)
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(.lyftText)
                            
                            Text("\(routine.exercises.count) exercises")
                                .font(.system(size: 16))
                                .foregroundColor(.lyftText.opacity(0.6))
                        }
                    }
                    
                    // Exercises List
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Exercises")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.lyftText)
                        
                        if routine.exercises.isEmpty {
                            Text("No exercises in this routine")
                                .font(.system(size: 16))
                                .foregroundColor(.lyftText.opacity(0.6))
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(Color.gray.opacity(0.1))
                                .cornerRadius(12)
                        } else {
                            LazyVStack(spacing: 12) {
                                ForEach(Array(routine.exercises.enumerated()), id: \.element.id) { index, exercise in
                                    FriendExerciseRow(exercise: exercise, index: index + 1)
                                }
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                .padding()
            }
            .navigationTitle("Routine Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.lyftRed)
                }
            }
        }
    }
}

struct FriendExerciseRow: View {
    let exercise: RoutineExercise
    let index: Int
    
    var body: some View {
        HStack(spacing: 16) {
            // Exercise number
            Circle()
                .fill(Color.lyftRed.opacity(0.1))
                .frame(width: 40, height: 40)
                .overlay(
                    Text("\(index)")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.lyftRed)
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(exercise.name)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.lyftText)
                
                Text("\(exercise.defaultSets) sets")
                    .font(.system(size: 14))
                    .foregroundColor(.lyftText.opacity(0.6))
            }
            
            Spacer()
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }
}
