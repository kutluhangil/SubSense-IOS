import SwiftUI

struct AuthFlowView: View {
    @State private var mode: AuthMode = .signIn

    enum AuthMode { case signIn, signUp }

    var body: some View {
        switch mode {
        case .signIn:
            SignInView(switchToSignUp: {
                withAnimation(Animation.spring(response: 0.4, dampingFraction: 0.8, blendDuration: 0)) {
                    mode = .signUp
                }
            })
        case .signUp:
            SignUpView(switchToSignIn: {
                withAnimation(Animation.spring(response: 0.4, dampingFraction: 0.8, blendDuration: 0)) {
                    mode = .signIn
                }
            })
        }
    }
}
