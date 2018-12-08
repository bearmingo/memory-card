//
//  ViewController.swift
//  memory-card
//
//  Created by 陈国民 on 2018/12/2.
//  Copyright © 2018 陈国民. All rights reserved.
//

import UIKit
import pop

fileprivate let sizePercent: CGFloat = 0.1

class ViewController: UIViewController {
    
    var currentIndex: Int = 0
    var initialLocation: CGFloat = 0
    var cardViews = [UIView]()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        showCardZone()
        
        let recognizer = UIPanGestureRecognizer(target: self, action: #selector(handleGesture(recognizer:)))
        self.view.addGestureRecognizer(recognizer)
    }

    @objc func handleGesture(recognizer: UIPanGestureRecognizer) {
        let location = recognizer.location(in: self.view)
        if recognizer.state == .began {
            self.initialLocation = location.x
            let cardView = createCardView()
            cardView.frame = CGRect(x: 0, y: 0, width: 300, height: 400)
            cardView.isHidden = true
            self.view.addSubview(cardView)
            if let firstView = cardViews.first {
                self.view.insertSubview(cardView, belowSubview: firstView)
            }
            self.setScale(withScalePercent: 1 - CGFloat(self.cardViews.count) * sizePercent, duration: 0.25, cardView: cardView)
            self.setCenter(CGPoint(x: self.view.bounds.width / 2, y: self.view.bounds.height / 2 + 150 - 20 - (sizePercent * 0 * 400)), duration: 0.25, cardView: cardView, index: 0)
            self.cardViews.insert(cardView, at: 0)
            return
        }
        
        // Move the last card according with gesture
        let cardView = self.cardViews[self.cardViews.count - 1]
        let transLocation = recognizer.translation(in: self.view)
        cardView.center = CGPoint(x: cardView.center.x + transLocation.x, y: cardView.center.y + transLocation.y)
        let xOffPercent = (cardView.center.x - self.view.bounds.width / 2) / self.view.bounds.width / 2
        let scalePercent = 1 - abs(xOffPercent) * 0.3
        let rotation = CGFloat.pi / 4 * xOffPercent
        self.setScale(withScalePercent: scalePercent, duration: 0.0001, cardView: cardView)
        self.setRotation(withAngle: rotation, duration: 0.001, cardView: cardView)
        recognizer.setTranslation(.zero, in: self.view)
        
        // Update card in background
        for (i, card) in cardViews.enumerated() {
            if cardView == card {
                continue
            }
            var percent = abs(xOffPercent)
            if percent > 1 {
                percent = 1.0
            }
            
            let scalePercent = 1 - (sizePercent * CGFloat(self.cardViews.count - 1 - i) - sizePercent * abs(percent))
            self.setScale(withScalePercent: scalePercent, duration: 0.0001, cardView: card)
            
            let viewCenterY = self.view.bounds.height / 2
            let centerY:CGFloat = viewCenterY + 150 - 20 - sizePercent * 400 * (CGFloat(i) - 1 + abs(percent))
            let cardCenter = CGPoint(x: self.view.bounds.width / 2, y: centerY)
            self.setCenter(cardCenter, duration: 0.0001, cardView: card, index: i)
        }
        
        if recognizer.state == .ended {
            if cardView.center.x > 120 && cardView.center.x < self.view.bounds.width - 120 {
                if let firstCardView = self.cardViews.first {
                    firstCardView.removeFromSuperview()
                    self.cardViews.remove(at: 0)
                    self.cardReCenterOrDismiss(isDismiss: false, cardView: cardView)
                }
            } else {
                self.cardReCenterOrDismiss(isDismiss: true, cardView: cardView)
            }
        }
    }
    
    func showCardZone() {
        for i in 0..<4 {
            let cardView = createCardView()
            
            cardView.frame = CGRect(x: 0, y: 0, width: 300, height: 400)
            self.setScale(withScalePercent: 1 - sizePercent * CGFloat(3 - i), duration: 0.0001, cardView: cardView)
            let targetCenter = calcCardCenter(index: i)
            self.setCenter(targetCenter, duration: 0.1, cardView: cardView, index: i)
            cardView.center = CGPoint(x: self.view.bounds.width / 2, y: self.view.bounds.height / 2 - 10 * CGFloat(i) + 50)
            self.view.addSubview(cardView)
            self.cardViews.append(cardView)
            self.currentIndex = i
        }
    }
    
    func setCenter(_ center: CGPoint, duration: TimeInterval, cardView: UIView, index: Int) {
        let ani = POPBasicAnimation(propertyNamed: kPOPViewCenter)
        ani?.toValue = NSValue(cgPoint: center)
        ani?.duration = duration
        ani?.completionBlock = { ani, isFinish in
            if isFinish {
                cardView.isHidden = false
            }
        }
        cardView.pop_add(ani, forKey: "center")
    }
    
    func setScale(withScalePercent percent: CGFloat, duration: TimeInterval, cardView: UIView) {
        let ani = POPBasicAnimation(propertyNamed: kPOPLayerScaleXY)
        ani?.toValue = NSValue(cgSize: CGSize(width: percent, height: percent))
        ani?.duration = duration
        cardView.layer.pop_add(ani, forKey: "scale")
    }
    
    func setRotation(withAngle angle: CGFloat, duration: TimeInterval, cardView: UIView) {
        let ani = POPBasicAnimation(propertyNamed: kPOPLayerRotation)
        ani?.toValue =  NSNumber(value: Float(angle))
        ani?.duration = duration
        ani?.timingFunction = CAMediaTimingFunction(name: .easeOut)
        cardView.layer.pop_add(ani, forKey: "rotation")
    }

    func cardReCenterOrDismiss(isDismiss: Bool, cardView: UIView) {
        if isDismiss {
            setRotation(withAngle: 0, duration: 0.25, cardView: cardView)
            if cardView.center.x < self.view.bounds.width / 2 {
                // Slip out of screen in left side
                self.setCenter(CGPoint(x: -150, y: cardView.center.y), duration: 0.25, cardView: cardView, index: 0)
            } else {
                // Slip out of screen in right side
                self.setCenter(CGPoint(x: self.view.bounds.width + cardView.bounds.size.width / 2, y: cardView.center.y), duration: 0.25, cardView: cardView, index: 0)
            }
            self.perform(#selector(removeCard(cardView:)), with: cardView, afterDelay: 0.25)
        } else {
            self.setScale(withScalePercent: 1, duration: 0.25, cardView: cardView)
            self.setRotation(withAngle: 0, duration: 0.25, cardView: cardView)
            let targetCenter = calcCardCenter(index: 3)
            self.setCenter(targetCenter, duration: 0.25, cardView: cardView, index: 3)
            self.perform(#selector(removeCard(cardView:)), with: nil, afterDelay: 0.25)
        }
    }
    
    @objc func removeCard(cardView: UIView?) {
        // Remove cardView after animate is finished.
        if cardView != nil {
            cardView!.removeFromSuperview()
            self.cardViews.removeAll(where: {$0 == cardView})
        }
        
        // Re location the coard
        for (i, card) in self.cardViews.enumerated() {
            self.setScale(withScalePercent: calcScale(index: i), duration: 0.1, cardView: card)
            self.setCenter(calcCardCenter(index: i), duration: 0.1, cardView: card, index: i)
        }
    }
    
    private func calcScale(index: Int) -> CGFloat {
        return 1 - sizePercent * CGFloat(self.cardViews.count - 1 - index)
    }
    
    // Calculate center pointer of ith card
    private func calcCardCenter(index: Int) -> CGPoint {
        let viewCenterY = self.view.bounds.height / 2
        return CGPoint(x: self.view.bounds.width / 2, y: viewCenterY + 150 - 20 - (sizePercent * CGFloat(index) * 400))
    }
    
    private func createCardView() -> UIView {
        //return Bundle.main.loadNibNamed("NumberCardView", owner: self, options: nil)?.first as! UIView
        
        let cardView = Bundle.main.loadNibNamed("TextCardView", owner: self, options: nil)?.first as! TextCardView
        cardView.numLabel?.text = "\(arc4random()  % 10)"
        return cardView
    }
}

