import SwiftUI
import AVFoundation
import PhotosUI

struct CameraFoodView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var capturedImage: UIImage?
    @State private var showImagePicker = false
    @State private var showAnalysis = false
    @State private var analysisResult: FoodAnalysis?
    @State private var isAnalyzing = false
    @State private var errorMessage: String?
    @State private var selectedMeal: MealType = .lunch
    @State private var photoItem: PhotosPickerItem?

    var body: some View {
        ZStack {
            Color.gymBackground.ignoresSafeArea()

            if let image = capturedImage {
                // Analysis view
                ScrollView {
                    VStack(spacing: 20) {
                        // Image preview
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                            .frame(height: 260)
                            .clipped()
                            .cornerRadius(20)
                            .padding(.horizontal)

                        if isAnalyzing {
                            VStack(spacing: 14) {
                                ProgressView()
                                    .tint(.gymGreen)
                                    .scaleEffect(1.4)
                                Text("AI is analyzing your meal...")
                                    .font(.system(size: 15, weight: .medium))
                                    .foregroundStyle(.white.opacity(0.7))
                                Text("Estimating calories, protein, carbs & fat")
                                    .font(.system(size: 12))
                                    .foregroundStyle(.white.opacity(0.4))
                            }
                            .padding(.vertical, 30)
                        } else if let error = errorMessage {
                            VStack(spacing: 12) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .font(.system(size: 32))
                                    .foregroundStyle(.gymOrange)
                                Text(error)
                                    .font(.system(size: 13))
                                    .foregroundStyle(.white.opacity(0.6))
                                    .multilineTextAlignment(.center)
                                Button("Try Manually") { dismiss() }
                                    .foregroundStyle(.gymPrimary)
                            }
                            .padding()
                        } else if let result = analysisResult {
                            FoodAnalysisResultView(
                                result: result,
                                selectedMeal: $selectedMeal,
                                onSave: { saveFood(result) },
                                onRetake: {
                                    capturedImage = nil
                                    analysisResult = nil
                                    errorMessage = nil
                                }
                            )
                        }

                        Spacer(minLength: 40)
                    }
                    .padding(.top, 20)
                }
            } else {
                // Camera / Photo picker UI
                VStack(spacing: 30) {
                    Spacer()
                    Image(systemName: "camera.viewfinder")
                        .font(.system(size: 80))
                        .foregroundStyle(
                            LinearGradient(colors: [.gymGreen, .gymPrimary],
                                           startPoint: .topLeading, endPoint: .bottomTrailing)
                        )
                    VStack(spacing: 8) {
                        Text("Snap Your Meal")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundStyle(.white)
                        Text("AI will identify the food and\nestimate the nutritional values")
                            .font(.system(size: 14))
                            .foregroundStyle(.white.opacity(0.5))
                            .multilineTextAlignment(.center)
                    }
                    Spacer()

                    VStack(spacing: 12) {
                        // Camera button
                        Button {
                            showImagePicker = true
                        } label: {
                            HStack(spacing: 14) {
                                Image(systemName: "camera.fill")
                                    .font(.system(size: 20))
                                Text("Take Photo")
                                    .font(.system(size: 17, weight: .bold))
                            }
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(LinearGradient.gymGreenGrad)
                            .cornerRadius(16)
                            .shadow(color: .gymGreen.opacity(0.4), radius: 10, y: 4)
                        }
                        .padding(.horizontal)

                        // Photo library
                        PhotosPicker(selection: $photoItem, matching: .images) {
                            HStack(spacing: 14) {
                                Image(systemName: "photo.on.rectangle")
                                    .font(.system(size: 18))
                                Text("Choose from Library")
                                    .font(.system(size: 16, weight: .semibold))
                            }
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color.gymCard)
                            .cornerRadius(16)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
                            )
                        }
                        .padding(.horizontal)
                    }
                    .padding(.bottom, 40)
                }
            }

            // Close button
            VStack {
                HStack {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 30))
                            .foregroundStyle(.white.opacity(0.6))
                            .background(Color.black.opacity(0.3))
                            .clipShape(Circle())
                    }
                    .padding(.leading, 20)
                    .padding(.top, 60)
                    Spacer()
                }
                Spacer()
            }
        }
        .sheet(isPresented: $showImagePicker) {
            CameraPickerView(image: $capturedImage)
        }
        .onChange(of: capturedImage) { _, newImage in
            if let img = newImage { Task { await analyzeImage(img) } }
        }
        .onChange(of: photoItem) { _, item in
            Task {
                if let data = try? await item?.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {
                    capturedImage = image
                }
            }
        }
    }

    private func analyzeImage(_ image: UIImage) async {
        isAnalyzing = true
        errorMessage = nil
        do {
            analysisResult = try await AIService.shared.analyzeFoodImage(image)
        } catch {
            errorMessage = error.localizedDescription
        }
        isAnalyzing = false
    }

    private func saveFood(_ result: FoodAnalysis) {
        let food = FoodEntry(
            name: result.name,
            calories: result.calories,
            protein: result.protein,
            carbs: result.carbs,
            fat: result.fat,
            mealType: selectedMeal.rawValue
        )
        modelContext.insert(food)
        dismiss()
    }
}

// MARK: - Analysis Result View
struct FoodAnalysisResultView: View {
    let result: FoodAnalysis
    @Binding var selectedMeal: MealType
    let onSave: () -> Void
    let onRetake: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            // Food name & confidence
            VStack(spacing: 6) {
                HStack {
                    Text(result.name)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(.white)
                    Spacer()
                    HStack(spacing: 4) {
                        Image(systemName: "brain.head.profile")
                            .font(.system(size: 12))
                        Text("\(Int(result.confidence * 100))% confident")
                            .font(.system(size: 12, weight: .medium))
                    }
                    .foregroundStyle(.gymGreen)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Color.gymGreen.opacity(0.12))
                    .cornerRadius(20)
                }
                if !result.servingSize.isEmpty {
                    HStack {
                        Text(result.servingSize)
                            .font(.system(size: 12))
                            .foregroundStyle(.white.opacity(0.45))
                        Spacer()
                    }
                }
            }
            .padding(.horizontal)

            // Macro cards
            HStack(spacing: 10) {
                NutrientBadge(label: "Calories", value: "\(Int(result.calories))", unit: "kcal", color: .gymOrange)
                NutrientBadge(label: "Protein",  value: "\(Int(result.protein))",  unit: "g",    color: .gymPrimary)
                NutrientBadge(label: "Carbs",    value: "\(Int(result.carbs))",    unit: "g",    color: .gymYellow)
                NutrientBadge(label: "Fat",      value: "\(Int(result.fat))",      unit: "g",    color: .gymPurple)
            }
            .padding(.horizontal)

            if !result.notes.isEmpty {
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "info.circle")
                        .font(.system(size: 13))
                        .foregroundStyle(.white.opacity(0.4))
                    Text(result.notes)
                        .font(.system(size: 12))
                        .foregroundStyle(.white.opacity(0.5))
                }
                .padding(12)
                .background(Color.gymCard)
                .cornerRadius(12)
                .padding(.horizontal)
            }

            // Meal type picker
            VStack(alignment: .leading, spacing: 10) {
                Text("Add to Meal")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.6))
                    .padding(.horizontal)
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(MealType.allCases, id: \.self) { meal in
                            Button { selectedMeal = meal } label: {
                                HStack(spacing: 6) {
                                    Image(systemName: meal.icon)
                                    Text(meal.rawValue)
                                }
                                .font(.system(size: 12, weight: selectedMeal == meal ? .bold : .medium))
                                .foregroundStyle(selectedMeal == meal ? .white : .white.opacity(0.6))
                                .padding(.horizontal, 14)
                                .padding(.vertical, 8)
                                .background(selectedMeal == meal ? meal.color : Color.gymCard)
                                .cornerRadius(20)
                            }
                        }
                    }
                    .padding(.horizontal)
                }
            }

            // Action buttons
            HStack(spacing: 12) {
                Button(action: onRetake) {
                    Text("Retake")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.gymCard)
                        .cornerRadius(14)
                }
                Button(action: onSave) {
                    Text("Save Food")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(LinearGradient.gymGreenGrad)
                        .cornerRadius(14)
                }
            }
            .padding(.horizontal)
        }
    }
}

struct NutrientBadge: View {
    let label: String
    let value: String
    let unit: String
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(color)
            Text(unit)
                .font(.system(size: 10))
                .foregroundStyle(.white.opacity(0.4))
            Text(label)
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(.white.opacity(0.55))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(color.opacity(0.1))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(color.opacity(0.2), lineWidth: 1)
        )
    }
}

// MARK: - Camera Picker (UIImagePickerController wrapper)
struct CameraPickerView: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    @Environment(\.dismiss) private var dismiss

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = UIImagePickerController.isSourceTypeAvailable(.camera) ? .camera : .photoLibrary
        picker.allowsEditing = false
        return picker
    }

    func updateUIViewController(_ vc: UIImagePickerController, context: Context) {}

    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: CameraPickerView
        init(_ parent: CameraPickerView) { self.parent = parent }

        func imagePickerController(_ picker: UIImagePickerController,
                                   didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            parent.image = info[.originalImage] as? UIImage
            parent.dismiss()
        }
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}
