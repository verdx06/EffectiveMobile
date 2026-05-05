import SwiftUI

struct TaskEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: TaskEditorViewModel
    @FocusState private var isFocused: Bool

    init(viewModel: @autoclosure @escaping () -> TaskEditorViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel())
    }

    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Button {
                    viewModel.save {
                        dismiss()
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                        Text("Назад")
                    }
                    .font(.system(size: 17))
                }
                .disabled(!viewModel.canSave || viewModel.isSaving)
                Spacer()
            }

            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
                    .font(.system(size: 12))
                    .foregroundStyle(.red)
            }

            TextEditor(text: $viewModel.title)
                .font(.system(size: 34, weight: .bold))
                .frame(height: 100)
                .scrollContentBackground(.hidden)
                .background(Color.clear)
                .focused($isFocused)

            if !viewModel.title.isEmpty {
                Text(viewModel.dateText)
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
            }

            TextEditor(text: $viewModel.subtitle)
                .font(.system(size: 16))
                .frame(minHeight: 100)
                .scrollContentBackground(.hidden)
                .background(Color.clear)
                .padding(.top, 5)

            Spacer()
        }
        .navigationBarBackButtonHidden()
        .padding(.horizontal)
        .padding(.top)
        .onAppear { isFocused = true }
    }
}
