import SwiftUI

struct SavedPlacesView: View {
    private enum ClearTarget: String, Identifiable {
        case favourites
        case history

        var id: Self { self }
    }

    @Environment(\.dismiss) private var dismiss
    @State private var favouriteBeingRenamed: LocationTarget?
    @State private var favouriteName = ""
    @State private var clearTarget: ClearTarget?

    let favourites: [LocationTarget]
    let history: [LocationTarget]
    let isFavourite: (LocationTarget) -> Bool
    let onSelect: (LocationTarget) -> Void
    let onToggleFavourite: (LocationTarget) -> Void
    let onDeleteFavourite: (LocationTarget) -> Void
    let onRenameFavourite: (LocationTarget, String) -> Void
    let onDeleteHistory: (LocationTarget) -> Void
    let onClearFavourites: () -> Void
    let onClearHistory: () -> Void

    var body: some View {
        NavigationStack {
            List {
                Section {
                    if favourites.isEmpty {
                        EmptySavedPlacesRow(
                            symbol: "heart",
                            message: "点击所选地点旁的爱心即可收藏。"
                        )
                    } else {
                        ForEach(favourites) { location in
                            SavedPlaceRow(
                                location: location,
                                symbol: "heart.fill",
                                isFavourite: true,
                                onSelect: { select(location) },
                                onToggleFavourite: { onToggleFavourite(location) }
                            )
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    onDeleteFavourite(location)
                                } label: {
                                    Label("删除", systemImage: "trash")
                                }

                                Button {
                                    beginRenaming(location)
                                } label: {
                                    Label("重命名", systemImage: "pencil")
                                }
                                .tint(.blue)
                            }
                        }
                    }
                } header: {
                    HStack {
                        Text("收藏")
                        Spacer()
                        if !favourites.isEmpty {
                            Button("清除") {
                                clearTarget = .favourites
                            }
                            .textCase(nil)
                        }
                    }
                }

                Section {
                    if history.isEmpty {
                        EmptySavedPlacesRow(
                            symbol: "clock",
                            message: "你使用过的地点会显示在这里。"
                        )
                    } else {
                        ForEach(history) { location in
                            SavedPlaceRow(
                                location: location,
                                symbol: "clock.fill",
                                isFavourite: isFavourite(location),
                                onSelect: { select(location) },
                                onToggleFavourite: { onToggleFavourite(location) }
                            )
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    onDeleteHistory(location)
                                } label: {
                                    Label("删除", systemImage: "trash")
                                }
                            }
                        }
                    }
                } header: {
                    HStack {
                        Text("历史记录")
                        Spacer()
                        if !history.isEmpty {
                            Button("清除") {
                                clearTarget = .history
                            }
                                .textCase(nil)
                        }
                    }
                }
            }
            .navigationTitle("已保存地点")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("完成") { dismiss() }
                }
            }
            .alert(
                "重命名收藏",
                isPresented: Binding(
                    get: { favouriteBeingRenamed != nil },
                    set: { if !$0 { favouriteBeingRenamed = nil } }
                )
            ) {
                TextField("收藏名称", text: $favouriteName)
                Button("取消", role: .cancel) {
                    favouriteBeingRenamed = nil
                }
                Button("保存") {
                    guard let favouriteBeingRenamed else { return }
                    onRenameFavourite(favouriteBeingRenamed, favouriteName)
                    self.favouriteBeingRenamed = nil
                }
                .disabled(favouriteName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            } message: {
                Text("为这个已保存地点设置一个容易识别的名称。")
            }
            .confirmationDialog(
                clearConfirmationTitle,
                isPresented: Binding(
                    get: { clearTarget != nil },
                    set: { if !$0 { clearTarget = nil } }
                ),
                titleVisibility: .visible
            ) {
                Button(clearConfirmationButton, role: .destructive) {
                    performClear()
                }
                Button("取消", role: .cancel) {
                    clearTarget = nil
                }
            } message: {
                Text(clearConfirmationMessage)
            }
        }
    }

    private func select(_ location: LocationTarget) {
        onSelect(location)
        dismiss()
    }

    private func beginRenaming(_ location: LocationTarget) {
        favouriteName = location.name
        favouriteBeingRenamed = location
    }

    private var clearConfirmationTitle: String {
        switch clearTarget {
        case .favourites: "清除全部收藏？"
        case .history: "清除位置历史记录？"
        case nil: "清除已保存地点？"
        }
    }

    private var clearConfirmationButton: String {
        switch clearTarget {
        case .favourites: "清除收藏"
        case .history: "清除历史记录"
        case nil: "清除"
        }
    }

    private var clearConfirmationMessage: String {
        switch clearTarget {
        case .favourites: "所有收藏都会被移除，但历史记录会保留。"
        case .history: "所有最近使用的位置都会被移除，但收藏会保留。"
        case nil: "此操作无法撤销。"
        }
    }

    private func performClear() {
        switch clearTarget {
        case .favourites:
            onClearFavourites()
        case .history:
            onClearHistory()
        case nil:
            break
        }
        clearTarget = nil
    }
}

private struct SavedPlaceRow: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    let location: LocationTarget
    let symbol: String
    let isFavourite: Bool
    let onSelect: () -> Void
    let onToggleFavourite: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Button(action: onSelect) {
                HStack(spacing: 12) {
                    Image(systemName: symbol)
                        .foregroundStyle(symbol.hasPrefix("heart") ? .pink : .blue)
                        .frame(width: 24)

                    VStack(alignment: .leading, spacing: 3) {
                        Text(location.name)
                            .foregroundStyle(.primary)
                            .lineLimit(dynamicTypeSize.isAccessibilitySize ? 2 : 1)
                        Text(location.subtitle)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(dynamicTypeSize.isAccessibilitySize ? 2 : 1)
                    }

                    Spacer()
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(locationAccessibilityLabel)
            .accessibilityHint("选择此位置")

            Button(action: onToggleFavourite) {
                Image(systemName: isFavourite ? "heart.fill" : "heart")
                    .foregroundStyle(isFavourite ? .pink : .secondary)
                    .frame(width: 44, height: 44)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(isFavourite ? "从收藏中移除" : "添加到收藏")
        }
    }

    private var locationAccessibilityLabel: String {
        guard !location.subtitle.isEmpty else { return location.name }
        return "\(location.name), \(location.subtitle)"
    }
}

private struct EmptySavedPlacesRow: View {
    let symbol: String
    let message: String

    var body: some View {
        Label(message, systemImage: symbol)
            .font(.subheadline)
            .foregroundStyle(.secondary)
            .padding(.vertical, 8)
    }
}
