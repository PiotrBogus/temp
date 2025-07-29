import SwiftUI

// Model
struct Tile: Identifiable {
    let id: UUID
    let title: String
    let parentId: String
}

// Sample Data
let sampleTiles: [Tile] = [
    Tile(id: UUID(), title: "Tile 1", parentId: "Group A"),
    Tile(id: UUID(), title: "Tile 2", parentId: "Group A"),
    Tile(id: UUID(), title: "Tile 3", parentId: "Group B"),
    Tile(id: UUID(), title: "Tile 4", parentId: "Group B"),
    Tile(id: UUID(), title: "Tile 5", parentId: "Group C"),
    Tile(id: UUID(), title: "Tile 6", parentId: "Group C")
]

// Grouping by parentId
func groupTiles(_ tiles: [Tile]) -> [String: [Tile]] {
    Dictionary(grouping: tiles, by: { $0.parentId })
}

// Dashboard View
struct DashboardView: View {
    let groupedTiles = groupTiles(sampleTiles)
    let columns = [GridItem(.flexible()), GridItem(.flexible())]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                ForEach(groupedTiles.sorted(by: { $0.key < $1.key }), id: \.key) { group, tiles in
                    VStack(alignment: .leading, spacing: 10) {
                        Text(group)
                            .font(.title2)
                            .bold()
                            .padding(.horizontal)

                        LazyVGrid(columns: columns, spacing: 16) {
                            ForEach(tiles) { tile in
                                TileView(tile: tile)
                            }
                        }
                        .padding(.horizontal)
                    }
                }
            }
            .padding(.vertical)
        }
    }
}

// Tile View
struct TileView: View {
    let tile: Tile

    var body: some View {
        VStack {
            Text(tile.title)
                .font(.headline)
                .padding()
                .frame(maxWidth: .infinity)
        }
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: .gray.opacity(0.2), radius: 4, x: 0, y: 2)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.gray.opacity(0.1), lineWidth: 1)
        )
    }
}

// Preview
struct DashboardView_Previews: PreviewProvider {
    static var previews: some View {
        DashboardView()
            .background(Color(.systemGroupedBackground))
    }
}
