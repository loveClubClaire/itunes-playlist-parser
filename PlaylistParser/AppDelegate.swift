//
//  AppDelegate.swift
//  PlaylistParser
//
//  Created by Zachary Whitten on 12/20/15.
//  Copyright © 2015 Zachary Whitten. All rights reserved.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate, NSXMLParserDelegate{

    @IBOutlet weak var window: NSWindow!
    var buttonOneURLS = [AnyObject]()
    var buttonTwoURLS = [AnyObject]()
    @IBOutlet weak var progressIndicator: NSProgressIndicator!
    @IBOutlet weak var parseFileProgress: NSWindow!
    @IBOutlet weak var mainWindow: NSWindow!
    @IBOutlet weak var mainViewProgressIndicator: NSProgressIndicator!
    var myClass = ViewLoading()
    
    
    @IBAction func help(sender: AnyObject) {
        let myPopup: NSAlert = NSAlert()
        myPopup.messageText = "Help"
        myPopup.informativeText = "Removes all songs in the secondary playlists from the main playlists and saves the results as a XML file"
        myPopup.alertStyle = NSAlertStyle.WarningAlertStyle
        myPopup.addButtonWithTitle("OK")
        myPopup.runModal()
    }
    
    @IBAction func GetFilesButtonOne(sender: AnyObject) {
        let openPanel = NSOpenPanel()
        let fileTypes = ["xml"]
        openPanel.allowsMultipleSelection = true;
        openPanel.canChooseDirectories = false;
        openPanel.canChooseFiles = true;
        openPanel.allowedFileTypes = fileTypes;
        
        if(openPanel.runModal() == NSModalResponseOK){
            buttonOneURLS = openPanel.URLs
        }
    }

    @IBAction func GetFilesButtonTwo(sender: AnyObject) {
        let openPanel = NSOpenPanel()
        let fileTypes = ["xml"]
        openPanel.allowsMultipleSelection = true;
        openPanel.canChooseDirectories = false;
        openPanel.canChooseFiles = true;
        openPanel.allowedFileTypes = fileTypes;
        
        if(openPanel.runModal() == NSModalResponseOK){
            buttonTwoURLS = openPanel.URLs
        }
    }
    
    @IBAction func GenerateXMLFile(sender: AnyObject) {
        //Give user an error if there is not at least one main and one secondary playlist selected
        if(self.buttonOneURLS.count < 1 || self.buttonTwoURLS.count < 1){
            let myPopup: NSAlert = NSAlert()
            myPopup.messageText = "Must Select Files"
            myPopup.informativeText = "Files must be selected to continue"
            myPopup.alertStyle = NSAlertStyle.WarningAlertStyle
            myPopup.addButtonWithTitle("OK")
            myPopup.runModal()
        }
        else{
            //create a dispatch group which holds a list of items
            let downloadGroup = dispatch_group_create()
            //Another dispatch_group for generating our dictionaries 
            let dictionaryGroups = dispatch_group_create()
            
            dispatch_group_enter(dictionaryGroups); dispatch_group_enter(dictionaryGroups)
            
            var buttonOneDictionary = NSMutableDictionary()
            var buttonTwoDictionary = NSMutableDictionary()
            
            myClass = ViewLoading(aWindow: window)
            myClass.makeDisabled()
            
            mergeButtonFiles(buttonOneURLS, aMasterDictionary: &buttonOneDictionary, dispatchGroup: dictionaryGroups)
            mergeButtonFiles(buttonTwoURLS, aMasterDictionary: &buttonTwoDictionary, dispatchGroup: dictionaryGroups)
            
            dispatch_group_notify(dictionaryGroups, dispatch_get_main_queue()) {
            self.mainViewProgressIndicator.stopAnimation(self)
            self.removeDuplicates(buttonOneDictionary, secondaryDictionary: buttonTwoDictionary, buttonOneDictionary: buttonOneDictionary,dispatchGroup: downloadGroup)
            //Add an instance of an asynrocynous callback function to our dispatch group
            dispatch_group_enter(downloadGroup)
            //Wait for the dispatch group is empty, then execute code in the block
            dispatch_group_notify(downloadGroup, dispatch_get_main_queue()) {
                let createXMLFile = iTunesXMLGenerator(aFileURL: self.buttonOneURLS.first as! NSURL, aMasterDictionary: buttonOneDictionary)
                print("Thread completed outside thread")
                createXMLFile.generate()
                self.myClass.makeEnabled()
            }
        }
        }
    }
    
    
    func mergeButtonFiles(urlArray: [AnyObject], inout aMasterDictionary: NSMutableDictionary, dispatchGroup: dispatch_group_t){
        let priority = DISPATCH_QUEUE_PRIORITY_DEFAULT
        dispatch_async(dispatch_get_global_queue(priority, 0)) {

        var allFileResults = [NSMutableDictionary]()
            
        //Parse all the files. So for each URL, its values are parsed and saved to the NSMutableDictionary bestDictionary. Then that URL's bestDictionary is appended to the allFileResults array of dictionarys. This leaves us with an array of dictionaries, each containing the parsed data from one of the selected files.
        for url in urlArray{
            let parser = NSXMLParser(contentsOfURL:(url) as! NSURL)!
            let bestDictionary = NSMutableDictionary()
            let myDelegate = iTunesXMLParser(masterDictionary: bestDictionary)
            parser.delegate = myDelegate
            parser.parse()
            allFileResults.append(bestDictionary)
        }
        //Ultimently this logic block is converting an array of dictionaries (allFileResults) into a single dictionary containing all of the values from allFileResults. No duplicates will exist cause its a dictionary.
        let masterDictionary = allFileResults.first
        for fileResult in allFileResults{
            let keys = fileResult.allKeys
            for key in keys{
                if(masterDictionary?.valueForKey(key as! String) == nil){
                    masterDictionary?.setObject(fileResult.valueForKey(key as! String)!, forKey: (key as! String))
                }
            }
        }

        //Adds the values from this threads masterDictionary to the dictionary it was passed. 
        dispatch_async(dispatch_get_main_queue()) {
            aMasterDictionary.addEntriesFromDictionary(masterDictionary! as [NSObject : AnyObject])
            dispatch_group_leave(dispatchGroup)
            }
        }
    }
    
    //Remove from one all songs that are in two
    func removeDuplicates(mainDictionary: NSMutableDictionary, secondaryDictionary: NSMutableDictionary, buttonOneDictionary: NSMutableDictionary, dispatchGroup: dispatch_group_t){
        parseFileProgress.center()
        parseFileProgress.makeKeyAndOrderFront(self)
        let priority = DISPATCH_QUEUE_PRIORITY_DEFAULT
        dispatch_async(dispatch_get_global_queue(priority, 0)) {
            // do some task
            let mainKeys = mainDictionary.allKeys
            let secondaryKeys = secondaryDictionary.allKeys
            self.progressIndicator.maxValue = Double(mainKeys.count * secondaryKeys.count)
            
            for aMainKey in mainKeys{
                for (index,aSecondaryKey) in secondaryKeys.enumerate(){
                    let mainSong = mainDictionary.objectForKey(aMainKey as! String)
                    let secondarySong = secondaryDictionary.valueForKey(aSecondaryKey as! String)
                    
                    let bool = mainSong!.valueForKey("Artist")
                    let bool2 = secondarySong!.valueForKey("Artist")
                    let bool3 = mainSong!.valueForKey("Name")
                    let bool4 = secondarySong!.valueForKey("Name")
                    let bool5 = mainSong!.valueForKey("Album")
                    let bool6 = secondarySong!.valueForKey("Album")
                    
                    if(bool != nil && bool2 != nil && bool3 != nil && bool4 != nil && bool5 != nil && bool6 != nil){
                        if( (mainSong!.valueForKey("Artist") as! String).caseInsensitiveCompare((secondarySong!.valueForKey("Artist")) as! String) == NSComparisonResult.OrderedSame){
                            if((mainSong!.valueForKey("Name") as! String).caseInsensitiveCompare((secondarySong!.valueForKey("Name")) as! String) == NSComparisonResult.OrderedSame){
                                if((mainSong!.valueForKey("Album") as! String).caseInsensitiveCompare((secondarySong!.valueForKey("Album")) as! String) ==
                                    NSComparisonResult.OrderedSame){
                                    
                                    mainDictionary.removeObjectForKey(aMainKey as! String)
                                    let delta = Double(secondaryKeys.count - index - 1)
                                    dispatch_async(dispatch_get_main_queue()){self.progressIndicator.incrementBy(delta)}
                                    break;
                                }
                            }
                }
            }
            //update some UI
            dispatch_async(dispatch_get_main_queue()) {
                //Update the progress bar by 1
                self.progressIndicator.incrementBy(1.0);
            }
        }
                
                
                
            }
            dispatch_async(dispatch_get_main_queue()) {
                self.parseFileProgress.orderOut(self)
                print("Thread Completed in thread")
                dispatch_group_leave(dispatchGroup)
            }
        }
    }
    
    func applicationShouldTerminateAfterLastWindowClosed(sender: NSApplication) -> Bool {
        return true
    }
}