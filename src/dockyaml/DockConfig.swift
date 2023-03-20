//
//  DockConfig.swift
//  dockyaml
//
//  Created by Aaron Jones on 3/18/23.
//

import Foundation
import Yams
import Commands
import OSAKit
import SystemConfiguration

enum DockSection: String, Codable {
    case persistentApps = "persistent-apps"
    case recentApps = "recent-apps"
    case persistentOthers = "persistent-others"
}

struct Dock: Encodable {
    var apps: [DockTile] = []
    var other: [DockTile] = []
    
    enum CodingKeys: String, CodingKey {
            case apps = "apps"
            case other = "other"
    }
    
    func getSimple(dock: DockTile) -> String? {
        let homeDir = FileManager.default.homeDirectory(forUser: dockUser)?.path ?? ""
        if(dock.section != .persistentApps) {
            return nil
        }
        
        if let outputLink = dock.link {
            let possible: [String] = [
                "/Applications/\(dock.label).app",
                "/System/Applications/\(dock.label).app",
                "\(homeDir)/Applications/\(dock.label).app"
            ]
        
            for poss in possible {
                if(poss == outputLink.path) {
                    return dock.label
                }
            }
            
            let special = [Safari(),Photoshop(),InDesign(),Acrobat(),ScreenSharing(),Illustrator(),XD()] as [SpecialApp]
            let compare = outputLink.lastPathComponent.replacingOccurrences(of: ".app", with: "").lowercased()
                
            for specialApp in special {
                if compare.contains(specialApp.key.replacingOccurrences(of: "_", with: " ")) {
                    return specialApp.key
                }
            }
        }
        
        return nil
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        var appData: [String] = []
        for app in self.apps {
            if let simple = self.getSimple(dock: app) {
                appData.append(simple)
            } else if let link = app.link {
                appData.append(link.path)
            } else {
                appData.append(app.label)
            }
        }
        
        try container.encode(appData, forKey: .apps)
        try container.encode(other, forKey: .other)
    }
    
}

struct DockConfig {
    let sections : [DockSection] = [.persistentApps, .recentApps, .persistentOthers]
    var dockItems = [DockSection:[DockTile]]()
    
    func getDictionary(node: Node) -> Dictionary<String,  String> {
        var dict: Dictionary<String, String> = [:]
        if let map = node.mapping {
            let keys = map.keys
            for key in keys {
                if let keyStr = key.string {
                    if let value = map[keyStr] {
                        if let valStr = value.string {
                            dict.updateValue(valStr, forKey: keyStr)
                        }
                    }
                }
            }
        }
        
        return dict
    }
    
    func getTile(fromDictionary: Dictionary<String, String>) -> DockTile? {
        if(isDirectory(dict: fromDictionary)) {
            return DockDirectoryTile(fromDictionary: fromDictionary, section: .persistentOthers)
        } else if(isFile(dict: fromDictionary)) {
            return DockFileTile(fromDictionary: fromDictionary, section: .persistentOthers)
        } else if(isUrl(dict: fromDictionary)) {
            return DockUrlTile(fromDictionary: fromDictionary, section: .persistentOthers)
        } else if(isApp(dict: fromDictionary)) {
            return DockAppTile(fromDictionary: fromDictionary, section: .persistentOthers)
        }
        
        return nil
    }
    
    func isDirectory(dict: Dictionary<String, String>) -> Bool {
        if dict["display"] != nil || dict["view"] != nil || dict["sort"] != nil {
            return true
        }
        
        if let link = dict["link"] {
            let normalized = link.replacingOccurrences(of: "file://", with: "").replacingOccurrences(of: "%20", with: " ")
            if normalized.hasPrefix("/") {
                let fm = FileManager()
                var isDir : ObjCBool = true
                if fm.fileExists(atPath: normalized, isDirectory: &isDir) {
                    return true
                }
            }
        }
        
        
        return false
    }
    
    func isFile(dict: Dictionary<String, String>) -> Bool {
        if dict["display"] != nil || dict["view"] != nil || dict["sort"] != nil {
            return false
        }
        
        if let link = dict["link"] {
            let normalized = link.replacingOccurrences(of: "file://", with: "").replacingOccurrences(of: "%20", with: " ")
            if normalized.hasPrefix("/") {
                let fm = FileManager()
                var isDir : ObjCBool = false
                if fm.fileExists(atPath: normalized, isDirectory: &isDir) {
                    return true
                }
            }
            
        }
        
        return false
    }

    func isUrl(dict: Dictionary<String, String>) -> Bool {
        if dict["display"] != nil || dict["view"] != nil || dict["sort"] != nil {
            return false
        }
        
        if let link = dict["link"] {
            if !link.hasPrefix("file://") {
                if URL(string: link) != nil {
                    return true
                }
            }
        }
        
        return false
    }
    
    func isApp(dict: Dictionary<String, String>) -> Bool {
        if dict["display"] != nil || dict["view"] != nil || dict["sort"] != nil {
            return false
        }
        
        if let link = dict["link"] {
            let normalized = link.replacingOccurrences(of: "file://", with: "").replacingOccurrences(of: "%20", with: " ")
            if normalized.hasPrefix("/") {
                let fm = FileManager()
                if fm.fileExists(atPath: "\(normalized)/Contents/Info.plist") {
                    return true
                }
            }
        }
        
        return false
    }
    
    init(fromYaml: String) throws {
        self.dockItems[.persistentApps] = []
        self.dockItems[.persistentOthers] = []
        let yamlString = fromYaml

        do {
          let yamlRealNode = try Yams.compose(yaml: yamlString)!
          let yamlMapping = yamlRealNode.mapping
            let yamlValues = yamlMapping?.values
            for value in yamlValues! {
                if let list = value.sequence {
                    for item in list {
                        if let itemStr = item.string {
                            let tile = DockAppTile(label: itemStr, section: DockSection.persistentApps)
                            self.dockItems[.persistentApps]!.append(tile)
                        } else {
                            let i = getDictionary(node: item)
                            if let tile = getTile(fromDictionary: i) {
                                self.dockItems[tile.section]!.append(tile)
                            }
                        }
                    }
                } else {
                    if let map = value.mapping {
                        let keys = map.keys
                        for key in keys {
                            if let keyStr = key.string {
                                if let keyNode = map[keyStr] {
                                    let item = getDictionary(node: keyNode)
                                    if let tile = getTile(fromDictionary: item) {
                                        self.dockItems[tile.section]!.append(tile)
                                    }
                                }
                            }
                        }
                    }
                }
            }
        } catch {
          print("handle error: \(error)")
        }
    }
}
