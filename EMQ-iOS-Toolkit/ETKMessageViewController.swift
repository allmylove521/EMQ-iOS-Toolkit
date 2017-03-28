//
//  ETKMessageViewController.swift
//  EMQ-iOS-Toolkit
//
//  Created by Alex Yu on 22/03/2017.
//  Copyright © 2017 EMQ. All rights reserved.
//

import UIKit
import CocoaMQTT

class ETKMessageViewController: UIViewController {
    
    // views
    @IBOutlet weak var blackMask: UIView!
    @IBOutlet weak var blurView: UIVisualEffectView!
    @IBOutlet weak var handleView: UIView!
    
    @IBOutlet weak var displayNameTextField: UITextField!
    @IBOutlet weak var serverTextField: UITextField!
    @IBOutlet weak var portTextField: UITextField!
    @IBOutlet weak var usernameTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    
    // constriants
    @IBOutlet weak var heightConstraint: NSLayoutConstraint!
    @IBOutlet weak var topConstraint: NSLayoutConstraint!
    
    // gestures
    @IBOutlet var panGestureRecognizer: UIPanGestureRecognizer!
    
    // to set blur view position
    private var topConstraintValueOriginal: CGFloat = 0.0
    private var topConstraintValueCollapse: CGFloat = 0.0
    private var blurViewOriginalY: CGFloat = 0.0
    private var blurViewYThreshold: CGFloat = 0.0
    private var blurViewCollapseDistance: CGFloat = 0.0
    private var blurViewCollapsed = false
    
    // mqtt & meta
    open var meta: ETKConnMeta?
    
    lazy var mqtt: CocoaMQTT = {
        let myCode = ShortCodeGenerator.getCode(length: 6)
        let clientID = "EMQ-iOS-Client-\(myCode)"
        
        // initialize mqtt
        let mqtt = CocoaMQTT(clientID: clientID, host: self.meta!.host, port: UInt16(self.meta!.port)!)
        mqtt.delegate = self
        return mqtt
    }()
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // for split view controller
        navigationItem.leftBarButtonItem = splitViewController?.displayModeButtonItem
        navigationItem.leftItemsSupplementBackButton = true

        // configure style
        blurView.layer.cornerRadius = 12
        handleView.isUserInteractionEnabled = false
        
        // vars for blur view animation
        topConstraintValueOriginal = topConstraint.constant
        blurViewCollapseDistance = topConstraintValueOriginal + heightConstraint.constant - 44
        topConstraintValueCollapse = topConstraintValueOriginal - blurViewCollapseDistance
        blurViewOriginalY = blurView.frame.origin.y
        blurViewYThreshold = blurViewCollapseDistance * 0.372
        
        blurView.addObserver(self, forKeyPath: "center", options: [.old, .new], context: nil)
        
        // sync UI with meta
        displayNameTextField.text = meta?.displayName
        serverTextField.text = meta?.host
        portTextField.text = meta?.port
        usernameTextField.text = meta?.userName
        passwordTextField.text = meta?.password
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        updateMetaFromUI()
    }
    
    private func updateMetaFromUI() {
        meta?.displayName = displayNameTextField.text!
        meta?.host = serverTextField.text!
        meta?.port = portTextField.text!
        meta?.userName = usernameTextField.text!
        meta?.password = passwordTextField.text!
        
        meta?.sync()
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath! == "center" {
            let y = blurView.frame.origin.y
            var alpha = (1 - (blurViewOriginalY - y) / blurViewCollapseDistance) * 0.3
            if alpha < 0 { alpha = 0 } else if alpha > 0.3 {alpha = 0.3}
            blackMask.alpha = alpha
        }
    }
    
    deinit {
        if blurView != nil {
            blurView.removeObserver(self, forKeyPath: "center", context: nil)
        }
    }
    
    @IBAction func onConnectButtonClicked(_ sender: UIButton) {
        updateMetaFromUI()
        mqtt.connect()
    }
    
    // MARK: - UX of blur view
    var panBeganConst: CGFloat = 0.0
    @IBAction func pan(_ sender: UIPanGestureRecognizer) {
        
        let vectorY = sender.translation(in: nil).y
        
        switch sender.state {
        case .began:
            panBeganConst = self.topConstraint.constant
            break
            
        case .changed:
            self.topConstraint.constant = panBeganConst + vectorY
            break
        
        case .ended:
            
            //
            var toCollapse = true
            let speed = sender.velocity(in: nil).y
            if fabs(speed) > 1000 {
                toCollapse = speed < 0
            } else {
                let validDistance = blurViewCollapsed ? vectorY : -vectorY
                if validDistance > blurViewYThreshold {
                    toCollapse = !blurViewCollapsed
                } else {
                    toCollapse = blurViewCollapsed
                }
            }
            
            // animate
            topConstraint.constant = toCollapse ? topConstraintValueCollapse : topConstraintValueOriginal
            UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 0.75, initialSpringVelocity: 0.5, options: .curveEaseOut, animations: {
                self.blurView.superview?.layoutIfNeeded()
            }, completion: { finished in
                self.blurViewCollapsed = toCollapse
            })
            
            break
            
        case .cancelled:
            
            break

        default:
            break
        }
    }
}


extension ETKMessageViewController: CocoaMQTTDelegate {
    func mqtt(_ mqtt: CocoaMQTT, didConnect host: String, port: Int) {
        print("didConnect \(host):\(port)")
    }
    
    // Optional ssl CocoaMQTTDelegate
    func mqtt(_ mqtt: CocoaMQTT, didReceive trust: SecTrust, completionHandler: @escaping (Bool) -> Void) {
        completionHandler(true)
    }
    
    func mqtt(_ mqtt: CocoaMQTT, didConnectAck ack: CocoaMQTTConnAck) {
        print("didConnectAck: \(ack)，rawValue: \(ack.rawValue)")
        handleView.backgroundColor = #colorLiteral(red: 0.3620333076, green: 0.8608141541, blue: 0.4826943278, alpha: 1)
    }
    
    func mqtt(_ mqtt: CocoaMQTT, didPublishMessage message: CocoaMQTTMessage, id: UInt16) {
        print("didPublishMessage with message: \(message.string)")
    }
    
    func mqtt(_ mqtt: CocoaMQTT, didPublishAck id: UInt16) {
        print("didPublishAck with id: \(id)")
    }
    
    func mqtt(_ mqtt: CocoaMQTT, didReceiveMessage message: CocoaMQTTMessage, id: UInt16 ) {
        print("didReceivedMessage: \(message.string) with id \(id)")
    }
    
    func mqtt(_ mqtt: CocoaMQTT, didSubscribeTopic topic: String) {
        print("didSubscribeTopic to \(topic)")
    }
    
    func mqtt(_ mqtt: CocoaMQTT, didUnsubscribeTopic topic: String) {
        print("didUnsubscribeTopic to \(topic)")
    }
    
    func mqttDidPing(_ mqtt: CocoaMQTT) {
        print("didPing")
    }
    
    func mqttDidReceivePong(_ mqtt: CocoaMQTT) {
        _console("didReceivePong")
    }
    
    func mqttDidDisconnect(_ mqtt: CocoaMQTT, withError err: Error?) {
        _console("mqttDidDisconnect")
        handleView.backgroundColor = #colorLiteral(red: 0.8824566007, green: 0.2664997876, blue: 0.3519365788, alpha: 1)
    }
    
    func _console(_ info: String) {
        print("Delegate: \(info)")
    }
}


struct ShortCodeGenerator {
    
    private static let base62chars = [Character]("0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz".characters)
    private static let maxBase : UInt32 = 62
    
    static func getCode(withBase base: UInt32 = maxBase, length: Int) -> String {
        var code = ""
        for _ in 0..<length {
            let random = Int(arc4random_uniform(min(base, maxBase)))
            code.append(base62chars[random])
        }
        return code
    }
}


