//
//  RoutineBuilderView.swift
//  lyft-up
//
//  Created by Colin Chu on 8/1/25.
//

import SwiftUI

struct RoutineBuilderView: View {
    @StateObject private var routineStorage = RoutineStorage()
    @State private var showingCreateRoutine = false
    
    var body: some View {
        NavigationView {
            VStack {
                if routineStorage.routines.isEmpty {
                    // Empty State
                    VStack(spacing: 20) {
                        Image(systemName: "list.bullet.clipboard")
                            .font(.system(size: 60))
                            .foregroundColor(.blue)
                        
                        Text("No Routines Yet")
                            .font(.title2)
                            .fontWeight(.semibold)
                        
                        Text("Create your first workout routine to get started")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                        
                        Button(action: { showingCreateRoutine = true }) {
                            HStack {
                                Image(systemName: "plus.circle.fill")
                                Text("Create Routine")
                            }
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(10)
                        }
                    }
                    .padding()
                } else {
                    // Routines List
                    List {
                        ForEach(routineStorage.routines) { routine in
                            RoutineRowView(routine: routine, routineStorage: routineStorage)
                        }
                        .onDelete(perform: deleteRoutines)
                    }
                }
            }
            .navigationTitle("Routines")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingCreateRoutine = true }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingCreateRoutine) {
                CreateRoutineView(routineStorage: routineStorage)
            }
        }
    }
    
    private func deleteRoutines(offsets: IndexSet) {
        for index in offsets {
            routineStorage.deleteRoutine(routineStorage.routines[index])
        }
    }
}

struct RoutineRowView: View {
    let routine: Routine
    let routineStorage: RoutineStorage
    @State private var showingRoutineDetail = false
    @State private var showingWorkoutSession = false
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(routine.name)
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Text("\(routine.exercises.count) exercises")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Button(action: { showingWorkoutSession = true }) {
                Text("Start Workout")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.blue)
                    .cornerRadius(8)
            }
        }
        .padding(.vertical, 4)
        .sheet(isPresented: $showingRoutineDetail) {
            RoutineDetailView(routine: routine, routineStorage: routineStorage)
        }
        .fullScreenCover(isPresented: $showingWorkoutSession) {
            WorkoutSessionView(routine: routine)
        }
    }
}

struct CreateRoutineView: View {
    @ObservedObject var routineStorage: RoutineStorage
    @Environment(\.dismiss) private var dismiss
    
    @State private var routineName = ""
    @State private var exercises: [RoutineExercise] = []
    @State private var newExerciseName = ""
    @State private var newExerciseSets = 3
    @State private var showingAddExercise = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Routine Name Input
                VStack(alignment: .leading, spacing: 8) {
                    Text("Routine Name")
                        .font(.headline)
                        .padding(.horizontal, 20)
                    
                    TextField("Enter routine name", text: $routineName)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding(.horizontal, 20)
                }
                .padding(.top, 20)
                
                // Exercises List
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Text("Exercises")
                            .font(.headline)
                        
                        Spacer()
                        
                        Button(action: { showingAddExercise = true }) {
                            Image(systemName: "plus.circle.fill")
                                .foregroundColor(.blue)
                                .font(.title2)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    
                    if exercises.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: "dumbbell")
                                .font(.system(size: 40))
                                .foregroundColor(.gray.opacity(0.5))
                            Text("No exercises added")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 40)
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 12) {
                                ForEach(exercises.indices, id: \.self) { index in
                                    RoutineExerciseRow(exercise: $exercises[index])
                                }
                                .onDelete(perform: deleteExercises)
                            }
                            .padding(.horizontal, 20)
                        }
                    }
                }
                
                Spacer()
                
                // Save Button
                Button(action: saveRoutine) {
                    Text("Save Routine")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            routineName.isEmpty || exercises.isEmpty ?
                            Color.gray.opacity(0.3) :
                            Color.blue
                        )
                        .cornerRadius(12)
                }
                .disabled(routineName.isEmpty || exercises.isEmpty)
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
            .navigationTitle("Create Routine")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingAddExercise) {
                AddExerciseView { exercise in
                    exercises.append(exercise)
                }
            }
        }
    }
    
    private func deleteExercises(offsets: IndexSet) {
        exercises.remove(atOffsets: offsets)
    }
    
    private func saveRoutine() {
        let routine = Routine(name: routineName)
        var updatedRoutine = routine
        updatedRoutine.exercises = exercises
        routineStorage.saveRoutine(updatedRoutine)
        dismiss()
    }
}

struct RoutineExerciseRow: View {
    @Binding var exercise: RoutineExercise
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(exercise.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text("\(exercise.defaultSets) sets")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
}

struct AddExerciseView: View {
    @Environment(\.dismiss) private var dismiss
    let onAdd: (RoutineExercise) -> Void
    
    @State private var exerciseName = ""
    @State private var sets = 3
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Exercise Name")
                        .font(.headline)
                    
                    TextField("Enter exercise name", text: $exerciseName)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Number of Sets")
                        .font(.headline)
                    
                    Stepper("\(sets) sets", value: $sets, in: 1...10)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("Add Exercise")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Add") {
                        let exercise = RoutineExercise(name: exerciseName, defaultSets: sets)
                        onAdd(exercise)
                        dismiss()
                    }
                    .disabled(exerciseName.isEmpty)
                }
            }
        }
    }
}

struct RoutineDetailView: View {
    let routine: Routine
    let routineStorage: RoutineStorage
    @Environment(\.dismiss) private var dismiss
    @State private var showingWorkoutSession = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Routine Info
                VStack(spacing: 8) {
                    Text(routine.name)
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("\(routine.exercises.count) exercises")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding()
                
                // Exercises List
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(routine.exercises) { exercise in
                            VStack(alignment: .leading, spacing: 8) {
                                Text(exercise.name)
                                    .font(.headline)
                                
                                Text("\(exercise.defaultSets) sets")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                        }
                    }
                    .padding(.horizontal, 20)
                }
                
                Spacer()
                
                // Start Workout Button
                Button(action: { showingWorkoutSession = true }) {
                    HStack {
                        Image(systemName: "play.circle.fill")
                        Text("Start Workout")
                    }
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.blue)
                    .cornerRadius(12)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
            .navigationTitle("Routine Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .fullScreenCover(isPresented: $showingWorkoutSession) {
            WorkoutSessionView(routine: routine)
        }
    }
}

#Preview {
    RoutineBuilderView()
}
