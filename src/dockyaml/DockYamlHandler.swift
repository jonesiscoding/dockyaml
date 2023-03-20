//
//  DockYaml.swift
//  dockutil-yaml
//
//  Created by Aaron Jones on 3/19/23.
//

import Foundation
import Yams

class DockYamlHandler {
    var yaml: URL
    var sections: [DockSection] = [DockSection.persistentApps, DockSection.persistentOthers]
    
    init(yaml: String) {
        self.yaml = URL(fileURLWithPath: yaml)
    }
    
    init(yaml: URL) {
        self.yaml = yaml
    }
    
    func toPreferences(dockUser: String) throws {
        let dockUtil = DockUtil(forUser: dockUser)
        let yamlString: String = try String(contentsOf: yaml, encoding: .utf8)
        let dockConfig = try DockConfig(fromYaml: yamlString)
        
        dockUtil.writeDock(dock: dockConfig)
    }
    
    // Reads preference list into DockConfig object, then writes to this object's Yaml file
    // Noted portions from:
    //      DockUtil (https://github.com/kcrawford/dockutil/)
    //      Apache 2.0 License (https://www.apache.org/licenses/LICENSE-2.0)
    //      Created by Kyle Crawford on 2/15/22.
    //      Copyright © 2022 KC. All rights reserved.
    func fromPreferenceList(dockPlist: URL) {
        let fm = FileManager()
        if(fm.fileExists(atPath: dockPlist.path)) {
            
            // BEGIN DOCKUTIL CODE
            let p = Process()
            p.executableURL = URL(fileURLWithPath: "/usr/bin/defaults")
            p.arguments = ["export", dockPlist.path, "-"]
            let outPipe = Pipe()
            p.standardOutput = outPipe
            p.launch()
            p.waitUntilExit()
            
            let defaultsExportData = outPipe.fileHandleForReading.readDataToEndOfFile()
            
            guard let dict = try? PropertyListSerialization.propertyList(from: defaultsExportData, options: .mutableContainersAndLeaves, format: nil) as? [String:AnyObject] else {
                print("failed to deserialize plist", dockPlist.path)
                return
            }
            
            var dock = Dock()
            for section in sections {
                if let value = dict[section.rawValue] as? [[String: AnyObject]] {
                    let dockItems: [DefaultsDockTile] = value.map({item in
                        DefaultsDockTile(dict: item, section: section)
                    })
                    // END DOCKUTIL CODE
                    
                    if(section == .persistentApps) {
                        for dockItem in dockItems {
                            if(dockItem.tileType == TileType.file.rawValue) {
                                let tile: DockAppTile = DockAppTile(fromDefaults: dockItem)
                                dock.apps.append(tile)
                            }
                        }
                    }
                    
                    if(section == .persistentOthers) {
                        for dockItem in dockItems {
                            switch(dockItem.tileType) {
                            case TileType.file.rawValue:
                                var tile: DockTile
                                if let urlStr = dockItem.url {
                                    let url = URL(fileURLWithPath: urlStr)
                                    if(url.pathExtension == "app") {
                                        tile = DockAppTile(fromDefaults: dockItem)
                                    } else {
                                        tile = DockFileTile(fromDefault: dockItem)
                                    }
                                    dock.other.append(tile)
                                }
                            case TileType.url.rawValue:
                                let tile = DockUrlTile(fromDefault: dockItem)
                                dock.other.append(tile)
                                break;
                            case TileType.directory.rawValue:
                                let tile: DockDirectoryTile = DockDirectoryTile(fromDefault: dockItem)
                                dock.other.append(tile)
                            default:
                                // We are ignoring spacrers for now
                                break;
                            }
                            
                            if(dockItem.tileType == TileType.file.rawValue) {
                                let tile: DockAppTile = DockAppTile(fromDefaults: dockItem)
                                dock.apps.append(tile)
                            }
                        }
                    }
                }
            }
            
            self.writeYaml(dock: dock)
        }
    }
    
    func fromPreferences(dockUser: String) {
        let homeDir = FileManager.default.homeDirectory(forUser: dockUser)?.path ?? ""
        let dockPlist = "\(homeDir)/Library/Preferences/com.apple.dock.plist"
        
        self.fromPreferenceList(dockPlist: URL(fileURLWithPath: dockPlist))
    }
    
    private func writeYaml(dock: Dock) {
        let yamlEncoder: YAMLEncoder = YAMLEncoder();
        do {
            let yaml = try yamlEncoder.encode(dock)
            try yaml.write(to: self.yaml, atomically: true, encoding: String.Encoding.utf8)
        } catch {
        // Handle error
        print(error)
        }
    }
}
