import CloudpaymentsNetworking
import Foundation
import UIKit

public class CloudpaymentsApi {
    public static let baseURLString = "https://api.cloudpayments.ru/"
    public static let baseIntentURLString = "https://intent-api.cloudpayments.ru/"
    private let threeDsSuccessURL = "https://cloudpayments.ru/success"
    private let threeDsFailURL = "https://cloudpayments.ru/fail"
    private let publicId: String
    private let apiUrl: String
        
    init(publicId: String, apiUrl: String = baseURLString) {
        self.publicId = publicId
        
        if (apiUrl.isEmpty) {
            self.apiUrl = CloudpaymentsApi.baseURLString
        } else {
            self.apiUrl = apiUrl
        }
    }
    
    public class func getBankInfo(cardNumber: String,
                                  completion: ((_ bankInfo: BankInfo?, _ error: CloudpaymentsError?) -> ())?) {
        let cleanCardNumber = Card.cleanCreditCardNo(cardNumber)
        guard cleanCardNumber.count >= 6 else {
            completion?(nil, CloudpaymentsError.init(message: "You must specify at least the first 6 digits of the card number"))
            return
        }
        
        let firstSixIndex = cleanCardNumber.index(cleanCardNumber.startIndex, offsetBy: 6)
        let firstSixDigits = String(cleanCardNumber[..<firstSixIndex])
        
        BankInfoRequest(firstSix: firstSixDigits).execute(keyDecodingStrategy: .convertToUpperCamelCase, onSuccess: { response in
            completion?(response.model, nil)
        }, onError: { error in
            if !error.localizedDescription.isEmpty  {
                completion?(nil, CloudpaymentsError.init(message: error.localizedDescription))
            } else {
                completion?(nil, CloudpaymentsError.defaultCardError)
            }
        })
    }
    
   public class func getBinInfoWithIntentId(cleanCardNumber: String,
                                             with configuration: PaymentConfiguration,
                                             completion: @escaping (BankInfo?, Bool?) -> Void) {
        
        guard let intentId = configuration.paymentData.intentId else {
            completion(nil, false)
            return
        }
        
        var firstSixDigits: String? = nil
        
        if cleanCardNumber.count >= 6 {
            let firstSixIndex = cleanCardNumber.index(cleanCardNumber.startIndex, offsetBy: 6)
            firstSixDigits = String(cleanCardNumber[..<firstSixIndex])
        }
        
        let queryItems = [
            "PaymentMethod": "Card",
            "Bin": firstSixDigits,
        ] as [String: String?]
        
        let request = BinInfoRequestWithIntentId(intentId: intentId, queryItems: queryItems, apiUrl: baseIntentURLString)
        
        request.execute { result in
            completion(result, true)
            
            LoggerService.shared.logApiRequest(method: request.data.method.rawValue, url: request.data.path, success: true)
            
        } onError: { error in
            print(error)
            completion(nil, false)
            
            LoggerService.shared.logApiRequest(method: request.data.method.rawValue, url: request.data.path, success: false)
        }
    }
    
    public class func getSbpLinkIntentApi(puid: String,
                                          schema: String,
                                          configuration: PaymentConfiguration,
                                          completion handler: @escaping (Int?, String?) -> Void) {
        var queryItems = [
            "webview": "false",
            "puid": puid
        ]
        
        if !schema.isEmpty {
            queryItems["schema"] = schema
        }
        
        guard let sbpLink = configuration.paymentData.paymentLinks["Sbp"] else {
            print("[getSbpLinkIntentApi] Ссылка Sbp отсутствует в paymentLinks")
            handler(nil, nil)
            return
        }
        
        print("[getSbpLinkIntentApi] Ссылка Sbp: \(sbpLink)")
        
        let request = SbpLinkRequestIntent(queryItems: queryItems, params: [:], apiUrl: sbpLink)
        
        print("[getSbpLinkIntentApi] Формируем запрос с URL: \(sbpLink)")
        print("[getSbpLinkIntentApi] Query Items: \(queryItems)")
        
        request.executeWithStatusCode { statusCode, resultLink in
            print("[getSbpLinkIntentApi] Получена ссылка: \(resultLink)")
            
            handler(statusCode, resultLink)
            
            LoggerService.shared.logApiRequest(method: request.data.method.rawValue, url: request.data.path, success: true)
            
        } onError: { statusCode, error in
            handler(statusCode, nil)
            
            LoggerService.shared.logApiRequest(method: request.data.method.rawValue, url: request.data.path, success: false)
        }
    }
    
    public class func intentPatchById(configuration: PaymentConfiguration,
                                      patches: [[String: Any]],
                                      completion: @escaping (PaymentIntentResponse?) -> Void) {
        guard let intentId = configuration.paymentData.intentId else {
            print("PATCH: intentId отсутствует")
            completion(nil)
            return
        }
        
        guard let bodyData = try? JSONSerialization.data(withJSONObject: patches, options: []) else {
            print("PATCH: не удалось сериализовать JSON")
            completion(nil)
            return
        }
        
        var headers: [String: String] = [
            "Content-Type": "application/json-patch+json"
        ]
        
        if let secret = configuration.paymentData.secret {
            headers["Secret"] = secret
        }
        
        let request = IntentPatchById(
            patchBody: bodyData,
            intentId: intentId,
            apiUrl: baseIntentURLString,
            headers: headers
        )
        
        print("PATCH: отправка запроса")
        print("PATCH: \(patches)")
        
        request.execute { result in
            
            print("PATCH: ответ получен")
            
            completion(result)
            
            LoggerService.shared.logApiRequest(method: request.data.method.rawValue, url: request.data.path, success: true)
            
        } onError: { error in
            
            print("PATCH: ошибка: \(error.localizedDescription)")
            completion(nil)
            
            LoggerService.shared.logApiRequest(method: request.data.method.rawValue, url: request.data.path, success: false)
        }
    }
    
    public class func createIntent(with configuration: PaymentConfiguration,
                                   paymentMethodSequence: [String],
                                   completion handler: @escaping (PaymentIntentResponse?) -> Void) {
        
        let publicId = configuration.publicId
        let currency = configuration.paymentData.currency
        let sсheme: IntentScheme = configuration.useDualMessagePayment ? .dual : .single
        let type = "Default"
        let scenario = "7"
        let amount = configuration.paymentData.amount
        let accountId = configuration.paymentData.accountId
        let email = configuration.paymentData.email
        let paymentUrl = "cloudpayments://sdk.cp.ru"
        let payer = configuration.paymentData.payer
        let recurrent = configuration.paymentData.recurrent?.toDictionary()
        let receipt = configuration.paymentData.receipt
        let successRedirectUrl = configuration.successRedirectUrl
        let failRedirectUrl = configuration.failRedirectUrl
        let invoiceId = configuration.paymentData.invoiceId
        let description = configuration.paymentData.description
        
        let metadata: [String: Any]? = {
            if let jsonString = configuration.paymentData.jsonData,
               let data = jsonString.data(using: .utf8) {
                return (try? JSONSerialization.jsonObject(with: data)) as? [String: Any]
            }
            return nil
        }()
        
        let params: [String: Any?] = [
            "publicTerminalId": publicId,
            "currency": currency,
            "paymentSchema": sсheme.rawValue,
            "culture": "RU-ru",
            "type": type,
            "scenario": scenario,
            "amount": amount,
            "paymentUrl": paymentUrl,
            "receiptEmail": email,
            "externalId": invoiceId,
            "description": description,
            "userInfo": [
                "accountId": accountId,
                "firstName": payer?.firstName,
                "lastName": payer?.lastName,
                "middleName": payer?.middleName,
                "address": payer?.address,
                "street": payer?.street,
                "city": payer?.city,
                "country": payer?.country,
                "phone": payer?.phone,
                "postcode": payer?.postcode
            ],
            "paymentMethodSequence": paymentMethodSequence,
            "recurrent": recurrent,
            "receipt": receipt,
            "metadata": metadata,
            "successRedirectUrl": successRedirectUrl,
            "failRedirectUrl":  failRedirectUrl
            
        ] as [String : Any?]
        
        let request = CreateIntentRequest(params: params,
                                          apiUrl: baseIntentURLString)
        request.execute { result in
            handler(result)
            LoggerService.shared.logApiRequest(method: request.data.method.rawValue, url: request.data.path, success: true)
        } onError: { error in
            print("createIntent error:", error.localizedDescription)
            handler(nil)
            LoggerService.shared.logApiRequest(method: request.data.method.rawValue, url: request.data.path, success: false)
        }
    }
    
    public class func getTPayLinkIntentApi(puid: String,
                                           configuration: PaymentConfiguration,
                                           completion handler: @escaping (Int?, String?) -> Void) {
        let queryItems = [
            "webview": "false",
            "puid": puid
        ]
        
        guard let tpayLink = configuration.paymentData.paymentLinks["TinkoffPay"] else {
            print("[getTPayLinkIntentApi] Ссылка TinkoffPay отсутствует в paymentLinks")
            handler(nil, nil)
            return
        }
        
        print("[getTPayLinkIntentApi] Ссылка TinkoffPay: \(tpayLink)")
        
        let request = TPayLinkRequestIntent(queryItems: queryItems, params: [:], apiUrl: tpayLink)
        
        print("[getTPayLinkIntentApi] Формируем запрос с URL: \(tpayLink)")
        print("[getTPayLinkIntentApi] Query Items: \(queryItems)")
        
        request.executeWithStatusCode { statusCode, resultLink in
            print("[getTPayLinkIntentApi] Получена ссылка: \(resultLink)")
            handler(statusCode, resultLink)
            
            LoggerService.shared.logApiRequest(method: request.data.method.rawValue, url: request.data.path, success: true)
            
        } onError: { statusCode, error in
            handler(statusCode, nil)
            LoggerService.shared.logApiRequest(method: request.data.method.rawValue, url: request.data.path, success: false)
        }
    }
    
    public class func getSberPayLinkIntentApi(puid: String,
                                              configuration: PaymentConfiguration,
                                              completion handler: @escaping (Int?, SberPayResponse?) -> Void) {
        let queryItems = [
            "webview": "false",
            "puid": puid
        ]
        
        guard let sberPayLink = configuration.paymentData.sberPayData else {
            print("[getSberPayLinkIntentApi] Ссылка SberPay отсутствует в paymentLinks")
            handler(nil, nil)
            return
        }
        
        print("[getSberPayLinkIntentApi] Ссылка SberPay: \(sberPayLink)")
        
        let request = SberPayLinkRequestIntent(queryItems: queryItems, params: [:], apiUrl: sberPayLink)
        
        print("[getSberPayLinkIntentApi] Формируем запрос с URL: \(sberPayLink)")
        print("[getSberPayLinkIntentApi] Query Items: \(queryItems)")
        
        request.executeWithStatusCode { statusCode, resultLink in
            print("[getSberPayLinkIntentApi] Получена ссылка: \(resultLink)")
            handler(statusCode, resultLink)
            
            LoggerService.shared.logApiRequest(method: request.data.method.rawValue, url: request.data.path, success: true)
            
        } onError: { statusCode, error in
            print("[getSberPayLinkIntentApi] Ошибка выполнения запроса SberPayLinkRequestIntent: \(error.localizedDescription)")
            handler(statusCode, nil)
            
            LoggerService.shared.logApiRequest(method: request.data.method.rawValue, url: request.data.path, success: false)
        }
    }
    
    public class func getDolyameLinkIntentApi(puid: String,
                                           configuration: PaymentConfiguration,
                                           completion handler: @escaping (Int?, String?) -> Void) {
        let queryItems = [
            "webview": "false",
            "puid": puid
        ]
        
        guard let dolyameLink = configuration.paymentData.paymentLinks["Dolyame"] else {
            print("[getDolyameLinkIntentApi] Ссылка Dolyame отсутствует в paymentLinks")
            handler(nil, nil)
            return
        }
        
        print("[getDolyameLinkIntentApi] Ссылка Dolyame: \(dolyameLink)")
        
        let request = DolyameLinkRequestIntent(queryItems: queryItems, params: [:], apiUrl: dolyameLink)
        
        print("[getDolyameLinkIntentApi] Формируем запрос с URL: \(dolyameLink)")
        print("[getDolyameLinkIntentApi] Query Items: \(queryItems)")
        
        request.executeWithStatusCode { statusCode, resultLink in
            print("[getDolyameLinkIntentApi] Получена ссылка: \(resultLink)")
            handler(statusCode, resultLink)
            
            LoggerService.shared.logApiRequest(method: request.data.method.rawValue, url: request.data.path, success: true)
            
        } onError: { statusCode, error in
            handler(statusCode, nil)
            LoggerService.shared.logApiRequest(method: request.data.method.rawValue, url: request.data.path, success: false)
        }
    }
    
    public class func getDRLinkIntentApi(puid: String,
                                           configuration: PaymentConfiguration,
                                           completion handler: @escaping (Int?, String?) -> Void) {
        let queryItems = [
            "webview": "false",
            "puid": puid
        ]
        
        guard let drLink = configuration.paymentData.paymentLinks["DR"] else {
            print("[getDRLinkIntentApi] Ссылка DR отсутствует в paymentLinks")
            handler(nil, nil)
            return
        }
        
        print("[getDRLinkIntentApi] Ссылка DR: \(drLink)")
        
        let request = DRLinkRequestIntent(queryItems: queryItems, params: [:], apiUrl: drLink)
        
        print("[getDRLinkIntentApi] Формируем запрос с URL: \(drLink)")
        print("[getDRLinkIntentApi] Query Items: \(queryItems)")
        
        request.executeWithStatusCode { statusCode, resultLink in
            print("[getDRLinkIntentApi] Получена ссылка: \(resultLink)")
            handler(statusCode, resultLink)
            
            LoggerService.shared.logApiRequest(method: request.data.method.rawValue, url: request.data.path, success: true)
            
        } onError: { statusCode, error in
            handler(statusCode, nil)
            LoggerService.shared.logApiRequest(method: request.data.method.rawValue, url: request.data.path, success: false)
        }
    }
    
    public class func getTInstallmentLinkIntentApi(puid: String,
                                           period: String?,
                                           configuration: PaymentConfiguration,
                                           completion handler: @escaping (Int?, String?) -> Void) {
        let queryItems = [
            "webview": "false",
            "puid": puid,
            "period": period
        ]
        
        guard let tInstallmentLink = configuration.paymentData.paymentLinks["TcsInstallment"] else {
            print("[getTInstallmentLinkIntentApi] Ссылка TInstallment отсутствует в paymentLinks")
            handler(nil, nil)
            return
        }
        
        print("[getTInstallmentLinkIntentApi] Ссылка TInstallment: \(tInstallmentLink)")
        
        let request = TInstallmentLinkRequestIntent(queryItems: queryItems, params: [:], apiUrl: tInstallmentLink)
        
        print("[getTInstallmentLinkIntentApi] Формируем запрос с URL: \(tInstallmentLink)")
        print("[getTInstallmentLinkIntentApi] Query Items: \(queryItems)")
        
        request.executeWithStatusCode { statusCode, resultLink in
            print("[getTInstallmentLinkIntentApi] Получена ссылка: \(resultLink)")
            handler(statusCode, resultLink)
            
            LoggerService.shared.logApiRequest(method: request.data.method.rawValue, url: request.data.path, success: true)
            
        } onError: { statusCode, error in
            handler(statusCode, nil)
            LoggerService.shared.logApiRequest(method: request.data.method.rawValue, url: request.data.path, success: false)
        }
    }
    
    public class func getAltForeignCardLinkIntentApi(puid: String,
                                           configuration: PaymentConfiguration,
                                           completion handler: @escaping (Int?, String?) -> Void) {
        let queryItems = [
            "webview": "false",
            "puid": puid
        ]
        
        guard let altForeignCardLink = configuration.paymentData.paymentLinks["ForeignCard"] else {
            print("[getAltForeignCardLinkIntentApi] Ссылка Dolyame отсутствует в paymentLinks")
            handler(nil, nil)
            return
        }
        
        print("[getAltForeignCardLinkIntentApi] Ссылка Dolyame: \(altForeignCardLink)")
        
        let request = AltForeignCardLinkRequestIntent(queryItems: queryItems, params: [:], apiUrl: altForeignCardLink)
        
        print("[getAltForeignCardLinkIntentApi] Формируем запрос с URL: \(altForeignCardLink)")
        print("[getAltForeignCardLinkIntentApi] Query Items: \(queryItems)")
        
        request.executeWithStatusCode { statusCode, resultLink in
            print("[getAltForeignCardLinkIntentApi] Получена ссылка: \(resultLink)")
            handler(statusCode, resultLink)
            
            LoggerService.shared.logApiRequest(method: request.data.method.rawValue, url: request.data.path, success: true)
            
        } onError: { statusCode, error in
            handler(statusCode, nil)
            LoggerService.shared.logApiRequest(method: request.data.method.rawValue, url: request.data.path, success: false)
        }
    }
    
    public class func getIntentWaitStatus(_ configuration: PaymentConfiguration,
                                          type: PaymentMethodType,
                                          completion: @escaping (Int?) -> Void) {
        guard let intentId = configuration.paymentData.intentId else { return }
        
        let request = IntentStatusWait(intentId: intentId, apiUrl: baseIntentURLString)
        
        let observerName: Notification.Name
        switch type {
        case .tpay:
            observerName = ObserverKeys.intentTpayObserver.key
        case .sberPay:
            observerName = ObserverKeys.intentSberPayObserver.key
        case .sbp:
            observerName = ObserverKeys.intentSbpObserver.key
        case .card:
            observerName = ObserverKeys.intentCardObserver.key
        case .dolyame:
            observerName = ObserverKeys.intentDolyameObserver.key
        case .foreignCard:
            observerName = ObserverKeys.intentAltForeignCardObserver.key
        case .tInstallment:
            observerName = ObserverKeys.intentTInstallmentObserver.key
        case .dr:
            observerName = ObserverKeys.intentDRObserver.key
        }
        
        request.executeWithStatusCode { statusCode, value in
            LoggerService.shared.logApiRequest(method: request.data.method.rawValue, url: request.data.path, success: true)
            
            completion(statusCode)
            
            NotificationCenter.default.post(name: observerName, object: value)
        } onError: { statusCode, error in
            LoggerService.shared.logApiRequest(method: request.data.method.rawValue, url: request.data.path, success: false)
            
            completion(statusCode)
            
            NotificationCenter.default.post(name: observerName, object: error)
        }
    }
    
    public func intentApiPay(cardCryptogram: String,
                                   with configuration: PaymentConfiguration,
                                   completion: @escaping (Int?, PaymentIntentResponse?) -> Void) {
        
        let params = ["Id": configuration.paymentData.intentId,
                      "PaymentMethod": "Card",
                      "Cryptogram": cardCryptogram]
        
        print(cardCryptogram)
        print(params)
        
        let request = CreateIntentApiPayRequest(params: params,
                                                apiUrl: CloudpaymentsApi.baseIntentURLString)
        
        request.executeWithStatusCode { statusCode, result in
            print("Status Code: \(statusCode), Result: \(String(describing: result))")
            completion(statusCode, result)
            
            LoggerService.shared.logApiRequest(method: request.data.method.rawValue, url: request.data.path, success: true)
            
        } onError: { statusCode, error in
            completion(statusCode, nil)
            
            LoggerService.shared.logApiRequest(method: request.data.method.rawValue, url: request.data.path, success: false)
        }
    }
    
    class func loadImage(url string: String,
                         completion: @escaping (UIImage?) -> Void) {
        
        guard let url = URL(string: string) else { return completion(nil) }
        
        let task = CloudpaymentsTrustedSession.shared.dataTask(with: .init(url: url)) { data, _, _ in
            guard let data = data, let image = UIImage(data: data) else { return completion(nil) }
            completion(image)
        }
        
        task.resume()
    }
}

public typealias CloudpaymentsRequestCompletion<T> = (_ response: T?, _ error: Error?) -> Void

private struct CloudpaymentsCodingKey: CodingKey {
    var stringValue: String
    
    init(stringValue: String) {
        self.stringValue = stringValue
    }
    
    var intValue: Int? {
        return nil
    }
    
    init?(intValue: Int) {
        return nil
    }
}

extension JSONDecoder.KeyDecodingStrategy {
    static var convertToUpperCamelCase: JSONDecoder.KeyDecodingStrategy {
        return .custom({ keys -> CodingKey in
            let lastKey = keys.last!
            if lastKey.intValue != nil {
                return lastKey
            }
            
            let firstLetter = lastKey.stringValue.prefix(1).lowercased()
            let modifiedKey = firstLetter + lastKey.stringValue.dropFirst()
            return CloudpaymentsCodingKey(stringValue: modifiedKey)
        })
    }
}

extension CloudpaymentsApi {
    public class func getPublicKey(completion: @escaping (PublicKeyResponse?, Error?) -> Void) {
        let publicKeyUrl = baseURLString + "payments/publickey"
        guard let url = URL(string: publicKeyUrl) else {
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        let session = CloudpaymentsTrustedSession.shared
        session.dataTask(with: request) { data, response, error in
            guard let method = request.httpMethod else {
                return
            }
            guard let path = request.url?.absoluteString else {
                return
            }
            
            guard let data = data else {
                completion(nil, CloudpaymentsError.networkError)
                return
            }
            
            do {
                let response = try JSONDecoder().decode(PublicKeyResponse.self, from: data)
                completion(response, nil)
                LoggerService.shared.logApiRequest(method: method, url: path, success: true)
            } catch {
                LoggerService.shared.logApiRequest(method: method, url: path, success: false)
                completion(nil, error)
            }
        }.resume()
    }
    
    public class func post<T: Encodable>(to endpoint: String, body: [T], completion: ((Result<Void, Error>) -> Void)? = nil) {
        guard let url = URL(string: endpoint) else {
            completion?(.failure(CloudpaymentsError.networkError))
            return
        }
        do {
            let data = try JSONEncoder().encode(body)
            if let json = String(data: data, encoding: .utf8) {
                print("------------>>>>> Analytics JSON payload:\n\(json)")
            }
            
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = data
            
            CloudpaymentsTrustedSession.shared.dataTask(with: request) { _, response, error in
                if let http = response as? HTTPURLResponse {
                    print("Analytics sent — Status:", http.statusCode)
                    completion?(.success(()))
                } else if let error = error {
                    print("Analytics send error:", error)
                    completion?(.failure(error))
                }
            }.resume()
        } catch {
            print("Encoding error:", error)
            completion?(.failure(error))
        }
    }
}
