//
//  GameViewController.swift
//  DuelShot
//
//  Created by Cole Margerum on 8/8/18.
//  Copyright © 2018 Cole Margerum. All rights reserved.
//

import UIKit
import SpriteKit
import GameplayKit
import MultipeerConnectivity

class GameViewController: UIViewController, GameSceneDelegate, MCSessionDelegate, MCBrowserViewControllerDelegate {
    var mcPeerID: MCPeerID!
    var mcSession: MCSession!
    var mcAdvertiserAssistant: MCAdvertiserAssistant!
    var scene: GameScene!
    
    @IBOutlet weak var connectButton: UIButton!
    @IBOutlet weak var singlePlayerButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        mcPeerID = MCPeerID(displayName: UIDevice.current.name)
        mcSession = MCSession(peer: mcPeerID, securityIdentity: nil, encryptionPreference: .optional)
        mcSession.delegate = self
        
        if let view = self.view as! SKView? {
            // Load the SKScene from 'GameScene.sks'
            if let scene = SKScene(fileNamed: "GameScene") as? GameScene {
                self.scene = scene
                // Set the scale mode to scale to fit the window
                scene.scaleMode = .aspectFill
                scene.gameSceneDelegate = self
                // Present the scene
                // view.presentScene(scene)
            }
            
            view.ignoresSiblingOrder = true
            view.showsFPS = true
            view.showsNodeCount = true
            view.isMultipleTouchEnabled = true
        }
    }
    
    @IBAction func didTouchSinglePlayer(_ sender: UIButton) {
        scene.isTwoPlayer = false
        hideButtons()
        if let view = self.view as! SKView? {
            view.presentScene(scene)
        }
        
    }
    @IBAction func didTouchConnect(_ sender: UIButton) {
        let actionSheet = UIAlertController(title: "Connect with a Peer", message: "Do you want to join or host a session?", preferredStyle: .actionSheet)
        
        actionSheet.addAction(UIAlertAction(title: "Host Session", style: .default, handler: { (action:UIAlertAction) in self.mcAdvertiserAssistant = MCAdvertiserAssistant(serviceType: "crm", discoveryInfo: nil, session: self.mcSession)
            self.mcAdvertiserAssistant.start()
        }))
        
        actionSheet.addAction(UIAlertAction(title: "Join Session", style: .default, handler: { (action:UIAlertAction) in
            let browser = MCBrowserViewController(serviceType: "crm", session: self.mcSession)
            browser.maximumNumberOfPeers = 2
            browser.delegate = self
            self.present(browser, animated: true, completion: nil)
        }))
        
        actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        present(actionSheet, animated: true, completion: nil)
    }
    
    func hideButtons() {
        connectButton.isHidden = true
        singlePlayerButton.isHidden = true
    }
    
    func sendUserState(isFiring: Bool, isHit: Bool) {
        let x = scene.user.position.x
        let y = scene.user.position.y
        let enemyState = PlayerState(x: Double(x), y: Double(y), isFiring: isFiring, isHit: isHit)
        let data = enemyState.data
        
        if mcSession.connectedPeers.count > 0 {
            do {
                try mcSession.send(data, toPeers: mcSession.connectedPeers, with: .unreliable)
//                print("data sent")
            } catch {
                return
            }
        } else if scene.isTwoPlayer {
            print("Not connected to another device")
        }
    }
    
    // MARK: - MC Delagate Functions
    
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        switch state {
        case MCSessionState.connected:
            print("Connected: \(peerID.displayName)")
            DispatchQueue.main.async {
                self.hideButtons()
            }
            if let view = self.view as! SKView? {
                view.presentScene(scene)
            }
            
        case MCSessionState.connecting:
            print("Connecting: \(peerID.displayName)")
            
        case MCSessionState.notConnected:
            print("Not Connected: \(peerID.displayName)")
        }
    }
    
    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        let enemyState = PlayerState(data: data)
        DispatchQueue.main.async {
//            print("data received")
            if let enemyState = enemyState {
                self.scene.updateEnemyState(x: -1 * enemyState.x,
                                            y: enemyState.y,
                                            isFiring: enemyState.isFiring,
                                            isHit: enemyState.isHit)
//                print("data processed")
            } else {
                print("data is nil")
            }
        }
    }
    
    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID){}
    
    func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {}
    
    func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {}
    
    func browserViewControllerDidFinish(_ browserViewController: MCBrowserViewController) {
        dismiss(animated: true, completion: nil)
        
    }
    func browserViewControllerWasCancelled(_ browserViewController: MCBrowserViewController) {
        dismiss(animated: true, completion: nil)
    }
}
