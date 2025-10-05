//
//  AddTripView.swift
//  AdventureLogger
//

import SwiftUI
import CoreData

struct AddTripView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var description = ""
    @State private var startDate = Date()
    @State private var endDate = Date()

    var body: some View {
        NavigationView {
            Form {
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("New Trip")
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundColor(.primary)
                        Text("Create a new memory collection")
                            .font(.system(size: 15, weight: .regular, design: .rounded))
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 8)
                }

                Section(header: Text("Trip Details").font(.system(size: 14, weight: .semibold, design: .rounded))) {
                    TextField("Trip Name", text: $name)
                        .font(.system(size: 16, design: .rounded))

                    TextField("Description (optional)", text: $description, axis: .vertical)
                        .font(.system(size: 16, design: .rounded))
                        .lineLimit(3...6)
                }

                Section(header: Text("Dates").font(.system(size: 14, weight: .semibold, design: .rounded))) {
                    DatePicker("Start Date", selection: $startDate, displayedComponents: .date)
                        .font(.system(size: 16, design: .rounded))

                    DatePicker("End Date", selection: $endDate, in: startDate..., displayedComponents: .date)
                        .font(.system(size: 16, design: .rounded))
                }

                Section {
                    Button(action: saveTrip) {
                        HStack {
                            Spacer()
                            Text("Create Trip")
                                .font(.system(size: 17, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                            Spacer()
                        }
                        .padding(.vertical, 12)
                        .background(
                            LinearGradient(
                                colors: [Color(hex: "667eea"), Color(hex: "764ba2")],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .cornerRadius(12)
                    }
                    .disabled(name.isEmpty)
                    .opacity(name.isEmpty ? 0.6 : 1.0)
                    .listRowInsets(EdgeInsets())
                }
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }

    private func saveTrip() {
        let newTrip = Trip(context: viewContext)
        newTrip.id = UUID()
        newTrip.name = name
        newTrip.tripDescription = description.isEmpty ? nil : description
        newTrip.startDate = startDate
        newTrip.endDate = endDate
        newTrip.createdAt = Date()
        newTrip.updatedAt = Date()

        do {
            try viewContext.save()
            dismiss()
        } catch {
            let nsError = error as NSError
            print("Error saving trip: \(nsError), \(nsError.userInfo)")
        }
    }
}

#Preview {
    AddTripView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
