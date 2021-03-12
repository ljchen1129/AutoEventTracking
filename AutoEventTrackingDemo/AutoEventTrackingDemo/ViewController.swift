//
//  ViewController.swift
//  AutoEventTrackingDemo
//
//  Created by 陈良静 on 2021/3/8.
//

import UIKit

class ViewController: UIViewController {

    @IBOutlet weak var tapGestureLabel: UILabel!
    @IBOutlet weak var longPressGestureLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        navigationItem.title = "我是控制器标题"
        
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(tapGesture(_:)))
        tapGestureLabel.addGestureRecognizer(tapGesture)
        
        let longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(longPressGesture(_:)))
        longPressGestureLabel.addGestureRecognizer(longPressGesture)
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
    }
    
    @IBAction func buttonClick(_ sender: UIButton) {
        let tableVC = TableViewController(nibName: "TableViewController", bundle: nil)
        navigationController?.pushViewController(tableVC, animated: true)
    }
    
    @IBAction func `switch`(_ sender: UISwitch) {
        
    }
    
    @IBAction func slider(_ sender: UISlider) {
        
    }
    
    @IBAction func collectionViewButtonClick(_ sender: UIButton) {
        let VC = CollectionViewController(nibName: "CollectionViewController", bundle: nil)
        navigationController?.pushViewController(VC, animated: true)
    }
    
     @objc func tapGesture(_ sender: UITapGestureRecognizer) {
        print("tapGesture")
        
    }
    
    @objc func longPressGesture(_ sender: UILongPressGestureRecognizer) {
       print("longPressGesture")
       
   }
    
}

