import SwiftUI
import UIKit

struct StatsView: View {
    @ObservedObject var vm: GroceryViewModel

    @State private var showCamera = false
    @State private var selectedImage: UIImage?
    @State private var extractedText = ""

    var monthlyTotal: Double {
        let calendar = Calendar.current

        return vm.shoppingSessions
            .filter {
                calendar.isDate($0.date, equalTo: Date(), toGranularity: .month)
            }
            .reduce(0) { $0 + $1.total }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppBackground()

                ScrollView {
                    VStack(spacing: 18) {
                        Button {
                            hideKeyboard()
                            showCamera = true
                        } label: {
                            Label("Scan Receipt", systemImage: "doc.text.viewfinder")
                                .font(.system(size: 17, weight: .semibold))
                                .frame(maxWidth: .infinity)
                                .frame(height: 52)
                                .background(Color.blue)
                                .foregroundStyle(.white)
                                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        }

                        Text("Monthly Overview")
                            .font(.headline)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        StatCard(
                            title: "Monthly Spending",
                            value: monthlyTotal.formatted(.currency(code: "EUR")),
                            icon: "calendar"
                        )

                        Text("Shopping History")
                            .font(.headline)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.top, 10)

                        if vm.shoppingSessions.isEmpty {
                            Text("No shopping sessions yet.")
                                .foregroundStyle(.secondary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        } else {
                            ForEach(vm.shoppingSessions) { session in
                                StatCard(
                                    title: session.date.formatted(date: .abbreviated, time: .shortened),
                                    value: session.total.formatted(.currency(code: "EUR")),
                                    icon: "bag.fill"
                                )
                            }
                        }

                        if !extractedText.isEmpty {
                            Text("Extracted Receipt Text")
                                .font(.headline)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.top, 10)

                            Text(extractedText)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding()
                                .background(Color(.systemGray6))
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                        }
                    }
                    .padding(20)
                }
            }
            .hideKeyboardOnTap()
            .navigationTitle("Stats")
            .onAppear {
                vm.fetchShoppingSessions()
            }
            .sheet(isPresented: $showCamera) {
                ImagePicker(selectedImage: $selectedImage)
            }
            .onChange(of: selectedImage) { oldValue, image in
                if let image {
                    hideKeyboard()

                    vm.extractText(from: image) { text in
                        extractedText = text

                        if let total = vm.extractTotalAmount(from: text) {
                            vm.saveShoppingSession(total: total)
                            vm.fetchShoppingSessions()
                        } else {
                            print("No total amount found")
                        }
                    }
                }
            }
        }
    }
}
