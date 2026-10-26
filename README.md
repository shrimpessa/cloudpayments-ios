## CloudPayments SDK for iOS 

CloudPayments SDK позволяет интегрировать прием платежей в мобильные приложения для платформы iOS.

### Требования
Для работы CloudPayments SDK необходим iOS версии 15.0 и выше.

### Подключение
Для подключения SDK вы можете использовать Swift Package Manager или CocoaPods.

* Для подключения через Swift Package Manager используйте меню File -> Add Package Dependencies, найдите SDK используя Package URL - https://gitpub.cloudpayments.ru/integrations/sdk/cloudpayments-ios и добавьте зависимость в проект.
* Для подключения через CocoaPods добавьте в файл Podfile зависимости:

```
pod 'Cloudpayments', :git =>  "https://gitpub.cloudpayments.ru/integrations/sdk/cloudpayments-ios", :branch => "master"
pod 'CloudpaymentsNetworking', :git =>  "https://gitpub.cloudpayments.ru/integrations/sdk/cloudpayments-ios", :branch => "master"
```

### Структура проекта:

* **demo** - Пример реализации приложения с использованием SDK
* **sdk** - Исходный код SDK

### Возможности CloudPayments SDK:

Вы можете использовать SDK одним из четырёх способов: 
* использовать стандартную платежную форму CloudPayments
* использовать стандартную платежную форму CloudPayments в режиме одного способа оплаты
* реализовать свою платежную форму с использованием функций CloudpaymentsApi без вашего сервера
* реализовать свою платежную форму, сформировать криптограмму и отправить ее на свой сервер

### Перед использованием SDK внесите доверенные домены в ваше приложение, в Info.plist:

```
<dict>
    <key>NSAppTransportSecurity</key>
    <dict>
        <key>NSExceptionDomains</key>
        <dict>

            <key>cloudpayments.ru</key>
            <dict>
                <key>NSExceptionAllowsInsecureHTTPLoads</key>
                <true/>
                <key>NSIncludesSubdomains</key>
                <true/>
            </dict>

            <key>tbank.ru</key>
            <dict>
                <key>NSExceptionAllowsInsecureHTTPLoads</key>
                <true/>
                <key>NSIncludesSubdomains</key>
                <true/>
            </dict>

        </dict>
    </dict>
```

### Использование стандартной платёжной формы от CloudPayments:

1. Cоздайте объект PaymentDataPayer и проинициализируйте его, затем создайте объект PaymentData передайте в него объект PaymentDataPayer, сумму платежа, валюту и дополнительные данные.

```

//создание объекта чека                
let receipt: [String: Any] = [
    "Items": [
        [
           "label": "Товар",
            "price": 1.95,
            "quantity": 1,
            "amount": 1.95,
            "vat": 0,
            "method": 4,
            "object": 1
        ]
    ],
    "taxationSystem": 0,
    "email": "test@test.ru",
    "amounts": [
        "electronic": 1.95,
        "advancePayment": 0,
        "credit": 0,
        "provision": 0
    ]
]
                
//создание объекта подписки
let recurrent = Recurrent(
            interval: "Month",
            period: 1,
            receipt: receipt, 
            amount: 99.99)
            
// Доп. поле, куда передается информация о плательщике. Используйте следующие параметры: FirstName, LastName, MiddleName, Birth, Street, Address, City, Country, Phone, Postcode
let payer = PaymentDataPayer(firstName: "Test", lastName: "Testov", middleName: "Testovich", birth: "1955-02-22", address: "home 6", street: "Testovaya", city: "Moscow", country: "RU", phone: "89991234567", postcode: "12345")
    
// Указывайте дополнительные данные если это необходимо
let jsonData: [String: Any] = ["age":27, "name":"Ivan", "phone":"+79998881122"] // Любые другие данные, которые будут связаны с транзакцией {name: Ivan}

let paymentData = PaymentData() 
    .setAmount(String(totalAmount)) // Cумма платежа в валюте, максимальное количество не нулевых знаков после запятой: 2
    .setCurrency(.ruble) // Валюта
    .setDescription("Корзина цветов") // Описание оплаты в свободной форме
    .setAccountId("111") // Обязательный идентификатор пользователя для создания подписки и получения токена
    .setInvoiceId("123") // Номер счета или заказа
    .setEmail("test@cp.ru") // E-mail плательщика, на который будет отправлена квитанция об оплате
    .setPayer(payer) // Информация о плательщике
    .setJsonData(jsonData) // Любые другие данные, которые будут связаны с транзакцией
    .setReceipt(receipt) // Данные для чека
    .setRecurrent(recurrent) // Данные для подписки           
```

1.1. За более подробной информацией по формированию чека, можно обратиться в [документацию CloudKassir](https://developers.cloudkassir.ru/)

**Внимание из-за частых изменений в формате чека, он передается как [String: Any]**

2. Создайте объект PaymentConfiguration, передайте в него объект PaymentData и ваш **Public_id** из [личного кабинета CloudPayments](https://merchant.cloudpayments.ru/). Реализуйте протокол PaymentDelegate, чтобы узнать о завершении платежа

```
let configuration = PaymentConfiguration(
    publicId: "", // Ваш Public_id из личного кабинета
    paymentData: paymentData, // Информация о платеже
    delegate: self, // Вывод информации о завершении платежа
    uiDelegate: self, // Вывод информации о UI 
    emailBehavior: .optional, // Опции отображения поля Email (Optional - пользователь может включить/отключить поле, Required - поле обязательно для заполнения, Hidden - поле не отображается)
    paymentMethodSequence: [.tpay, .card], // Порядок отображения платежных методов, если указать не все методы, тогда первыми буду отображены переданные методы, а остальные будут отображены в порядке по умолчанию
    useDualMessagePayment: true, // Использовать двухстадийную схему проведения платежа, (по умолчанию используется одностадийная схема)
    successRedirectUrl: "", // Ваш deeplink для редиректа из приложения банка после успешной оплаты, (если ничего не передано, по умолчанию используется URL адрес вашего сайта)
    failRedirectUrl: "" //  Ваш deeplink для редиректа из приложения банка после неуспешной оплаты, (если ничего не передано, по умолчанию используется URL адрес вашего сайта)
```
2.1. Для передачи deeplink при использовании CБП,TPay,SberPay,Долями нужно использовать Universal Links:

2.2. Документация от Apple: [Universal Links](https://developer.apple.com/documentation/xcode/supporting-universal-links-in-your-app)

2.3. В вашем приложении реализуйте метод application(_:continue:restorationHandler:) в классе вашего AppDelegate для обработки Universal Links

3. Вызовите форму оплаты 

3.1 При использовании UIKit

```
PaymentOptionsViewController.present(with: configuration, from: self)
```

3.2 При использовании SwiftUI

```
struct PaymentScreen: SwiftUI.View {
    var body: some SwiftUI.View {
        VStack(spacing: 20) {
            Button(action: {
                runPayment()
            }) {
                Text("Оплатить")
                    .frame(width: 200, height: 60)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
        }
    }
    
    private func runPayment() {
        guard let rootViewController = UIApplication.shared.connectedScenes
                .compactMap({ $0 as? UIWindowScene })
                .first?.windows.first?.rootViewController else {
            return
        }

        PaymentOptionsViewController.present(with: configuration, from: rootViewController)
    }
}
```

### Использование T-Pay, SberPay, СБП, Долями, Цифровой рубль в стандартной платежной форме:

1. Включить необходимые опции в [личном кабинете CloudPayments](https://merchant.cloudpayments.ru/).
2. Если эти опции недоступны, обратитесь к курирующему вас менеджеру.

### Использование стандартной платежной формы CloudPayments в режиме одного способа оплаты:

1. В объекте PaymentConfiguration укажите какой способ оплаты необходимо запусть (singlePaymentMode = .card или .tpay, .sberPay, .sbp, .dolyame), SDK пропустит экран выбора способов оплаты и сразу запустит выбранный способ оплаты (если он доступен на терминале, иначе SDK сообщит об ошибке конфигурации).
2. Если необходимо скройте финальный экран (showResultScreenForSinglePaymentMode = false) и SDK сразу после оплаты вернет результат работы в ваше приложение, не показывая экран успеха или ошибки, данный параметр работает только в режиме одного способа оплаты (в конфигурации указан singlePaymentMode)

```
let configuration = PaymentConfiguration(
    publicId: "",
    paymentData: paymentData,
    delegate: self,
    uiDelegate: self,
    emailBehavior: .optional, 
    paymentMethodSequence: [],
    singlePaymentMode: .card, // Какой платежный метод необходимо запустить
    useDualMessagePayment: true,
    showResultScreenForSinglePaymentMode: false, // Не показывать финальный экран, по умолчанию true
    successRedirectUrl: "",
    failRedirectUrl: "" 
```

### Использование вашей платежной формы с использованием функций CloudPaymentsApi:

* **Для использования нового формата криптограммы:**

1. Получите **publicKey (Pem)** и **keyVersion (Version)** с данного [API](https://api.cloudpayments.ru/payments/publickey)
2. Полученные **publicKey** и **keyVersion** передайте в метод создания криптограммы Card.makeCardCryptogramPacket, а также **merchantPublicId** полученный в [личном кабинете CloudPayments](https://merchant.cloudpayments.ru/) и данные карты для создания криптограммы

3. Cоздайте криптограмму карточных данных

```
// Обязательно проверяйте входящие данные карты (номер, срок действия и cvc код) на корректность, иначе метод создания криптограммы вернет nil.
let cardCryptogramPacket = Card.makeCardCryptogramPacket(cardNumber: cardNumber, expDate: expDate, cvv: cvv, merchantPublicID: "Ваш Public_id из личного кабинета", publicKey: "Полученный публичный ключ", keyVersion: "Полученная версия ключа")
```

4. Выполните запрос на проведения платежа (см. [документацию по API](https://developers.cloudpayments.ru/#oplata-po-kriptogramme)).

5. Если необходимо, покажите 3DS форму для подтверждения платежа

```
let data = ThreeDsData(transactionId: transactionId, paReq: paReq, acsUrl: acsUrl)
let threeDsProcessor = ThreeDsProcessor()
threeDsProcessor.make3DSPayment(with: data, delegate: self)
```

6. Для получения формы 3DS и получения результатов прохождения 3DS аутентификации реализуйте протокол ThreeDsDelegate.

```
extension CheckoutViewController: ThreeDsDelegate {
    // Вы получаете объект WKWebView, который сами показываете нужным вам способом и в нужном вам месте
    func willPresentWebView(_ webView: WKWebView) {
        self.showThreeDsForm(webView)
    }

    // threeDsCallbackId - идентификатор, полученный в ответ на запрос на проведение платежа
    // Используйте md и paRes, для завершения оплаты
    func onAuthotizationCompleted(with md: String, paRes: String) {
        hideThreeDs() // метод закрытия 3ds
        // Здесь вызовите свой созданный метод post3ds из пункта 7
    }

    func onAuthorizationFailed(with html: String) {
        hideThreeDs() // метод закрытия 3ds
        print("error: \(html)")
    }
}
```
7. Выполните запрос post3ds для завершения оплаты (см. [документацию по API](https://developers.cloudpayments.ru/#obrabotka-3-d-secure)).

### История обновлений:

#### 2.1.10

Добавлены сертификаты МинЦифры

#### 2.1.9

Добавлен новый способ оплаты Цифровой рубль

#### 2.1.8

Добавлена альбомная ориентация

#### 2.1.7

* Новый способ оплаты рассрочка

#### 2.1.6

* Поправили уязвимость и обновили demo

#### 2.1.5

* Внедрили оплату иностранной картой

#### 2.1.4

* Исправлен баг с отображением сохранения карты на устройствах SE

#### 2.1.3

* Исправлена ошибка 3дс в тестовом режиме при оплате банковской картой

#### 2.1.2

* Изменён параметр customerReceipt на receipt в объекте Recurrent

#### 2.1.1 

* Изменён формат передачи чека на [String: Any]

#### 2.1.0 

* Добавлена возможность использовать SDK в режиме одного способа оплаты (см. документацию)

#### 2.0.0 

* Новый дизайн, новые возможности, добавлены новые способы оплаты, добавлена возможность изменять порядок отображения способов оплаты

#### 1.6.0
* Выполнен переход на новое API (только для стандартной формы)

### Поддержка

По возникающим вопросам технического характера обращайтесь на support@cp.ru
