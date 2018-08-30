//
//  TMDBClient.swift
//  TheMovieManager
//
//  Created by Jarrod Parkes on 2/11/15.
//  Copyright (c) 2015 Jarrod Parkes. All rights reserved.
//

import Foundation

// MARK: - TMDBClient: NSObject

class TMDBClient : NSObject {
    
    // MARK: Properties
    
    // shared session
    var session = URLSession.shared
    
    // configuration object
    var config = TMDBConfig()
    
    // authentication state
    var requestToken: RequestToken? = nil
    var sessionID : String? = nil
    var userID : Int? = nil
    
    // MARK: Initializers
    
    override init() {
        super.init()
    }
    
    // MARK: GET
    
    func taskForGETMethod<T: Decodable>(_ method: String, parameters: [String:AnyObject], completionHandlerForGET: @escaping (_ result: T?, _ error: Error?) -> Void)  {
                
        /* 1. Set the parameters */
        var parametersWithApiKey = parameters
        parametersWithApiKey[ParameterKeys.ApiKey] = Constants.ApiKey as AnyObject?
        
        let url = TMDBClient.tmdbURLFromParameters(parametersWithApiKey, withPathExtension: method)
        /* 2/3. Build the URL, Configure the request */
        let request = URLRequest(url: url)
        print("** URL Request for \(method) = \(request)")
        
        /* 4. Make the request */
        let task = session.dataTask(with: request as URLRequest) { (data, response, error) in
            
            func sendError(_ error: String) {
                print(error)
                let userInfo = [NSLocalizedDescriptionKey : error]
                completionHandlerForGET(nil, NSError(domain: "taskForGETMethod", code: 1, userInfo: userInfo))
            }
            
            /* GUARD: Was there an error? */
            guard (error == nil) else {
                print("There was an error with your request: \(String(describing: error))")
                return
            }
            
            /* GUARD: Did we get a successful 2XX response? */
            guard let statusCode = (response as? HTTPURLResponse)?.statusCode, statusCode >= 200 && statusCode <= 299 else {
                if let errorMessageFromJSON = self.parseErrorFromTMDB(methodDescription: method, data: data!) {
                    print(errorMessageFromJSON)
                }
                return
            }
            
            /* GUARD: Was there any data returned? */
            guard let data = data else {
                sendError("No data was returned by the GET request!")
                return
            }
            
            var jsonObject: T? = nil
            do {
                let jsonDecoder = JSONDecoder()
                let jsonData = Data(data)
                jsonObject = try jsonDecoder.decode(T.self, from: jsonData)
            } catch {
                sendError(error.localizedDescription)
                return
            }
            
            completionHandlerForGET(jsonObject, error as Error?)

        }
        
        /* 7. Start the request */
        task.resume()
        
    }
    
    // MARK: POST
    
    func taskForPOSTMethod<TResponse: Decodable, TRequest: Encodable>(_ method: String, parameters: [String:AnyObject], postObject: TRequest, completionHandlerForPOST: @escaping (_ result: TResponse?, _ error: NSError?) -> Void )  {
        
        var returnData: Data? = nil
        let headerFields = ["content-type": "application/json;charset=utf-8",
                       "accept": "application/json;charset=utf-8"]
        /* 1. Set the parameters */
        var parametersWithApiKey = parameters
        parametersWithApiKey[ParameterKeys.ApiKey] = Constants.ApiKey as AnyObject?
        
        /* 2/3. Build the URL, Configure the request */
        let request = NSMutableURLRequest(url: TMDBClient.tmdbURLFromParameters(parametersWithApiKey, withPathExtension: method))
        
        var postBody: Data? = nil
        do {
            let jsonEncoder = JSONEncoder()
            postBody = try jsonEncoder.encode(postObject)
        }
        catch {print(error)}
        
        
        request.httpMethod = "POST"
        request.allHTTPHeaderFields = headerFields
        request.httpBody = postBody
        
        /* 4. Make the request */
        let task = session.dataTask(with: request as URLRequest) { (data, response, error) in
            
            func sendError(_ error: String) {
                print(error)
                let userInfo = [NSLocalizedDescriptionKey : error]
                completionHandlerForPOST(nil, NSError(domain: "taskForGETMethod", code: 1, userInfo: userInfo))
            }
            
            /* GUARD: Was there an error? */
            guard (error == nil) else {
                print(error!)
                return
            }
            
            /* GUARD: Did we get a successful 2XX response? */
            guard let statusCode = (response as? HTTPURLResponse)?.statusCode, statusCode >= 200 && statusCode <= 299 else
            {
                print(data!)
                if let errorMessageFromJSON = self.parseErrorFromTMDB(methodDescription: method, data: data!) {
                    print(errorMessageFromJSON)
                }
                return
            }
            
            /* GUARD: Was there any data returned? */
            guard let data = data else {
                sendError("No data was returned by the POST request!")
                return
            }
            
            var jsonObject: TResponse? = nil
            do {
                let jsonDecoder = JSONDecoder()
                let jsonData = Data(data)
                jsonObject = try jsonDecoder.decode(TResponse.self, from: jsonData)
            } catch {
                sendError(error.localizedDescription)
                return
            }
            
            completionHandlerForPOST(jsonObject, error as NSError?)
            
        }
        task.resume()
    }
    
    // MARK: GET Image
    
    func taskForGETImage(_ size: String, filePath: String, completionHandlerForImage: @escaping (_ imageData: Data?, _ error: NSError?) -> Void)  {
        
        /* 1. Set the parameters */
        // There are none...
        
        /* 2/3. Build the URL and configure the request */
        let baseURL = URL(string: config.baseImageURLString)!
        let url = baseURL.appendingPathComponent(size).appendingPathComponent(filePath)
        let request = URLRequest(url: url)
        
        /* 4. Make the request */
        let task = session.dataTask(with: request) { (data, response, error) in
            
            /* GUARD: Was there an error? */
            guard (error == nil) else {
                print(error!)
                return
            }
            
            /* GUARD: Did we get a successful 2XX response? */
            guard let statusCode = (response as? HTTPURLResponse)?.statusCode, statusCode >= 200 && statusCode <= 299 else {
                if let errorMessageFromJSON = self.parseErrorFromTMDB(methodDescription: nil, data: data!) {
                    print(errorMessageFromJSON)
                }
                return
            }
            
            /* GUARD: Was there any data returned? */
            guard let data = data else {
                print("No data was returned by the Image request!")
                return
            }
            
            /* 5/6. Parse the data and use the data (happens in completion handler) */
            completionHandlerForImage(data, nil)
        }
        
        /* 7. Start the request */
        task.resume()
    }
    
    // MARK: Helpers
    
    // substitute the key for the value that is contained within the method name
    func substituteKeyInMethod(_ method: String, key: String, value: String) -> String? {
        if method.range(of: "{\(key)}") != nil {
            return method.replacingOccurrences(of: "{\(key)}", with: value)
        } else {
            return nil
        }
    }
    
    func parseErrorFromTMDB(methodDescription: String?, data: Data) -> String? {
        var errorString: String? = nil
        do {
            let jsonDecoder = JSONDecoder()
            let jsonData = Data(data)
            let decodedError = try jsonDecoder.decode(TMDBError.self, from: jsonData)
            if decodedError.status_code != nil {
                var message = "* An errorString was returned from parseErrorFromTMDB"
                message += "There was an error with your \(String(describing: methodDescription)) \n"
                message += "Movie Database returned an error of code \(String(describing: decodedError.status_code)) \n"
                message += "message reads \(String(describing: decodedError.status_message))"
                errorString = message
            }
        }
        catch {print(error)}
        return errorString
    }
    
    // given raw JSON, return a usable Foundation object
    //    private func convertDataWithCompletionHandler(_ data: Data, completionHandlerForConvertData: (_ result: AnyObject?, _ error: NSError?) -> Void) {
    //
    //        var parsedResult: AnyObject! = nil
    //        do {
    //            parsedResult = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as AnyObject
    //        } catch {
    //            let userInfo = [NSLocalizedDescriptionKey : "Could not parse the data as JSON: '\(data)'"]
    //            completionHandlerForConvertData(nil, NSError(domain: "convertDataWithCompletionHandler", code: 1, userInfo: userInfo))
    //        }
    //
    //        completionHandlerForConvertData(parsedResult, nil)
    //    }
    
    // create a URL from parameters
    class func tmdbURLFromParameters(_ parameters: [String:AnyObject], withPathExtension: String? = nil) -> URL {
        
        var components = URLComponents()
        components.scheme = TMDBClient.Constants.ApiScheme
        components.host = TMDBClient.Constants.ApiHost
        components.path = TMDBClient.Constants.ApiPath + (withPathExtension ?? "")
        components.queryItems = [URLQueryItem]()
        
        for (key, value) in parameters {
            let queryItem = URLQueryItem(name: key, value: "\(value)")
            components.queryItems!.append(queryItem)
        }
        
        return components.url!
    }
    
    // MARK: Shared Instance
    
    class func sharedInstance() -> TMDBClient {
        struct Singleton {
            static var sharedInstance = TMDBClient()
        }
        return Singleton.sharedInstance
    }
}
