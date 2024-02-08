//
//  NLSwift.swift
//  NLSwiftFramework
//
//  Created by apple on 08/02/24.
//

import Foundation

// MARK: - NLSwift
class NLSwift {
    public static let shared = NLSwift()
    public init() {}
    
    // Main request function
    public func request(urlString: String, method: NLSwiftHttpMethod, parameters: [String: Any]? = nil, headers: [String: String]? = nil, completion: @escaping (Result<Data, NLSwiftNetworkError>) -> Void) {
        guard let url = URL(string: urlString) else {
            completion(.failure(.invalidURL))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        
        // Adding parameters for POST request
        if let parameters = parameters, method == .post {
            request.httpBody = try? JSONSerialization.data(withJSONObject: parameters, options: [])
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        }
        
        // Setting headers
        headers?.forEach { request.setValue($1, forHTTPHeaderField: $0) }
        
        // Sending request
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    completion(.failure(.custom(error.localizedDescription)))
                    return
                }
                
                guard let httpResponse = response as? HTTPURLResponse else {
                    completion(.failure(.unknownHTTPResponse))
                    return
                }
                
                guard (200...299).contains(httpResponse.statusCode) else {
                    completion(.failure(NLSwiftNetworkError.error(fromStatusCode: httpResponse.statusCode)))
                    return
                }
                
                guard let data = data else {
                    completion(.failure(.noData))
                    return
                }
                
                completion(.success(data))
            }
        }
        
        task.resume()
    }
}

public enum NLSwiftNetworkError: Error {
    case invalidURL
    case custom(String)
    case noData
    case unknownHTTPResponse
    case decodeError(String)
    
    static func error(fromStatusCode code: Int, errorDescription: String? = nil) -> NLSwiftNetworkError {
        switch code {
        case 400: return .custom("Bad Request")
        case 401: return .custom("Unauthorized")
        case 403: return .custom("Forbidden")
        case 404: return .custom("Not Found")
        case 500: return .custom("Internal Server Error")
        default:
            return .custom(errorDescription ?? "Unknown Error with status code: \(code)")
        }
    }
}

// MARK: - Supporting Types
public enum NLSwiftHttpMethod: String {
    case get = "GET"
    case post = "POST"
}

// MARK: - Data Parsing
extension NLSwift {
   public func decode<T: Decodable>(_ data: Data, to type: T.Type) -> Result<T, NLSwiftNetworkError> {
        let decoder = JSONDecoder()
        do {
            let responseData = try decoder.decode(T.self, from: data)
            return .success(responseData)
        } catch {
            return .failure(.decodeError(error.localizedDescription))
        }
    }
}






