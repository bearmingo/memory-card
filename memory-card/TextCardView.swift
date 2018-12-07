//
//  TextCardView.swift
//  memory-card
//
//  Created by 陈国民 on 2018/12/7.
//  Copyright © 2018 陈国民. All rights reserved.
//

import UIKit

@IBDesignable
class TextCardView: UIView {
    
    @IBOutlet weak var numLabel: UILabel?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        setupUI()
    }
    
    override func prepareForInterfaceBuilder() {
        super.prepareForInterfaceBuilder()
        setupUI()
    }
    
    private func setupUI() {
        self.layer.cornerRadius = 20
        self.layer.borderColor = UIColor.lightGray.cgColor
        self.layer.borderWidth = 0.5
    }

}
