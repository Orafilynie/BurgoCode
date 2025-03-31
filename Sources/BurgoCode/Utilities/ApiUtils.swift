import Foundation
import CommonCrypto

public class ApiUtils {
    public static func commonHeaders() -> [String: String] {
        return [
            "Accept": "application/json, text/plain, */*",
            "Connection": "keep-alive",
            "Content-Type": "application/json",
            "Host": "webapi.burgerking.fr",
            "User-Agent": "com.unit9.bkFrApp/10.24.0",
            "x-application": "WEBSITE",
            "x-platform": "APP_IOS",
            "x-version": "10.24.0"
        ]
    }
    
    public static func resolveCaptcha() async throws -> String {
        let apiKey = "6Lf5DqUUAAAAAIHKVINTlK4DGAisCEIXM75KeUqT"
        let params = [
            "ar": "1",
            "k": apiKey,
            "co": "aHR0cHM6Ly93d3cuYnVyZ2Vya2luZy5mcjo0NDM.",
            "hl": "fr",
            "v": "-QbJqHfGOUB8nuVRLvzFLVed",
            "size": "invisible",
            "cb": "np3eftnhlzvl"
        ]
        
        let anchorURL = try createURL(base: "https://www.google.com/recaptcha/api2/anchor", params: params)
        let (anchorData, _) = try await URLSession.shared.data(from: anchorURL)
        let token = try extractToken(from: String(data: anchorData, encoding: .utf8) ?? "")
        
        let reloadURL = URL(string: "https://www.google.com/recaptcha/api2/reload?k=\(apiKey)")!
        var request = URLRequest(url: reloadURL)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.httpBody = try createReloadBody(token: token, params: params)
        
        let (reloadData, _) = try await URLSession.shared.data(for: request)
        return try parseReloadResponse(data: reloadData)
    }
    
    private static func createURL(base: String, params: [String: String]) throws -> URL {
        var components = URLComponents(string: base)!
        components.queryItems = params.map { URLQueryItem(name: $0.key, value: $0.value) }
        guard let url = components.url else { throw NSError(domain: "URLCreation", code: 0) }
        return url
    }
    
    private static func extractToken(from html: String) throws -> String {
        let pattern = #"<input\s+[^>]*id\s*=\s*["']recaptcha-token["'][^>]*value\s*=\s*["']([^"']+)"#
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(in: html, range: NSRange(html.startIndex..., in: html)),
              let range = Range(match.range(at: 1), in: html)
        else { throw NSError(domain: "TokenExtraction", code: 0) }
        
        return String(html[range])
    }
    
    private static func createReloadBody(token: String, params: [String: String]) throws -> Data {
        var components = URLComponents()
        components.queryItems = [
            URLQueryItem(name: "v", value: params["v"]),
            URLQueryItem(name: "reason", value: "q"),
            URLQueryItem(name: "c", value: token),
            URLQueryItem(name: "k", value: params["k"]),
            URLQueryItem(name: "co", value: params["co"]),
            URLQueryItem(name: "hl", value: params["hl"]),
            URLQueryItem(name: "size", value: params["size"]),
            URLQueryItem(name: "chr", value: "[30,85,0]"),
            URLQueryItem(name: "vh", value: "-419930829"),
            URLQueryItem(name: "bg", value: "!4Oag5uMKAAQeEAnmbQEHnAgEoUMfuFJKlcwL6HmbC6a1sjQUfZsj5PV0lu22LNAK2XlpN9GVXT-RbJVjyjON0aqCO_-ebeIGPwKwh6c4NtXQ9hfSA6WdPuyXnKxXmeYO0skcT8j7LiRDhhZ_BCmQmIENC1KrdTwljoROHGrebqR95s1bmhQlQw9yt1D5rDAdnDVA7wL1mMZ2uUjRRzw_qMG8_d-aF8jcnBsje5mp0RXA4_Op4FDb1wJDtyuYcz7Z5wXKz1OQYt_SD2-hVTavVDle7MtGXiFry6I1ZlArZpjtddJic1AaVSULLaN-VtKWD65dibDNEAQgX9LoXnwOPYc_FWPLT5kVAvoVz09aM7E-iM4bExpFuC68ulz-ooSaVtfjVBNvKrP9IUW02CYYIIvZx4koKVuBE8rG3V-CyJbtO3ukDGsbRgK60VVnQXJfOtgGGtw3HFOLFvHtAA8XplK5Ly9fE1grFERTd_DV4VhCrOVCs1HWs7wXkcM7DiX9E88DIGNYiS9XVY5RvFDzacz4PaqJpbELOEXqZ3XSLXxSUTVmuToYfiMLd6389egnhh18dZCZqES61keiN1dP0LthERvYPHlHhygZ3VCR9naNSXrRrzWaSNnIdoVtQVhFeczznFQKwkdK2qJWMSJ2gUURKavFAplGj5CNxiZXRBRbEOYBTXtTm0tkdu66mrXFtVrsWTUVHypJhlMdXBP5HfAOxJDwaksAiWos4VgJ0l8HuflJA7O8lutYLVZBmGjVQTsoc1cNi-zP82kM8-TJU0tK9SLFiUhJJVBDhxPLmGRhchHFdzFEZukIaZ2f9PJoptR7dprn6kmSqcNQ9XMCbz30w7sXAf2ZGE6twbtIjBThuNKlI7Qikl6zyefbPNX1LX5vU2j8YOLH26lM0NMJwOvXMRUcZ9mZBe6-Ukn-rEhNFLpNzQXDfDI2GSdXUUnF0V9h7BIXLxslNL-H4TbCj6zpRVXAroVQnh4WpG33E9kd8imJJlTdlc5WbqvEBCqGSLywYluyEojmBeFnUoCncatKZnpZqpbx6i8cnSiUrIjc-PhhN3u7aII8f_FecZoA-xjFsufZiMzkEewcfKY2PxLFCW17lm3Eb2eoKxy-LzhMx230JU5fdslgXSWGTRkOP_c7TtAaiQNZLq7q6spDXYmpVTP6GDD0pZ0NkTfWo-jRMr2u5YF-Rfd4GleSK7l_OYLnvX8CJGhBUP6CgkFWVNViUFgJrV9s8LrZRXuo9B29C-peH0gQC_FqiIW2hZW1GrcRfW-91KbgJhsU0tJYcG-Ctvh6n04Jq1c3ZaXk0TxBrj9sInuzftEjqVEf-TEsozF89cNoNRC5TS5UZsDIM4MVoJG3PGeoWXTLrZh_nql8l1ip9_rs5P-0zjfO9aVchukjzARs4_Ln_KRMdR2PIGnojK4FLGlh7H2SWliBoUdy3T9r5oL23vOHurd_f-J5mlRFNK8esDIXZ36UDEQzJml0segit7Jxfbk-ghnBwYCvjfPeO47qz9FjGRIF85LSfMeQDXYATyjQwAkkLloSW3eD_BNEfDqRkyNxi0M7JRRnnRdxX0kw1Q1XRpnlgM9hgf7P1022UWn9YgQq5dOQu3Q_y32PEuX374DTMiD1iZ8xvgevDU-wrToRYEVqtCrUwLcr1SqiZW_YbSNKpaZzsC7yqXlTEYN6cmBy_PmKDHkmlqMHtS-64vdKBuGMcvNzTfcWnMgv5PbMojSJ2NFP9ZTX83so3R2MdATfjEJQAhosijN191qUpeF6xFPoxBblSJZEmV51Ns1qfgUhp55RZiWkwbaoDIBeCc0qPhfENtYJLHGFHO-gPQgRUsWoONUKF3Z9sJettl7IsRUZyZx9xf014En00UPoBvoAcmWI417CpGqWq12YWtCb-DXatO_ChgJkeDxUPBXjeZWWj_fM9YyodVn-TKtswqUSaNigfRgl3haoY2-Yu4tVU_llvZgqOdZuM89O8aH7pUCqd3Jnk6kdJqcCQ534Oap2MgdsTanU_y6TvRU9EZnCze2Eon6idzBRbWu0ba8IuM9g2BedOSxTV_0_ysDj_u3bNiXVJuS7yPP0BWTyKoyAkdkK80XZSpmE0pLJUtpKrQkYzDWAOKo4A8Wuh1xKsZMjFa7VVnPP430kn-wS3sRuPRq9koTclY0GoRsHwMiDRUHFqSwxTWIvO9c7i6JCh3X-e7TagPuJG9J8R_2dCKJ2Z1MyTC5fg2FBgSwss5oTAH0hrftRzLzKIuebTcDBAY7cS6p1xhXa_1jKNzQn9-6P3e6QsaVhdLGjOLMRIHXRsZhYOfLenZUHF4tVCMTv-sOMERA6m4W4J-pdt2Q3qJvT1CvpXeXViUn6QWC5zWgpjj54-V1CbW450PHq733Q9qzMsGzKCenz2iy97idlFL_HjCQwgSCqsrGZjvH-oV_UslBxlfOACdYStpvvhjWhx8mItow2H1OQgl_lsGdeXC7fR6RBRTk6-F2Q4jSgBFbe2hOYQEsZZ8NXKZ4GDpHzbcLY7sqZ0sLrQlPqwzfhBvWDCcs7hwcTncdcPGLawANmKOad0K6yMRBJ4N5pBK-YVUrGXtVACik5Y2a9hDkKl96t3KtFAFTs0ZawOX0REcpDkFFRTKpN4fpdgpO1dN9AD45M0op25LphRyTvRdFomnD0XGYhbbPB3ClRvT7dLYQBh3yPfP7vgFujDQBeQgWzqM-SZhH1b-SVEYERcFQPmIg-KQSeo6rSr-4EB1l-")
        ]
        
        guard let bodyData = components.percentEncodedQuery?.data(using: .utf8) else {
            throw NSError(domain: "BodyEncoding", code: 0)
        }
        return bodyData
    }
    
    private static func parseReloadResponse(data: Data) throws -> String {
        let responseString = String(data: data, encoding: .utf8) ?? ""
        let jsonString = String(responseString.dropFirst(5))
        guard let jsonData = jsonString.data(using: .utf8),
              let jsonArray = try JSONSerialization.jsonObject(with: jsonData) as? [Any],
              jsonArray.count > 1 else {
            throw NSError(domain: "ReloadParse", code: 0)
        }
        return jsonArray[1] as? String ?? ""
    }
    
    public static func resolveHash(deviceId: String) -> String {
        let pepper = "merci,votrecommandeabienetepriseencompte#jejoueautennis&TupeuxpasToast!@burritoking5console.log(Oups,uneerreurestsurvenue)"
        let combinedString = deviceId + pepper
        return generateMD5(for: combinedString)
    }
    
    private static func generateMD5(for string: String) -> String {
        let data = Data(string.utf8)
        var digest = [UInt8](repeating: 0, count: Int(CC_MD5_DIGEST_LENGTH))
        
        data.withUnsafeBytes { bytes in
            CC_MD5(bytes.baseAddress, CC_LONG(data.count), &digest)
        }
        
        return digest.map { String(format: "%02hhx", $0) }.joined()
    }
}
