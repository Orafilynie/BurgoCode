import Foundation

public struct CodeResult: Sendable {
    public let deviceId: String
    public let promotionName: String
    public let promotionId: [String]
    public let promotionType: String
    public let codes: [String]
}

public class CodesGenerator {
    public static func GetPromotions() async throws -> [String] {
        let deviceId = UUID().uuidString.uppercased()
        let postResponse = try await sendPostRequest(
            deviceId: deviceId,
            hash: ApiUtils.resolveHash(deviceId: deviceId),
            queen: try await ApiUtils.resolveCaptcha()
        )
            
        var promotions = [String]()
            
        if let responseArray = postResponse as? [[String: Any]] {
            for promotion in responseArray {
                if let code = promotion["code"] as? String {
                    promotions.append(code)
                }
            }
        }
            
        return Array(Set(promotions))
    }
    
    public static func GenerateCodes(promotionName: String) async throws -> CodeResult {
        let deviceId = UUID().uuidString.uppercased()
        let hash = ApiUtils.resolveHash(deviceId: deviceId)
        let queen = try await ApiUtils.resolveCaptcha()

        let postResponse = try await sendPostRequest(deviceId: deviceId, hash: hash, queen: queen)
        
        var codes = [String]()
        var promotionId = [String]()
        var promotionType = ""
        
        if let promotions = postResponse as? [[String: Any]] {
            for promotion in promotions {
                if let code = promotion["code"] as? String, code == promotionName {
                    if let coupons = promotion["coupons"] as? [[String: Any]] {
                        codes = coupons.compactMap { $0["restaurantCode"] as? String }
                    }
                            
                    if let operationPromotions = promotion["operationDevicePromotions"] as? [[String: Any]] {
                        promotionId = operationPromotions.compactMap { $0["promotionId"] as? String }
                    }
                        
                    promotionType = promotion["operationRepeatAttributionType"] as? String ?? ""
                    break
                }
            }
        }
        
        return CodeResult(
            deviceId: deviceId,
            promotionName: promotionName,
            promotionId: promotionId,
            promotionType: promotionType,
            codes: codes
        )
    }
    
    private static func sendPostRequest(deviceId: String, hash: String, queen: String) async throws -> Any {
        guard let url = URL(string: "https://webapi.burgerking.fr/blossom/api/v13/public/operation-device/all") else {
            throw NSError(domain: "InvalidURL", code: 0)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        setHeaders(for: &request, deviceId: deviceId)
        
        let body: [String: Any] = [
            "king": deviceId,
            "hash": hash,
            "queen": queen
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, _) = try await URLSession.shared.data(for: request)
        return try JSONSerialization.jsonObject(with: data)
    }
    
    private static func setHeaders(for request: inout URLRequest, deviceId: String) {
        ApiUtils.commonHeaders().forEach {
            request.setValue($0.value, forHTTPHeaderField: $0.key)
        }
        
        request.setValue(deviceId, forHTTPHeaderField: "x-device")
    }
}
