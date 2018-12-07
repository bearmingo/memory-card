//
//  CircleView.swift
//  memory-card
//
//  Created by 陈国民 on 2018/12/2.
//  Copyright © 2018 陈国民. All rights reserved.
//

import UIKit
import pop

@IBDesignable
class CircleView: UIView {

    @IBInspectable var lineColor: UIColor = UIColor.white {
        didSet {
            self.circleLayer.strokeColor = self.lineColor.cgColor
        }
    }
    
    private var circleLayer: CAShapeLayer!
    private var label: UILabel!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        setupUI()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        setupUI()
    }
    
    private func setupUI() {
        label = UILabel()
        label.text = "0%"
        label.frame = CGRect(x: 0, y: 0, width: 100, height: 100)
        label.textColor = UIColor.white
        label.center = CGPoint(x: self.bounds.size.width / 2, y: self.bounds.size.height / 2)
        label.font = UIFont.systemFont(ofSize: 25)
        label.textAlignment = .center
        self.addSubview(label)
        
        circleLayer = CAShapeLayer()
        let lineWidth:CGFloat = 4.0
        let radius = self.bounds.size.width / 2 - lineWidth
        let rect = CGRect(x: lineWidth / 2, y: lineWidth / 2, width: radius * 2, height: radius * 2)
        let bezierPath = UIBezierPath(roundedRect: rect, cornerRadius: radius)
        self.circleLayer.strokeColor = lineColor.cgColor
        self.circleLayer.path = bezierPath.cgPath
        self.circleLayer.fillColor = nil
        self.circleLayer.lineJoin = .round
        self.circleLayer.lineCap = .round
        self.circleLayer.lineWidth = lineWidth
        
        let bgCircle = CAShapeLayer()
        bgCircle.lineWidth = 1.0
        bgCircle.strokeStart = 0.0
        bgCircle.strokeEnd = 1.0
        bgCircle.strokeColor = UIColor.gray.cgColor
        bgCircle.path = UIBezierPath(roundedRect: CGRect(x: lineWidth - 1 , y: lineWidth - 1, width: radius * 2, height: radius * 2), cornerRadius: radius - lineWidth + 1).cgPath
        bgCircle.lineCap = .round
        bgCircle.lineJoin = .round
        bgCircle.fillColor = nil
        
        self.layer.addSublayer(bgCircle)
        self.layer.addSublayer(self.circleLayer)
    }

    func setCircleStrokeEnd(_ strokeEnd: CGFloat, animated: Bool) {
        if animated {
            animationWithStrokenEnd(strokeEnd)
        } else {
            self.circleLayer.strokeEnd = strokeEnd
        }
    }
    
    private func animationWithStrokenEnd(_ strokeEnd: CGFloat) {
        if let ani = POPBasicAnimation(propertyNamed: kPOPShapeLayerStrokeEnd) {
            ani.toValue = strokeEnd
            ani.duration = 1
            ani.removedOnCompletion = true
            self.circleLayer.pop_add(ani, forKey: "123")
        }
        
        let labelAni = POPBasicAnimation()
        labelAni.duration = 1
        let prop = POPAnimatableProperty.property(withName: "count") { (prop) in
            prop?.readBlock = { obj, values in
                //values[0] = CGFloat((obj as! UILabel).text)!
            }
            
            prop?.writeBlock = { obj, values in
                let str = String(format: "%.2f%%", values?[0] ?? 0.0)
                (obj as! UILabel).text = str
            }
            prop?.threshold = 0.01
        }
        
        labelAni.property = prop as? POPAnimatableProperty
        labelAni.fromValue = 0.0
        labelAni.toValue = 100.0 * strokeEnd
        self.label.pop_add(labelAni, forKey: "123")
    }
    
    
}
