//
//  AppDelegate.swift
//  TempCPU
//
//  Created by User on 16/06/2020.
//  Copyright © 2020 SimpleDev. All rights reserved.
//

import Cocoa

class AppDelegate: NSObject, NSApplicationDelegate {
    
    var statusItem: NSStatusItem?
    
    @IBOutlet weak var appMenu: NSMenu!
    
    @objc func displayMenu() {
        guard let button = statusItem?.button else { return }
        let x = button.frame.origin.x
        let y = button.frame.origin.y - 5
        let location = button.superview!.convert(NSMakePoint(x, y), to: nil)
        let w = button.window!
        let event = NSEvent.mouseEvent(with: .leftMouseUp,
                                       location: location,
                                       modifierFlags: NSEvent.ModifierFlags(rawValue: 0),
                                       timestamp: 0,
                                       windowNumber: w.windowNumber,
                                       context: w.graphicsContext,
                                       eventNumber: 0,
                                       clickCount: 1,
                                       pressure: 0)!
        NSMenu.popUpContextMenu(appMenu, with: event, for: button)
    }
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        statusItem = NSStatusBar.system.statusItem(withLength: -1)
        
        guard let button = statusItem?.button else {
            print("status bar item failed. Try removing some menu bar item.")
            NSApp.terminate(nil)
            return
        }
        
        button.target = self
        button.action = #selector(displayMenu)
        button.font = NSFont(name: "Helvetica-Bold", size: 11)
        
        var message = ""
        var failure = false
        
        if #available(OSX 10.12, *) {
            _ = Timer.scheduledTimer(withTimeInterval: 10.0, repeats: true) {_ in
                DispatchQueue.background(background: {
                    message = self.doTask(failure: &failure)
                }, completion: {
                    button.title = message
                })
                if failure {
                    self.messageBox(title: "Error", text: message)
                    exit(0)
                }
            }
        } else {
            self.messageBox(title: "Error", text: "You need OSX >= 10.12")
            exit(0)
        }
        
    }
    
    func doTask(failure: inout Bool) -> String {
        
        //  let script = "do shell script \"sudo powermetrics -n 1|grep -i \\\"CPU die temperature\\\"| sed 's/^.*: //' \" with administrator privileges"
        
        // let script = "do shell script \"echo 'password'|sudo -S powermetrics -n 1|grep -i \\\"CPU die temperature\\\"| sed 's/^.*: //' \""
        
        let script = "do shell script \"sudo powermetrics --samplers smc -n 1|grep -i \\\"CPU die temperature\\\\|Fan:\\\"| sed 's/^.*: //'\""
        
        var errorInfo: NSDictionary?
        
        if let script = NSAppleScript(source: script),
            let result = script.executeAndReturnError(&errorInfo) as? NSAppleEventDescriptor,
            let text = result.stringValue {
            return text
        }
        else if let error = errorInfo {
            failure = true
            return error.description
        }
        else {
            failure = true
            return "Unexpected error while executing script"
        }
        
    }
    
    func messageBox(title: String, text: String) {
        let alert = NSAlert()
        alert.messageText = title
        alert.informativeText = text
        alert.alertStyle = .warning
        alert.addButton(withTitle: "OK")
        alert.addButton(withTitle: "Cancel")
        alert.runModal()
    }
    
}

extension DispatchQueue {
    
    static func background(delay: Double = 0.0, background: (()->Void)? = nil, completion: (() -> Void)? = nil) {
        DispatchQueue.global(qos: .background).async {
            background?()
            if let completion = completion {
                DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: {
                    completion()
                })
            }
        }
    }
    
}
