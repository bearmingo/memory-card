//
//  CardsSlideView.swift
//  memory-card
//
//  Created by 陈国民 on 2018/12/7.
//  Copyright © 2018 陈国民. All rights reserved.
//

import UIKit
import pop

fileprivate let sizePercent: CGFloat = 0.1

@objc protocol CardsSlideDelegate {
    @objc optional func cardsSlideView(_ view: CardsSlideView, createFor: Int) -> UIView
    @objc optional func cardsSlideView(_ view: CardsSlideView, willMove: UIView)
    @objc optional func cardsSlideView(_ view: CardsSlideView, moving: UIView)
    @objc optional func cardsSlideView(_ view: CardsSlideView, cancelMove: UIView)
    @objc optional func cardsSlideView(_ view: CardsSlideView, hasMoved: UIView)
}

@IBDesignable
class CardsSlideView: UIView {
    
    enum CardType {
        case number0_9
        case number0_99
        case letter
    }
    
    enum CardOrder {
        case normal
        case random
    }
    
    weak var delegate: CardsSlideDelegate?
    
    var cardType: CardType = .number0_9
    var cardOrder: CardOrder = .random
    
    var currentIndex: Int = 0
    var initialLocation: CGFloat = 0
    var cardViews = [UIView]()
    
    private var moving: Bool = false
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        setupUI()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        setupUI()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        if !moving {
            relayoutCards()
        }
    }
    
    override func setNeedsLayout() {
        super.setNeedsLayout()
    }
    
    private func setupUI() {
        showCardZone()
        
        let recognizer = UIPanGestureRecognizer(target: self, action: #selector(handleGesture(recognizer:)))
        self.addGestureRecognizer(recognizer)
    }
    
    func showCardZone() {
        var last: UIView?
        for i in 0..<4 {
            let cardView = createCardView()
            
            cardView.frame = CGRect(x: 0, y: 0, width: 300, height: 400)
            self.setScale(withScalePercent: 1 - sizePercent * CGFloat(i), duration: 0.0001, cardView: cardView)
            let targetCenter = calcCardCenter(index: i)
            self.setCenter(targetCenter, duration: 0.1, cardView: cardView, index: i)
            cardView.center = CGPoint(x: self.bounds.width / 2, y: self.bounds.height / 2 - 10 * CGFloat(i) + 50)
            if let last = last {
                self.insertSubview(cardView, belowSubview: last)
            } else {
                self.addSubview(cardView)
            }
            self.cardViews.append(cardView)
            self.currentIndex = i
            last = cardView
        }
    }
    
    @objc private func handleGesture(recognizer: UIPanGestureRecognizer) {
        let location = recognizer.location(in: self)
        if recognizer.state == .began {
            self.moving = true
            self.initialLocation = location.x
            let cardView = createCardView()
            cardView.frame = CGRect(x: 0, y: 0, width: 300, height: 400)
            cardView.isHidden = true
            self.addSubview(cardView)
            
            if let last = cardViews.last {
                self.insertSubview(cardView, belowSubview: last)
            }
            self.setScale(withScalePercent: calcScale(index: self.cardViews.count), duration: 0.25, cardView: cardView)
            self.setCenter(calcCardCenter(index: self.cardViews.count), duration: 0.25, cardView: cardView, index: 0)
            self.cardViews.append(cardView)
            return
        }
        
        // Move the first card according with gesture
        let cardView = self.cardViews[0]
        // Remove all existed animations
        cardView.pop_removeAllAnimations()
        let transLocation = recognizer.translation(in: self)
        cardView.center = CGPoint(x: cardView.center.x + transLocation.x, y: cardView.center.y + transLocation.y)
        let xOffPercent = (cardView.center.x - self.bounds.width / 2) / self.bounds.width / 2
        let scalePercent = 1 - abs(xOffPercent) * 0.3
        let rotation = CGFloat.pi / 4 * xOffPercent
        self.setScale(withScalePercent: scalePercent, duration: 0.0001, cardView: cardView)
        self.setRotation(withAngle: rotation, duration: 0.001, cardView: cardView)
        recognizer.setTranslation(.zero, in: self)
        
        // Update card in background
        for (i, card) in cardViews.enumerated() {
            if cardView == card {
                continue
            }
            var percent = abs(xOffPercent)
            if percent > 1 {
                percent = 1.0
            }
            
            let scalePercent = calcScale(index: i) + sizePercent * abs(percent)
            self.setScale(withScalePercent: scalePercent, duration: 0.0001, cardView: card)
            var cardCenter = calcCardCenter(index: i)
            cardCenter.y = cardCenter.y - sizePercent * 400 * abs(percent)
            self.setCenter(cardCenter, duration: 0.0001, cardView: card, index: i)
            if i == cardViews.count - 1 {
                // set alpha for last one
                setAlpha(withAlpah: percent, duration: 0.0001, cardView: card)
            }
        }
        
        if recognizer.state == .ended {
            moving = false
            if cardView.center.x > 120 && cardView.center.x < self.bounds.width - 120 {
                if let firstCardView = self.cardViews.last {
                    firstCardView.removeFromSuperview()
                    self.cardViews.removeLast()
                    self.cardReCenterOrDismiss(isDismiss: false, cardView: cardView)
                }
            } else {
                self.cardReCenterOrDismiss(isDismiss: true, cardView: cardView)
            }
        }
    }
    
    func setCenter(_ center: CGPoint, duration: CGFloat, cardView: UIView, index: Int) {
        let ani = POPBasicAnimation(propertyNamed: kPOPViewCenter)
        ani?.toValue = NSValue(cgPoint: center)
        ani?.duration = TimeInterval(duration)
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
    
    func setAlpha(withAlpah alpha: CGFloat, duration: TimeInterval, cardView: UIView) {
        let ani = POPBasicAnimation(propertyNamed: kPOPViewAlpha)
        ani?.toValue = NSNumber(value: Float(alpha))
        ani?.duration = duration
        cardView.pop_add(ani, forKey: "alpha")
    }
    
    func cardReCenterOrDismiss(isDismiss: Bool, cardView: UIView) {
        // 没有想到其他办法，这个时候禁用掉界面，避免用户快速拖动时界面混乱，出现卡片越来越多的问题。
        // TODO(cgm)：优化，如果这时能够不禁用操作，还能交互，用户就能够更快的切换卡片，操作更顺畅。
        isUserInteractionEnabled = false
        
        if isDismiss {
            setRotation(withAngle: 0, duration: 0.25, cardView: cardView)
            if cardView.center.x < self.bounds.width / 2 {
                // Slip out of screen in left side
                self.setCenter(CGPoint(x: -150, y: cardView.center.y), duration: 0.25, cardView: cardView, index: 0)
            } else {
                // Slip out of screen in right side
                self.setCenter(CGPoint(x: self.bounds.width + cardView.bounds.size.width / 2, y: cardView.center.y), duration: 0.25, cardView: cardView, index: 0)
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
        relayoutCards()
        isUserInteractionEnabled = true
    }
    
    private func relayoutCards() {
        for (i, card) in self.cardViews.enumerated() {
            self.setScale(withScalePercent: calcScale(index: i), duration: 0.1, cardView: card)
            self.setCenter(calcCardCenter(index: i), duration: 0.1, cardView: card, index: i)
            if i == self.cardViews.count - 1 && card.alpha != 1 {
                setAlpha(withAlpah: 1, duration: 0.1, cardView: card)
            } else {
                card.alpha = 1
            }
        }
    }
    
    private func calcScale(index: Int) -> CGFloat {
        return 1 - sizePercent * CGFloat(index)
    }
    
    // Calculate center pointer of ith card
    private func calcCardCenter(index: Int) -> CGPoint {
        let viewCenterY = self.bounds.height / 2
        return CGPoint(x: self.bounds.width / 2, y: viewCenterY + (sizePercent * CGFloat(index) * 400))
    }
    
    
    private func createCardView() -> UIView {
        //return Bundle.main.loadNibNamed("NumberCardView", owner: self, options: nil)?.first as! UIView
        if let view = delegate?.cardsSlideView?(self, createFor: 0) {
            return view
        }
        
        let cardView = Bundle.main.loadNibNamed("TextCardView", owner: self, options: nil)?.first as! TextCardView
        switch self.cardType {
        case .number0_9:
            cardView.numLabel?.text = "\(arc4random() % 10)"
        case .number0_99:
            cardView.numLabel?.text = "\(arc4random() % 100)"
        case .letter:
            let offset = Int(arc4random() % 26)
            let ch =  String(letters[letters.index(letters.startIndex, offsetBy: offset)])
            cardView.numLabel?.text = ch.uppercased() + ch
        }
        
        return cardView
    }
}

fileprivate let letters = "abcdefghijklmnopqrstuvwxyz"
