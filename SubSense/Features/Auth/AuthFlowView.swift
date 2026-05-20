import SwiftUI

struct AuthFlowView: View {
    @State private var mode: AuthMode = .signIn

    enum AuthMode { case signIn, signUp }

    var body: some View {
        switch mode {
        case .signIn:
            SignInView(switchToSignUp: {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    mode = .signUp
                }
            })
        case .signUp:
            SignUpView(switchToSignIn: {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    mode = .signIn
                }
            })
        }
    }
}
