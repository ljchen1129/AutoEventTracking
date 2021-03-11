//
//  ViewController.swift
//  AutoEventTrackingDemo
//
//  Created by 陈良静 on 2021/3/8.
//

import UIKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        navigationItem.title = "我是控制器标题"
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
}

