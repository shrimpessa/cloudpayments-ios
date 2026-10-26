//
//  CloudpaymentsURLSessionNetworkDispatcher.swift
//  Cloudpayments
//
//  Created by Sergey Iskhakov on 01.07.2021.
//

import Foundation
import Security

private final class CloudpaymentsTrustBundleToken: NSObject {}

public enum CloudpaymentsTrustedSession {
    
    private static let delegate = TrustDelegate()
    
    public static let shared: URLSession = {
        URLSession(
            configuration: .default,
            delegate: delegate,
            delegateQueue: nil
        )
    }()
    
    private final class TrustDelegate: NSObject, URLSessionDelegate {
        
        func urlSession(
            _ session: URLSession,
            didReceive challenge: URLAuthenticationChallenge,
            completionHandler: @escaping (
                URLSession.AuthChallengeDisposition,
                URLCredential?
            ) -> Void
        ) {
            
            guard
                challenge.protectionSpace.authenticationMethod
                    == NSURLAuthenticationMethodServerTrust,
                let serverTrust = challenge.protectionSpace.serverTrust
            else {
                completionHandler(
                    .performDefaultHandling,
                    nil
                )
                return
            }
            
            let host = challenge.protectionSpace.host
            
            if CloudpaymentsTrustEvaluator.evaluate(
                serverTrust: serverTrust,
                host: host
            ) {
                completionHandler(
                    .useCredential,
                    URLCredential(trust: serverTrust)
                )
            } else {
                completionHandler(
                    .cancelAuthenticationChallenge,
                    nil
                )
            }
        }
    }
}

internal enum CloudpaymentsTrustEvaluator {
    
    static func evaluate(
        serverTrust: SecTrust,
        host: String
    ) -> Bool {
        
        var systemError: CFError?
        
        if SecTrustEvaluateWithError(
            serverTrust,
            &systemError
        ) {
            print("TRUST: system trust OK for \(host)")
            return true
        }
        
        print(
            "TRUST: system trust FAILED for \(host), error = \(String(describing: systemError))"
        )
        
        let certificates = loadRussianTrustedCertificates()
        
        print(
            "TRUST: loaded Russian certificates = \(certificates.count)"
        )
        
        guard !certificates.isEmpty else {
            print("TRUST: Russian certificates NOT FOUND")
            return false
        }
        
        let policy = SecPolicyCreateSSL(
            true,
            host as CFString
        )
        
        let policyStatus = SecTrustSetPolicies(
            serverTrust,
            policy
        )
        
        guard policyStatus == errSecSuccess else {
            print(
                "TRUST: SecTrustSetPolicies failed = \(policyStatus)"
            )
            return false
        }
        
        let anchorStatus = SecTrustSetAnchorCertificates(
            serverTrust,
            certificates as CFArray
        )
        
        guard anchorStatus == errSecSuccess else {
            print(
                "TRUST: SecTrustSetAnchorCertificates failed = \(anchorStatus)"
            )
            return false
        }
        
        SecTrustSetAnchorCertificatesOnly(
            serverTrust,
            false
        )
        
        var russianTrustError: CFError?
        
        let result = SecTrustEvaluateWithError(
            serverTrust,
            &russianTrustError
        )
        
        if result {
            print(
                "TRUST: Russian CA trust OK for \(host)"
            )
        } else {
            print(
                "TRUST: Russian CA trust FAILED for \(host), error = \(String(describing: russianTrustError))"
            )
        }
        
        return result
    }
    
    // MARK: - Certificates
    
    private static func loadRussianTrustedCertificates()
    -> [SecCertificate] {
        
        let names = [
            "Russian_Trusted_Root_CA",
            "Russian_Trusted_Sub_CA_1",
            "Russian_Trusted_Sub_CA_2"
        ]
        
        var result: [SecCertificate] = []
        
        for name in names {
            if let certificate = loadCertificate(
                named: name
            ) {
                result.append(certificate)
            } else {
                print(
                    "TRUST: certificate NOT FOUND: \(name).cer"
                )
            }
        }
        
        return result
    }
    
    private static func loadCertificate(
        named name: String
    ) -> SecCertificate? {
        
        let bundles = candidateBundles()
        
        for bundle in bundles {
            
            print(
                "TRUST: searching \(name).cer in \(bundle.bundlePath)"
            )
            
            if let url = bundle.url(
                forResource: name,
                withExtension: "cer"
            ) {
                
                print(
                    "TRUST: found \(name).cer at \(url.path)"
                )
                
                guard let data = try? Data(
                    contentsOf: url
                ) else {
                    print(
                        "TRUST: can't read \(url.path)"
                    )
                    continue
                }
                
                guard let certificate =
                        SecCertificateCreateWithData(
                            nil,
                            data as CFData
                        )
                else {
                    print(
                        "TRUST: invalid certificate data: \(url.path)"
                    )
                    continue
                }
                
                return certificate
            }
        }
        
        return nil
    }
    
    private static func candidateBundles() -> [Bundle] {
        
        var bundles: [Bundle] = []
        
#if SWIFT_PACKAGE
        print(
            "TRUST: SPM Bundle.module = \(Bundle.module.bundlePath)"
        )
        
        bundles.append(
            Bundle.module
        )
#endif
        
        let frameworkBundle = Bundle(
            for: CloudpaymentsTrustBundleToken.self
        )
        
        print(
            "TRUST: framework bundle = \(frameworkBundle.bundlePath)"
        )
        
        print(
            "TRUST: main bundle = \(Bundle.main.bundlePath)"
        )
        
        bundles.append(
            frameworkBundle
        )
        
        bundles.append(
            .main
        )
        
        let possibleBundleNames = [
            "CloudpaymentsNetworkingResources",
            "CloudpaymentsNetworking",
            "Cloudpayments",
            "org.cocoapods.CloudpaymentsNetworking"
        ]
        
        for parentBundle in [
            frameworkBundle,
            Bundle.main
        ] {
            for bundleName in possibleBundleNames {
                
                if let url = parentBundle.url(
                    forResource: bundleName,
                    withExtension: "bundle"
                ),
                   let bundle = Bundle(url: url) {
                    
                    print(
                        "TRUST: found nested bundle = \(bundle.bundlePath)"
                    )
                    
                    bundles.append(
                        bundle
                    )
                }
            }
        }
        
        var unique: [Bundle] = []
        var paths = Set<String>()
        
        for bundle in bundles {
            
            if paths.insert(
                bundle.bundlePath
            ).inserted {
                
                print(
                    "TRUST: candidate bundle = \(bundle.bundlePath)"
                )
                
                unique.append(
                    bundle
                )
            }
        }
        
        return unique
    }
}


public protocol CloudpaymentsNetworkDispatcher {
    func dispatch(request: CloudpaymentsRequest,
                  onSuccess: @escaping (Data) -> Void,
                  onError: @escaping (Error) -> Void,
                  onRedirect: ((URLRequest) -> Bool)?)
    
    func dispatchWithStatusCode(request: CloudpaymentsRequest,
                                onSuccess: @escaping (Int, Data) -> Void,
                                onError: @escaping (Error, Int) -> Void,
                                onRedirect: ((URLRequest) -> Bool)?)
}

public class CloudpaymentsURLSessionNetworkDispatcher: NSObject, CloudpaymentsNetworkDispatcher {
    private lazy var session = URLSession(configuration: .default, delegate: self, delegateQueue: .main)
    
    public static let instance = CloudpaymentsURLSessionNetworkDispatcher()
    
    private var onRedirect: ((URLRequest) -> Bool)?
    
    public func dispatch(request: CloudpaymentsRequest,
                         onSuccess: @escaping (Data) -> Void,
                         onError: @escaping (Error) -> Void,
                         onRedirect: ((URLRequest) -> Bool)? = nil) {
        self.onRedirect = onRedirect
        
        guard let url = URL(string: request.path) else {
            onError(CloudpaymentsConnectionError.invalidURL)
            return
        }
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = request.method.rawValue
        
        if let body = request.body {
            urlRequest.httpBody = body
            print("[dispatch] Используется кастомный body (Data), длина: \(body.count) байт")
        } else if request.method != .get && !request.params.isEmpty {
            do {
                urlRequest.httpBody = try JSONSerialization.data(withJSONObject: request.params, options: [])
                print("[dispatch] Сериализованное тело из params: \(request.params)")
                if let json = String(data: urlRequest.httpBody ?? Data(), encoding: .utf8) {
                    print("------------>>>>> Final JSON:\n\(json)")
                }
            } catch let error {
                print("[dispatch] Ошибка сериализации параметров: \(error.localizedDescription)")
                onError(error)
                return
            }
        } else {
            print("[dispatch] Метод \(request.method.rawValue) — тело запроса не добавляется.")
        }
        
        var headers = request.headers
        if headers["User-Agent"] == nil {
            headers["User-Agent"] = "Mobile_SDK_iOS"
        }
        headers["Content-Type"] = headers["Content-Type"] ?? "application/json"
        urlRequest.allHTTPHeaderFields = headers
        
        print("[dispatch] Заголовки запроса: \(urlRequest.allHTTPHeaderFields ?? [:])")
        print("[dispatch] \(request.method) → \(urlRequest.url?.absoluteString ?? "")")
        
        session.dataTask(with: urlRequest) { (data, response, error) in
            if let error = error {
                print("[dispatch] Ошибка: \(error.localizedDescription)")
                onError(error)
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse {
                print("[dispatch] HTTP Status Code: \(httpResponse.statusCode)")
                print("[dispatch] HTTP Headers: \(httpResponse.allHeaderFields)")
            }
            
            guard let data = data else {
                print("[dispatch] Нет данных в ответе")
                onError(CloudpaymentsConnectionError.noData)
                return
            }
            
            onSuccess(data)
        }.resume()
    }
    
    public func dispatchWithStatusCode(request: CloudpaymentsRequest,
                                       onSuccess: @escaping (Int, Data) -> Void,
                                       onError: @escaping (Error, Int) -> Void,
                                       onRedirect: ((URLRequest) -> Bool)? = nil) {
        performRequest(request: request, returnStatusCode: true, onSuccess: onSuccess, onError: onError, onRedirect: onRedirect)
    }
    
    private func performRequest(request: CloudpaymentsRequest,
                                returnStatusCode: Bool,
                                onSuccess: @escaping (Int, Data) -> Void,
                                onError: @escaping (Error, Int) -> Void,
                                onRedirect: ((URLRequest) -> Bool)? = nil) {
        guard let url = URL(string: request.path) else {
            onError(CloudpaymentsConnectionError.invalidURL, 0)
            return
        }
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = request.method.rawValue
        
        if !request.params.isEmpty {
            urlRequest.httpBody = try? JSONSerialization.data(withJSONObject: request.params, options: [])
        }
        
        var headers = request.headers
        headers["Content-Type"] = "application/json"
        headers["User-Agent"] = "Mobile_SDK_iOS"
        urlRequest.allHTTPHeaderFields = headers
        
        session.dataTask(with: urlRequest) { (data, response, error) in
            if let error = error {
                onError(error, 0)
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                onError(CloudpaymentsConnectionError.noData, 0)
                return
            }
            
            let statusCode = httpResponse.statusCode
            guard let data = data else {
                onError(CloudpaymentsConnectionError.noData, statusCode)
                return
            }
            
            if returnStatusCode {
                onSuccess(statusCode, data)
            } else {
                onSuccess(0, data)
            }
        }.resume()
    }
}

extension CloudpaymentsURLSessionNetworkDispatcher: URLSessionTaskDelegate {
    public func urlSession(_ session: URLSession, task: URLSessionTask, willPerformHTTPRedirection response: HTTPURLResponse, newRequest request: URLRequest, completionHandler: @escaping (URLRequest?) -> Void) {
        if let _ = onRedirect?(request) {
            completionHandler(request)
        } else {
            completionHandler(nil)
        }
    }
}

extension CloudpaymentsURLSessionNetworkDispatcher: URLSessionDelegate {
    public func urlSession(
        _ session: URLSession,
        didReceive challenge: URLAuthenticationChallenge,
        completionHandler: @escaping (
            URLSession.AuthChallengeDisposition,
            URLCredential?
        ) -> Void
    ) {
        guard
            challenge.protectionSpace.authenticationMethod ==
                NSURLAuthenticationMethodServerTrust,
            let serverTrust = challenge.protectionSpace.serverTrust
        else {
            completionHandler(.performDefaultHandling, nil)
            return
        }
        
        let host = challenge.protectionSpace.host
        
        if CloudpaymentsTrustEvaluator.evaluate(
            serverTrust: serverTrust,
            host: host
        ) {
            completionHandler(
                .useCredential,
                URLCredential(trust: serverTrust)
            )
        } else {
            completionHandler(
                .cancelAuthenticationChallenge,
                nil
            )
        }
    }
}
