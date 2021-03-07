//
//  DataTask.swift
//  
//
//  Created by Sasha on 04/03/2021.
//

import Foundation

public typealias Parameters = [String: Any]

public enum NetworkError: Error {
    
    case callMethodError(Error)
    case resiveDataError
    case httpRequestError
    case jsonDecodeError
    case jsonEncodeError
    case sendBodyWithoutParam
    case buildUrlError
    case unexpectedError
}

public enum ParametersType {
    case defaultParam
    case httpBody
}

public final class DataTask {
    
    private(set) var url: String
    private(set) var httpMethod: HTTPMethod
    private(set) var parameters: Parameters?
    private(set) var httpHeaders: [String:String]
    private(set) var parametersType: ParametersType
    private var validator: ((HTTPURLResponse) -> Bool)?
    private let session: URLSessionProxy
    
    internal init(url: String,
         httpMethod: HTTPMethod,
         parameters: Parameters?,
         httpHeaders: [String:String],
         parametersType: ParametersType,
         session: URLSessionProxy = URLSession.shared) {
        self.url = url
        self.httpMethod = httpMethod
        self.httpHeaders = httpHeaders
        self.parameters = parameters
        self.parametersType = parametersType
        self.session = session
    }
    
}

// MARK: Setup Methods

private extension DataTask {
    
    func setupRequest() -> Result<URLRequest, NetworkError> {
        
        guard var urlComponents = URLComponents(string: self.url) else {
            return .failure(.buildUrlError)
        }
        
        if self.parametersType == .defaultParam {
            urlComponents.queryItems = self.parameters?.map { (key, value) in
                return URLQueryItem(name: key, value: "\(value)")
            }
        }
        
        guard let requestUrl = urlComponents.url else {
            return .failure(.buildUrlError)
        }
        
        var request = URLRequest(url: requestUrl)
        request.httpMethod = httpMethod.title
        
        if self.parametersType == .httpBody {
            
            guard let param = parameters else {
                return .failure(.sendBodyWithoutParam)
            }
            
            guard let jsonData = try? JSONSerialization.data(withJSONObject: param, options: .prettyPrinted) else {
                return .failure(.jsonEncodeError)
            }
            
            request.httpBody = jsonData
            
        }
        
        httpHeaders.forEach {
            request.addValue($0.value, forHTTPHeaderField: $0.key)
        }
        
        return .success(request)
        
    }
    
}

// MARK: Response Methods

public extension DataTask {
    
    func response(queue: DispatchQueue = .main,
                         completion: @escaping (Result<Data, NetworkError>) -> Void) {
        
        let result = setupRequest()
            
        switch result {
        case .success(let request):
            self.session.dataTask(with: request) { data, response, error in
                if let error = error {
                    queue.async { completion(.failure(.callMethodError(error))) }
                    return
                }
                
                if let validator = self.validator {
                    guard let response = response as? HTTPURLResponse,
                          validator(response) else {
                        queue.async { completion(.failure(.httpRequestError)) }
                        return
                    }
                }
                
                guard let data = data else {
                    queue.async { completion(.failure(.resiveDataError)) }
                    return
                }
                
                queue.async { completion(.success(data)) }
            }.resume()
        case .failure(let error):
            queue.async { completion(.failure(error)) }
        }
            
            
    }
    
    func responseDecodable<T: Decodable>(of type: T.Type,
                                                queue: DispatchQueue = .main,
                                                completion: @escaping (Result<T, NetworkError>) -> Void) {
        self.response(queue: queue) { result in
            
            switch result {
            case .success(let data):
                guard let item = try? JSONDecoder().decode(T.self, from: data) else {
                    queue.async { completion(.failure(.jsonDecodeError)) }
                    return
                }
                queue.async { completion(.success(item)) }
            case .failure(let error):
                queue.async { completion(.failure(error)) }
            }
            
        }
        
    }

    func responseJSON(queue: DispatchQueue = .main,
                             completion: @escaping (Result<Any, NetworkError>) -> Void) {
        
        self.response(queue: queue) { result in
            
            switch result {
            case .success(let data):
                guard let json = try? JSONSerialization.jsonObject(with: data, options: []) else {
                    queue.async { completion(.failure(.jsonDecodeError)) }
                    return
                }
                queue.async { completion(.success(json)) }
            case .failure(let error):
                queue.async { completion(.failure(error)) }
            }
            
        }
        
    }

    func responseString(queue: DispatchQueue = .main,
                               completion: @escaping (Result<String, NetworkError>) -> Void) {
        
        self.response(queue: queue) { result in
            
            switch result {
            case .success(let data):
                let str = String(decoding: data, as: UTF8.self)
                queue.async { completion(.success(str)) }
            case .failure(let error):
                queue.async { completion(.failure(error)) }
            }
            
        }
        
    }
    
}

// MARK: Validate Methods

public extension DataTask {
    
    func validate<S: Sequence>(statusCode: S) -> Self where S.Iterator.Element == Int {
        
        validator = { response in
            let validator = ResponseValidator(statusCode)
            return validator.validate(response: response)
        }
        
        return self
    }
    
    func validate() -> Self {
        self.validator = { response in
            let validator = ResponseValidator(200 ..< 300)
            return validator.validate(response: response)
        }
        return self
    }
    
    func validate(contentType: String) -> Self {
        httpHeaders["Content-type"] = contentType
        return self
    }
    
}
