//
//  main.swift
//  dockyaml
//
//  Created by Aaron Jones on 3/11/23.
//

import Foundation
import Yams
import Commands
import OSAKit
import SystemConfiguration

var dockUser: String = "notreal"
var dockPlist: String = "notreal"
var configUrl: URL?
// Switches
var nextUser: Bool = false
var nextYaml: Bool = false
var isDump: Bool = false
var isWrite: Bool = false
var isFile: Bool = false
var isVersion: Bool = false

// Parse the Command Line Arguments
for arg in CommandLine.arguments {
    if arg.hasPrefix("--") {
        nextYaml = false
        nextUser = false
        switch(arg) {
        case "--user":
            nextUser = true
        case "--to":
            isDump = true
            nextYaml = true
        case "--from":
            isWrite = true
            nextYaml = true
        case "--version":
            isVersion = true
        default:
            break;
        }
    } else if(nextUser) {
        dockUser = arg
        nextUser = false
    } else if(nextYaml) {
        configUrl = URL(fileURLWithPath: arg)
        nextYaml = false
    } else if arg.hasSuffix(".plist") {
        dockPlist = arg
    }
}

if(isVersion) {
    print("DockYaml v1.1")
    exit(0)
}

// Get User from Console if not given
if(dockUser == "notreal" && !isFile) {
    guard let consoleUser: String = SCDynamicStoreCopyConsoleUser(nil, nil , nil) as String? else {
        fatalError("Could not detect user.  Please use the --user flag.")
    }
    
    dockUser = consoleUser
}

// Abort if we don't have a Yaml file
if(configUrl == nil) {
    fatalError("You did not include the path to a YAML file!")
}


// Get our handler
let dockHandler = DockYamlHandler(yaml: configUrl!)

// Take action
if(isWrite) {
    try dockHandler.toPreferences(dockUser: dockUser)
} else if(isDump) {
    if(dockPlist != "notreal") {
        dockHandler.fromPreferenceList(dockPlist: URL(fileURLWithPath: dockPlist))
    } else {
        dockHandler.fromPreferences(dockUser: dockUser)
    }
}
