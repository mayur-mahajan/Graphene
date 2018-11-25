//
//  ViewController.swift
//  Graphene
//
//  Created by MAYUR MAHAJAN on 7/13/18.
//  Copyright © 2018 Orion Labs. All rights reserved.
//

import UIKit

class DeviceViewController: UICollectionViewController, UICollectionViewDelegateFlowLayout,
                            NetServiceDelegate, NetServiceBrowserDelegate {
    
    let cellId = "DeviceCellId"
    
    let spacings: CGFloat = 15
    let cellsPerRow = 3
    
    let serviceType = "_http._tcp."
    let serviceBroswer = NetServiceBrowser()
    var devices = [NetService:KarbonDevice]()
    var discoveredServices = [NetService]()

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        collectionView!.register(DeviceCell.self, forCellWithReuseIdentifier: cellId)
        
        setupView()
        startDiscovery()        
    }
    
    func setupView() {
        navigationItem.title = "Select Device"

        collectionView!.backgroundColor = UIColor.init(white: 0.85, alpha: 1.0)
        collectionView?.alwaysBounceVertical = true

    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func startDiscovery() {
        serviceBroswer.delegate = self
        serviceBroswer.searchForServices(ofType: serviceType, inDomain: "local.")
    }
    
    func stopDiscovery() {
        NSLog("Stop discovery")
        serviceBroswer.stop()
        serviceBroswer.delegate = nil
    }
    
    //MARK: - UICollectionViewDataSource methods
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        discoveredServices = Array(devices.keys)
        if discoveredServices.count > 0 {
            collectionView.restore()
        }
        else {
            collectionView.setEmptyMessage("No Devices Found")
        }
        return discoveredServices.count
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellId, for: indexPath) as! DeviceCell
        let device = discoveredServices[indexPath.row]
        cell.device = device
        NSLog("Rendering for service \(device.name)")
        return cell
    }

    //MARK: - UICollectionViewDelegate methods
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let service = discoveredServices[indexPath.row]
        guard let device = devices[service] else {
            NSLog("Device not found for service \(service)")
            return
        }

        NSLog("User tapped on item \(indexPath.row) service \(service.name)")
        device.makeRequest(path: "") { data in
            let responseData = String(data: data, encoding: .utf8)
            NSLog("Received \(String(describing: responseData))")
        }
        
        let message: String
        if device.isResolved {
            message = "Resolved address for \(device.name) at \(device.address!) on \(device.address!):\(device.port!)"
        }
        else {
            message = "Device \(device.name) is not resolved"
        }
        let alert = UIAlertController.init(title: device.name, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        self.present(alert, animated: true, completion: nil)

    }

    //MARK: - UICollectionViewDelegateFlowLayout methods
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        // Calculate space for actual cells
        // Safe area left and right, spacing inset on left and right, spacing * number of items in a row is the total spacing for each row
        let unusedSpace = spacings * 2 + collectionView.safeAreaInsets.left + collectionView.safeAreaInsets.right + spacings * CGFloat(cellsPerRow - 1)
        let size = ((collectionView.bounds.size.width - unusedSpace) / CGFloat(cellsPerRow)).rounded(.down)
        return CGSize(width: size, height: size)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets.init(top: spacings, left: collectionView.safeAreaInsets.left + spacings, bottom: spacings, right: collectionView.safeAreaInsets.right + spacings)
    }
    
    //MARK: - NSNetServiceDelegate methods
    func netServiceDidResolveAddress(_ sender: NetService) {
        NSLog("Service \(sender.name) resolved")
        
        guard sender.addresses?.count ?? 0 > 0 else {
            NSLog("Service \(sender.name) did not return any resolved address(es)")
            return
        }
        
        let address = sender.addresses!.first! as NSData
        var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
        if getnameinfo(address.bytes.assumingMemoryBound(to: sockaddr.self), socklen_t(address.length),
                       &hostname, socklen_t(hostname.count), nil, 0, NI_NUMERICHOST) == 0 {
            let ipAddr = String(cString: hostname)
            let txtRecords = sender.txtRecordData() != nil ? NetService.dictionary(fromTXTRecord: sender.txtRecordData()!) : nil
            devices[sender]?.resolve(address: ipAddr, port: sender.port, record: txtRecords)
        }
    }
    
    //MARK: - NSNetServiceBrowserDelegate methods
    func netServiceBrowser(_ browser: NetServiceBrowser, didFind service: NetService, moreComing: Bool) {
        NSLog("Discovered service \(service)")
        devices[service] = KarbonDevice(named: service.name)
        service.delegate = self
        service.resolve(withTimeout: 30)
        if (!moreComing) {
            collectionView?.reloadData()
        }
    }
    
    func netServiceBrowser(_ browser: NetServiceBrowser, didRemove service: NetService, moreComing: Bool) {
        guard let device = devices.removeValue(forKey: service) else {
            return
        }
        NSLog("Removed device \(device) for service \(service)")
        
        if (!moreComing) {
            collectionView?.reloadData()
        }
    }
    
    func netServiceBrowserWillSearch(_ browser: NetServiceBrowser) {
        NSLog("Start searching for devices...")
        devices.removeAll()
    }

    func netServiceBrowserDidStopSearch(_ browser: NetServiceBrowser) {
        stopDiscovery()
    }
    
    func netServiceBrowser(_ browser: NetServiceBrowser, didNotSearch errorDict: [String : NSNumber]) {
        stopDiscovery()
    }
}

extension UICollectionView {
    
    func setEmptyMessage(_ message: String) {
        let messageLabel = UILabel(frame: CGRect(x: 0, y: 0, width: self.bounds.size.width, height: self.bounds.size.height))
        messageLabel.text = message
        messageLabel.textColor = .darkGray
        messageLabel.numberOfLines = 0;
        messageLabel.textAlignment = .center;
        messageLabel.sizeToFit()
        
        self.backgroundView = messageLabel;
    }
    
    func restore() {
        self.backgroundView = nil
    }
}

class DeviceCell: UICollectionViewCell {
    
    weak var device: NetService?
    
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

