//
//  CardView.swift
//  memory-card
//
//  Created by 陈国民 on 2018/12/2.
//  Copyright © 2018 陈国民. All rights reserved.
//

import UIKit
import pop

@IBDesignable
class CardView: UIView {
    
    @IBInspectable var bgColor: UIColor = UIColor.black
    @IBInspectable var cornerRadius: CGFloat = 15
    @IBInspectable var buttonConnerRadius: CGFloat = 20
    @IBInspectable var tapColor1: UIColor = UIColor.gray
    @IBInspectable var tapColor2: UIColor = UIColor.gray
    @IBInspectable var circleSize: CGSize = CGSize(width: 160, height: 160)
    @IBInspectable var shadowSize: CGSize = CGSize(width: 10, height: 10)
    
    @IBOutlet weak var tapButton: UIButton?
    
    private var circleView1: CircleView!
    private var circleView2: CircleView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        setupUI()
        
    }
    
    override func prepareForInterfaceBuilder() {
        super.prepareForInterfaceBuilder()
        setupUI()
    }

    
    private func setupUI() {
        let maskLayer = CAShapeLayer()
        maskLayer.path = UIBezierPath(roundedRect: self.layer.bounds, byRoundingCorners: UIRectCorner.allCorners, cornerRadii: CGSize(width: self.cornerRadius, height: self.cornerRadius)).cgPath
        self.layer.mask = maskLayer
        self.backgroundColor = self.bgColor
        self.circleView1 = CircleView(frame: CGRect(x: 15, y: 15, width: self.circleSize.width, height: self.circleSize.height))
        self.circleView1.lineColor = self.tapColor1
        self.circleView1.transform = self.circleView1.transform.scaledBy(x: 0.5, y: 0.5)
        self.circleView1.center = CGPoint(x: 15 + self.circleSize.width / 2 / 2, y: 15 + self.circleSize.width / 2 / 2)
        
        self.circleView2 = CircleView(frame: CGRect(x: 15, y: 15, width: self.circleSize.width, height: self.circleSize.height))
        self.circleView2.lineColor = tapColor2
        self.circleView2.center = CGPoint(x: self.bounds.width / 2, y: self.bounds.height / 2)

        self.addSubview(self.circleView1)
        self.addSubview(self.circleView2)
        
        self.circleView1.setCircleStrokeEnd(0.0, animated: true)
        self.circleView2.setCircleStrokeEnd(1.0, animated: true)
        self.tapButton?.layer.cornerRadius = self.buttonConnerRadius
        self.tapButton?.layer.masksToBounds = true
        self.tapButton?.updateConstraints()
        self.layoutIfNeeded()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        if let maskLayer = self.layer.mask as? CAShapeLayer {
            maskLayer.path = UIBezierPath(roundedRect: self.layer.bounds, byRoundingCorners: UIRectCorner.allCorners, cornerRadii: CGSize(width: self.cornerRadius, height: self.cornerRadius)).cgPath
        }
    }

    @IBAction func tapClicked(_ sender: Any) {
        let firstIsCenter: Bool = CGPoint(x: self.bounds.width / 2, y: self.bounds.height / 2) == self.circleView1.center
        
        let ani1 = POPBasicAnimation(propertyNamed: kPOPViewCenter)
        let ani2 = POPBasicAnimation(propertyNamed: kPOPViewCenter)
        let sani1 = POPSpringAnimation(propertyNamed: kPOPViewScaleXY)
        let sani2 = POPSpringAnimation(propertyNamed: kPOPViewScaleXY)
        
        sani1?.springSpeed = 12.0
        sani2?.springSpeed = 12.0
        sani1?.springBounciness = 20.0
        sani2?.springBounciness = 20.0
        sani1?.velocity = NSValue(cgPoint: CGPoint(x: 5, y: 5))
        sani2?.velocity = NSValue(cgPoint: CGPoint(x: 5, y: 5))
        if firstIsCenter {
            sani2?.toValue = NSValue(cgPoint: CGPoint(x: 1, y: 1))
            sani1?.toValue = NSValue(cgPoint: CGPoint(x: 0.5, y: 0.5))
            ani1?.toValue = NSValue(cgPoint: CGPoint(x: 15 + self.circleSize.width / 2 / 2, y: 15 + self.circleSize.width / 2 / 2))
            ani2?.toValue = NSValue(cgPoint: CGPoint(x: self.bounds.width / 2, y: self.bounds.height / 2))
        } else {
            sani1?.toValue = NSValue(cgPoint: CGPoint(x: 1, y: 1))
            sani2?.toValue = NSValue(cgPoint: CGPoint(x: 0.5, y: 0.5))
            ani2?.toValue = NSValue(cgPoint: CGPoint(x: self.bounds.width - 15 - self.circleSize.width / 2 / 2, y: 15 + self.circleSize.width / 2 / 2))
            ani1?.toValue = NSValue(cgPoint: CGPoint(x: self.bounds.width / 2, y: self.bounds.height / 2))
        }
        ani1?.duration = 0.4
        ani2?.duration = 0.5
        
        if firstIsCenter {
            ani1?.completionBlock = { animation, isFinish in
                if isFinish {
                    self.circleView1.setCircleStrokeEnd(0.0, animated: true)
                }
            }
            ani2?.completionBlock = { animation, isFinish in
                if isFinish {
                    self.circleView2.setCircleStrokeEnd(1.0, animated: true)
                }
            }
        } else {
            ani1?.completionBlock = { animation, isFinish in
                if isFinish {
                    self.circleView1.setCircleStrokeEnd(1.0, animated: true)
                }
            }
            ani2?.completionBlock = { animation, isFinish in
                if isFinish {
                    self.circleView2.setCircleStrokeEnd(0.0, animated: true)
                }
            }
        }
        self.circleView1.pop_add(sani1, forKey: "1233")
        self.circleView2.pop_add(sani2, forKey: "1233")
        self.circleView1.pop_add(ani1, forKey: "123")
        self.circleView2.pop_add(ani2, forKey: "123")
        
        let buttonAni = POPBasicAnimation(propertyNamed: kPOPViewSize)
        buttonAni?.duration = 0.4
        buttonAni?.toValue = NSValue(cgSize: CGSize(width: 40, height: 40))
        buttonAni?.completionBlock = { ani, isFinish in
            if isFinish {
                let buttonAni1 = POPBasicAnimation(propertyNamed: kPOPViewSize)
                buttonAni1?.duration = 0.4
                buttonAni1?.toValue = NSValue(cgSize: CGSize(width: self.bounds.width * 0.8, height: 40))
                self.tapButton?.pop_add(buttonAni1, forKey: "1233")
            }
        }
        let buttonColorAni = POPBasicAnimation(propertyNamed: kPOPViewBackgroundColor)
        buttonColorAni?.duration = 0.8
        if firstIsCenter {
            buttonColorAni?.toValue = self.tapColor2
        } else {
            buttonColorAni?.toValue = self.tapColor1
        }
        
        self.tapButton?.pop_add(buttonColorAni, forKey: "ani-bk-color")
        self.tapButton?.pop_add(buttonAni, forKey: "pos")
    }
}
