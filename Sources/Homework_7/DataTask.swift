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
                         completion: @escaping (DataResponse<Data>) -> Void) {
        
        let result = setupRequest()
            
        switch result {
        case .success(let request):
            self.session.dataTask(with: request) { data, response, error in
                if let error = error {
                    let dataResponse = DataResponse<Data>(result: .failure(.callMethodError(error)),
                                                          request: request)
                    queue.async { completion(dataResponse) }
                    return
                }
                
                
                guard let response = response as? HTTPURLResponse, (self.validator?(response) ?? true) else {
                    let dataResponse = DataResponse<Data>(result: .failure(.httpRequestError),
                                                          request: request)
                    queue.async { completion(dataResponse) }
                    return
                }
                
                guard let data = data else {
                    let dataResponse = DataResponse<Data>(result: .failure(.resiveDataError),
                                                          request: request,
                                                          response: response)
                    queue.async { completion(dataResponse) }
                    return
                }
                
                let dataResponse = DataResponse<Data>(result: .success(data),
                                                      request: request,
                                                      response: response)
                
                queue.async { completion(dataResponse) }
            }.resume()
        case .failure(let error):
            let dataResponse = DataResponse<Data>(result: .failure(error))
            queue.async { completion(dataResponse) }
        }
            
            
    }
    
    func responseDecodable<T: Decodable>(of type: T.Type,
                                                queue: DispatchQueue = .main,
                                                completion: @escaping (DataResponse<T>) -> Void) {
        self.response(queue: queue) { response in
            
            switch response.result {
            case .success(let data):
                guard let item = try? JSONDecoder().decode(T.self, from: data) else {
                    let dataResponse = DataResponse<T>(result: .failure(.jsonDecodeError),
                                                       request: response.request,
                                                       response: response.response)
                    queue.async { completion(dataResponse) }
                    return
                }
                let dataResponse = DataResponse<T>(result: .success(item),
                                                   request: response.request,
                                                   response: response.response)
                queue.async { completion(dataResponse) }
            case .failure(let error):
                let dataResponse = DataResponse<T>(result: .failure(error),
                                                   request: response.request,
                                                   response: response.response)
                queue.async { completion(dataResponse) }
            }
            
        }
        
    }

    func responseJSON(queue: DispatchQueue = .main,
                             completion: @escaping (DataResponse<Any>) -> Void) {
        
        self.response(queue: queue) { response in
            
            switch response.result {
            case .success(let data):
                guard let json = try? JSONSerialization.jsonObject(with: data, options: []) else {
                    let dataResponse = DataResponse<Any>(result: .failure(.jsonDecodeError),
                                                         request: response.request,
                                                        response: response.response)
                    queue.async { completion(dataResponse) }
                    return
                }
                let dataResponse = DataResponse<Any>(result: .success(json),
                                                     request: response.request,
                                                     response: response.response)
                queue.async { completion(dataResponse) }
            case .failure(let error):
                let dataResponse = DataResponse<Any>(result: .failure(error),
                                                     request: response.request,
                                                     response: response.response)
                queue.async { completion(dataResponse) }
            }
            
        }
        
    }

    func responseString(queue: DispatchQueue = .main,
                               completion: @escaping (DataResponse<String>) -> Void) {
        
        self.response(queue: queue) { response in
            
            switch response.result {
            case .success(let data):
                let str = String(decoding: data, as: UTF8.self)
                let dataResponse = DataResponse<String>(result: .success(str),
                                                        request: response.request,
                                                        response: response.response)
                queue.async { completion(dataResponse) }
            case .failure(let error):
                let dataResponse = DataResponse<String>(result: .failure(error),
                                                        request: response.request,
                                                        response: response.response)
                queue.async { completion(dataResponse) }
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
