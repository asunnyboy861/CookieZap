import SwiftUI

struct ContactSupportView: View {
    @State private var selectedSubject: String = "General"
    @State private var customSubject: String = ""
    @State private var name: String = ""
    @State private var email: String = ""
    @State private var message: String = ""
    @State private var isSubmitting = false
    @State private var showAlert = false
    @State private var alertMessage = ""

    private let subjects = [
        "General",
        "Feature Suggestion",
        "Bug Report",
        "Usage Question",
        "Performance Issue",
        "UI Improvement",
        "Other"
    ]

    private var effectiveSubject: String {
        selectedSubject == "Other" ? customSubject : selectedSubject
    }

    private var canSubmit: Bool {
        !name.isEmpty &&
        !email.isEmpty &&
        !message.isEmpty &&
        (selectedSubject != "Other" || !customSubject.isEmpty)
    }

    var body: some View {
        Form {
            subjectSection
            nameSection
            emailSection
            messageSection
            submitSection
        }
        .navigationTitle("Contact Us")
        .alert(isPresented: $showAlert) {
            Alert(title: Text(alertMessage.contains("Success") ? "Thank You!" : "Oops"),
                  message: Text(alertMessage),
                  dismissButton: .default(Text("OK")) {
                    if alertMessage.contains("Success") {
                        resetForm()
                    }
                  })
        }
    }

    private var subjectSection: some View {
        Section("Subject") {
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                ForEach(subjects, id: \.self) { subject in
                    Button {
                        withAnimation(.easeInOut(duration: 0.15)) {
                            selectedSubject = subject
                        }
                    } label: {
                        Text(subject)
                            .font(.subheadline)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .frame(maxWidth: .infinity)
                            .background(selectedSubject == subject ? Color.blue : Color(.systemGray5))
                            .foregroundStyle(selectedSubject == subject ? .white : .primary)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    .buttonStyle(.plain)
                }
            }

            if selectedSubject == "Other" {
                TextField("Describe your topic", text: $customSubject)
                    .textInputAutocapitalization(.sentences)
            }
        }
    }

    private var nameSection: some View {
        Section {
            TextField("Your name", text: $name)
                .textInputAutocapitalization(.words)
        }
    }

    private var emailSection: some View {
        Section {
            TextField("your@email.com", text: $email)
                .textInputAutocapitalization(.never)
                .keyboardType(.emailAddress)
                .autocorrectionDisabled()
        }
    }

    private var messageSection: some View {
        Section {
            TextEditor(text: $message)
                .frame(minHeight: 120)
        } header: {
            Text("Message")
        }
    }

    private var submitSection: some View {
        Section {
            Button(action: submitFeedback) {
                if isSubmitting {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                } else {
                    Text("Submit Feedback")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                }
            }
            .disabled(!canSubmit || isSubmitting)
        }
    }

    private func submitFeedback() {
        guard canSubmit else { return }
        isSubmitting = true

        let request = FeedbackRequest(
            name: name,
            email: email,
            subject: effectiveSubject,
            message: message,
            app_name: Constants.appName
        )

        guard let url = URL(string: Constants.feedbackURL) else {
            alertMessage = "Invalid server URL"
            showAlert = true
            isSubmitting = false
            return
        }

        var requestURL = URLRequest(url: url)
        requestURL.httpMethod = "POST"
        requestURL.setValue("application/json", forHTTPHeaderField: "Content-Type")

        do {
            requestURL.httpBody = try JSONEncoder().encode(request)
        } catch {
            alertMessage = "Failed to encode request"
            showAlert = true
            isSubmitting = false
            return
        }

        URLSession.shared.dataTask(with: requestURL) { _, response, error in
            DispatchQueue.main.async {
                isSubmitting = false
                if let error = error {
                    alertMessage = "Network error: \(error.localizedDescription)"
                } else if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                    alertMessage = "Success! Your feedback has been submitted."
                } else {
                    alertMessage = "Failed to submit. Please try again later."
                }
                showAlert = true
            }
        }.resume()
    }

    private func resetForm() {
        selectedSubject = "General"
        customSubject = ""
        name = ""
        email = ""
        message = ""
    }
}

struct FeedbackRequest: Codable {
    let name: String
    let email: String
    let subject: String
    let message: String
    let app_name: String
}
