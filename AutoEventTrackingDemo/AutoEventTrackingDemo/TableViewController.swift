//
//  TableViewController.swift
//  AutoEventTrackingDemo
//
//  Created by 陈良静 on 2021/3/11.
//

import UIKit

class TableViewController: UIViewController {

    // MARK: ------------------------ let constant ------------------------
    
    // MARK: ------------------------ lazy Var ----------------------------
    
    @IBOutlet weak var tableView: UITableView!
    // MARK: ------------------------ var ---------------------------------
    
    // MARK: ------------------------ lifeCycle ---------------------------
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupUI()
        bind()
    }
}

// MARK: - UI
extension TableViewController {
    private func setupUI() {
        setupNavigation()
        
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cellID")
    }
    
    private func setupNavigation() {
        navigationItem.title = "TableViewController 标题"
    }
}

// MARK: - bind
extension TableViewController {
    private func bind() {
        
    }
}

// MARK: - privateFunc
extension TableViewController {
    
}

// MARK: - publicFunc
extension TableViewController {
    
}

// MARK: - evenetResponse
extension TableViewController {
    
}

extension TableViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 20
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cellID", for: indexPath)
        cell.textLabel?.text = "\(indexPath.section)-\(indexPath.row)"
        
        return cell
    }
}

extension TableViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        print("deselectRow \(indexPath.section)-\(indexPath.row)")
    }
}
