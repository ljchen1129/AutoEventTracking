//
//  CollectionViewController.swift
//  AutoEventTrackingDemo
//
//  Created by 陈良静 on 2021/3/11.
//

import UIKit

class CollectionViewController: UIViewController {

    // MARK: ------------------------ let constant ------------------------
    
    // MARK: ------------------------ lazy Var ----------------------------
    @IBOutlet weak var collcetionView: UICollectionView!
    
    // MARK: ------------------------ var ---------------------------------
    
    // MARK: ------------------------ lifeCycle ---------------------------
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupUI()
        bind()
    }
}

// MARK: - UI
extension CollectionViewController {
    private func setupUI() {
        setupNavigation()
        
        collcetionView.backgroundColor = UIColor.clear
        collcetionView.register(UICollectionViewCell.self, forCellWithReuseIdentifier: "cellID")
    }
    
    private func setupNavigation() {
        navigationItem.title = "我是 CollectionViewController 标题"
    }
}

// MARK: - bind
extension CollectionViewController {
    private func bind() {
        
    }
}

// MARK: - privateFunc
extension CollectionViewController {
    
}

// MARK: - publicFunc
extension CollectionViewController {
    
}

// MARK: - evenetResponse
extension CollectionViewController {
    
}

extension CollectionViewController: UICollectionViewDataSource {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 10
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 10
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cellID", for: indexPath)
        let label = UILabel()
        label.text = "section: \(indexPath.section), row: \(indexPath.row)"
        label.numberOfLines = 0
        
        cell.contentView.subviews.forEach({ $0.removeFromSuperview() })
        if !cell.contentView.subviews.contains(label) {
            cell.contentView.addSubview(label)
            label.frame = CGRect(x: 20, y: 20, width: 60, height: 80)
        }
        
        cell.backgroundColor = UIColor.clear
        cell.contentView.backgroundColor = UIColor(red: CGFloat(Int.random(in: 0...255)), green: CGFloat(Int.random(in: 0...255)), blue: CGFloat(Int.random(in: 0...255)), alpha: 1.0)
        
        return cell
    }
}

extension CollectionViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: true)
        
        
    }
}

extension CollectionViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = UIScreen.main.bounds.size.width / 3 - 24
        
        return CGSize(width: width, height: width)
    }
}
