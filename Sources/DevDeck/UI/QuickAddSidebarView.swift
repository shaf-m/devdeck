import SwiftUI

struct QuickAddSidebarView: View {
    var onAdd: (Macro) -> Void
    var onClose: () -> Void
    
    @State private var searchText = ""
    @State private var selectedCategory: QuickAddCategory? = nil
    
    var filteredItems: [QuickAddRecommendation] {
        let items = QuickAddRecommendation.all
        
        if searchText.isEmpty && selectedCategory == nil {
            return items
        }
        
        return items.filter { item in
            let matchesText = searchText.isEmpty || item.label.localizedCaseInsensitiveContains(searchText)
            let matchesCategory = selectedCategory == nil || item.category == selectedCategory
            return matchesText && matchesCategory
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Quick Add")
                        .font(.title2)
                        .fontWeight(.bold)
                    Spacer()
                    Button(action: onClose) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                            .font(.title3)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 4)
                
                // Search
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    TextField("Search actions...", text: $searchText)
                        .textFieldStyle(PlainTextFieldStyle())
                }
                .padding(8)
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(8)
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.secondary.opacity(0.1)))
                
                // Category Filter (Horizontal Scroll)
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        FilterChip(label: "All", isSelected: selectedCategory == nil) {
                            selectedCategory = nil
                        }
                        
                        ForEach(QuickAddCategory.allCases, id: \.self) { category in
                            FilterChip(label: category.rawValue, isSelected: selectedCategory == category) {
                                selectedCategory = category
                            }
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor).opacity(0.5))
            
            Divider()
            
            // List
            List(filteredItems) { item in
                HStack(spacing: 12) {
                    // Icon Box
                    ZStack {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(
                                LinearGradient(
                                    colors: [.blue.opacity(0.1), .purple.opacity(0.1)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 36, height: 36)
                        
                        Image(systemName: item.iconName)
                            .font(.system(size: 16))
                            .foregroundColor(.blue)
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(item.label)
                            .font(.body)
                            .fontWeight(.medium)
                        
                        Text(item.category.rawValue)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Button(action: {
                        let newMacro = Macro(
                            label: item.label,
                            type: item.type,
                            value: item.value,
                            iconName: item.iconName
                        )
                        onAdd(newMacro)
                    }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title3)
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.blue, .purple],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    }
                    .buttonStyle(.plain)
                }
                .padding(.vertical, 4)
                .contentShape(Rectangle()) // Make whole row tappable if needed, or just draggable
                // Drag Support
                .onDrag {
                    let data: [String: Any] = [
                        "type": "macro_json",
                        "label": item.label,
                        "macroType": item.type.rawValue,
                        "value": item.value,
                        "iconName": item.iconName
                    ]
                    
                    if let jsonData = try? JSONSerialization.data(withJSONObject: data),
                       let jsonString = String(data: jsonData, encoding: .utf8) {
                        return NSItemProvider(object: jsonString as NSString)
                    }
                    return NSItemProvider(object: item.label as NSString)
                }
            }
            .listStyle(SidebarListStyle())
        }
        .frame(minWidth: 260)
        .background(Color(NSColor.windowBackgroundColor))
    }
}

struct FilterChip: View {
    let label: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.caption)
                .fontWeight(isSelected ? .semibold : .regular)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(
                    isSelected ?
                    LinearGradient(colors: [.blue, .purple], startPoint: .leading, endPoint: .trailing) :
                        LinearGradient(colors: [Color(NSColor.controlBackgroundColor)], startPoint: .leading, endPoint: .trailing)
                )
                .foregroundColor(isSelected ? .white : .primary)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(isSelected ? Color.clear : Color.secondary.opacity(0.2), lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }
}
