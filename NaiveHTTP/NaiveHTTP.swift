//
//  NaiveHTTP.swift
//  NaiveHTTP
//
//  Created by Robert Otani on 6/20/15.
//  Copyright © 2015 otanistudio.com. All rights reserved.
//

import Foundation
import UIKit

public class NaiveHTTP {
    let urlSession: NSURLSession!
    let configuration: NSURLSessionConfiguration!
    let errorDomain = "com.otanistudio.NaiveHTTP.error"
    
    required public init(configuration: NSURLSessionConfiguration?) {
        if let config = configuration {
            self.configuration = config
            urlSession = NSURLSession(configuration: config)
        } else {
            self.configuration = NSURLSessionConfiguration.defaultSessionConfiguration()
            urlSession = NSURLSession(configuration: NSURLSessionConfiguration.defaultSessionConfiguration())
        }
    }
    
    deinit {
        urlSession.invalidateAndCancel()
    }
    
    public class func normalizedURL(uri uri:String, params:[String: String]?) -> NSURL {
        // Deal with any query params already in the URI String
        let urlComponents = NSURLComponents(string: uri)
        var queryItems: [NSURLQueryItem]? = urlComponents?.queryItems
        
        if queryItems == nil {
            queryItems = []
        }
        
        // Now, incorporate items in queryParams to generate the fully-formed NSURL
        if let p = params {
            for (key, val) in p {
                let qItem = NSURLQueryItem(name: key, value: val)
                queryItems?.append(qItem)
            }
        }
        
        if queryItems!.count > 0 {
            queryItems?.sortInPlace({ (qItem1: NSURLQueryItem, qItem2: NSURLQueryItem) -> Bool in
                return qItem1.name < qItem2.name
            })
            urlComponents?.queryItems = queryItems
        }
        
        return NSURL(string: (urlComponents?.string)!)!
    }
    
    public func imageGET(uri uri:String, success:((image: UIImage?)->())?, failure:(()->())?) {
        
        let url = NSURL(string: uri)!
        let request = NSMutableURLRequest(URL: url)
        request.setValue("image/png,image/jpg,image/jpeg,image/tiff,image/gif", forHTTPHeaderField: "Accept")
        
        urlSession.dataTaskWithRequest(request) { (imageData: NSData?, response: NSURLResponse?, error: NSError?) -> Void in
            
            let image = UIImage(data: imageData!)
            success!(image: image)
            
            }.resume()
        
    }
    
    public func dataGET(uri uri:String, params:[String: String]?, success:((data: NSData)->())?, failure:((error: NSError)->Void)?) {
        
        let url: NSURL =  NaiveHTTP.normalizedURL(uri: uri, params: params)
        
        urlSession.dataTaskWithURL(url) { [weak self](responseData: NSData?, response: NSURLResponse?, error: NSError?) -> Void in
            
            if (error != nil) {
                failure!(error: error!)
                return
            }
            
            let httpResponse = response as! NSHTTPURLResponse
            
            if (httpResponse.statusCode > 400) {
                let responseError = NSError(domain: self!.errorDomain, code: 400, userInfo: nil)
                failure!(error: responseError)
                return
            }
            
            success!(data: responseData!)
            
            }.resume()
    }
    
    public func jsonGET(uri uri:String, params:[String: String]?, success:((json: JSON)->())?, failure:((error: NSError)->Void)?) {
        dataGET(uri: uri, params: params, success: { (data) -> () in
            let json = JSON(data: data)
            
            if let error = json.error {
                debugPrint(error)
                failure!(error: error)
                return
            }
            
            success!(json: json)
            
            }, failure: failure)
    }
    
    public func post(uri uri:String, postObject: AnyObject, additionalHeaders: [String:String]?, success: ((responseJSON: JSON)->())?, failure:((postError: NSError)->())?) {
        let url = NSURL(string: uri)!
        let request = NSMutableURLRequest(URL: url)
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.HTTPMethod = "POST"
        
        if let headers = additionalHeaders {
            for (k, v) in headers {
                request.setValue(v, forHTTPHeaderField: k)
            }
        }
        
        do {
            try request.HTTPBody = JSON(postObject).rawData()
        } catch {
            let postObjectError = NSError(domain: self.errorDomain, code: -1, userInfo: [NSLocalizedFailureReasonErrorKey: "failed to convert postObject to JSON"])
            failure!(postError: postObjectError)
        }
        
        urlSession.dataTaskWithRequest(request) { [weak self](data, response, error) -> Void in
            if error != nil {
                failure!(postError: error!)
                return
            }
            
            let httpResponse = response as! NSHTTPURLResponse
            
            if (httpResponse.statusCode > 400) {
                let responseError = NSError(domain: self!.errorDomain, code: 400, userInfo: [NSLocalizedFailureReasonErrorKey: "400 or above error", NSLocalizedDescriptionKey: "HTTP Error \(httpResponse.statusCode)"])
                failure!(postError: responseError)
                return
            }
            
            let json = JSON(data: data!)
            success!(responseJSON: json)
            }.resume()
    }
    
    public func post(uri uri:String, postObject: AnyObject, success: ((responseJSON: JSON)->Void)?, failure:( (postError: NSError)->Void )?) {
        post(uri: uri, postObject: postObject, additionalHeaders: nil, success: success, failure: failure)
    }
    
    
}