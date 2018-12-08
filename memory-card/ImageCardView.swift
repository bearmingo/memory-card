//
//  ImageCardView.swift
//  memory-card
//
//  Created by 陈国民 on 2018/12/8.
//  Copyright © 2018 陈国民. All rights reserved.
//

import UIKit

@IBDesignable
class ImageCardView: CardView {

    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var label: UILabel!
    
    override func prepareForInterfaceBuilder() {
        super.prepareForInterfaceBuilder()
    }
}
