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
    
    // Constants
    let subscriptTitle = "Subscript"
    let unsubscriptTitle = "Unsubscript"
    
    // views
    @IBOutlet weak var blackMask: UIView!
    @IBOutlet weak var blurView: UIVisualEffectView!
    @IBOutlet weak var handleView: UIView!
    
    @IBOutlet weak var displayNameTextField: UITextField!
    @IBOutlet weak var serverTextField: UITextField!
    @IBOutlet weak var portTextField: UITextField!
    @IBOutlet weak var usernameTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var topicTextField: UITextField!
    
    @IBOutlet weak var messagesTableView: UITableView!
    
    @IBOutlet weak var connectButton: UIButton!
    @IBOutlet weak var subscriptButton: UIButton!
    @IBOutlet weak var subscriptQosSegmentControl: UISegmentedControl!
    
    @IBOutlet weak var publishView: UIView!
    @IBOutlet weak var publishTextField: UITextField!
    @IBOutlet weak var publishQosSegmentControl: UISegmentedControl!
    @IBOutlet weak var publishTopicButton: UIButton!
    
    
    // constriants
    @IBOutlet weak var heightConstraint: NSLayoutConstraint!
    @IBOutlet weak var topConstraint: NSLayoutConstraint!
    @IBOutlet weak var publishViewBottomConstraint: NSLayoutConstraint!
    
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
        let myCode = ETKTools.randomCode(length: 6)
        let clientID = "EMQ-iOS-Client-\(myCode)"
        
        // initialize mqtt
        let mqtt = CocoaMQTT(clientID: clientID, host: self.meta!.host, port: UInt16(self.meta!.port)!)
        mqtt.delegate = self
        return mqtt
    }()
    
    // message
    var messages:[CocoaMQTTMessage] = []
    
    // MARK: - Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // for split view controller
        navigationItem.leftBarButtonItem = splitViewController?.displayModeButtonItem
        navigationItem.leftItemsSupplementBackButton = true
        
        // mask view gesture
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(self.tapMaskView(_:)))
        blackMask.addGestureRecognizer(tapGesture)
        
        //
        subscriptButton.isEnabled = false

        // configure style
        blurView.layer.cornerRadius = 12
        handleView.isUserInteractionEnabled = false
        
        // vars for blur view animation
        topConstraintValueOriginal = topConstraint.constant
        blurViewCollapseDistance = topConstraintValueOriginal + heightConstraint.constant - 34
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
        topicTextField.text = meta?.subscriptions.first
        
        // notification from keyboard
        NotificationCenter.default.addObserver(self, selector:#selector(keyboardWillChangeFrame(notification:)), name:NSNotification.Name.UIKeyboardWillChangeFrame, object: nil)
    }
    
    func keyboardWillChangeFrame(notification: NSNotification) {
        if let userInfo = notification.userInfo {
            let endFrame = (userInfo[UIKeyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue
            let duration:TimeInterval = (userInfo[UIKeyboardAnimationDurationUserInfoKey] as? NSNumber)?.doubleValue ?? 0
            let animationCurveRawNSN = userInfo[UIKeyboardAnimationCurveUserInfoKey] as? NSNumber
            let animationCurveRaw = animationCurveRawNSN?.uintValue ?? UIViewAnimationOptions.curveEaseInOut.rawValue
            let animationCurve:UIViewAnimationOptions = UIViewAnimationOptions(rawValue: animationCurveRaw)
            
            // conditions
            let keyboardUp = (endFrame?.origin.y)! < UIScreen.main.bounds.size.height
            let shouldPubViewUp = keyboardUp && (publishTextField.isFirstResponder)
            
            // publish view move
            var const: CGFloat = 0
            if shouldPubViewUp {
                const = endFrame?.size.height ?? 0.0
            } else {
                const = 0
            }
            
            self.publishViewBottomConstraint?.constant = const
            
            UIView.animate(withDuration: duration,
                           delay: TimeInterval(0),
                           options: animationCurve,
                           animations: { self.view.layoutIfNeeded() },
                           completion: nil)
            
            // message table view content inset bottoms
            let insetBottom = shouldPubViewUp ? (endFrame?.size.height ?? 0.0) : 0
            messagesTableView.contentInset.bottom = insetBottom
            
            if shouldPubViewUp {
                if messages.count > 0 {
                    let indexPath = IndexPath(row: messages.count - 1, section: 0)
                    messagesTableView.scrollToRow(at: indexPath, at: .bottom, animated: true)
                }
            }
        }
    }
    
    deinit {
        if blurView != nil {
            blurView.removeObserver(self, forKeyPath: "center", context: nil)
        }
        NotificationCenter.default.removeObserver(self)
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
        meta?.subscriptions = [topicTextField.text!]
        
        mqtt.host = meta!.host
        mqtt.port = UInt16(meta!.port)!
        mqtt.username = meta!.userName
        mqtt.password = meta!.password
        
        mqtt.logLevel = .debug
        
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
    
    @IBAction func onCleanSessionSwitchValueChanged(_ sender: UISwitch) {
        mqtt.cleanSession = sender.isOn
    }
    
    @IBAction func onConnectButtonClicked(_ sender: UIButton) {
        updateMetaFromUI()

        if mqtt.connState == .connected  {
            mqtt.disconnect()
        } else {
            mqtt.connect()
        }
    }
    
    @IBAction func onSubscriptButtonClicked(_ sender: Any) {
        if subscriptButton.title(for: .normal) == subscriptTitle {
            let qosRaw = subscriptQosSegmentControl.selectedSegmentIndex
            let qos = CocoaMQTTQOS(rawValue: UInt8(qosRaw))!
            mqtt.subscribe(topicTextField.text!,  qos: qos)
        } else {
            mqtt.unsubscribe(topicTextField.text!)
        }
    }
    
    @IBAction func onPublishButtonClicked(_ sender: UIButton) {
        if (publishTopicButton.title(for: .normal)?.isValidPublishTopic())! {
            let text = publishTextField.text!
            let topic = publishTopicButton.title(for: .normal)!
            let qosRaw = publishQosSegmentControl.selectedSegmentIndex
            let qos = CocoaMQTTQOS(rawValue: UInt8(qosRaw))!
            
            mqtt.publish(topic, withString: text, qos: qos)
            publishTextField.text = nil
        } else {
            changePublishTitle(publishTopicButton)
        }
    }
    
    @IBAction func onPublishTopicButtonClicked(_ sender: UIButton) {
        changePublishTitle(sender)
    }
    
    func tapMaskView(_ sender: Any) {
        animateBlurView(true)
    }
    
    func changePublishTitle(_ button: UIButton) {
        let alertController = UIAlertController(title: "Modify Topic for publishing", message: nil, preferredStyle: .alert)
        
        let currentTopic = button.title(for: .normal)!
        
        alertController.addTextField { (textField) in
            textField.placeholder = "topic"
            textField.text = currentTopic
        }
        
        let textField = alertController.textFields?.first!
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { action in
            // ...
        }
        alertController.addAction(cancelAction)
        
        let OKAction = UIAlertAction(title: "OK", style: .default) { action in
            button.setTitle(textField?.text, for: .normal)
            if (button.title(for: .normal)?.isValidPublishTopic())! {
                button.setTitleColor(#colorLiteral(red: 0.2876902819, green: 0.4403573275, blue: 0.5107608438, alpha: 1), for: .normal)
            } else {
                button.setTitleColor(#colorLiteral(red: 0.8824566007, green: 0.2664997876, blue: 0.3519365788, alpha: 1), for: .normal)
            }
        }
        alertController.addAction(OKAction)
        
        self.present(alertController, animated: true, completion: nil)
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
            animateBlurView(toCollapse)
            
            break
            
        case .cancelled:
            
            break

        default:
            break
        }
    }
    
    func animateBlurView(_ toCollapse: Bool) {
        topConstraint.constant = toCollapse ? topConstraintValueCollapse : topConstraintValueOriginal
        UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 0.75, initialSpringVelocity: 0.5, options: .curveEaseOut, animations: {
            self.blurView.superview?.layoutIfNeeded()
        }, completion: { finished in
            self.blurViewCollapsed = toCollapse
        })
        
        blackMask.isUserInteractionEnabled = !toCollapse
    }
}


extension ETKMessageViewController: CocoaMQTTDelegate {
    func mqtt(_ mqtt: CocoaMQTT, didConnect host: String, port: Int) {
    }
    
    // Optional ssl CocoaMQTTDelegate
    func mqtt(_ mqtt: CocoaMQTT, didReceive trust: SecTrust, completionHandler: @escaping (Bool) -> Void) {
        completionHandler(true)
    }
    
    func mqtt(_ mqtt: CocoaMQTT, didConnectAck ack: CocoaMQTTConnAck) {
        handleView.backgroundColor = #colorLiteral(red: 0.1056478098, green: 0.71177876, blue: 0.650462091, alpha: 1)
        
        // change button UI
        connectButton.backgroundColor = #colorLiteral(red: 0.8824566007, green: 0.2664997876, blue: 0.3519365788, alpha: 1)
        connectButton.setTitle("Disconnect", for: .normal)
        
        // subscript button enable
        subscriptButton.isEnabled = true
        subscriptButton.setTitle(subscriptTitle, for: .normal)
    }
    
    func mqtt(_ mqtt: CocoaMQTT, didPublishMessage message: CocoaMQTTMessage, id: UInt16) {
    }
    
    func mqtt(_ mqtt: CocoaMQTT, didPublishAck id: UInt16) {
    }
    
    func mqtt(_ mqtt: CocoaMQTT, didReceiveMessage message: CocoaMQTTMessage, id: UInt16 ) {
        messages.append(message)
        let indexPath = IndexPath(row: messages.count - 1, section: 0)
        messagesTableView.insertRows(at: [indexPath], with: .none)
        messagesTableView.scrollToRow(at: indexPath, at: .bottom, animated: true)
    }
    
    func mqtt(_ mqtt: CocoaMQTT, didSubscribeTopic topic: String) {
        topicTextField.isEnabled = false
        subscriptButton.setTitle(unsubscriptTitle, for: .normal)
        self.animateBlurView(true)
        
        // publish topic
        publishTopicButton.setTitle(topicTextField.text!, for: .normal)
        if (publishTopicButton.title(for: .normal)?.isValidPublishTopic())! {
            publishTopicButton.setTitleColor(#colorLiteral(red: 0.2876902819, green: 0.4403573275, blue: 0.5107608438, alpha: 1), for: .normal)
        } else {
            publishTopicButton.setTitleColor(#colorLiteral(red: 0.8824566007, green: 0.2664997876, blue: 0.3519365788, alpha: 1), for: .normal)
        }
    }
    
    func mqtt(_ mqtt: CocoaMQTT, didUnsubscribeTopic topic: String) {
        subscriptButton.setTitle(subscriptTitle, for: .normal)
        topicTextField.isEnabled = true
    }
    
    func mqttDidPing(_ mqtt: CocoaMQTT) {
    }
    
    func mqttDidReceivePong(_ mqtt: CocoaMQTT) {
    }
    
    func mqttDidDisconnect(_ mqtt: CocoaMQTT, withError err: Error?) {
        handleView.backgroundColor = #colorLiteral(red: 0.8824566007, green: 0.2664997876, blue: 0.3519365788, alpha: 1)
        animateBlurView(false)
        
        // change button UI
        connectButton.backgroundColor = #colorLiteral(red: 0.1797867119, green: 0.7414731383, blue: 0.8447360396, alpha: 1)
        connectButton.setTitle("Connect", for: .normal)
        
        // subscript button enable
        subscriptButton.isEnabled = false
        subscriptButton.setTitle(subscriptTitle, for: .normal)
    }
}

extension ETKMessageViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
//        if textField == publishTextField {
//            onPublishButtonClicked(textField)
//        } else {
            textField.resignFirstResponder()
//        }
        return true
    }
}

extension ETKMessageViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return messages.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "message")
        let message = messages[indexPath.row]
        let content = message.string!
        
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        let timeString = formatter.string(from: Date())
        
        cell!.textLabel!.text = content
        cell!.detailTextLabel!.text = "#\(message.topic) - \(timeString)"
        return cell!
    }
    
}


