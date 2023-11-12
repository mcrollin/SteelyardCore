//
//  File.swift
//  
//
//  Created by Marc Rollin on 10/11/2023.
//

import Foundation

public extension Bundle {

    static var marketingVersion: String? {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String
    }

    static var buildNumber: String? {
        Bundle.main.object(forInfoDictionaryKey: kCFBundleVersionKey as String) as? String
    }
}
