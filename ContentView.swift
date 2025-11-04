import SwiftUI

struct BrandKPI: Identifiable {
    let id = UUID()
    let name: String
    let month: String
    let vsPY: String
    let vsPYColor: Color
    let mat: String
}

struct KPIView: View {
    let data: [BrandKPI] = [
        .init(name: "Novartis Brand", month: "6.7%", vsPY: "1.6 ppt", vsPYColor: .green, mat: "1.7 ppt"),
        .init(name: "Competitor B", month: "3.6%", vsPY: "-0.3 ppt", vsPYColor: .red, mat: "-0.4 ppt"),
        .init(name: "Competitor C", month: "3.6%", vsPY: "-0.3 ppt", vsPYColor: .red, mat: "-0.4 ppt"),
        .init(name: "Competitor D", month: "3.6%", vsPY: "-0.3 ppt", vsPYColor: .red, mat: "-0.4 ppt"),
        .init(name: "Competitor E", month: "3.6%", vsPY: "-0.3 ppt", vsPYColor: .red, mat: "-0.4 ppt"),
        .init(name: "Competitor F", month: "3.6%", vsPY: "-0.3 ppt", vsPYColor: .red, mat: "-0.4 ppt"),
    ]
    
    var body: some View {
        VStack(spacing: 0) {
            headerView()
            Divider()
            filterView()
            tableHeader()
            Divider()
            
            ForEach(data) { item in
                tableRow(for: item)
                Divider()
            }
            
            Spacer()
        }
        .background(Color(.systemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(radius: 4)
        .padding()
    }
}

extension KPIView {
    
    // MARK: - HEADER
    @ViewBuilder
    func headerView() -> some View {
        HStack {
            Text("Patient Share/US/Entresto")
                .font(.headline)
                .foregroundColor(.primary)
            Spacer()
            Button(action: {}) {
                Image(systemName: "xmark")
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color.white)
    }
    
    // MARK: - KPI FILTER MENU
    @ViewBuilder
    func filterView() -> some View {
        HStack {
            Menu {
                Button("KPI 1", action: {})
                Button("KPI 2", action: {})
            } label: {
                HStack {
                    Text("KPI +1")
                    Image(systemName: "chevron.down")
                        .font(.caption)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color(.systemGray6))
                .cornerRadius(10)
            }
            Spacer()
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }
    
    // MARK: - TABLE HEADER
    @ViewBuilder
    func tableHeader() -> some View {
        HStack {
            Text("Brand").bold().frame(maxWidth: .infinity, alignment: .leading)
            Text("Month\nActual")
                .font(.footnote)
                .multilineTextAlignment(.center)
                .frame(width: 80)
            Text("vs PY")
                .font(.footnote)
                .frame(width: 70)
            Text("MAT")
                .font(.footnote)
                .frame(width: 60)
        }
        .padding(.horizontal)
        .padding(.bottom, 6)
        .foregroundColor(.secondary)
    }
    
    // MARK: - TABLE ROW
    @ViewBuilder
    func tableRow(for item: BrandKPI) -> some View {
        HStack {
            Text(item.name)
                .frame(maxWidth: .infinity, alignment: .leading)
            Text(item.month)
                .frame(width: 80)
            Text(item.vsPY)
                .foregroundColor(item.vsPYColor)
                .frame(width: 70)
            Text(item.mat)
                .foregroundColor(item.vsPYColor)
                .frame(width: 60)
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }
}

#Preview {
    KPIView()
}
