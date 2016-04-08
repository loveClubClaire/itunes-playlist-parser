//
//  iTunesXMLGenerator.swift
//  PlaylistParser
//
//  Created by Zachary Whitten on 12/21/15.
//  Copyright © 2015 WCNURadio. All rights reserved.
//

import Foundation

class iTunesXMLGenerator: NSObject{
    
    var ogXMLFile = NSURL()
    var masterDictionary = NSMutableDictionary()
    var finalXMLFile = NSString()
    
    init(aFileURL: NSURL, aMasterDictionary: NSMutableDictionary) {
        ogXMLFile = aFileURL
        masterDictionary = aMasterDictionary
    }
    
    func generate(){
        let fileContent = try? NSString(contentsOfURL: ogXMLFile, encoding: NSUTF8StringEncoding)
        let fileContentArray = fileContent?.componentsSeparatedByString("\n")
        
        //Generate the header of the XML file by ripping it from one of the given XML files
        for(var i = 0; i < fileContentArray?.count; i++){
            finalXMLFile = (finalXMLFile as String) + (fileContentArray![i] as String) + "\n"
            if(fileContentArray![i] == "\t<dict>"){
                i = (fileContentArray?.count)!+1
            }
        }
     
        let masterDictionaryKeys = masterDictionary.allKeys
        print(masterDictionaryKeys.count)
        for(var i = 0; i < masterDictionaryKeys.count; i++){
            let bool = masterDictionary.objectForKey(masterDictionaryKeys[i])
            if(bool != nil){
            if(bool!.isNotEqualTo(NSNull)){
                //add key
                finalXMLFile = (finalXMLFile as String) + "\t\t<key>" + (masterDictionaryKeys[i] as! String) + "</key>\n\t\t\t<dict>\n"
                let songKeys = masterDictionary.objectForKey(masterDictionaryKeys[i])?.allKeys
                let songDictionary = masterDictionary.objectForKey(masterDictionaryKeys[i])
                for(var j = 0; j < songKeys?.count; j++){
                    //add song
                    finalXMLFile = (finalXMLFile as String) + "\t\t\t\t<key>" + (songKeys![j] as String) + "</key>"
                    let value = songDictionary?.objectForKey(songKeys![j]) as! NSString
                    let tag = getFlagType(value)
                    finalXMLFile = (finalXMLFile as String) + "<" + (tag as String) + ">" + (value as String)
                    finalXMLFile = (finalXMLFile as String) + "</" + (tag as String) + ">" + "\n"
                }
                finalXMLFile = (finalXMLFile as String) + "\t\t\t</dict>\n"
            }
        }
        }
        finalXMLFile = (finalXMLFile as String) + "\t</dict>\n"
        finalXMLFile = (finalXMLFile as String) + "\t<key>Playlists</key>\n"
        finalXMLFile = (finalXMLFile as String) + "\t<array>\n\t\t<dict>\n"
        finalXMLFile = (finalXMLFile as String) + "\t\t\t<key>Name</key><string>Generated Playlist</string>\n"
        finalXMLFile = (finalXMLFile as String) + "\t\t\t<key>Description</key><string>This is a description</string>\n"
        finalXMLFile = (finalXMLFile as String) + "\t\t\t<key>All Items</key><true/>\n"
        finalXMLFile = (finalXMLFile as String) + "\t\t\t<key>Playlist Items</key>\n\t\t\t<array>\n"
        
        for(var i = 0; i < masterDictionaryKeys.count; i++){
            finalXMLFile = (finalXMLFile as String) + "\t\t\t\t<dict>\n\t\t\t\t\t<key>Track ID</key><integer>" + (masterDictionaryKeys[i] as! String) + "</integer>\n\t\t\t\t</dict>\n"
        }
        
        finalXMLFile = (finalXMLFile as String) + "\t\t\t</array>\n\t\t</dict>\n\t</array>\n</dict>\n</plist>"
        
        var filepath = ogXMLFile.absoluteString.componentsSeparatedByString("/")
        filepath.removeLast()
        filepath.append("GeneratedPlaylist.xml")
        var newFilepath = ""
        for(var i = 0; i < filepath.count; i++){
            newFilepath = (newFilepath as String) + filepath[i]
            if(i + 1 < filepath.count){
                newFilepath = (newFilepath as String) + "/"
            }
        }
        
        do{
            let newURL = NSURL(string: newFilepath)
            try finalXMLFile.writeToURL(newURL!, atomically: false, encoding: NSUTF8StringEncoding)
        }
            
        catch{
           print("Oops")
        }        
    }
    
    func getFlagType(object: NSString) -> NSString{
        //Constatns
        let zero: unichar = ("0" as NSString).characterAtIndex(0)
        let dash: unichar = ("-" as NSString).characterAtIndex(0)
        
        var toReturn = "string"
        
        if(object.integerValue != 0){
            toReturn = "integer"
        }
        else if(object.length > 7){
            if(object.characterAtIndex(0) != zero && object.characterAtIndex(4) == dash && object.characterAtIndex(6) == dash){
                toReturn = "date"
            }
        }
        
        return toReturn
    }
    
    
}