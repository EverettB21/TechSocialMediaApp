//
//  DetailViewController.swift
//  techSocialMediaApp
//
//  Created by Everett Brothers on 12/5/23.
//

import UIKit

class DetailViewController: UIViewController {

    @IBOutlet weak var bodyLabel: UILabel!
    @IBOutlet weak var userDateLabel: UILabel!
    
    var post: Post?
    var comment: Comment?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let post = post {
            navigationItem.title = post.title
            bodyLabel.text = post.body
            userDateLabel.text = "\(post.authorUserName): \(post.createdDate)"
            return
        }
        
        if let comment = comment {
            navigationItem.title = comment.userName
            bodyLabel.text = comment.body
            userDateLabel.text = comment.createdDate
            return
        }
    }
    
}
