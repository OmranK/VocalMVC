//
//  CustomSplitVC.swift
//  VocalMVC
//
//  Created by Omran Khoja on 1/12/20.
//  Copyright © 2020 AcronDesign. All rights reserved.
//

import UIKit

class CustomSplitVC: UISplitViewController, UISplitViewControllerDelegate {

    override func viewDidLoad() {
        super.viewDidLoad()
        delegate = self
        preferredDisplayMode = .allVisible
    }
    
    func splitViewController(_ splitViewController: UISplitViewController, collapseSecondary secondaryViewController: UIViewController, onto primaryViewController: UIViewController) -> Bool {
        guard let topAsDetailController = (secondaryViewController as? UINavigationController)?.topViewController as? PlayBackVC else { return false }
        if topAsDetailController.recording == nil {
            // Don't include an empty player in the navigation stack when collapsed
            return true
        }
        return false
    }
}
