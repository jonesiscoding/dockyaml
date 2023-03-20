//
//  main.swift
//  dockutil-yaml
//
//  Created by Aaron Jones on 3/11/23.
//

import Foundation

protocol SpecialApp {
    var key: String { get }
    var label: String { get }
    var url: URL? { get }

}

extension SpecialApp {
    func getLabel() -> String? {
        if let url: URL = self.url {
            return url.lastPathComponent.replacingOccurrences(of: ".app", with: "")
        }
        
        return nil
    }
    
    func getAdobeUrl(name: String) -> URL? {
        var urls: [URL] = []
        let normalized = name.capitalized
            .replacingOccurrences(of: "Indesign", with: "InDesign")
            .replacingOccurrences(of: "Xd", with: "XD")
        for i in 2014...2024 {
            let possible: [String] = [
                "/Applications/Adobe \(normalized) \(i)/Adobe \(normalized) \(i).app",
                "/Applications/Adobe \(normalized) \(i)/Adobe \(normalized).app",
                "/Applications/Adobe \(normalized)/Adobe \(normalized).app",
                "/Applications/Adobe \(normalized) CC \(i)/Adobe \(normalized).app",
                "/Applications/Adobe \(normalized) CC/Adobe \(normalized).app",
            ]
            
            if let url = getUrl(possible: possible) {
                urls.append(url)
            }
        }
        
        if let url = urls.first {
            return url
        }
        
        return nil
    }
    
    func getUrl(possible: [String]) -> URL? {
        let fm = FileManager()
        for path in possible {
            if(fm.fileExists(atPath: path)) {
                return URL(fileURLWithPath: path)
            }
        }
        
        return nil
    }
}

struct Safari:SpecialApp {
    var key: String = "safari"
    var label: String = "Safari"
    var url:URL? = URL(fileURLWithPath: "/System/Volumes/Preboot/Cryptexes/App/System/Applications/Safari.app")
}

struct ScreenSharing:SpecialApp {
    var key: String = "screen_sharing"
    var label: String = "Screen Sharing"
    var url:URL? = URL(fileURLWithPath: "/System/Library/CoreServices/Applications/Screen Sharing.app")
}

struct Acrobat:SpecialApp {
    var key: String = "acrobat"
    var label: String {
        getLabel() ?? ""
    }
    var url:URL? {
        let possible: [String] = [
            "/Applications/Adobe Acrobat DC/Adobe Acrobat.app",
            "/Applications/Adobe Acrobat XI Pro/Adobe Acrobat Pro.app",
            "/Applications/Adobe Acrobat Reader DC.app",
            "/Applications/Adobe Acrobat Reader.app",
            "/Applications/Adobe Acrobat.app",
            "/System/Applications/Preview.app"
        ]
        
        return getUrl(possible: possible)
    }
}

class AdobeApp:SpecialApp {
    var key: String
    var label: String {
        return self.getLabel() ?? self.key.capitalized
    }
    var url:URL? {
        return getAdobeUrl(name: self.key)
    }
    
    init(key: String) {
        self.key = key
    }
}

class Photoshop:AdobeApp {
    init() {
        super.init(key: "photoshop")
    }
}

class InDesign:AdobeApp {
    init() {
        super.init(key: "indesign")
    }
}

class Illustrator:AdobeApp {
    init() {
        super.init(key: "illustrator")
    }
}

class XD:AdobeApp {
    init() {
        super.init(key: "xd")
    }
}

class Dimension:AdobeApp {
    init() {
        super.init(key: "dimension")
    }
}

class Animate:AdobeApp {
    init() {
        super.init(key: "animate")
    }
}

class Lightroom:AdobeApp {
    init() {
        super.init(key: "lightroom")
    }
}
