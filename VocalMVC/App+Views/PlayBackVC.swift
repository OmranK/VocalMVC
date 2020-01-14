//
//  PlayBackVC.swift
//  VocalMVC
//
//  Created by Omran Khoja on 1/12/20.
//  Copyright © 2020 AcronDesign. All rights reserved.
//

import UIKit
import AVFoundation

class PlayBackVC: UIViewController, UITextFieldDelegate, AVAudioPlayerDelegate {

    //MARK: - IBOutlets
    
    @IBOutlet weak var nameTextField: UITextField!
    @IBOutlet weak var noRecordLabel: UILabel!
    @IBOutlet weak var activeItems: UIView!
    @IBOutlet weak var progressSlider: UISlider!
    @IBOutlet weak var durationLabel: UILabel!
    @IBOutlet weak var progressLabel: UILabel!
    @IBOutlet weak var playButton: UIButton!
    
    //MARK: - Properties
    var audioPlayer: Player?
    var recording: Recording? {
        didSet {
            updateForChangedRecording()
        }
    }
    
    //MARK: - VC LifeCycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupNavBar()
        setupStoreModelChangeObserver()
        updateForChangedRecording()

        // Do any additional setup after loading the view.
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        recording = nil
    }
    
    //MARK: - Layout Navbar Items
    fileprivate func setupNavBar() {
        navigationItem.leftBarButtonItem = splitViewController?.displayModeButtonItem
        navigationItem.leftItemsSupplementBackButton = true
        navigationItem.leftBarButtonItems?.forEach { $0.tintColor = .white }
    }
    
    
    //MARK: - Model-Change Observer & Handler Methods
    fileprivate func setupStoreModelChangeObserver() {
        Store.addObserver(self, selector: .handleChange, notification: .storeChanged)
    }
    
    @objc func storeChanged(notification: Notification) {
        guard let item = notification.object as? Item, item === recording else { return }
        updateForChangedRecording()
    }
    

    func updateForChangedRecording() {
        if let recording = recording, let url = recording.fileURL {
            audioPlayer = Player(url: url) { [weak self] time in
                if let time = time {
                    self?.updateProgressDisplays(progress: time, duration: self?.audioPlayer?.duration ?? 0)
                } else {
                    self?.recording = nil
                }
            }
            
            if let ap = audioPlayer {
                updateProgressDisplays(progress: 0, duration: ap.duration)
                title = recording.name
                nameTextField?.text = recording.name
                activeItems?.isHidden = false
                noRecordLabel?.isHidden = true
            } else {
                self.recording = nil
            }
        } else {
            updateProgressDisplays(progress: 0, duration: 0)
            audioPlayer = nil
            title = ""
            activeItems?.isHidden = true
            noRecordLabel?.isHidden = false
        }
    }
    
    func updateProgressDisplays(progress: TimeInterval, duration: TimeInterval) {
        progressLabel?.text = timeString(progress)
        durationLabel?.text = timeString(duration)
        progressSlider?.maximumValue = Float(duration)
        progressSlider?.value = Float(progress)
        updatePlayButton()
    }
    
    func updatePlayButton() {
        if audioPlayer?.isPlaying == true {
            playButton.setTitle(.pause, for: .normal)
        } else if audioPlayer?.isPaused == true {
            playButton?.setTitle(.resume, for: .normal)
        } else {
            playButton?.setTitle(.play, for: .normal)
        }
    }
    
    //MARK: - TextField Delegate Methods
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        if let r = recording, let text = textField.text {
            r.setName(text)
            title = r.name
        }
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    //MARK: - IBAction
    @IBAction func play() {
        audioPlayer?.togglePlay()
        updatePlayButton()
    }
    
    @IBAction func setProgress() {
        guard let s = progressSlider else { return }
        audioPlayer?.setProgress(TimeInterval(s.value))
    }
    
    // MARK: - UIState Restoring
    
    override func encodeRestorableState(with coder: NSCoder) {
        super.encodeRestorableState(with: coder)
        coder.encode(recording?.uuidPath, forKey: .uuidPathKey)
    }
    
    override func decodeRestorableState(with coder: NSCoder) {
        super.decodeRestorableState(with: coder)
        if let uuidPath = coder.decodeObject(forKey: .uuidPathKey) as? [UUID], let recording = Store.shared.item(atUUIDPath: uuidPath) as? Recording {
            self.recording = recording
        }
    }
}


//MARK: - KeyCodes

fileprivate extension String {
    static let uuidPathKey = "uuidPath"
    
    static let pause = NSLocalizedString("Pause", comment: "")
    static let resume = NSLocalizedString("Resume playing", comment: "")
    static let play = NSLocalizedString("Play", comment: "")
}

fileprivate extension Selector {
    static let handleChange = #selector(PlayBackVC.storeChanged(notification:))
}
