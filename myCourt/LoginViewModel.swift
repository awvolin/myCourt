////
////  Content-ViewModel.swift
////  myCourt
////
////  Created by Alex Volin on 6/22/23.
////
//
//import Foundation
//import SwiftUI
//import MapKit
//import CoreLocation
//
//class LoginViewModel: ObservableObject {
//    @AppStorage("AUTH_KEY") var authenticated = false {
//        willSet { objectWillChange.send() }
//    }
//    @AppStorage("USER_KEY") var username = ""
//    @Published var password = ""
//    @Published var invalid: Bool = false
//
//    private var sampleUser = "username"
//    private var samplePassword = "password"
//
//    init() {
//        print("Currently logged on: \(authenticated)")
//        print("Current user: \(username)")
//    }
//
//    func toggleAuthentication() {
//        self.password = ""
//        withAnimation {
//            authenticated.toggle()
//        }
//    }
//
//    func authenticate() {
//        guard self.username.lowercased() == sampleUser else {
//            self.invalid = true
//            return
//        }
//
//        guard self.password.lowercased() == samplePassword else {
//            self.invalid = true
//            return
//        }
//
//        print("Before authentication toggle: \(authenticated)")  // Debug line
//        toggleAuthentication()
//        print("After authentication toggle: \(authenticated)")
//    }
//
//    func logOut() {
//        toggleAuthentication()
//    }
//
//    func logPressed() {
//        print("Button pressed")
//    }
//}


//import AuthenticationServices
//import UIKit
//
//class LoginViewModel: UIViewController {
//    private let signInButton = ASAuthorizationAppleIDButton()
//
//    override func viewDidLoad() {
//        super.viewDidLoad()
//        view.addSubview(signInButton)
//        signInButton.addTarget(self, action: #selector(didTapSignIn), for: .touchUpInside)
//    }
//
//    override func viewDidLayoutSubviews() {
//        super.viewDidLayoutSubviews()
//        signInButton.frame = CGRect(x: 0, y: 0, width: 250, height: 50)
//        signInButton.center = view.center
//    }
//
//    @objc func didTapSignIn() {
//        let provider = ASAuthorizationPasswordProvider().self
//        let request = provider.createRequest()
//        request.requestedScopes = [.fullName, .email]
//
//        let controller = ASAuthorizationController(authorizationRequests: [request])
//        controller.delegate = self
//        controller.performRequests()
//    }
//
//    extension UIViewController
//}
//
//

import AuthenticationServices
import Combine

class LoginViewModel: NSObject, ObservableObject {
    @Published var isUserAuthenticated: Bool = false

    func handleAuthorizationAppleIDButtonPress() {
        let provider = ASAuthorizationAppleIDProvider()
        let request = provider.createRequest()
        request.requestedScopes = [.fullName, .email]

        let controller = ASAuthorizationController(authorizationRequests: [request])
        controller.delegate = self
        controller.presentationContextProvider = self
        controller.performRequests()
    }
}

extension LoginViewModel: ASAuthorizationControllerDelegate {
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
            // Here, you might want to send the authorization data to your server or save it locally
            DispatchQueue.main.async {
                self.isUserAuthenticated = true
            }
        }
    }

    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        // Handle error here
    }
}

extension LoginViewModel: ASAuthorizationControllerPresentationContextProviding {
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        return UIApplication.shared.windows.first!
    }
}

