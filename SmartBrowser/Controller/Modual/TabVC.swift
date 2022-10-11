//
//  TabVC.swift
//  SmartBrowser
//
//  Created by yangjian on 2022/10/9.
//

import UIKit

class TabVC: BaseVC {
    
    @IBOutlet weak var collectionView: UICollectionView!

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    func setupUI() {
        collectionView.contentInset = UIEdgeInsets(top: 12, left: 20, bottom: 16, right: 20)
        collectionView.register(UINib(nibName: "TabCell", bundle: .main), forCellWithReuseIdentifier: "TabCell")
    }
    
    override func viewWillAppear(_ animated: Bool) {
        FirebaseUtil.logEvent(name: .tabShow)
    }

}

extension TabVC {
    @IBAction func backAction() {
        self.dismiss(animated: true)
    }
    
    @IBAction func addAction() {
        FirebaseUtil.logEvent(name: .tabNew, params: ["lig": "tab"])
        BrowserUtil.shared.add()
        collectionView.reloadData()
        self.dismiss(animated: true)
    }
}

extension TabVC: UICollectionViewDelegateFlowLayout, UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 20.0
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 16.0
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = (UIScreen.main.bounds.width - 40 - 16) / 2.0
        return CGSize(width: width, height: 220)
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let item = BrowserUtil.shared.webItems[indexPath.item]
        BrowserUtil.shared.select(item)
        collectionView.reloadData()
        self.dismiss(animated: true)
    }
}

extension TabVC: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return BrowserUtil.shared.webItems.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "TabCell", for: indexPath)
        if let cell = cell as? TabCell {
            let item = BrowserUtil.shared.webItems[indexPath.item]
            cell.item = item
            cell.deleteHandle = { [weak self] in
                BrowserUtil.shared.removeItem(item)
                self?.collectionView.reloadData()
            }
        }
        return cell
    }
}
