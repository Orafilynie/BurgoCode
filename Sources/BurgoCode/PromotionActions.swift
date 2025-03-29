import Foundation

public enum PromotionActionType {
    case CHOICE
}

public struct PromotionActionResult {
    public let finalCode: String
}

public class PromotionActionHandler {
    private let deviceId: String
    private let promoName: String
    private let promotionId: String
    private let code: String
    
    public init(
        deviceId: String,
        promoName: String,
        promotionId: String,
        code: String
    ) {
        self.deviceId = deviceId
        self.promoName = promoName
        self.promotionId = promotionId
        self.code = code
    }
    
    public func execute(action: PromotionActionType) async throws -> PromotionActionResult {
        switch action {
        case .CHOICE:
            return try await handleChoiceAction()
        }
    }
    
    private func handleChoiceAction() async throws -> PromotionActionResult {
        let urlString = "https://webapi.burgerking.fr/blossom/api/v13/public/operation-device/\(promoName)/confirm-choice?couponCode=\(code)&promotionId=\(promotionId)"
            
        guard let encoded = urlString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
                let url = URL(string: encoded) else {
            throw NSError(domain: "InvalidURL", code: 0)
        }
            
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
            
        Self.setHeaders(for: &request, deviceId: deviceId)
        request.httpBody = try await Self.createRequestBody(deviceId: deviceId)
            
        let (data, _) = try await URLSession.shared.data(for: request)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] ?? [:]
            
        guard let finalCode = (json["coupons"] as? [[String: Any]])?.first?["restaurantCode"] as? String else {
            throw NSError(domain: "DataError", code: 1)
        }
            
        return PromotionActionResult(finalCode: finalCode)
    }
    
    private static func setHeaders(for request: inout URLRequest, deviceId: String) {
        ApiUtils.commonHeaders().forEach {
            request.setValue($0.value, forHTTPHeaderField: $0.key)
        }
        request.setValue(deviceId, forHTTPHeaderField: "x-device")
    }
    
    private static func createRequestBody(deviceId: String) async throws -> Data {
        let body: [String: Any] = [
            "king": deviceId,
            "hash": ApiUtils.resolveHash(deviceId: deviceId),
            "queen": try await ApiUtils.resolveCaptcha()
        ]
        return try JSONSerialization.data(withJSONObject: body)
    }
}
