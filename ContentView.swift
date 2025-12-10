import ComposableArchitecture
import SwiftUI

// MARK: - Reducer

@Reducer
struct ESimManualEntryReducer {
    @ObservableState
    struct State: Sendable, Equatable {
        var lpa: String = ""
        var smdpAddress: String = ""
        var activationCode: String = ""
        var iosActivationUrl: String = ""
        var confirmationCode: String = ""
        var carrierName: String = ""
        var planLabel: String = ""
        var cardNumber: String = ""
        
        var isFormValid: Bool {
            !lpa.isEmpty &&
            !smdpAddress.isEmpty &&
            !activationCode.isEmpty &&
            !iosActivationUrl.isEmpty &&
            !confirmationCode.isEmpty &&
            !carrierName.isEmpty &&
            !planLabel.isEmpty &&
            !cardNumber.isEmpty
        }
        
        var createdData: ESimActivationData?
    }
    
    enum Action: Sendable, BindableAction {
        case binding(BindingAction<State>)
        case onSubmitTapped
        case onClearTapped
        case onDismiss
    }
    
    var body: some ReducerOf<Self> {
        BindingReducer()
        
        Reduce { state, action in
            switch action {
            case .binding:
                return .none
                
            case .onSubmitTapped:
                let data = ESimActivationData(
                    lpa: state.lpa,
                    smdpAddress: state.smdpAddress,
                    activationCode: state.activationCode,
                    iosActivationUrl: state.iosActivationUrl,
                    confirmationCode: state.confirmationCode,
                    carrierName: state.carrierName,
                    planLabel: state.planLabel,
                    cardNumber: state.cardNumber
                )
                state.createdData = data
                return .none
                
            case .onClearTapped:
                state.lpa = ""
                state.smdpAddress = ""
                state.activationCode = ""
                state.iosActivationUrl = ""
                state.confirmationCode = ""
                state.carrierName = ""
                state.planLabel = ""
                state.cardNumber = ""
                state.createdData = nil
                return .none
                
            case .onDismiss:
                return .none
            }
        }
    }
}

// MARK: - SwiftUI View

struct ESimManualEntryView: View {
    @Bindable var store: StoreOf<ESimManualEntryReducer>
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 8) {
                        Image(systemName: "simcard.fill")
                            .font(.system(size: 50))
                            .foregroundColor(.blue)
                        
                        Text("Ręczne wprowadzanie danych eSIM")
                            .font(.title2)
                            .fontWeight(.bold)
                            .multilineTextAlignment(.center)
                        
                        Text("Wypełnij wszystkie pola aby utworzyć konfigurację eSIM")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top)
                    
                    // Form Fields
                    VStack(spacing: 16) {
                        FormField(
                            title: "LPA",
                            placeholder: "np. test-lpa",
                            text: $store.lpa
                        )
                        
                        FormField(
                            title: "SMDP Address",
                            placeholder: "np. test-smdp",
                            text: $store.smdpAddress
                        )
                        
                        FormField(
                            title: "Activation Code",
                            placeholder: "np. test-code",
                            text: $store.activationCode
                        )
                        
                        FormField(
                            title: "iOS Activation URL",
                            placeholder: "np. https://test.esim.com/activate",
                            text: $store.iosActivationUrl,
                            keyboardType: .URL
                        )
                        
                        FormField(
                            title: "Confirmation Code",
                            placeholder: "np. 123456",
                            text: $store.confirmationCode,
                            keyboardType: .numberPad
                        )
                        
                        FormField(
                            title: "Carrier Name",
                            placeholder: "np. Test Carrier",
                            text: $store.carrierName
                        )
                        
                        FormField(
                            title: "Plan Label",
                            placeholder: "np. Test Plan",
                            text: $store.planLabel
                        )
                        
                        FormField(
                            title: "Card Number",
                            placeholder: "np. 1234567890",
                            text: $store.cardNumber,
                            keyboardType: .numberPad
                        )
                    }
                    .padding(.horizontal)
                    
                    // Buttons
                    VStack(spacing: 12) {
                        Button {
                            store.send(.onSubmitTapped)
                        } label: {
                            Text("Utwórz eSIM Data")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(store.isFormValid ? Color.blue : Color.gray)
                                .cornerRadius(12)
                        }
                        .disabled(!store.isFormValid)
                        
                        Button {
                            store.send(.onClearTapped)
                        } label: {
                            Text("Wyczyść formularz")
                                .font(.headline)
                                .foregroundColor(.red)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.red.opacity(0.1))
                                .cornerRadius(12)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom)
                }
            }
            .navigationTitle("Dane eSIM")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Zamknij") {
                        store.send(.onDismiss)
                    }
                }
            }
            .alert(
                "eSIM Data utworzone!",
                isPresented: .constant(store.createdData != nil)
            ) {
                Button("OK") {
                    // Możesz tu dodać akcję
                }
            } message: {
                if let data = store.createdData {
                    Text("""
                    Carrier: \(data.carrierName)
                    Plan: \(data.planLabel)
                    Card: \(data.cardNumber)
                    """)
                }
            }
        }
    }
}

// MARK: - Form Field Component

struct FormField: View {
    let title: String
    let placeholder: String
    @Binding var text: String
    var keyboardType: UIKeyboardType = .default
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            TextField(placeholder, text: $text)
                .textFieldStyle(.roundedBorder)
                .keyboardType(keyboardType)
                .autocapitalization(.none)
                .autocorrectionDisabled()
        }
    }
}

// MARK: - Alternative: Grouped Style View

struct ESimManualEntryGroupedView: View {
    @Bindable var store: StoreOf<ESimManualEntryReducer>
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Image(systemName: "simcard.fill")
                        .font(.system(size: 50))
                        .foregroundColor(.blue)
                        .frame(maxWidth: .infinity)
                        .padding()
                    
                    Text("Wypełnij wszystkie pola aby utworzyć konfigurację eSIM")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity)
                }
                .listRowBackground(Color.clear)
                
                Section("Informacje podstawowe") {
                    LabeledContent("LPA") {
                        TextField("test-lpa", text: $store.lpa)
                            .multilineTextAlignment(.trailing)
                    }
                    
                    LabeledContent("SMDP Address") {
                        TextField("test-smdp", text: $store.smdpAddress)
                            .multilineTextAlignment(.trailing)
                    }
                    
                    LabeledContent("Activation Code") {
                        TextField("test-code", text: $store.activationCode)
                            .multilineTextAlignment(.trailing)
                    }
                }
                
                Section("URL i kody") {
                    LabeledContent("iOS Activation URL") {
                        TextField("https://...", text: $store.iosActivationUrl)
                            .multilineTextAlignment(.trailing)
                            .keyboardType(.URL)
                    }
                    
                    LabeledContent("Confirmation Code") {
                        TextField("123456", text: $store.confirmationCode)
                            .multilineTextAlignment(.trailing)
                            .keyboardType(.numberPad)
                    }
                }
                
                Section("Informacje o operatorze") {
                    LabeledContent("Carrier Name") {
                        TextField("Test Carrier", text: $store.carrierName)
                            .multilineTextAlignment(.trailing)
                    }
                    
                    LabeledContent("Plan Label") {
                        TextField("Test Plan", text: $store.planLabel)
                            .multilineTextAlignment(.trailing)
                    }
                    
                    LabeledContent("Card Number") {
                        TextField("1234567890", text: $store.cardNumber)
                            .multilineTextAlignment(.trailing)
                            .keyboardType(.numberPad)
                    }
                }
                
                Section {
                    Button {
                        store.send(.onSubmitTapped)
                    } label: {
                        HStack {
                            Spacer()
                            Text("Utwórz eSIM Data")
                                .fontWeight(.semibold)
                            Spacer()
                        }
                    }
                    .disabled(!store.isFormValid)
                    
                    Button(role: .destructive) {
                        store.send(.onClearTapped)
                    } label: {
                        HStack {
                            Spacer()
                            Text("Wyczyść formularz")
                            Spacer()
                        }
                    }
                }
            }
            .navigationTitle("Dane eSIM")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Zamknij") {
                        store.send(.onDismiss)
                    }
                }
            }
            .alert(
                "eSIM Data utworzone!",
                isPresented: .constant(store.createdData != nil)
            ) {
                Button("OK") {
                    // Możesz tu dodać akcję
                }
            } message: {
                if let data = store.createdData {
                    Text("""
                    Carrier: \(data.carrierName)
                    Plan: \(data.planLabel)
                    Card: \(data.cardNumber)
                    """)
                }
            }
        }
    }
}

// MARK: - Preview

#Preview("Standard Style") {
    ESimManualEntryView(
        store: Store(
            initialState: ESimManualEntryReducer.State()
        ) {
            ESimManualEntryReducer()
        }
    )
}

#Preview("Grouped Style") {
    ESimManualEntryGroupedView(
        store: Store(
            initialState: ESimManualEntryReducer.State()
        ) {
            ESimManualEntryReducer()
        }
    )
}

#Preview("With Data") {
    ESimManualEntryView(
        store: Store(
            initialState: ESimManualEntryReducer.State(
                lpa: "test-lpa",
                smdpAddress: "test-smdp",
                activationCode: "test-code",
                iosActivationUrl: "https://test.esim.com/activate",
                confirmationCode: "123456",
                carrierName: "Test Carrier",
                planLabel: "Test Plan",
                cardNumber: "1234567890"
            )
        ) {
            ESimManualEntryReducer()
        }
    )
}

// MARK: - Integration Example

// Jak zintegrować z istniejącym reducerem:

extension ESimActivationReducer {
    @CasePathable
    enum Destination: Sendable {
        case esimNotSupported
        case activationSuccess
        case eSimPhoneSettings
        case activation(String)
        case manualEntry(ESimManualEntryReducer.State) // Dodaj to
    }
    
    enum Action: Sendable {
        // ... istniejące akcje
        case onShowManualEntry
        case manualEntry(ESimManualEntryReducer.Action) // Dodaj to
    }
    
    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            // ... istniejące case'y
            
            case .onShowManualEntry:
                state.destination = .manualEntry(ESimManualEntryReducer.State())
                return .none
                
            case .manualEntry(.onSubmitTapped):
                // Tutaj możesz pobrać utworzone dane
                if case let .manualEntry(manualState) = state.destination,
                   let createdData = manualState.createdData {
                    print("Utworzono dane: \(createdData)")
                    // Możesz teraz użyć tych danych do aktywacji
                }
                return .none
                
            case .manualEntry(.onDismiss):
                state.destination = nil
                return .none
                
            case .manualEntry:
                return .none
            }
        }
        .ifLet(\.destination, action: \.destination) {
            Scope(state: \.manualEntry, action: \.manualEntry) {
                ESimManualEntryReducer()
            }
        }
    }
}

// W widoku głównym:
struct MainView: View {
    let store: StoreOf<ESimActivationReducer>
    
    var body: some View {
        VStack {
            Button("Wprowadź dane ręcznie") {
                store.send(.onShowManualEntry)
            }
        }
        .sheet(
            item: $store.scope(
                state: \.destination?.manualEntry,
                action: \.manualEntry
            )
        ) { manualEntryStore in
            ESimManualEntryView(store: manualEntryStore)
        }
    }
}
