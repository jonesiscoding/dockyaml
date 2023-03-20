//
//  DockTile.swift
//  dockutil-yaml
//
//  Created by Aaron Jones on 3/11/23.
//

import Foundation
import Commands

protocol DockTileProtocol: Codable {
    var label: String { get set }
    var link: URL? { get set }
    var section: DockSection { get set }
    var display: String? { get set }
    var view: String? { get set }
    var sort: String? { get set }
}

class DockTile: DockTileProtocol {
    var label: String
    var link: URL?
    var section: DockSection
    var display: String?
    var view: String?
    var sort: String?
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(label, forKey: .label)
        try container.encode(section, forKey: .section)
        try container.encodeIfPresent(link, forKey: .link)
        try container.encodeIfPresent(display, forKey: .display)
        try container.encodeIfPresent(view, forKey: .view)
        try container.encodeIfPresent(sort, forKey: .sort)
    }
    
    init(label: String, section: DockSection, link: URL? = nil, display: String? = nil, view: String? = nil, sort: String? = nil) {
        self.label = label
        self.link = link
        self.section = section
        self.display = display
        self.view = view
        self.sort = sort
    }
}

class DockFileTile: DockTile {
    var type: TileType = TileType.file
    
    init(link: URL, section: DockSection) {
        let label = link.deletingPathExtension().lastPathComponent
        super.init(label: label, section: section, link: link)
    }
    
    init(fromDefault: DefaultsDockTile) {
        let linkStr = fromDefault.url ?? "/Applications"
        let linkNormal = linkStr.replacingOccurrences(of: "file://", with: "").replacingOccurrences(of: "%20", with: " ")
        let linkUrl = URL(fileURLWithPath: linkNormal)
        var labelStr = fromDefault.label ?? ""
        if(labelStr.isEmpty) {
            labelStr = linkUrl.deletingPathExtension().lastPathComponent
        }
        
        super.init(label: labelStr, section: fromDefault.section, link: linkUrl)
    }
    
    init(fromDictionary: Dictionary<String, String>, section: DockSection = DockSection.persistentOthers) {
        var labelStr: String
        let linkUrl: URL?
        if let linkStr = fromDictionary["link"] {
            let linkNormal: String = linkStr.replacingOccurrences(of: "file://", with: "").replacingOccurrences(of: "%20", with: " ")
            linkUrl = URL(fileURLWithPath: linkNormal)
            labelStr = fromDictionary["label"] ?? ""
            if labelStr.isEmpty {
                labelStr = linkUrl?.deletingPathExtension().lastPathComponent ?? linkNormal
            }
        } else {
            linkUrl = URL(fileURLWithPath: "/Applications")
            labelStr = fromDictionary["label"] ?? ""
        }
        
        super.init(
            label: labelStr,
            section: section,
            link: linkUrl ?? nil
        )
    }
    
    required init(from decoder: Decoder) throws {
        try super.init(from: decoder)
    }
}

class DockUrlTile: DockTile {
    var type: TileType = TileType.url
    
    init(fromDefault: DefaultsDockTile) {
        let linkStr = fromDefault.url ?? "https://google.com"
        var labelStr = fromDefault.label ?? ""
        if let linkUrl = URL(string: linkStr) {
            if(labelStr.isEmpty) {
                labelStr = linkUrl.host ?? "Unknown"
            }
            
            super.init(label: labelStr, section: fromDefault.section, link: linkUrl)
        } else {
            super.init(label: labelStr, section: fromDefault.section)
        }
    }
    
    init(fromDictionary: Dictionary<String, String>, section: DockSection = DockSection.persistentOthers) {
        var labelStr: String = fromDictionary["label"] ??  ""
        let linkStr: String = fromDictionary["link"] ?? "https://google.com"
        if let linkUrl = URL(string: linkStr) {
            if(labelStr.isEmpty) {
                labelStr = linkUrl.host ?? "Unknown"
            }
            
            super.init(label: labelStr, section: section, link: linkUrl)
        } else {
            super.init(label: labelStr, section: section)
        }
    }
    
    required init(from decoder: Decoder) throws {
        try super.init(from: decoder)
    }
}

class DockDirectoryTile: DockTile {
    var type: TileType = TileType.directory
    
    init(link: URL, section: DockSection, display: String? = nil, view: String? = nil, sort: String? = nil) {
        let label = link.deletingPathExtension().lastPathComponent
        super.init(label: label, section: section, link: link, display: display, view: view, sort: sort)
    }
    
    init(fromDefault: DefaultsDockTile) {
        let linkStr = fromDefault.url?.replacingOccurrences(of: "file://", with: "").replacingOccurrences(of: "%20", with: " ") ?? "/Applications"
        let linkUrl = URL(fileURLWithPath: linkStr)
        var labelStr = fromDefault.label ?? ""
        if(labelStr.isEmpty) {
            labelStr = linkUrl.deletingPathExtension().lastPathComponent
        }
        
        var sortStr: String?
        if let sortInt = fromDefault.itemAtKeyPath("arrangement") as? Int {
            sortStr = FolderSort.withValue(value: sortInt)?.description
        }

        var displayStr: String?
        if let displayInt = fromDefault.itemAtKeyPath("displayas") as? Int {
            displayStr = FolderView.withValue(value: displayInt)?.description
        }

        var viewStr: String?
        if let viewInt = fromDefault.itemAtKeyPath("showas") as? Int {
            viewStr = FolderView.withValue(value: viewInt)?.description
        }
        
        super.init(
            label: labelStr,
            section: fromDefault.section,
            link: linkUrl,
            display: displayStr,
            view: viewStr,
            sort: sortStr
        )
    }
    
    init(fromDictionary: Dictionary<String, String>, section: DockSection = DockSection.persistentOthers) {
        var labelStr: String
        let linkUrl: URL?
        if let linkStr = fromDictionary["link"] {
            let linkNormal = linkStr.replacingOccurrences(of: "file://", with: "").replacingOccurrences(of: "%20", with: " ")
            linkUrl = URL(fileURLWithPath: linkNormal)
            labelStr = fromDictionary["label"] ?? ""
            if labelStr.isEmpty {
                labelStr = linkUrl?.lastPathComponent.replacingOccurrences(of: "app", with: "") ?? linkNormal
            }
        } else {
            linkUrl = URL(fileURLWithPath: "/Applications")
            labelStr = fromDictionary["label"] ?? ""
        }
        
        super.init(
            label: labelStr,
            section: section,
            link: linkUrl ?? nil,
            display: fromDictionary["display"],
            view: fromDictionary["view"],
            sort: fromDictionary["sort"]
        )
    }
    
    required init(from decoder: Decoder) throws {
        try super.init(from: decoder)
    }
}

class DockAppTile: DockTile {
    var bundleId: String?
    
    func getBundleId(url: URL) -> String? {
        if(!url.path.isEmpty) {
            let result = Commands.Bash.run("defaults read \"\(url.path)/Contents/Info.plist CFBundleIdentifier")
            if result.isSuccess {
                return result.output
            } else {
                return nil
            }
        }
        
        return nil
    }
    
    func getUrl(forLabel: String) -> URL? {
        if(forLabel != "Safari") {
            let fm = FileManager()
            var url = URL(fileURLWithPath: "/Applications/\(forLabel).app")
            if(fm.fileExists(atPath: url.path)) {
                return url
            }
            
            let homeDir = FileManager.default.homeDirectory(forUser: dockUser)?.path ?? ""
            if(!homeDir.isEmpty) {
                url = URL(fileURLWithPath: "\(homeDir)/Applications/\(forLabel).app")
                if(fm.fileExists(atPath: url.path)) {
                    return url
                }
            }
            
            url = URL(fileURLWithPath: "/System/Applications/\(forLabel).app")
            if(fm.fileExists(atPath: url.path)) {
                return url
            }
        }
        
        let special = [Safari(),Photoshop(),InDesign(),Acrobat(),ScreenSharing(),Illustrator(),XD()] as [SpecialApp]
        for specialApp in special  {
            if(specialApp.key == forLabel.lowercased()) {
                if let url: URL = specialApp.url {
                    return url
                }
            }
        }
        
        return nil
    }
    
    init(label: String, section: DockSection) {
        super.init(label: label, section: section)
        if let appLink = getUrl(forLabel: label) {
            let appLabel = self.label
            if(appLabel.lowercased().replacingOccurrences(of: " ", with: "-") == self.label) {
                self.label = (appLink.lastPathComponent.replacingOccurrences(of: ".app", with: ""))
            }
            
            self.link = appLink
            self.bundleId = getBundleId(url: appLink)
        }
    }
    
    init(label: String, section: DockSection, link: URL) {
        super.init(label: label, section: section, link: link)
    }
    
    init(fromDefaults: DefaultsDockTile) {
        let labelStr = fromDefaults.label ?? ""
        super.init(label: labelStr, section: fromDefaults.section)
        
        if let linkStr = fromDefaults.url {
            let linkNormal = linkStr.replacingOccurrences(of: "file://", with: "").replacingOccurrences(of: "%20", with: " ")
            self.link = URL(fileURLWithPath: linkNormal)
            if self.label.isEmpty {
                if let lastPath = self.link?.lastPathComponent {
                    self.label = lastPath.replacingOccurrences(of: "app", with: "")
                }
            }
        } else if !self.label.isEmpty {
            self.link = getUrl(forLabel: self.label)
        }
        
        if let link = self.link {
            self.bundleId = getBundleId(url: link)
        }
    }
    
    init(fromDictionary: Dictionary<String, String>, section: DockSection = DockSection.persistentOthers) {
        let labelStr = fromDictionary["label"] ?? ""
        super.init(label: labelStr, section: section)
        
        if let linkStr = fromDictionary["link"] {
            self.link = URL(fileURLWithPath: linkStr)
            if self.label.isEmpty {
                if let lastPath = self.link?.lastPathComponent {
                    self.label = lastPath.replacingOccurrences(of: "app", with: "")
                }
            }
            
            if(self.label.lowercased().replacingOccurrences(of: " ", with: "-") == self.label) {
                if let lastPath = self.link?.lastPathComponent {
                    self.label = (lastPath.replacingOccurrences(of: ".app", with: ""))
                }
            }
        } else if !self.label.isEmpty {
            self.link = getUrl(forLabel: self.label)
        }

        if let link = self.link {
            self.bundleId = getBundleId(url: link)
        }
    }
    
    required init(from decoder: Decoder) throws {
        try super.init(from: decoder)
    }
}

//struct DockOtherTile: DockTileProtocol, Codable {
//    var label: String
//    var link: URL?
//    var section: DockSection
//    var display: String?
//    var view: String?
//    var sort: String?
//
//    func isSimple() -> Bool {
//        return false
//    }
//
//    func encode(to encoder: Encoder) throws {
//        var container = encoder.container(keyedBy: CodingKeys.self)
//        try container.encode(label, forKey: .label)
//        try container.encode(section, forKey: .section)
//        if let eLink = self.link {
//            try container.encode(eLink, forKey: .link)
//        }
//        if let eDisplay = self.display {
//            try container.encode(eDisplay, forKey: .display)
//        }
//        if let eView = self.view {
//            try container.encode(eView, forKey: .view)
//        }
//        if let eSort = self.sort {
//            try container.encode(eSort, forKey: .sort)
//        }
//    }
//
//    init(label: String, section: DockSection, link: URL? = nil, display: String? = nil, view: String? = nil, sort: String? = nil) {
//        self.label = label
//        self.section = section
//        self.link = link
//        self.display = display
//        self.view = view
//        self.sort = sort
//    }
//
//    init(fromDictionary: Dictionary<String, String>) {
//        if let linkStr = fromDictionary["link"] {
//            let linkUrl = URL(fileURLWithPath: linkStr)
//            self.link = linkUrl
//            if fromDictionary["label"] == nil {
//                self.label = linkUrl.lastPathComponent
//            }
//        }
//
//        if let label = fromDictionary["label"] {
//            self.label = label
//        } else if let label = self.link?.lastPathComponent {
//            self.label = label
//        } else {
//            self.label = "Unknown"
//        }
//
//        self.display = fromDictionary["display"]
//        self.view = fromDictionary["view"]
//        self.sort = fromDictionary["sort"]
//        self.section = DockSection.persistentOthers
//    }
//}

class DefaultsDockTile {
    var dict: [String: AnyObject]
    var section: DockSection
    
    init(dict: [String:AnyObject], section: DockSection) {
        self.dict = dict
        self.section = section
    }
    
//    GUID = 1706939552;
//    "tile-data" =             {
//        book = {length = 592, bytes = 0x626f6f6b 50020000 00000410 30000000 ... 04000000 00000000 };
//        "bundle-identifier" = "com.apple.TV";
//        "dock-extra" = 0;
//        "file-data" =                 {
//            "_CFURLString" = "file:///System/Applications/TV.app/";
//            "_CFURLStringType" = 15;
//        };
//        "file-label" = TV;
//        "file-mod-date" = 3665116737;
//        "file-type" = 41;
//        "parent-mod-date" = 3665366337;
//    };
//    "tile-type" = "file-tile";
    
    func itemAtKeyPath(_ keyPath: String) -> Any? {
        (dict as NSDictionary).value(forKeyPath: keyPath)
    }

    var label : String? {
        get {
            (itemAtKeyPath("tile-data.file-label") ?? itemAtKeyPath("tile-data.label"))  as? String
        }
    }

    var tileType : String? {
        get {
            itemAtKeyPath("tile-type") as? String
        }
    }

    
    var bundleIdentifier : String? {
        get {
            itemAtKeyPath("tile-data.bundle-identifier") as? String
        }
    }
    
    var url : String? {
        get {
            (itemAtKeyPath("tile-data.file-data._CFURLString") ?? itemAtKeyPath("tile-data.url._CFURLString")) as? String
        }
    }
}
