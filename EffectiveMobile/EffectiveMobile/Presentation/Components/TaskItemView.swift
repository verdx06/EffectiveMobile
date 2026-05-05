import SwiftUI

struct TaskItemView: View {
    let item: Task
    let onToggle: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .top, spacing: 8) {
                Button(action: onToggle) {
                    Image(item.completed ? "completed" : "notcompleted")
                }
                .buttonStyle(.plain)

                VStack(alignment: .leading, spacing: 4) {
                    Text(item.todo)
                        .font(.system(size: 16))
                        .strikethrough(item.completed)
                        .foregroundStyle(item.completed ? .secondary : .primary)
                        .lineLimit(3)

                    Text("User ID: \(item.userId)")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}
