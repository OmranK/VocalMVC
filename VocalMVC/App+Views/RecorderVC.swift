//
//  RecorderVC.swift
//  VocalMVC
//
//  Created by Omran Khoja on 1/12/20.
//  Copyright © 2020 AcronDesign. All rights reserved.
//

import UIKit
import AVFoundation

class RecorderVC: UIViewController, AVAudioRecorderDelegate {
    
    //MARK: - IBOutlets
    
    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var stopButton: UIButton!
    
    //MARK: - Properties
    
    var audioRecorder: Recorder?
    var folder: Folder? = nil
    var recording = Recording(name: "", uuid: UUID())
    
    //MARK: VC LifeCycle
    override func viewDidLoad() {
        super.viewDidLoad()
        timeLabel.text = timeString(0)

    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        audioRecorder = folder?.store?.fileURL(for: recording).flatMap { url in
            Recorder(url: url) { time in
                if let t = time {
                    self.timeLabel.text = timeString(t)
                } else {
                    self.dismiss(animated: true)
                }
            }
        }
        
        if audioRecorder == nil {
            dismiss(animated: true)
        }
    }
    
    //MARK: - IBAction
    
    @IBAction func stopPressed(_ sender: UIButton) {
        audioRecorder?.stop()
        modalTextAlert(title: .saveRecording, accept: .save, placeholder: .nameForRecording) { (string) in
            if let title = string {
                self.recording.setName(title)
                self.folder?.add(self.recording)
            } else {
                self.recording.deleted()
            }
            self.dismiss(animated: true, completion: nil)
        }
    }
    
}

//MARK: - KeyCodes
fileprivate extension String {
    static let saveRecording = NSLocalizedString("Save recording", comment: "Heading for audio recording save dialog")
    static let save = NSLocalizedString("Save", comment: "Confirm button text for audio recoding save dialog")
    static let nameForRecording = NSLocalizedString("Name for recording", comment: "Placeholder for audio recording name text field")
}
