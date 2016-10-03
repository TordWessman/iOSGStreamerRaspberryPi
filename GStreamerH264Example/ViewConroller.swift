//
//  ViewController.swift
//  GstreamerLiveStream
//
//  Created by Tord Wessman on 17/08/15.
//  Copyright (c) 2015 Axel IT AB. All rights reserved.
//

import Foundation
import UIKit
import AVFoundation

class ViewConroller : UIViewController, CameraViewDelegate, CameraViewTouch, UITextFieldDelegate {
    
    @IBOutlet var playerView:CameraView!
    @IBOutlet var errorMessage:UILabel!
    @IBOutlet var activityIndicator: UIActivityIndicatorView!

    override var supportedInterfaceOrientations : UIInterfaceOrientationMask {
        
        return .landscape
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        playerView.setDelegate(self)
        
        playerView.setup(
            "81.232.14.53",
            port: 8554)
        
        playerView.setTouch(self)

        (UIApplication.shared.delegate as! AppDelegate).pauseMe(pausable: playerView)
        
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        playerView.reset()
        
    }
    /*
    override func viewWillTransitionToSize(size: CGSize, withTransitionCoordinator coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransitionToSize(size, withTransitionCoordinator: coordinator)
        
        guard playerView != nil else {
            return
        }
        
        playerView.reset()
        
    }*/

    @IBAction func start() {
        
        playerView.start()
        
    }
    
    @IBAction func reset() {
        
        playerView.reset()
        
    }
    
    func gotError(message: String!) {
        
        DispatchQueue.main.async {
            
            self.errorMessage.text = message

        }
        
    }
    
    func beginBuffering() {
        
        DispatchQueue.main.async {
            
            self.activityIndicator.isHidden = false
            self.activityIndicator.startAnimating()
            
        }
        
    }
    
    func doneBuffering() {
        
        DispatchQueue.main.async(execute: {
            
            self.activityIndicator.isHidden = true
            self.activityIndicator.stopAnimating()
            
        })
        
    }
    
    func didTouch(_ dx: CGFloat, dy: CGFloat) {
    
    }
    


}
