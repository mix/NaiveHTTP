//
//  SwiftyHTTP.swift
//  NaiveHTTP
//
//  Created by Robert Otani on 9/7/15.
//  Copyright © 2015 otanistudio.com. All rights reserved.
//

import Foundation
import NaiveHTTP
import enum NaiveHTTP.Method
import SwiftyJSON

public enum SwiftyHTTPError: ErrorType {
    case HTTPBodyDataConversion
    case SwiftyJSONInternal
}

public final class SwiftyHTTP: NaiveHTTPProtocol {
    public let errorDomain = "com.otanistudio.SwiftyHTTP.error"
    public typealias swiftyCompletion = (json: SwiftyJSON.JSON?, response: NSURLResponse?, error: NSError?) -> Void
    
    let naive: NaiveHTTP
    
    public var urlSession: NSURLSession {
        return naive.urlSession
    }
    
    public var configuration: NSURLSessionConfiguration {
        return naive.configuration
    }
    
    required public init(_ naiveHTTP: NaiveHTTP? = nil, configuration: NSURLSessionConfiguration? = nil) {
        if naiveHTTP == nil {
            naive = NaiveHTTP(configuration)
        } else {
            naive = naiveHTTP!
        }
    }
    
    public func GET(
        uri:String,
        params:[String: String]?,
        responseFilter: String?,
        headers: [String:String]?,
        completion: swiftyCompletion?) -> NSURLSessionDataTask? {

        return naive.GET(uri,
            params: params,
            headers: self.jsonHeaders(headers)) { [weak self](data, response, error) -> () in
            
                guard error == nil else {
                    completion?(json: nil, response: response, error: error)
                    return
                }
                
                let json: SwiftyJSON.JSON?
                let jsonError: NSError?
                
                if responseFilter != nil {
                    json = self?.dynamicType.filteredJSON(responseFilter!, data: data)
                } else {
                    json = SwiftyJSON.JSON(data: data!)
                }
                
                jsonError = json!.error
                
                completion?(json: json, response: response, error: jsonError)
            }
    }
    
    public func POST(
        uri: String,
        postObject: AnyObject?,
        responseFilter: String?,
        headers: [String : String]?,
        completion: swiftyCompletion?) -> NSURLSessionDataTask? {
            
            var body: NSData? = nil
            if postObject != nil {
                do {
                    body = try jsonData(postObject!)
                } catch {
                    completion?(json: nil, response: nil, error: naiveHTTPSwiftyJSONError)
                    return nil
                }
            }
            
            return naive.POST(uri, body: body, headers: self.jsonHeaders(headers)) { [weak self](data, response, error)->() in
                guard error == nil else {
                    completion?(json: nil, response: response, error: error)
                    return
                }
                
                // TODO: pass any SwiftyJSON.JSON errors into completion function
                let json: SwiftyJSON.JSON?
                if responseFilter != nil {
                    json = self?.dynamicType.filteredJSON(responseFilter!, data: data)
                } else {
                    json = SwiftyJSON.JSON(data: data!)
                }
                
                completion?(json: json, response: response, error: error)
                
            }
    }
    
    public func PUT(
        uri: String,
        body: AnyObject?,
        responseFilter: String?,
        headers: [String : String]?,
        completion: swiftyCompletion?) -> NSURLSessionDataTask? {
        
        var putBody: NSData? = nil
            
        if body != nil {
            do {
                putBody = try jsonData(body!)
            } catch {
                completion?(json: nil, response: nil, error: naiveHTTPSwiftyJSONError)
                return nil
            }
        }
            
        return naive.PUT(uri, body: putBody, headers: self.jsonHeaders(headers)) { [weak self](data, response, error) -> Void in
            guard error == nil else {
                completion?(json: nil, response: response, error: error)
                return
            }
            
            // TODO: pass any SwiftyJSON.JSON errors into completion function
            let json: SwiftyJSON.JSON?
            if responseFilter != nil {
                json = self?.dynamicType.filteredJSON(responseFilter!, data: data)
            } else {
                json = SwiftyJSON.JSON(data: data!)
            }
            
            completion?(json: json, response: response, error: error)
        }
            
    }

    public func DELETE(
        uri: String,
        body: AnyObject?,
        responseFilter: String?,
        headers: [String : String]?,
        completion: swiftyCompletion?) -> NSURLSessionDataTask? {

        var deleteBody: NSData? = nil
        if body != nil {
            do {
                deleteBody = try jsonData(body!)
            } catch {
                completion?(json: nil, response: nil, error: naiveHTTPSwiftyJSONError)
                return nil
            }
        }
            
        return naive.DELETE(uri, body: deleteBody, headers: self.jsonHeaders(headers)) { [weak self](data, response, error) -> Void in
            guard error == nil else {
                completion?(json: nil, response: response, error: error)
                return
            }

            // TODO: pass any SwiftyJSON.JSON errors into completion function
            let json: SwiftyJSON.JSON?
            if responseFilter != nil {
                json = self?.dynamicType.filteredJSON(responseFilter!, data: data)
            } else {
                json = SwiftyJSON.JSON(data: data!)
            }

            completion?(json: json, response: response, error: error)
        }

    }
    
    /// A convenience function for services that returns a string response prepended with
    /// with an anti-hijacking string.
    ///
    /// Some services return a string, like `while(1);` pre-pended to their SwiftyJSON.JSON string, which can
    /// break the normal decoding dance.
    ///
    /// - parameter prefixFilter: The string to remove from the beginning of the response
    /// - parameter data: The data, usually the response data from of your `NSURLSession` or `NSURLConnection` request
    /// - returns: a valid `SwiftyJSON` object
    public static func filteredJSON(prefixFilter: String, data: NSData?) -> SwiftyJSON.JSON {
        let json: SwiftyJSON.JSON?
        
        if let unfilteredJSONStr = NSString(data: data!, encoding: NSUTF8StringEncoding) {
            if unfilteredJSONStr.hasPrefix(prefixFilter) {
                let range = unfilteredJSONStr.rangeOfString(prefixFilter, options: .LiteralSearch)
                let filteredStr = unfilteredJSONStr.substringFromIndex(range.length)
                let filteredData = filteredStr.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false)
                json = SwiftyJSON.JSON(data: filteredData!)
            } else {
                let filteredData = unfilteredJSONStr.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false)
                json = SwiftyJSON.JSON(data: filteredData!)
            }
        } else {
            json = SwiftyJSON.JSON(NSNull())
        }
        
        return json!
    }
    
    private var naiveHTTPSwiftyJSONError: NSError {
       return NSError(
        domain: errorDomain,
        code: -3,
        userInfo: [
            NSLocalizedFailureReasonErrorKey : "SwiftyJSON Error",
            NSLocalizedDescriptionKey: "Error while processing objects to SwiftyJSON data"
        ])
    }
    
    private func jsonData(object: AnyObject) throws -> NSData {
        do {
            let o = SwiftyJSON.JSON(object)
            if o.type == .String {
                if let jsonData: NSData = (o.stringValue as NSString).dataUsingEncoding(NSUTF8StringEncoding) {
                    return jsonData
                } else {
                    throw SwiftyHTTPError.HTTPBodyDataConversion
                }
            } else {
                return try o.rawData()
            }
        } catch let jsonError as NSError {
            debugPrint("NaiveHTTP+JSON: \(jsonError)")
            throw SwiftyHTTPError.SwiftyJSONInternal
        }
    }
    
    public func performRequest(method: Method, uri: String, body: NSData?, headers: [String : String]?, completion: ((data: NSData?, response: NSURLResponse?, error: NSError?) -> Void)?) -> NSURLSessionDataTask? {
        return naive.performRequest(method, uri: uri, body: body, headers: headers, completion: { (data, response, error) -> Void in
            completion?(data: data, response: response, error: error)
        })
    }

    private func jsonHeaders(additionalHeaders: [String : String]?) -> [String : String] {
        let jsonHeaders: [String : String] = [
            "Accept" : "application/json",
            "Content-Type" : "application/json"
        ]
        
        let headers: [String : String]?
        if let additional = additionalHeaders {
            headers = additional.reduce(jsonHeaders) { dict, pair in
                var fixed = dict
                fixed[pair.0] = pair.1
                return fixed
            }
        } else {
            headers = jsonHeaders
        }
        
        return headers!
    }
}

