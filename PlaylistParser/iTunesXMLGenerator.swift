//
//  iTunesXMLGenerator.swift
//  PlaylistParser
//
//  Created by Zachary Whitten on 12/21/15.
//  Copyright © 2015 Zachary Whitten. All rights reserved.
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
        for aFileContent in fileContentArray!{
            finalXMLFile = (finalXMLFile as String) + (aFileContent as String) + "\n"
            if(aFileContent == "\t<dict>"){
                break;
            }
        }
        
        let masterDictionaryKeys = masterDictionary.allKeys
        
        for aMasterDictionaryKey in masterDictionaryKeys{
            let bool = masterDictionary.objectForKey(aMasterDictionaryKey)
            if(bool != nil){
                if(bool!.isNotEqualTo(NSNull)){
                    //add key
                    finalXMLFile = (finalXMLFile as String) + "\t\t<key>" + (aMasterDictionaryKey as! String) + "</key>\n\t\t\t<dict>\n"
                    let songKeys = masterDictionary.objectForKey(aMasterDictionaryKey)?.allKeys
                    let songDictionary = masterDictionary.objectForKey(aMasterDictionaryKey)
                    
                    for aSongKey in songKeys!{
                        //add song
                        finalXMLFile = (finalXMLFile as String) + "\t\t\t\t<key>" + (aSongKey as! String) + "</key>"
                        let value = songDictionary?.objectForKey(aSongKey) as! NSString
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
        
        for aMasterDictionaryKey in masterDictionaryKeys{
            finalXMLFile = (finalXMLFile as String) + "\t\t\t\t<dict>\n\t\t\t\t\t<key>Track ID</key><integer>" + (aMasterDictionaryKey as! String) + "</integer>\n\t\t\t\t</dict>\n"
        }
        
        finalXMLFile = (finalXMLFile as String) + "\t\t\t</array>\n\t\t</dict>\n\t</array>\n</dict>\n</plist>"
        
        var filepath = ogXMLFile.absoluteString.componentsSeparatedByString("/")
        filepath.removeLast()
        filepath.append("GeneratedPlaylist.xml")
        var newFilepath = ""
        
        for(index,aFilepath) in filepath.enumerate(){
            newFilepath = (newFilepath as String) + aFilepath
            if(index + 1 < filepath.count){
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