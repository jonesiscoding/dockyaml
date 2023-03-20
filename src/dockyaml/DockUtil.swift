//
//  DockUtil.swift
//  dockutil-yaml
//
//  Created by Aaron Jones on 3/18/23.
//

import Foundation
import Commands
import Yams

enum TileType: String {
    case spacer = "spacer-tile"
    case smallSpacer = "small-spacer-tile"
    case flexSpacer = "flex-spacer-tile"
    case file = "file-tile"
    case directory = "directory-tile"
    case url = "url-tile"
}

enum FolderSort: Int, CaseIterable, Codable, CustomStringConvertible {
    case name = 1
    case dateadded = 2
    case datemodified = 3
    case datecreated = 4
    case kind = 5

    static func withLabel(_ label: String) -> FolderSort? {
        return self.allCases.first{ "\($0)" == label }
    }
    
    static func withValue(value: Int) -> FolderSort? {
        for sort in self.allCases {
            if(sort.rawValue == value) {
                return sort
            }
        }
        
        
        return nil
    }
    
    var description: String {
        return "\(self)"
    }
}

enum FolderView: Int, CaseIterable, Codable, CustomStringConvertible {
    case auto = 0
    case fan = 1
    case grid = 2
    case list = 3

    static func withLabel(_ label: String) -> FolderView? {
        return self.allCases.first{ "\($0)" == label }
    }
    
    static func withValue(value: Int) -> FolderView? {
        for view in self.allCases {
            if(view.rawValue == value) {
                return view
            }
        }
        
        return nil
    }
    
    var description: String {
        return "\(self)"
    }

}

enum FolderDisplay: Int, CaseIterable {
    case folder = 1
    case stack = 0
    
    static func withLabel(_ label: String) -> FolderDisplay? {
        return self.allCases.first{ "\($0)" == label }
    }
    
    static func withValue(value: Int) -> FolderDisplay? {
        for display in self.allCases {
            if(display.rawValue == value) {
                return display
            }
        }
        
        return nil
    }
    
    var description: String {
        return "\(self)"
    }
}

class DockUtil {
    var sections: [DockSection] = [DockSection.persistentApps, DockSection.persistentOthers]
    var path: String = "/usr/local/bin/dockutil"
    var username: String
    
    init(forUser: String, path: String = "/usr/local/bin/dockutil") {
        self.path = path
        self.username = forUser
    }
    
    func parseDockUtilTile(line: String) -> DockTile {
        let parts = line.components(separatedBy: .whitespaces)
        // Use filter to eliminate empty strings.
        let usable = parts.filter { (x) -> Bool in !x.isEmpty }
        var labelParts: [String] = []
        var link: String?
        var section: DockSection?
        for part in usable {
            if(part.hasPrefix("file://")) {
                link = part.replacingOccurrences(of: "file://", with: "").replacingOccurrences(of: "%20", with: " ")
            } else if(part.hasPrefix("persistent")) {
                if(part == "persistentApps") {
                    section = .persistentApps
                } else {
                    section = .persistentOthers
                }
            } else if(!part.hasSuffix("plist") && !part.contains(".")) {
                labelParts.append(part)
            }
        }
        
        let label = labelParts.joined(separator: " ")
        let url = URL(fileURLWithPath: link ?? "/Applications")
        if(url.pathExtension == "app") {
            return DockAppTile(label: label, section: section ?? .persistentApps, link: url)
        } else {
            var isDir : ObjCBool = true
            let fm = FileManager()
            if fm.fileExists(atPath: url.path, isDirectory: &isDir) {
                return DockTile(label: label, section: section ?? .persistentOthers, link: url, display: "folder", view: "grid", sort: "name")
            } else {
                return DockTile(label: label, section: section ?? .persistentOthers, link: url)
            }
        }
    }
    
    func exportDock(exportTo: String) {
        let result = Commands.Bash.run("\(self.path) --list")
        if(result.isSuccess) {
            var dock = Dock()
            result.output.enumerateLines { (line, _) in
                let tile = self.parseDockUtilTile(line: line)
                if tile is DockAppTile {
                    dock.apps.append(tile)
                } else {
                    dock.other.append(tile)
                }
            }
            
            let yamlEncoder: YAMLEncoder = YAMLEncoder();
            let exportUrl = URL(fileURLWithPath: exportTo)
            do {
                let yaml = try yamlEncoder.encode(dock)
                try yaml.write(to: exportUrl, atomically: true, encoding: String.Encoding.utf8)
            } catch {
            // Handle error
            print(error)
            }
        }
    }
    
    func writeDock(dock: DockConfig) {
        let homeDir = FileManager.default.homeDirectory(forUser: self.username)?.path ?? ""
        let fm = FileManager()
        // Clear the Dock
        let clearCmd = "dockutil --remove all --no-restart \(homeDir)"
        let result = Commands.Bash.run("\(clearCmd)")
        if(!result.isSuccess) {
            print(clearCmd)
            fatalError("\(result.request.arguments ??  "")\n\(result.errorOutput)")
        }
        
        var cmds: [String] = []
        for (_, tiles) in dock.dockItems {
            for tile in tiles {
                var cmd: String = ""
                if let link = tile.link {
                    cmd = ""
                    if(link.isFileURL) {
                        let path = link.path
                        if(!path.isEmpty && fm.fileExists(atPath: path)) {
                            cmd = "\(cmd) --add \"\(path)\""
                            
                            cmd = "\(cmd) --label \"\(tile.label)\" "
                            
                            if tile is DockDirectoryTile {
                                let otherTile: DockDirectoryTile = tile as! DockDirectoryTile
                                let tileView = otherTile.view ?? ""
                                let tileSort = otherTile.sort ?? ""
                                let tileDisplay = otherTile.display ?? ""
                                if(!tileView.isEmpty) {
                                    cmd = "\(cmd) --view \(tileView) "
                                }
                                
                                if(!tileDisplay.isEmpty) {
                                    cmd = "\(cmd) --display \(tileDisplay) "
                                }
                                
                                if(!tileSort.isEmpty) {
                                    cmd = "\(cmd) --sort \(tileSort) "
                                }
                            }
                        }
                    } else {
                        cmd = "\(cmd) --add \"\(link)\""
                        cmd = "\(cmd) --label \"\(tile.label)\" "
                    }
                }
                
                if(!cmd.isEmpty) {
                    cmds.append(cmd)
                }
            }
        }
        
        for cmd in cmds {
            var runMe = cmd
            if(runMe == cmds.last) {
                runMe = "dockutil \(runMe) \(homeDir)"
            } else {
                runMe = "dockutil \(runMe) --no-restart \(homeDir)"
            }
            
            let result = Commands.Bash.run("\(runMe)")
            if(result.isFailure) {
                fatalError(result.errorOutput)
            }
        }
    }
}
