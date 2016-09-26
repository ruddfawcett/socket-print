//
//  AppDelegate.swift
//  socket-print
//
//  Created by Rudd Fawcett on 9/25/16.
//  Copyright © 2016 Rudd Fawcett. All rights reserved.
//

import Cocoa
import SocketIO

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    @IBOutlet weak var window: NSWindow!
    @IBOutlet weak var status: NSTextField!
    
    @IBOutlet weak var labelBack: NSView!
    @IBOutlet weak var labelFront: NSView!
    
    @IBOutlet weak var firstBack: NSTextField!
    @IBOutlet weak var lastBack: NSTextField!
    @IBOutlet weak var affiliationBack: NSTextField!
    
    @IBOutlet weak var firstFront: NSTextField!
    @IBOutlet weak var lastFront: NSTextField!
    @IBOutlet weak var affiliationFront: NSTextField!
    
    func applicationDidFinishLaunching(aNotification: NSNotification) {
        window.title = "Socket Print"
        window.backgroundColor = NSColor(red:0.12, green:0.13, blue:0.18, alpha:1.00)
        
        labelBack.wantsLayer = true
        labelFront.wantsLayer = true
        
        labelBack.layer?.backgroundColor = NSColor.whiteColor().CGColor
        labelBack.layer?.cornerRadius = 5
        
        labelFront.layer?.backgroundColor = NSColor(red:0.15, green:0.16, blue:0.21, alpha:1.00).CGColor
        labelFront.layer?.cornerRadius = 3
        
        let socket = SocketIOClient(socketURL: NSURL(string: "http://rolodex-csnyc.herokuapp.com")!, config: [.Log(false), .ForcePolling(true)])
        
        socket.on("connect") {data, ack in
            socket.emit("temp", withItems: [])
            
            self.status.stringValue = "Connected to server."
        }
        
        socket.on("disconnect") {data, error in
            self.status.stringValue = "Disconnected to server."
        }
    
        socket.on("error") {data, error in
            self.status.stringValue = "Error connecting to server."
        }
        
        socket.on("checkin") {data, ack in
            let payload = data[0] as! [String: AnyObject]
            let member = payload["member"] as! [String : AnyObject]
            let event = payload["event"] as! [String : AnyObject]
            
            let fullName: String? = member["name"] as? String
            
            if fullName != nil {
                var fullNameArr = fullName!.characters.split{$0 == " "}.map(String.init)
                let first: String = fullNameArr[0]
                let last: String? = fullNameArr.count > 1 ? fullNameArr[1] : nil
                
                self.firstBack.stringValue = first
                self.firstFront.stringValue = first
                if last != nil {
                    self.lastBack.stringValue = last!
                    self.lastFront.stringValue = last!
                }
                else {
                    self.lastBack.stringValue = ""
                    self.lastFront.stringValue = ""
                }
            }
            
            let profile: [String: AnyObject] = member["profile"]! as! [String : AnyObject]
            let affiliation: String? = profile["affiliation"] as? String
            if affiliation != nil {
                self.affiliationBack.stringValue = affiliation!
                self.affiliationFront.stringValue = affiliation!
            }
            else {
                self.affiliationBack.stringValue = ""
                self.affiliationFront.stringValue = ""
            }
            
            let data = self.labelBack.dataWithPDFInsideRect(self.labelBack.visibleRect)
            
            do {
                let paths = NSSearchPathForDirectoriesInDomains(NSSearchPathDirectory.DocumentDirectory, NSSearchPathDomainMask.UserDomainMask, true)
                var documents = paths[0]
                documents = documents.stringByAppendingString("/")
                documents = documents.stringByAppendingString(event["meetup_id"] as! String)
                documents = documents.stringByAppendingString("/")
                

                try NSFileManager.defaultManager().createDirectoryAtPath(documents, withIntermediateDirectories:true , attributes: nil)
                
                do {
                    let pdf = documents.stringByAppendingString(member["meetup_id"] as! String).stringByAppendingString(".pdf")
                    print()
                    _ = try data.writeToFile(pdf, options: NSDataWritingOptions.DataWritingAtomic)
                    
                    let command : String = "lp -d DYMO_LabelWriter_450_Turbo -o fit-to-page \(pdf)"
                    let task = NSTask()
                    task.launchPath = "/bin/bash"
                    task.arguments = ["-c", command]
                    task.launch()
                    
                }
                catch let error as NSError {
                    print(error.localizedDescription)
                }
            }
            catch let error as NSError {
                print(error.localizedDescription)
            }
        }
        
        socket.connect()
    }

    func applicationWillTerminate(aNotification: NSNotification) {
        // Insert code here to tear down your application
    }


}

