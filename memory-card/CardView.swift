//
//  CardView.swift
//  memory-card
//
//  Created by 陈国民 on 2018/12/8.
//  Copyright © 2018 陈国民. All rights reserved.
//

import UIKit

@IBDesignable
class CardView: UIView {
    
    @IBInspectable var cornerRadius: CGFloat = 20 { didSet { setupUI() }}
    @IBInspectable var borderColor: UIColor = UIColor.lightGray { didSet { setupUI() }}
    @IBInspectable var borderWidth: CGFloat = 0.5 { didSet { setupUI() }}

    override func awakeFromNib() {
        super.awakeFromNib()
        setupUI()
    }
    
    override func prepareForInterfaceBuilder() {
        super.prepareForInterfaceBuilder()
        setupUI()
    }
    
    private func setupUI() {
        self.layer.masksToBounds = true
        self.layer.cornerRadius = cornerRadius
        self.layer.borderColor = borderColor.cgColor
        self.layer.borderWidth = borderWidth
    }

}
