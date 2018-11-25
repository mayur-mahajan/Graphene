//
//  KarbonDevice.swift
//  Graphene
//
//  Created by MAYUR MAHAJAN on 7/14/18.
//  Copyright © 2018 Orion Labs. All rights reserved.
//

import Foundation

class KarbonDevice {

    let name: String
    private(set) var address: String?
    private(set) var port: Int?
    private(set) var isResolved: Bool
    
    init(named name:String) {
        self.name = name
        self.isResolved = false
    }
    
    func resolve(address:String, port:Int, record: [String:Data]?) {
        guard !isResolved else {
            NSLog("ERROR: Device is already resolved")
            return
        }

        self.address = address
        self.port = port
        self.isResolved = true
    }
    
    func makeRequest(path:String, handler: @escaping (Data)->Void) {
        guard isResolved else {
            NSLog("Device is not resolved")
            return
        }

        guard let url = URL(string: "http://\(address!):\(port!)/\(path)") else {
            NSLog("Failed to create URL")
            return
        }
        
        NSLog("Make request to URL \(url)")
        let session = URLSession.shared
        let task = session.dataTask(with: url) { (data, response, error) in
            NSLog("Data \(String(describing: data)), response \(String(describing: response)), error \(String(describing: error))")
            if let data = data {
                handler(data)
            }
        }
        task.resume()
    }
}
