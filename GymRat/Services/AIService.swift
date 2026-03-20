import Foundation
import UIKit

// MARK: - Response Models
struct FoodAnalysis: Codable {
    let name: String
    let calories: Double
    let protein: Double
    let carbs: Double
    let fat: Double
    let servingSize: String
    let confidence: Double
    let notes: String
}

struct AIInsight: Identifiable {
    let id = UUID()
    let title: String
    let body: String
    let icon: String
    let category: InsightCategory

    enum InsightCategory {
        case workout, nutrition, sleep, general
    }
}

// MARK: - AI Service
@MainActor
class AIService: ObservableObject {
    static let shared = AIService()

    // Store your Claude API key here or in environment
    private var apiKey: String {
        // Load from UserDefaults for easy configuration
        UserDefaults.standard.string(forKey: "anthropic_api_key") ?? ""
    }

    private let baseURL = "https://api.anthropic.com/v1/messages"
    private let model = "claude-haiku-4-5-20251001"

    @Published var isLoading = false
    @Published var lastError: String?

    private init() {}

    // MARK: - Food Image Analysis
    func analyzeFoodImage(_ image: UIImage) async throws -> FoodAnalysis {
        guard !apiKey.isEmpty else {
            throw AIError.noAPIKey
        }

        // Resize to max 1024px on longest side to keep payload small
        let resized = resizeImage(image, maxDimension: 1024)
        guard let imageData = resized.jpegData(compressionQuality: 0.5) else {
            throw AIError.invalidImage
        }
        let base64Image = imageData.base64EncodedString()

        let prompt = """
        Analyze this food image and provide nutritional information.
        Respond ONLY with a valid JSON object in this exact format:
        {
            "name": "Food name",
            "calories": 350.0,
            "protein": 25.0,
            "carbs": 40.0,
            "fat": 12.0,
            "servingSize": "1 serving (approximately X grams)",
            "confidence": 0.85,
            "notes": "Brief notes about the estimation"
        }
        All nutritional values are per serving shown in the image. Be as accurate as possible.
        """

        let requestBody: [String: Any] = [
            "model": model,
            "max_tokens": 1024,
            "messages": [
                [
                    "role": "user",
                    "content": [
                        [
                            "type": "image",
                            "source": [
                                "type": "base64",
                                "media_type": "image/jpeg",
                                "data": base64Image
                            ]
                        ],
                        [
                            "type": "text",
                            "text": prompt
                        ]
                    ]
                ]
            ]
        ]

        let response = try await makeRequest(body: requestBody)
        return try parseFoodAnalysis(from: response)
    }

    // MARK: - Generate Insights
    func generateInsights(
        caloriesThisWeek: [Double],
        workoutsThisWeek: Int,
        avgSleepHours: Double,
        topExercises: [String]
    ) async throws -> [AIInsight] {
        guard !apiKey.isEmpty else {
            return defaultInsights(
                calories: caloriesThisWeek,
                workouts: workoutsThisWeek,
                sleep: avgSleepHours
            )
        }

        let prompt = """
        As a fitness coach AI, analyze this week's data and provide 3-4 personalized insights.

        Weekly data:
        - Calories (last 7 days): \(caloriesThisWeek.map { Int($0) })
        - Workouts completed: \(workoutsThisWeek)
        - Average sleep: \(String(format: "%.1f", avgSleepHours)) hours
        - Top exercises: \(topExercises.joined(separator: ", "))

        Respond ONLY with a JSON array:
        [
            {
                "title": "Insight title",
                "body": "Actionable insight (2-3 sentences)",
                "icon": "SF Symbol name",
                "category": "workout|nutrition|sleep|general"
            }
        ]
        Use motivating, specific language. Reference actual numbers from the data.
        """

        let requestBody: [String: Any] = [
            "model": model,
            "max_tokens": 1024,
            "messages": [
                ["role": "user", "content": prompt]
            ]
        ]

        let response = try await makeRequest(body: requestBody)
        return try parseInsights(from: response)
    }

    // MARK: - Workout Suggestion
    func suggestWorkout(recentExercises: [String], fitnessGoal: String = "general fitness") async throws -> String {
        guard !apiKey.isEmpty else {
            return "Set your Claude API key in Settings to get personalized workout suggestions."
        }

        let prompt = """
        As a personal trainer, suggest a workout for today.
        Recent exercises: \(recentExercises.joined(separator: ", "))
        Goal: \(fitnessGoal)

        Provide a concise workout plan (4-6 exercises) with sets and reps. Keep it under 150 words.
        """

        let requestBody: [String: Any] = [
            "model": model,
            "max_tokens": 512,
            "messages": [
                ["role": "user", "content": prompt]
            ]
        ]

        return try await makeRequest(body: requestBody)
    }

    // MARK: - Private Helpers
    private func resizeImage(_ image: UIImage, maxDimension: CGFloat) -> UIImage {
        let size = image.size
        let scale = min(maxDimension / size.width, maxDimension / size.height, 1.0)
        guard scale < 1.0 else { return image }
        let newSize = CGSize(width: size.width * scale, height: size.height * scale)
        let renderer = UIGraphicsImageRenderer(size: newSize)
        return renderer.image { _ in image.draw(in: CGRect(origin: .zero, size: newSize)) }
    }

    private func makeRequest(body: [String: Any]) async throws -> String {
        guard let url = URL(string: baseURL) else { throw AIError.invalidURL }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw AIError.invalidResponse
        }
        guard httpResponse.statusCode == 200 else {
            let errorMsg = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw AIError.apiError("Status \(httpResponse.statusCode): \(errorMsg)")
        }

        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let content = json["content"] as? [[String: Any]],
              let firstContent = content.first,
              let text = firstContent["text"] as? String else {
            throw AIError.invalidResponse
        }

        return text
    }

    private func parseFoodAnalysis(from text: String) throws -> FoodAnalysis {
        // Extract JSON from response
        let jsonStr = extractJSON(from: text) ?? text
        guard let data = jsonStr.data(using: .utf8) else { throw AIError.parseError }
        return try JSONDecoder().decode(FoodAnalysis.self, from: data)
    }

    private func parseInsights(from text: String) throws -> [AIInsight] {
        let jsonStr = extractJSONArray(from: text) ?? text
        guard let data = jsonStr.data(using: .utf8),
              let array = try JSONSerialization.jsonObject(with: data) as? [[String: Any]] else {
            throw AIError.parseError
        }

        return array.compactMap { dict in
            guard let title = dict["title"] as? String,
                  let body = dict["body"] as? String,
                  let icon = dict["icon"] as? String,
                  let categoryStr = dict["category"] as? String else { return nil }

            let category: AIInsight.InsightCategory = switch categoryStr {
            case "workout": .workout
            case "nutrition": .nutrition
            case "sleep": .sleep
            default: .general
            }

            return AIInsight(title: title, body: body, icon: icon, category: category)
        }
    }

    private func extractJSON(from text: String) -> String? {
        guard let start = text.range(of: "{"),
              let end = text.range(of: "}", options: .backwards) else { return nil }
        return String(text[start.lowerBound...end.upperBound])
    }

    private func extractJSONArray(from text: String) -> String? {
        guard let start = text.range(of: "["),
              let end = text.range(of: "]", options: .backwards) else { return nil }
        return String(text[start.lowerBound...end.upperBound])
    }

    // MARK: - Default Insights (offline mode)
    private func defaultInsights(calories: [Double], workouts: Int, sleep: Double) -> [AIInsight] {
        var insights: [AIInsight] = []

        let avgCalories = calories.isEmpty ? 0 : calories.reduce(0, +) / Double(calories.count)
        if avgCalories > 0 {
            if avgCalories > 2500 {
                insights.append(AIInsight(
                    title: "Calorie Check", body: "Your average daily intake is \(Int(avgCalories)) calories. Consider if this aligns with your goals.",
                    icon: "flame.fill", category: .nutrition))
            } else {
                insights.append(AIInsight(
                    title: "Nutrition on Track", body: "You're averaging \(Int(avgCalories)) calories daily. Keep up the consistent tracking!",
                    icon: "checkmark.circle.fill", category: .nutrition))
            }
        }

        if workouts >= 4 {
            insights.append(AIInsight(
                title: "Crushing It!", body: "\(workouts) workouts this week — you're in the top tier. Rest and recovery are equally important.",
                icon: "dumbbell.fill", category: .workout))
        } else if workouts > 0 {
            insights.append(AIInsight(
                title: "Keep Moving", body: "\(workouts) workout(s) logged. Aim for 4-5 sessions per week for optimal results.",
                icon: "figure.run", category: .workout))
        } else {
            insights.append(AIInsight(
                title: "Time to Train", body: "No workouts logged this week. Even a 20-minute session makes a difference!",
                icon: "exclamationmark.circle.fill", category: .workout))
        }

        if sleep < 6 {
            insights.append(AIInsight(
                title: "Prioritize Sleep", body: "You're averaging \(String(format: "%.1f", sleep))h of sleep. Aim for 7-9 hours for optimal recovery and muscle growth.",
                icon: "moon.zzz.fill", category: .sleep))
        } else if sleep >= 7 {
            insights.append(AIInsight(
                title: "Sleep Champion", body: "Great job getting \(String(format: "%.1f", sleep))h of sleep on average. Quality sleep fuels performance.",
                icon: "moon.stars.fill", category: .sleep))
        }

        return insights
    }
}

// MARK: - Error Types
enum AIError: LocalizedError {
    case noAPIKey, invalidImage, invalidURL, invalidResponse, apiError(String), parseError

    var errorDescription: String? {
        switch self {
        case .noAPIKey: return "No API key configured. Add your Claude API key in Settings."
        case .invalidImage: return "Could not process the image."
        case .invalidURL: return "Invalid API URL."
        case .invalidResponse: return "Invalid response from AI."
        case .apiError(let msg): return msg
        case .parseError: return "Could not parse AI response."
        }
    }
}
