//
//  AddExerciseToWorkoutView.swift
//  lyft-up
//
//  Created by Colin Chu on 8/1/25.
//

import SwiftUI

struct AddExerciseToWorkoutView: View {
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
                    }
                    .disabled(exerciseName.isEmpty)
                }
            }
        }
    }
}

#Preview {
    AddExerciseToWorkoutView { exercise in
        print("Added exercise: \(exercise.name)")
    }
}
