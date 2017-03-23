//
//  ETKMessageViewController.swift
//  EMQ-iOS-Toolkit
//
//  Created by Alex Yu on 22/03/2017.
//  Copyright © 2017 EMQ. All rights reserved.
//

import UIKit

class ETKMessageViewController: UIViewController {
    
    @IBOutlet weak var blurView: UIVisualEffectView!
    @IBOutlet weak var configureView: UIView!
    @IBOutlet weak var handleView: UIView!
    
    @IBOutlet weak var heightConstraint: NSLayoutConstraint!
    @IBOutlet weak var topConstraint: NSLayoutConstraint!
    
    @IBOutlet var panGestureRecognizer: UIPanGestureRecognizer!
    
    // to set blur view position
    private var topConstraintValueOriginal: CGFloat = 0.0
    private var topConstraintValueCollapse: CGFloat = 0.0
    private var blurViewOriginalY: CGFloat = 0.0
    private var blurViewYThreshold: CGFloat = 0.0
    private var blurViewCollapseDistance: CGFloat = 0.0
    private var blurViewCollapsed = false
    
    
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
        
//        handleView.backgroundColor = #colorLiteral(red: 0.8824566007, green: 0.2664997876, blue: 0.3519365788, alpha: 1)
//        handleView.backgroundColor = #colorLiteral(red: 0.3620333076, green: 0.8608141541, blue: 0.4826943278, alpha: 1)
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
