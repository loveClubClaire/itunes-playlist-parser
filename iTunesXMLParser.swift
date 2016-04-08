//
//  iTunesXMLParser.swift
//  PlaylistParser
//
//  Created by Zachary Whitten on 12/20/15.
//  Copyright © 2015 WCNURadio. All rights reserved.
//

import Foundation

class iTunesXMLParser: NSObject, NSXMLParserDelegate{
    

    
    //Initalization Variables for our parser
    var aString = ""
    var dictCount = 0;
    var halfWay = false
    var repeatTag = false
    
    //Define exception characters
    let ø: unichar = ("ø" as NSString).characterAtIndex(0)
    let apostrophe: unichar = ("’" as NSString).characterAtIndex(0)
    let and: unichar = ("&" as NSString).characterAtIndex(0)
    
    var dictionary3 = NSMutableDictionary()
    var dict3Contents = NSMutableArray()
    var allDict3 = NSMutableArray()
    
    var dictionary2 = NSMutableDictionary()
    var dict2Contents = NSMutableArray()
    
    init(masterDictionary: NSMutableDictionary) {
        dictionary2 = masterDictionary
    }
    
    //Function gets the start of an XML tag. The tag is passed in to the function as a string
    func parser(parser: NSXMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String]){
        //Set our variable aString to the elementName (the opening tag currently being parsed)
        aString = elementName
        //If that opening tag is a "dict" tag, then increnment our dictCount by one
        //This tells us how many dictionary tags deep in we are, because this XML file can have tags of the same name imbeded
        if(elementName == "dict"){
            dictCount++
        }
    }
    
    //Get the value inside a tag passed in as a String
    func parser(parser: NSXMLParser, foundCharacters string: String){
        //Remove line break strings
        if(string != "\n\t\t\t" && string != "\n\t\t" && string != "\n\t"){
            //If the tag we are currently parsing is one of the following and we  are three dictionary tags deep (implying we are getting unique song data)
            //We add the content of that tag to an array of content
            
            //Keys will be added followed by their values. Leading to an every other structure in the array, where there is a key every other entry and a value every other entry
            if( (aString == "integer" || aString == "string" || aString == "date" || aString == "key") && dictCount == 3){

                //Craft apostrope execption
                if((string as NSString).characterAtIndex(0) == apostrophe){
                    var aString = dict3Contents.lastObject as! String
                    aString = aString + string
                    dict3Contents.removeLastObject()
                    dict3Contents.addObject(aString)
                }
                //Craft ø exception (Fuckin Nørgaard)
                else if((string as NSString).characterAtIndex(0) == ø){
                    var aString = dict3Contents.lastObject as! String
                    aString = aString + string
                    dict3Contents.removeLastObject()
                    dict3Contents.addObject(aString)
                }
                else if((string as NSString).characterAtIndex(0) == and){
                    var aString = dict3Contents.lastObject as! String
                    aString = aString + string + "#38;"
                    dict3Contents.removeLastObject()
                    dict3Contents.addObject(aString)
                    repeatTag = true
                }
                else if(repeatTag == true){
                    var aString = dict3Contents.lastObject as! String
                    aString = aString + string
                    dict3Contents.removeLastObject()
                    dict3Contents.addObject(aString)
                    repeatTag = false
                }
                else{
                    if(!(aString == "key" && string == "Compilation")){
                        dict3Contents.addObject(string);
                    }
                }
            }
            if( (aString == "key") && dictCount == 2){
                dict2Contents.addObject(string);
            }
        }
    }
    //Gets the value of a closing tag. This function detects which dict tag is being closed and then stores the resulting data into a dictionary
    func parser(parser: NSXMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?){
        if(elementName == "dict"){
            dictCount--
            
            if(dictCount == 2){
                for(var i = 1; i < dict3Contents.count; i = i + 2){
                    dictionary3.setObject(dict3Contents.objectAtIndex(i), forKey: (dict3Contents.objectAtIndex(i-1) as! String) )
                }
                allDict3.addObject(dictionary3)
                dictionary3 = NSMutableDictionary()
                dict3Contents = NSMutableArray()
            }
            
            if(dictCount == 1 && halfWay == false){
                for(var i = 0; i < allDict3.count; i++){
                    dictionary2.setObject(allDict3.objectAtIndex(i), forKey: (dict2Contents.objectAtIndex(i) as! String) )
                }
                halfWay = true
            }
        }
    }

    
}
