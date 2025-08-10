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
            ZStack {
                // Background
                Color.lyftGray.ignoresSafeArea()
                
                VStack {
                    if routineStorage.routines.isEmpty {
                        // Empty State
                        VStack(spacing: 32) {
                            Spacer()
                            
                            VStack(spacing: 24) {
                                ZStack {
                                    Circle()
                                        .fill(Color.lyftRed.opacity(0.1))
                                        .frame(width: 120, height: 120)
                                    
                                    Image(systemName: "list.bullet.clipboard")
                                        .font(.system(size: 50))
                                        .foregroundColor(.lyftRed)
                                }
                                
                                VStack(spacing: 16) {
                                    Text("No Routines Yet")
                                        .font(.system(size: 24, weight: .bold))
                                        .foregroundColor(.lyftText)
                                    
                                    Text("Create your first workout routine to get started")
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(.lyftTextSecondary)
                                        .multilineTextAlignment(.center)
                                }
                            }
                            
                            Button(action: { showingCreateRoutine = true }) {
                                HStack(spacing: 12) {
                                    Image(systemName: "plus.circle.fill")
                                        .font(.system(size: 18, weight: .medium))
                                    Text("Create Routine")
                                        .font(.system(size: 16, weight: .semibold))
                                }
                            }
                            .buttonStyle(LyftButtonStyle())
                            .padding(.horizontal, 40)
                            
                            Spacer()
                        }
                        .padding(.horizontal, 24)
                    } else {
                        // Routines List
                        ScrollView {
                            LazyVStack(spacing: 16) {
                                ForEach(routineStorage.routines) { routine in
                                    RoutineRowView(routine: routine, routineStorage: routineStorage)
                                }
                            }
                            .padding(.horizontal, 20)
                            .padding(.top, 20)
                        }
                    }
                }
            }
            .navigationTitle("Routines")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingCreateRoutine = true }) {
                        Image(systemName: "plus")
                            .foregroundColor(.lyftRed)
                            .font(.system(size: 18, weight: .medium))
                    }
                }
            }
            .sheet(isPresented: $showingCreateRoutine) {
                CreateRoutineView(routineStorage: routineStorage)
            }
            .onAppear {
                routineStorage.loadRoutinesFromFirebase()
                // Also sync any local routines to Firebase
                routineStorage.syncLocalRoutinesToFirebase()
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
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    Text(routine.name)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.lyftText)
                    
                    Text("\(routine.exercises.count) exercises")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.lyftTextSecondary)
                }
                
                Spacer()
            }
            
            HStack(spacing: 12) {
                Button(action: {
                    print("Edit button pressed")
                    showingRoutineDetail = true
                    showingWorkoutSession = false
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "pencil")
                            .font(.system(size: 14, weight: .medium))
                        Text("Edit")
                            .font(.system(size: 14, weight: .semibold))
                    }
                    .foregroundColor(.lyftRed)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(Color.lyftRed.opacity(0.1))
                    .cornerRadius(8)
                }
                .buttonStyle(PlainButtonStyle())
                
                Button(action: {
                    print("Start Workout button pressed")
                    showingWorkoutSession = true
                    showingRoutineDetail = false
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "play.fill")
                            .font(.system(size: 14, weight: .medium))
                        Text("Start Workout")
                            .font(.system(size: 14, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(Color.lyftRed)
                    .cornerRadius(8)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(.vertical, 20)
        .padding(.horizontal, 20)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 2)
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

struct EditableRoutineExerciseRow: View {
    @Binding var exercise: RoutineExercise
    let onDelete: () -> Void
    @State private var isEditing = false
    @State private var editedName = ""
    @State private var editedSets = 3
    @State private var showingDeleteAlert = false
    
    var body: some View {
        HStack {
            if isEditing {
                VStack(alignment: .leading, spacing: 8) {
                    TextField("Exercise name", text: $editedName)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    HStack {
                        Text("Sets:")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Stepper("\(editedSets)", value: $editedSets, in: 1...10)
                            .scaleEffect(0.8)
                    }
                }
                
                Spacer()
                
                HStack(spacing: 8) {
                    Button("Save") {
                        saveChanges()
                    }
                    .font(.caption)
                    .foregroundColor(.blue)
                    
                    Button("Cancel") {
                        cancelEdit()
                    }
                    .font(.caption)
                    .foregroundColor(.red)
                }
            } else {
                VStack(alignment: .leading, spacing: 4) {
                    Text(exercise.name)
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Text("\(exercise.defaultSets) sets")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                HStack(spacing: 8) {
                    Button("Edit") {
                        startEdit()
                    }
                    .font(.caption)
                    .foregroundColor(.blue)
                    
                    Button("Delete") {
                        showingDeleteAlert = true
                    }
                    .font(.caption)
                    .foregroundColor(.red)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(8)
        .alert("Delete Exercise", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                onDelete()
            }
        } message: {
            Text("Are you sure you want to delete '\(exercise.name)'?")
        }
    }
    
    private func startEdit() {
        editedName = exercise.name
        editedSets = exercise.defaultSets
        isEditing = true
    }
    
    private func cancelEdit() {
        isEditing = false
    }
    
    private func saveChanges() {
        exercise.name = editedName
        exercise.defaultSets = editedSets
        isEditing = false
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
    @State private var isEditing = false
    @State private var editedRoutineName = ""
    @State private var editedExercises: [RoutineExercise] = []
    @State private var showingAddExercise = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                if isEditing {
                    editModeView
                } else {
                    viewModeView
                }
            }
            .navigationTitle("Routine Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    if isEditing {
                        Button("Cancel") {
                            print("Cancel edit pressed")
                            cancelEdit()
                        }
                    } else {
                        Button("Done") {
                            print("Done button pressed - dismissing RoutineDetailView")
                            dismiss()
                        }
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    if isEditing {
                        Button("Save") {
                            saveChanges()
                        }
                        .disabled(editedRoutineName.isEmpty || editedExercises.isEmpty)
                    } else {
                        Button("Edit") {
                            startEdit()
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $showingAddExercise) {
            AddExerciseView { exercise in
                editedExercises.append(exercise)
            }
        }
    }
    
    private var viewModeView: some View {
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
        }
    }
    
    private var editModeView: some View {
        VStack(spacing: 0) {
            // Routine Name Input
            VStack(alignment: .leading, spacing: 8) {
                Text("Routine Name")
                    .font(.headline)
                    .padding(.horizontal, 20)
                
                TextField("Enter routine name", text: $editedRoutineName)
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
                
                if editedExercises.isEmpty {
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
                            ForEach(editedExercises.indices, id: \.self) { index in
                                EditableRoutineExerciseRow(
                                    exercise: $editedExercises[index],
                                    onDelete: {
                                        editedExercises.remove(at: index)
                                    }
                                )
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                }
            }
            
            Spacer()
        }
    }
    
    private func startEdit() {
        editedRoutineName = routine.name
        editedExercises = routine.exercises
        isEditing = true
    }
    
    private func cancelEdit() {
        isEditing = false
        editedRoutineName = ""
        editedExercises = []
    }
    
    private func saveChanges() {
        var updatedRoutine = routine
        updatedRoutine.name = editedRoutineName
        updatedRoutine.exercises = editedExercises
        routineStorage.saveRoutine(updatedRoutine)
        isEditing = false
    }
    
    private func deleteExercises(offsets: IndexSet) {
        editedExercises.remove(atOffsets: offsets)
    }
}

#Preview {
    RoutineBuilderView()
}
