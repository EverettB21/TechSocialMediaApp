//
//  CommentsTableViewCell.swift
//  techSocialMediaApp
//
//  Created by Everett Brothers on 12/1/23.
//

import UIKit

class CommentsTableViewCell: UITableViewCell {
    static let reuseIdentifier = "CommentsTableViewCell"

    @IBOutlet weak var bodyLabel: UILabel!
    @IBOutlet weak var userButton: UIButton!
    @IBOutlet weak var dateLabel: UILabel!
    
    var comment: Comment!
    
    var onUserClick: (() -> Void)?
    
    func update(with comment: Comment, onClick: (() -> Void)?) {
        self.comment = comment
        self.onUserClick = onClick
        self.bodyLabel.text = comment.body
        self.userButton.setTitle(comment.userName, for: .normal)
        self.dateLabel.text = comment.createdDate
    }
    
    @IBAction func userClicked(_ sender: Any) {
        onUserClick?()
    }
    
}
