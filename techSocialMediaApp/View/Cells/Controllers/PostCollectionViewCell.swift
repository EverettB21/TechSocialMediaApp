//
//  PostCollectionViewCell.swift
//  techSocialMediaApp
//
//  Created by Everett Brothers on 12/1/23.
//

import UIKit

class PostCollectionViewCell: UICollectionViewCell {
    static var reuseIdentifier = "PostCollectionViewCell"
    @IBOutlet weak var bodyLabel: UILabel!
    @IBOutlet weak var userButton: UIButton!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var likeButton: UIButton!
    @IBOutlet weak var commentButton: UIButton!
    
    private let likedHeart = "heart.fill"
    private let unLikedHeart = "heart"
    var liked: Bool!
    var post: Post!
    
    var commentsAction: (() -> Void)?
    var likedAction: (() -> Void)?
    var userAction: ((Post) -> Void)?
    
    func setComment(_ commentClicked: (() -> Void)?) {
        self.commentsAction = commentClicked
    }
    
    func setUserClicked(_ userClicked: ((Post) -> Void)?) {
        self.userAction = userClicked
    }
    
    func update(with post: Post, onLike: (() -> Void)?) {
        self.post = post
        self.likedAction = onLike
        bodyLabel.text = post.body
        userButton.setTitle(post.authorUserName, for: .normal)
        dateLabel.text = post.createdDate
        liked = post.userLiked
        let image = UIImage(systemName: liked ? likedHeart : unLikedHeart)
        likeButton.setImage(image, for: .normal)
        commentButton.setTitle("\(post.numComments)", for: .normal)
        likeButton.setTitle("\(post.likes)", for: .normal)
    }
    
    @IBAction func commentsClicked(_ sender: Any) {
        commentsAction?()
    }
    
    @IBAction func userClicked(_ sender: Any) {
        userAction?(post)
    }
    
    @IBAction func likedClicked(_ sender: Any) {
        liked.toggle()
        post.likes = liked ? post.likes + 1 : post.likes - 1
        let image = UIImage(systemName: liked ? likedHeart : unLikedHeart)
        likeButton.setImage(image, for: .normal)
        likeButton.setTitle("\(post.likes)", for: .normal)
        likedAction?()
    }
}
