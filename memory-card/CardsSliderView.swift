//
//  CardsSliderView.swift
//  memory-card
//
//  Created by 陈国民 on 2018/12/7.
//  Copyright © 2018 陈国民. All rights reserved.
//

import UIKit
import pop

fileprivate let sizePercent: CGFloat = 0.1

@objc protocol CardsSliderDataSource {
    @objc optional func numberOfCards(_ cardsSlider: CardsSliderView) -> Int
    @objc optional func cardsSliderViewSize(_ cardsSlider: CardsSliderView) -> CGSize
    @objc optional func cardsSliderView(_ cardsSlider: CardsSliderView, createForIndex index: Int) -> CardView
}

@objc protocol CardsSliderDelegate {

    @objc optional func cardsSliderView(_ cardsSlider: CardsSliderView, willMove: CardView)
    @objc optional func cardsSliderView(_ cardsSlider: CardsSliderView, moving: CardView)
    @objc optional func cardsSliderView(_ cardsSlider: CardsSliderView, cancelMove: CardView)
    @objc optional func cardsSliderView(_ cardsSlider: CardsSliderView, hasMoved: CardView)
}

@IBDesignable
class CardsSliderView: UIView {
    
    @objc enum CardType : Int {
        case number0_9
        case number0_99
        case letter
        case custom
    }
    
    @objc enum CardOrder : Int {
        case normal
        case random
    }
    
    weak var dataSource: CardsSliderDataSource?
    weak var delegate: CardsSliderDelegate?
    
    @IBInspectable var cardType: CardType = .number0_9
    @IBInspectable var cardOrder: CardOrder = .random
    var showCardNum = 4
    
    var currentIndex: Int = 0
    
    private var initialLocation: CGFloat = 0
    private var cardViews = [CardView]()
    
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
    
    override func prepareForInterfaceBuilder() {
        super.prepareForInterfaceBuilder()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        // Forbid relayout when moving card
        if !moving {
            for (i, card) in self.cardViews.enumerated() {
                let ani = POPBasicAnimation(propertyNamed: kPOPViewSize)
                ani?.toValue = NSValue(cgSize: sizeOfCard())
                ani?.duration = 0.25
                card.pop_add(ani, forKey: "size")
                self.setCenter(calcCardCenter(indexOfShow: i), duration: 0.25, cardView: card, index: i)
            }
            //relayoutCards()
        }
    }
    
    private func setupUI() {
        showCardZone()
        
        let recognizer = UIPanGestureRecognizer(target: self, action: #selector(handleGesture(recognizer:)))
        self.addGestureRecognizer(recognizer)
    }
    
    // MARK: - comment
    private var registeredClass: CardView.Type?
    private var registeredNib: UINib?
    private var cachedInstances = [CardView]()
    private var maxCachedInstance = 2
    
    func register(cls: CardView.Type) {
        cachedInstances.removeAll()
        registeredClass = cls
        registeredNib = nil
    }
    
    func register(nib: UINib) {
        cachedInstances.removeAll()
        registeredNib = nib
        registeredClass = nil
    }
    
    func dequene() -> CardView {
        if cachedInstances.isEmpty {
            if registeredClass != nil {
                return registeredClass!.init()
            } else if registeredNib != nil {
                return registeredNib?.instantiate(withOwner: self, options: nil).first as! CardView
            } else {
                fatalError("Do not have registered class or nib")
            }
        }
        
        let instance = cachedInstances.first!
        cachedInstances.removeFirst()
        
        // reset transform,
        // 避免再使用的时候，view.bounds大小于frame大小不一致。
        instance.transform = CGAffineTransform(scaleX: 1, y: 1).translatedBy(x: 0, y: 0)
        return instance
    }
    
    func cacheInstance(cardView: CardView) {
        if cachedInstances.count > maxCachedInstance {
            return
        }
        
        cachedInstances.append(cardView)
    }
    
    func reloadData() {
        for view in cardViews {
            view.removeFromSuperview()
        }
        cardViews.removeAll()
        showCardZone()
    }
    
    // MARK: - Card Views Animations
    
    private func showCardZone() {
        let totalCardNum: Int
        if cardType != .custom {
            totalCardNum = showCardNum
        } else {
            totalCardNum = dataSource?.numberOfCards?(self) ?? 0
        }
        
        for _ in 0..<min(showCardNum, totalCardNum) {
            createCardView(appendAtEnd: true, duration: 0.01)
        }
    }
    
    private func createCardView(appendAtEnd: Bool, duration: TimeInterval) {
        let i = self.cardViews.count
        let index = appendAtEnd ? (self.currentIndex + i) : self.currentIndex - 1
        let cardView = createCardView(index: index)
        cardView.frame = CGRect(origin: .zero, size: sizeOfCard())
        cardView.isHidden = true
        self.setScale(withScalePercent: calcScale(indexOfShow: i), duration: duration, cardView: cardView)
        self.setCenter(calcCardCenter(indexOfShow: i), duration: duration, cardView: cardView, index: i)
        if let last = cardViews.last {
            self.insertSubview(cardView, belowSubview: last)
        } else {
            self.addSubview(cardView)
        }
        self.cardViews.append(cardView)
    }
    
    private func sizeOfCard() -> CGSize {
        if let size = dataSource?.cardsSliderViewSize?(self) {
            return size
        }
        
        let height = self.bounds.height - (sizePercent * CGFloat(showCardNum - 1) * 400)
        return CGSize(width: self.bounds.width * 0.9, height: height * 0.9)
    }
    
    @objc private func handleGesture(recognizer: UIPanGestureRecognizer) {
        guard cardViews.count != 0 else { return }
        
        let location = recognizer.location(in: self)
        if recognizer.state == .began {
            self.moving = true
            self.initialLocation = location.x
            createCardView(appendAtEnd: true, duration: 0.25)

            return
        }
        
        // Move the first card according with gesture
        let cardView = self.cardViews[0]
        // Remove all existed animations
        cardView.pop_removeAllAnimations()
        let transLocation = recognizer.translation(in: self)
        cardView.center = CGPoint(x: cardView.center.x + transLocation.x, y: cardView.center.y + transLocation.y)
        let xOffPercent = (cardView.center.x - self.bounds.width / 2) / (self.bounds.width / 2)
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
            
            let scalePercent = calcScale(indexOfShow: i) + sizePercent * abs(percent)
            self.setScale(withScalePercent: scalePercent, duration: 0.0001, cardView: card)
            var cardCenter = calcCardCenter(indexOfShow: i)
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
                if let lastCardView = self.cardViews.last {
                    lastCardView.removeFromSuperview()
                    self.cardViews.removeLast()
                    self.cacheInstance(cardView: lastCardView)
                    self.cardReCenterOrDismiss(isDismiss: false, cardView: cardView)
                }
            } else {
                self.cardReCenterOrDismiss(isDismiss: true, cardView: cardView)
            }
        }
    }
    
    private func setCenter(_ center: CGPoint, duration: TimeInterval, cardView: UIView, index: Int) {
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
    
    private func setScale(withScalePercent percent: CGFloat, duration: TimeInterval, cardView: UIView) {
        let ani = POPBasicAnimation(propertyNamed: kPOPLayerScaleXY)
        ani?.toValue = NSValue(cgSize: CGSize(width: percent, height: percent))
        ani?.duration = duration
        cardView.layer.pop_add(ani, forKey: "scale")
    }
    
    private func setRotation(withAngle angle: CGFloat, duration: TimeInterval, cardView: UIView) {
        let ani = POPBasicAnimation(propertyNamed: kPOPLayerRotation)
        ani?.toValue =  NSNumber(value: Float(angle))
        ani?.duration = duration
        ani?.timingFunction = CAMediaTimingFunction(name: .easeOut)
        cardView.layer.pop_add(ani, forKey: "rotation")
    }
    
    private func setAlpha(withAlpah alpha: CGFloat, duration: TimeInterval, cardView: UIView) {
        let ani = POPBasicAnimation(propertyNamed: kPOPViewAlpha)
        ani?.toValue = NSNumber(value: Float(alpha))
        ani?.duration = duration
        cardView.pop_add(ani, forKey: "alpha")
    }
    
    private func cardReCenterOrDismiss(isDismiss: Bool, cardView: UIView) {
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
            self.currentIndex += 1
            self.cardViews.removeAll(where: {$0 == cardView})
            self.perform(#selector(removeCard(cardView:)), with: cardView, afterDelay: 0.25)
        } else {
            self.setScale(withScalePercent: 1, duration: 0.25, cardView: cardView)
            self.setRotation(withAngle: 0, duration: 0.25, cardView: cardView)
            let targetCenter = calcCardCenter(indexOfShow: 0)
            self.setCenter(targetCenter, duration: 0.25, cardView: cardView, index: 0)
            self.perform(#selector(removeCard(cardView:)), with: nil, afterDelay: 0.25)
        }
        
        // Re location the coard
        relayoutCards()
    }
    
    @objc func removeCard(cardView: CardView?) {
        // Remove cardView after animate is finished.
        if cardView != nil {
            cardView!.removeFromSuperview()
            //self.cardViews.removeAll(where: {$0 == cardView})
            cacheInstance(cardView: cardView!)
        }

        isUserInteractionEnabled = true
    }
    
    private func relayoutCards() {
        for (i, card) in self.cardViews.enumerated() {
            self.setScale(withScalePercent: calcScale(indexOfShow: i), duration: 0.1, cardView: card)
            self.setCenter(calcCardCenter(indexOfShow: i), duration: 0.1, cardView: card, index: i)
            if i == self.cardViews.count - 1 && card.alpha != 1 {
                setAlpha(withAlpah: 1, duration: 0.1, cardView: card)
            } else {
                card.alpha = 1
            }
        }
    }
    
    // MARK: - Calc for card
    
    private func calcScale(indexOfShow index: Int) -> CGFloat {
        return 1 - sizePercent * CGFloat(index)
    }
    
    // Calculate center pointer of ith card
    private func calcCardCenter(indexOfShow index: Int) -> CGPoint {
        let viewCenterY = self.bounds.height / 2
        return CGPoint(x: self.bounds.width / 2, y: viewCenterY + (sizePercent * CGFloat(index) * sizeOfCard().height) * 0.9)
    }
    
    private func createCardView(index: Int) -> CardView {
        //return Bundle.main.loadNibNamed("NumberCardView", owner: self, options: nil)?.first as! UIView
        if cardType == .custom {
            if let view = dataSource?.cardsSliderView?(self, createForIndex: index) {
                return view
            }
            fatalError()
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
        case .custom:
            fatalError()
        }
        
        return cardView
    }
}

fileprivate let letters = "abcdefghijklmnopqrstuvwxyz"
