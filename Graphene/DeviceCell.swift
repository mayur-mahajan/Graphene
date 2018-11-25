//
//  DeviceCell.swift
//  Graphene
//
//  Created by Mayur Mahajan on 11/24/18.
//  Copyright © 2018 Orion Labs. All rights reserved.
//

import Foundation
import UIKit

class DeviceCell: UICollectionViewCell {
    
    weak var device: NetService?
    
    static let identifier = "DeviceCellId"
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupCell()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    let deviceName: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        return label
    }()
    
    override func layoutSubviews() {
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOffset = CGSize(width: 0, height: 2.0)
        layer.shadowRadius = 10.0
        layer.shadowOpacity = 0.5
        layer.masksToBounds = false
        layer.shadowPath = UIBezierPath(roundedRect: self.bounds, cornerRadius: self.layer.cornerRadius).cgPath
        
        
        addSubview(deviceName)
        deviceName.translatesAutoresizingMaskIntoConstraints = false
        deviceName.leadingAnchor.constraint(equalTo: self.leadingAnchor).isActive = true
        deviceName.trailingAnchor.constraint(equalTo: self.trailingAnchor).isActive = true
        deviceName.bottomAnchor.constraint(equalTo: self.bottomAnchor).isActive = true
        deviceName.heightAnchor.constraint(equalToConstant: 20)
        deviceName.text = device?.name ?? "Unknown"
        
    }
    
    func setupCell() {
        layer.cornerRadius = 10
        backgroundColor = .white
        
        layer.cornerRadius = 10.0
        layer.borderWidth = 5.0
        layer.borderColor = UIColor.clear.cgColor
        layer.masksToBounds = true
    }
}
