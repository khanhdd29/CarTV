//
//  String+Localized.swift
//  SwiftBase
//
//  Created by VanTuan on 18/6/26.
//

import Foundation

extension String {
    var localized: String {
        let lang = UserDefaults.standard.string(forKey: Constants.Key.languageSelected) ?? "en"

        if let path = Bundle.main.path(forResource: lang, ofType: "lproj"),
           let bundle = Bundle(path: path) {
            return NSLocalizedString(self, tableName: nil, bundle: bundle, value: "", comment: "")
        }

        return NSLocalizedString(self, comment: "")
    }
}
