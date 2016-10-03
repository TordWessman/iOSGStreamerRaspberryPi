//
//  AppDelegate.swift
//  GstreamerLiveStream
//
//  Created by Tord Wessman on 14/06/15.
//  Copyright (c) 2015 Axel IT AB. All rights reserved.
//

import UIKit

@objc(AppDelegate) public class AppDelegate: UIResponder, UIApplicationDelegate {
    
    public var window: UIWindow?
    private var m_pauseUsWhenEnteringBackground:Array<PauseProtocol>?
    
    @nonobjc public func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        // Override point for customization after application launch.
        
        m_pauseUsWhenEnteringBackground = Array<PauseProtocol>()
        
        return true
    }
    
    public func pauseMe(pausable:PauseProtocol) {
        
        m_pauseUsWhenEnteringBackground?.append(pausable)
        
    }
    
    public func applicationWillResignActive(_ application: UIApplication) {
        
        for pausable in m_pauseUsWhenEnteringBackground! {
            pausable.reset()
        }
        
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }
    
    public func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }
    
    public func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }
    
    public func applicationDidBecomeActive(_ application: UIApplication) {
        
        //Temporary fix for video player...
        for pausable in m_pauseUsWhenEnteringBackground! {
            pausable.reset()
        }
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }
    
    public func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }
    
    
}

