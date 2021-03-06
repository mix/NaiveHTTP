//
//  FakabilityTests.swift
//  NaiveHTTP
//
//  Created by Robert Otani on 9/7/15.
//  Copyright © 2015 otanistudio.com. All rights reserved.
//

import XCTest

class FakeTests: XCTestCase {
    
    struct FakeNaive: NaiveHTTPProtocol {
        let errorDomain = "com.otanistudio.FakeNaive.error"
        
        var urlSession: NSURLSession {
            return NSURLSession(configuration: configuration)
        }
        
        var configuration: NSURLSessionConfiguration {
            return NSURLSessionConfiguration.ephemeralSessionConfiguration()
        }
        
        let commonJSONString = "{\"somekey\":\"somevalue\"}"
        
        private func fakeAsync(
            success:((data: NSData, response: NSURLResponse)->())?,
            failure:((error: NSError)->())?) -> NSURLSessionDataTask? {
                
            let s = NSString(string: commonJSONString)
            let data = s.dataUsingEncoding(NSUTF8StringEncoding)
            let resp = NSURLResponse()
            success!(data: data!, response: resp)
            
            return nil
        }
        
        func performRequest(method: Method, uri: String, body: NSData?, headers: [String : String]?, completion: ((data: NSData?, response: NSURLResponse?, error: NSError?) -> Void)?)  -> NSURLSessionDataTask? {
            
            return fakeAsync({ (data, response) -> () in
                completion!(data: data, response: response, error: nil)
            }) { (error) -> () in
                completion!(data: nil, response: nil, error: error)
            }
        }
    }
    
    override func setUp() {
        super.setUp()
    }
    
    func testBasicFake() {
        let fakeNaive = FakeNaive()
        let asyncExpectation = self.expectationWithDescription("async expectation")
        
        fakeNaive.GET("http://example.com", params: nil, headers: nil) { [asyncExpectation](data, response, error) -> () in
            XCTAssertNil(error)
            let resultString = NSString(data: data!, encoding: NSUTF8StringEncoding)
            XCTAssertEqual(fakeNaive.commonJSONString, resultString)
            asyncExpectation.fulfill()
        }
        
        self.waitForExpectationsWithTimeout(1.0, handler: nil)
        
    }
    
    func testJSONGET() {
        // This is nice because we only needed to write one struct, and we inherit
        // expected behavior from the other protocol extensions
        let fakeNaive = FakeNaive()
        let asyncExpectation = self.expectationWithDescription("async expectation")
        
        fakeNaive.GET("http://example.com/whatever", params: nil, headers: nil) { (data, response, error) -> Void in
            XCTAssertNil(error)
            let json = try! NSJSONSerialization.JSONObjectWithData(data!, options: NSJSONReadingOptions.AllowFragments)
            XCTAssertEqual("somevalue", json["somekey"]!)
            asyncExpectation.fulfill()
        }
        
        self.waitForExpectationsWithTimeout(1.0, handler: nil)
    }
    
}