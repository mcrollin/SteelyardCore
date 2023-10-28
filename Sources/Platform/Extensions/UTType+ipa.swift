//
//  File.swift
//  
//
//  Created by Marc Rollin on 28/10/2023.
//

import Foundation
import UniformTypeIdentifiers

extension UTType {

    public static var ipa: UTType {
        UTType(exportedAs: "com.apple.itunes.ipa", conformingTo: .data)
    }
}
