//
//  FolderTVC.swift
//  VocalMVC
//
//  Created by Omran Khoja on 1/12/20.
//  Copyright © 2020 AcronDesign. All rights reserved.
//

import UIKit

class FolderTVC: UITableViewController {
    
//    enum Notification: String {
//        case makeCoffee
//    }
    
    //MARK: - Properties
    var folder: Folder = Store.shared.rootFolder {
        didSet {
            tableView.reloadData()
            if folder === folder.store?.rootFolder {
                title = .recordings
            } else {
                title = folder.name
            }
        }
    }

    //MARK: - VC LifeCycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupNavBar()
        setupStoreChangeObserver()
        
    }
    
    //MARK: - Navigation Bar Customization
    fileprivate func setupNavBar() {
        navigationItem.leftItemsSupplementBackButton = true
        navigationItem.leftBarButtonItem = editButtonItem
        navigationItem.leftBarButtonItems?.forEach { $0.tintColor = .white }
    }
    
    //MARK: - Model-Change Observer & Handler
    fileprivate func setupStoreChangeObserver() {
        Store.addObserver(self, selector: .handleChange, notification: .storeChanged)
    }
    
    @objc fileprivate func handleChangeNotification(_ notification: Notification) {
        // Handle changes to current folder.
        if let item = notification.object as? Folder, item === folder {
            let description = notification.userInfo?[Item.logDescription] as? String
            if description == Item.removed, let nc = navigationController {
                navigationController?.setViewControllers(nc.viewControllers.filter { $0 !== self }, animated: false)
            } else {
                folder = item
            }
        }

        // Handle changes to current folder's children (contents).
        guard let userInfo = notification.userInfo, userInfo[Item.parentFolder] as? Folder === folder else { return }

        if let description = userInfo[Item.logDescription] as? String {
            let oldValue = userInfo[Item.oldValue]
            let newValue = userInfo[Item.newValue]

            switch (description, newValue, oldValue) {
            case let (Item.removed, _, (oldIndex as Int)?):
                tableView.deleteRows(at: [IndexPath(row: oldIndex, section: 0)], with: .right)
            case let (Item.added, (newIndex as Int)?, _):
                tableView.insertRows(at: [IndexPath(row: newIndex, section: 0)], with: .left)
            case let (Item.renamed, (newIndex as Int)?, (oldIndex as Int)?):
                tableView.moveRow(at: IndexPath(row: oldIndex, section: 0), to: IndexPath(row: newIndex, section: 0))
                tableView.reloadRows(at: [IndexPath(row: newIndex, section: 0)], with: .fade)
            default:
                tableView.reloadData()
            }
        } else {
            tableView.reloadData()
        }
    }
    
    // MARK: - Table View Delegate Methods

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return folder.contents.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let item = folder.contents[indexPath.row]
        let itemIsRecording = item is Recording
        let identifier = itemIsRecording ? "RecordingCell" : "FolderCell"
        let cell = tableView.dequeueReusableCell(withIdentifier: identifier, for: indexPath)
        cell.textLabel?.text = "\(itemIsRecording ? "🔊" : "📁")  \(item.name)"
        return cell
    }
    
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        folder.remove(folder.contents[indexPath.row])
    }
    
    var selectedItem: Item? {
        if let indexPath = tableView.indexPathForSelectedRow {
            return folder.contents[indexPath.row]
        }
        return nil
    }
    
    //MARK: - IBActions
    @IBAction func createNewRecording(_ sender: UIBarButtonItem) {
        performSegue(withIdentifier: "showRecorder", sender: self)
    }
    
    @IBAction func createNewFolder(_ sender: UIBarButtonItem) {
        modalTextAlert(title: .createFolder, accept: .create, placeholder: .folderName) { name in
            if let folderName = name {
                let newFolder = Folder(name: folderName, uuid: UUID())
                self.folder.add(newFolder)
            }
            self.dismiss(animated: true)
        }
    }
    
    //MARK: - Segues
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let identifier = segue.identifier else { return }
        if identifier == .showFolder {
            guard
                let folderVC = segue.destination as? FolderTVC,
                let selectedFolder = selectedItem as? Folder
            else { fatalError() }
            
            folderVC.folder = selectedFolder
        }
        else if identifier == .showRecorder {
            guard let recorderVC = segue.destination as? RecorderVC else { fatalError() }
            recorderVC.folder = folder
            
        } else if identifier == .showPlayer {
            guard let playVC = (segue.destination as? UINavigationController)?.topViewController as? PlayBackVC,
            let recording = selectedItem as? Recording
            else { fatalError() }
            playVC.recording = recording
            
            if let indexPath = tableView.indexPathForSelectedRow {
                tableView.deselectRow(at: indexPath, animated: true)
            }
        }
    }
    
    // MARK: - UIState Restoring
    
    override func encodeRestorableState(with coder: NSCoder) {
        super.encodeRestorableState(with: coder)
        coder.encode(folder.uuidPath, forKey: .uuidPathKey)
    }

    override func decodeRestorableState(with coder: NSCoder) {
        super.decodeRestorableState(with: coder)
        if let uuidPath = coder.decodeObject(forKey: .uuidPathKey) as? [UUID], let folder = Store.shared.item(atUUIDPath: uuidPath) as? Folder {
            self.folder = folder
        } else {
            if let index = navigationController?.viewControllers.firstIndex(of: self), index != 0 {
                navigationController?.viewControllers.remove(at: index)
            }
        }
    }
}

//MARK: - KeyCodes
fileprivate extension String {
    static let uuidPathKey = "uuidPath"
    static let showRecorder = "showRecorder"
    static let showPlayer = "showPlayer"
    static let showFolder = "showFolder"
    
    static let recordings = NSLocalizedString("Recordings", comment: "Heading for the list of recorded audio items and folders.")
    static let createFolder = NSLocalizedString("Create Folder", comment: "Header for folder creation dialog")
    static let folderName = NSLocalizedString("Folder Name", comment: "Placeholder for text field where folder name should be entered.")
    static let create = NSLocalizedString("Create", comment: "Confirm button for folder creation dialog")
}

fileprivate extension Selector {
    static let handleChange = #selector(FolderTVC.handleChangeNotification(_:))
}
