//
//  NumberViewController.swift
//  memory-card
//
//  Created by 陈国民 on 2018/12/7.
//  Copyright © 2018 陈国民. All rights reserved.
//

import UIKit


class NumberViewController: UIViewController {

    @IBOutlet weak var cardSlider: CardsSliderView!
    
    private var numberImages = [UIImage]()
    private var numberSort = [Int]()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        for i in 0...9 {
            numberImages.append(UIImage(named: "\(i)")!)
            numberSort.append(i)
        }
        
        numberSort.shuffle()
        
        cardSlider.register(nib: UINib(nibName: "ImageCardView", bundle: Bundle(for: ImageCardView.self)))
        cardSlider.cardType = .custom
        cardSlider.dataSource = self
        cardSlider.reloadData()
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}

extension NumberViewController : CardsSliderDataSource {
    func numberOfCards(_ cardsSlider: CardsSliderView) -> Int {
        return 10
    }
    
    func cardsSliderView(_ cardsSlider: CardsSliderView, createForIndex index: Int) -> CardView {
        let cardView = cardsSlider.dequene() as! ImageCardView
        
        let num = numberSort[index % 10]
        cardView.imageView.image = numberImages[num]
        cardView.label.text = "\(num)"
        return cardView
    }
}
