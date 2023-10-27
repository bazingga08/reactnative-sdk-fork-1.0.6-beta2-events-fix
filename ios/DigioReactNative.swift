import DigiokycSDK
import React
import UIKit
import Foundation

@objc(DigioReactNative)
class DigioReactNative: RCTEventEmitter, DigioKycResponseDelegate {
    var result: RCTPromiseResolveBlock!
    
    override func supportedEvents() -> [String]! {
        return ["gatewayEvent"]
    }

    @objc(start:withIdentifier:withTokenId:withAdditionalData:withConfig:withResolver:withRejecter:)
    func start(documentId: String, identifier: String, tokenId: String?, additionalData: NSDictionary?, config: NSDictionary?, resolve:@escaping RCTPromiseResolveBlock,reject:@escaping RCTPromiseRejectBlock) -> Void {
        self.result = resolve;
        DispatchQueue.main.async {
                let rootViewController = UIApplication.shared.windows.filter({ (w) -> Bool in
                    return w.isHidden == false
                }).first?.rootViewController

                if rootViewController != nil {
                    do {
                        var additionalParams: [String: String]?
                        var primaryColor: String?
                        var logo: String?
                        var fontFormat: String?
                        var fontFamily: String?
                        var fontUrl: String?
                        var environment: String = "production"
                        
                        additionalParams = additionalData as? [String : String];
                        
                        environment = config?["environment"] as? String ?? "production";
                        primaryColor = config?["primaryColor"] as? String;
                        logo = config?["logo"] as? String;
                        fontFormat = config?["fontFormat"] as? String;
                        fontFamily = config?["fontFamily"] as? String;
                        fontUrl = config?["fontUrl"] as? String;
                        
                        // Your existing code here...
                        try DigioKycBuilder()
                            .withController(viewController: rootViewController!)
                            .setDocumentId(documentId: documentId)
                            .setKycResponseDelegate(delegate: self)
                            .setIdentifier(identifier: identifier)
                            .setEnvironment(environment: environment.elementsEqual("sandbox") ? DigioEnvironment.SANDBOX : DigioEnvironment.PRODUCTION)
                            .setPrimaryColor(hexColor: primaryColor ?? "")
                            .setTokenId(tokenId: tokenId ?? "")
                            .setFontFormat(fontFormat: fontFormat ?? "")
                            .setFontFamily(fontFamily: fontFamily ?? "")
                            .setFontUrl(fontUrl: fontUrl ?? "")
                            .setLogo(logo: logo ?? "")
                            .setAdditionalParams(additionalParams: additionalParams ?? [:])
                            .build()
                    } catch let error {
                        print("Exception --> \(error.localizedDescription)")
                    }
                } else {
                  reject("Error", "Root view controller not found", nil)
                }
            }
    }
//
    private func formatJson(response: String)->[String: Any]{
        let kycResponse = try! JSONDecoder().decode(DigioKycResponse.self, from: response.data(using: .utf8)!)
        var resultMap: [String: Any] = [:]
        resultMap["message"] = kycResponse.message
        resultMap["documentId"] = kycResponse.id
        if let code = kycResponse.code {
            resultMap["code"] = code
        }
        if let errorCode = kycResponse.errorCode{
            resultMap["errorCode"] = errorCode
        }
        if let screen = kycResponse.screen{
            resultMap["screen"] = screen
        }
        if let type = kycResponse.type {
            resultMap["type"] = type
        }
        return resultMap
    }

    func onDigioKycResponseSuccess(successResponse: String) {
        print("Success \(successResponse)")
        if self.result != nil {
            self.result(formatJson(response: successResponse))
        }
    }

    func onDigioKycResponseFailure(failureResponse: String) {
        print("Failure \(failureResponse)")
        if self.result != nil {
            self.result(formatJson(response: failureResponse))
        }
    }

    func onGateWayEvent(event: String) {
        print("Gateway event \(event)")
        self.sendEvent(withName: "gatewayEvent", body: convertToDictionary(text: event))
    }
    
    func convertToDictionary(text: String) -> [String: Any]? {
        if let data = text.data(using: .utf8) {
            do {
                return try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
            } catch {
                print(error.localizedDescription)
            }
        }
        return nil
    }
}
