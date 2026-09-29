import SwiftUI

struct LoginView: View {
    @EnvironmentObject var store: DataStore
    @State private var email = ""
    @State private var password = ""
    @State private var loginError = ""
    @State private var showRegister = false

    var body: some View {
        ZStack {
            Color(.systemBackground).ignoresSafeArea()
            VStack(spacing: 0) {
                Spacer()

                Image("logo_sazon")
                    .resizable().scaledToFit().frame(height: 130).padding(.bottom, 28)

                VStack(spacing: 6) {
                    Text("¡Bienvenido a Sazón Express!")
                        .font(.title2).fontWeight(.bold).multilineTextAlignment(.center)
                    Text("Inicia sesión para continuar")
                        .font(.subheadline).foregroundColor(.secondary)
                }
                .padding(.bottom, 32)

                VStack(spacing: 12) {
                    TextField("Correo electrónico", text: $email)
                        .keyboardType(.emailAddress).autocapitalization(.none)
                        .padding(12).background(Color(.systemGray6)).cornerRadius(10)

                    SecureField("Contraseña", text: $password)
                        .padding(12).background(Color(.systemGray6)).cornerRadius(10)

                    if !loginError.isEmpty {
                        Text(loginError).font(.caption).foregroundColor(.red)
                    }

                    Button { handleLogin() } label: {
                        Text("Iniciar sesión")
                            .fontWeight(.semibold).foregroundColor(.white)
                            .frame(maxWidth: .infinity).frame(height: 50)
                            .background(Color.red).cornerRadius(12)
                    }

                    Button { showRegister = true } label: {
                        Text("Registrarse")
                            .fontWeight(.semibold).foregroundColor(.red)
                    }
                    .padding(.top, 4)
                }
                .padding(.horizontal, 28)

                Spacer()
            }
        }
        .sheet(isPresented: $showRegister) {
            RegisterView().environmentObject(store)
        }
    }

    func handleLogin() {
        guard !email.trimmingCharacters(in: .whitespaces).isEmpty else {
            loginError = "Ingresá tu correo electrónico."; return
        }
        guard email.contains("@") else {
            loginError = "El correo no es válido."; return
        }
        guard !password.isEmpty else {
            loginError = "Ingresá tu contraseña."; return
        }

        // Buscar usuario registrado
        if let user = store.findUser(email: email.lowercased()) {
            if user.password == password {
                loginError = ""
                store.loginUser(email: email.lowercased())
                store.saveUserName(user.name)
            } else {
                loginError = "Contraseña incorrecta."
            }
        } else {
            loginError = "No existe una cuenta con ese correo."
        }
    }
}

// MARK: - Register View
struct RegisterView: View {
    @EnvironmentObject var store: DataStore
    @Environment(\.dismiss) var dismiss

    @State private var name = ""
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var errorMsg = ""

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 16) {
                    Image("logo_sazon")
                        .resizable().scaledToFit().frame(height: 90).padding(.top, 20)

                    Text("Crear cuenta")
                        .font(.title2).fontWeight(.bold)

                    VStack(spacing: 12) {
                        TextField("Nombre completo", text: $name)
                            .padding(12).background(Color(.systemGray6)).cornerRadius(10)

                        TextField("Correo electrónico", text: $email)
                            .keyboardType(.emailAddress).autocapitalization(.none)
                            .padding(12).background(Color(.systemGray6)).cornerRadius(10)

                        SecureField("Contraseña (mín. 6 caracteres)", text: $password)
                            .padding(12).background(Color(.systemGray6)).cornerRadius(10)

                        SecureField("Confirmar contraseña", text: $confirmPassword)
                            .padding(12).background(Color(.systemGray6)).cornerRadius(10)
                    }

                    if !errorMsg.isEmpty {
                        Text(errorMsg).font(.caption).foregroundColor(.red).multilineTextAlignment(.center)
                    }

                    Button { handleRegister() } label: {
                        Text("Crear cuenta")
                            .fontWeight(.semibold).foregroundColor(.white)
                            .frame(maxWidth: .infinity).frame(height: 50)
                            .background(Color.red).cornerRadius(12)
                    }
                }
                .padding(.horizontal, 28)
            }
            .navigationTitle("Registro")
            .navigationBarItems(leading: Button("Cancelar") { dismiss() })
        }
    }

    func handleRegister() {
        guard !name.trimmingCharacters(in: .whitespaces).isEmpty else {
            errorMsg = "Ingresá tu nombre."; return
        }
        guard email.contains("@") && email.contains(".") else {
            errorMsg = "Ingresá un correo válido."; return
        }
        guard password.count >= 6 else {
            errorMsg = "La contraseña debe tener al menos 6 caracteres."; return
        }
        guard password == confirmPassword else {
            errorMsg = "Las contraseñas no coinciden."; return
        }
        guard store.findUser(email: email.lowercased()) == nil else {
            errorMsg = "Ya existe una cuenta con ese correo."; return
        }

        store.registerUser(name: name, email: email.lowercased(), password: password)
        store.loginUser(email: email.lowercased())
        store.saveUserName(name)
        dismiss()
    }
}
