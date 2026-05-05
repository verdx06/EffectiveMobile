import SwiftUI

struct MainView: View {
    @StateObject var viewModel: MainViewModel
    @State var isAddPresented = false
    @State var selectedTask: Task?

    private let taskEditorUseCase: TaskEditorUseCase

    init(
        viewModel: @autoclosure @escaping () -> MainViewModel,
        taskEditorUseCase: TaskEditorUseCase
    ) {
        _viewModel = StateObject(wrappedValue: viewModel())
        self.taskEditorUseCase = taskEditorUseCase
    }

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 0) {
                CustomTextField(text: $viewModel.searchText)
                    .padding(.horizontal)
                    .padding(.bottom, 12)

                if viewModel.isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity, alignment: .center)
                } else if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                        .foregroundStyle(.red)
                        .padding(.horizontal)
                } else {
                    tasks
                        .padding(.horizontal)
                }

                Spacer(minLength: 0)
                bottomPanel
            }
            .navigationTitle("Задачи")
            .navigationDestination(isPresented: $isAddPresented, destination: {
                TaskEditorView(
                    viewModel: TaskEditorViewModel(
                        mode: .create,
                        useCase: taskEditorUseCase,
                        onSaved: { viewModel.loadTasks() }
                    )
                )
            })
            .navigationDestination(item: $selectedTask, destination: { task in
                TaskEditorView(
                    viewModel: TaskEditorViewModel(
                        mode: .edit(task),
                        useCase: taskEditorUseCase,
                        onSaved: { viewModel.loadTasks() }
                    )
                )
            })
        }
        .task {
            if viewModel.tasks.isEmpty {
                viewModel.loadTasks()
            }
        }
    }
}

private extension MainView {
    var tasks: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 10) {
                ForEach(viewModel.filteredTasks) { item in
                    TaskItemView(item: item) {
                        withAnimation {
                            viewModel.toggleCompleted(id: item.id)
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        selectedTask = item
                    }
                    .contextMenu {
                        Button {
                            selectedTask = item
                        } label: {
                            Label("Редактировать", systemImage: "square.and.pencil")
                        }
                        
                        Button(role: .destructive) {
                            withAnimation {
                                viewModel.deleteTask(id: item.id)
                            }
                        } label: {
                            Label("Удалить", systemImage: "trash")
                        }
                    }
                    
                    Divider()
                }
            }
        }
        .refreshable {
            viewModel.loadTasks()
        }
    }
    
    var bottomPanel: some View {
        ZStack(alignment: .top) {
            Rectangle()
                .ignoresSafeArea(edges: .bottom)
                .foregroundStyle(Color(.secondarySystemBackground))
                .frame(maxWidth: .infinity)
                .frame(height: 49)
            
            HStack {
                Spacer()
                Text("\(viewModel.tasks.count) Задач")
                    .foregroundStyle(.primary)
                Spacer()
                Button {
                    isAddPresented = true
                } label: {
                    Image("newzapis")
                }
            }
            .padding(.top)
            .padding(.horizontal)
        }
    }
}

#Preview {
    let repository = TaskRepositoryImpl(networkService: NetworkServiceImpl())

    MainView(
        viewModel: MainViewModel(
            useCase: MainUseCaseImpl(
                repository: repository
            )
        ),
        taskEditorUseCase: TaskEditorUseCaseImpl(repository: repository)
    )
}
