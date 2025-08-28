import SwiftUI

struct MasonryGrid<Content: View, T: Identifiable>: View {
    let items: [T]
    let columns: Int
    let spacing: CGFloat
    let content: (T) -> Content
    
    init(items: [T], columns: Int = 2, spacing: CGFloat = 16, @ViewBuilder content: @escaping (T) -> Content) {
        self.items = items
        self.columns = columns
        self.spacing = spacing
        self.content = content
    }
    
    var body: some View {
        GeometryReader { geometry in
            let columnWidth = (geometry.size.width - CGFloat(columns - 1) * spacing) / CGFloat(columns)
            
            HStack(alignment: .top, spacing: spacing) {
                ForEach(0..<columns, id: \.self) { columnIndex in
                    LazyVStack(spacing: spacing) {
                        ForEach(itemsForColumn(columnIndex)) { item in
                            content(item)
                                .frame(width: columnWidth)
                        }
                    }
                }
            }
        }
    }
    
    private func itemsForColumn(_ columnIndex: Int) -> [T] {
        return items.enumerated().compactMap { index, item in
            index % columns == columnIndex ? item : nil
        }
    }
}