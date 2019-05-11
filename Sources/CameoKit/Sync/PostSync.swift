//
//  PostSync.swift
//  Camouflage
//
//  Created by Todd on 1/25/19.
//  Copyright © 2019 Todd Bruss. All rights reserved.
//

import Foundation

typealias PostReturnTuple = (message: String, success: Bool, data: Dictionary<String, Any>, response: HTTPURLResponse )

internal func PostSync(request: Dictionary<String, Any>, endpoint: String, method: String) -> PostReturnTuple  {
    
    //MARK - for Sync
    let semaphore = DispatchSemaphore(value: 0)
    var syncData : PostReturnTuple? = (message: "", success: false, data: Dictionary<String, Any>(), response: HTTPURLResponse() )
    let http_method = "POST"
    let time_out = 30
    let url = URL(string: endpoint)
    var urlReq : URLRequest? = URLRequest(url: url!)
    
    if urlReq != nil {
        urlReq!.httpBody = try? JSONSerialization.data(withJSONObject: request, options: .prettyPrinted)
        urlReq!.addValue("application/json", forHTTPHeaderField: "Content-Type")
        urlReq!.httpMethod = http_method
        urlReq!.timeoutInterval = TimeInterval(time_out)
        urlReq!.setValue("Mozilla/5.0 (Macintosh; Intel Mac OS X 10_14_2) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/12.0.2 Safari/605.1.15", forHTTPHeaderField: "User-Agent")
        let task = URLSession.shared.dataTask(with: urlReq! ) { ( rData, resp, error ) in
            
            if resp != nil && (resp as? HTTPURLResponse)!.statusCode == 200 {
                
                var result : Dictionary? = Dictionary<String, Any>()
                var myData : Data? = Data()
                myData = rData 
                
                do {
                    result = try? JSONSerialization.jsonObject(with: myData!, options: JSONSerialization.ReadingOptions.allowFragments) as? Dictionary<String, Any> ?? nil
                } 
                

                syncData = ((message: method + " was successful.", success: true, data: result, response: resp as! HTTPURLResponse ) as! PostReturnTuple)
                
                myData = nil
                result = nil
            } else {
                //we always require 200 on the post, anything else is a failure
                
                if resp != nil {
                    syncData = (message: method + " failed, see response.", success: false, data: ["": ""], response: resp as! HTTPURLResponse ) as PostReturnTuple
                } else {
                    syncData = (message: method + " failed, no response.", success: false, data: ["": ""], response: HTTPURLResponse() ) as PostReturnTuple
                }
            }
            
            //MARK - for Sync
            semaphore.signal()
        }
        
        task.resume()
        _ = semaphore.wait(timeout: .distantFuture)
    }

    urlReq = nil
    
    if syncData != nil {
        return syncData!
    }
    
    return (message: method + " failed!", success: false, data: ["Error": "Fatal Error"], response: HTTPURLResponse() ) as PostReturnTuple
}


