//
//  SignedInViewController.swift
//  techSocialMediaApp
//
//  Created by Everett Brothers on 12/4/23.
//

import UIKit

class SignedInViewController: UIViewController {
    
    typealias DataSourceType = UICollectionViewDiffableDataSource<ViewModel.Section, ViewModel.Item>
    
    enum ViewModel {
        typealias Section = Int
        typealias Item = Post
    }
    
    var dataSource: DataSourceType!
    
    let user = User.current!
    var pageNumber: Int = 0

    @IBOutlet weak var collectionView: UICollectionView!
    
    @IBOutlet weak var techBioView: UIView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var bioLabel: UILabel!
    @IBOutlet weak var techInterestsLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .edit, target: self, action: #selector(editProfile))
        
        setUpCollectionView()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        getUserProfile()
    }
    
    @objc func editProfile() {
        let ac = UIAlertController(title: "Edit Profile", message: nil, preferredStyle: .alert)
        ac.addTextField { text in
            text.placeholder = self.user.userName
        }
        ac.addTextField { text in
            text.placeholder = "New Bio"
        }
        ac.addTextField { text in
            text.placeholder = "Your Tech Interests"
        }
        
        let submitAction = UIAlertAction(title: "Update", style: .default) { [weak self, weak ac] _ in
            guard let textFields = ac?.textFields else { return }
            var usernameText = textFields[0].text!
            var bioText = textFields[1].text!
            var techText = textFields[2].text!
            if usernameText.isEmpty {
                let currentUsername = self?.user.userName
                if let current = currentUsername {
                    usernameText = current
                }
            }
            if bioText.isEmpty {
                bioText = self!.bioLabel.text!
            }
            if techText.isEmpty {
                techText = self!.techInterestsLabel.text!
            }
            let profile = Profile(userName: usernameText, bio: bioText, techInterests: techText)
            self?.updateProfile(profile)
        }
        
        ac.addAction(submitAction)
        ac.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        present(ac, animated: true)
    }
    
    @IBSegueAction func toCommentsFromSign(_ coder: NSCoder, sender: Any?) -> CommentsTableViewController? {
        if let post = sender as? Post {
            let vc = CommentsTableViewController(coder: coder)
            vc?.post = post
            return vc
        }
        return nil
    }
    
}

private extension SignedInViewController {
    func setUpCollectionView() {
        setUpDataSource()
        collectionView.delegate = self
        collectionView.dataSource = dataSource
        collectionView.collectionViewLayout = createLayout()
        collectionView.register(UINib(nibName: PostCollectionViewCell.reuseIdentifier, bundle: nil), forCellWithReuseIdentifier: PostCollectionViewCell.reuseIdentifier)
        getPosts(pageNumber: pageNumber)
    }
    
    func setUpDataSource() {
        dataSource = DataSourceType(collectionView: collectionView) { collectionView, indexPath, post in
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: PostCollectionViewCell.reuseIdentifier, for: indexPath) as! PostCollectionViewCell
            cell.update(with: post) {
                self.updateLiked(post: post)
            }
            cell.setUserClicked { post in
                
            }
            cell.setComment {
                self.performSegue(withIdentifier: "toCommentsFromSign", sender: post)
            }
            cell.layer.borderColor = CGColor(red: 0, green: 0, blue: 0, alpha: 1)
            cell.layer.borderWidth = 2
            cell.layer.cornerRadius = 10
            return cell
        }
    }
    
    func createLayout() -> UICollectionViewCompositionalLayout {
        let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .fractionalHeight(1))
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        
        let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .absolute(100))
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])
        
        let section = NSCollectionLayoutSection(group: group)
        section.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 10, bottom: 0, trailing: 10)
        section.interGroupSpacing = 10
        
        return UICollectionViewCompositionalLayout(section: section)
    }
    
    func updateSnapshot(with posts: [Post]) {
        var snapshot = NSDiffableDataSourceSnapshot<ViewModel.Section, ViewModel.Item>()
        snapshot.appendSections([0])
        snapshot.appendItems(posts)
        dataSource?.apply(snapshot, animatingDifferences: true)
    }
    
    func getPosts(pageNumber: Int) {
        Task {
            do {
                let posts = try await UserPostsRequest(userSecret: self.user.secret, userUUID: self.user.userUUID, pageNumber: pageNumber).send()
                DispatchQueue.main.async {
                    self.updateSnapshot(with: posts)
                }
            } catch {
                print("Error: \(error.localizedDescription)")
            }
        }
    }
    
    func updateLiked(post: Post) {
        let queue = DispatchQueue(label: "userLiked")
        queue.async {
            Task {
                do {
                    try await UpdatePostLikesRequest(userSecret: self.user.secret, postid: post.postid).send()
                } catch {
                    print("Error: \(error.localizedDescription)")
                }
            }
        }
    }
    
    func loadProfile(_ profile: UserProfile) {
        navigationItem.title = profile.userName
        nameLabel.text = "\(profile.firstName)\n \(profile.lastName)"
        bioLabel.text = profile.bio ?? "No Bio"
        techInterestsLabel.text = profile.techInterests ?? "No Tech Interests"
    }
    
    func getUserProfile() {
        Task {
            do {
                let profile = try await UserProfileRequest(userUUID: self.user.userUUID, userSecret: self.user.secret).send()
                DispatchQueue.main.async {
                    self.loadProfile(profile)
                }
            } catch {
                print("Error: \(error.localizedDescription)")
            }
        }
    }
    
    func updateProfile(_ profile: Profile) {
        Task {
            do {
                try await UpdateProfileRequest(userSecret: self.user.secret, profile: profile).send()
                getUserProfile()
            } catch {
                print("Error: \(error.localizedDescription)")
            }
        }
    }
    
    func updatePost(_ post: Post) {
        let ac = UIAlertController(title: "Edit Post", message: nil, preferredStyle: .alert)
        ac.addTextField { text in
            text.placeholder = post.title
        }
        ac.addTextField { text in
            text.placeholder = post.body
        }
        
        let update = UIAlertAction(title: "Update", style: .default) { [weak self, weak ac] _ in
            guard let textFields = ac?.textFields, var title = textFields[0].text, var body = textFields[1].text else {
                return
            }
            if title.isEmpty {
                title = post.title
            }
            if body.isEmpty {
                body = post.body
            }
            self?.sendUpdatedPost(postid: post.postid, title: title, body: body)
        }
        
        ac.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        ac.addAction(update)
        
        present(ac, animated: true)
    }
    
    func sendUpdatedPost(postid: Int, title: String, body: String) {
        Task {
            do {
                let editPost = EditPost(postid: postid, title: title, body: body)
                try await EditPostRequest(userSecret: self.user.secret, post: editPost).send()
                DispatchQueue.main.async {
                    self.getPosts(pageNumber: self.pageNumber)
                }
            } catch {
                print("Error: \(error.localizedDescription)")
            }
        }
    }
    
    func deletePost(_ post: Post) {
        Task {
            do {
                try await DeletePostRequest(userSecret: self.user.secret, postid: post.postid).send()
                DispatchQueue.main.async {
                    self.getPosts(pageNumber: self.pageNumber)
                }
            } catch {
                print("Error: \(error.localizedDescription)")
            }
        }
    }
}

extension SignedInViewController: UICollectionViewDelegate {
    
    func collectionView(_ collectionView: UICollectionView, contextMenuConfigurationForItemsAt indexPaths: [IndexPath], point: CGPoint) -> UIContextMenuConfiguration? {
        guard let indexPath = indexPaths.first else { return nil }
        let config = UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { _ in
            let post = self.dataSource.itemIdentifier(for: indexPath)!
            
            let edit = UIAction(title: "Edit") { (action) in
                self.updatePost(post)
            }
            
            let delete = UIAction(title: "Delete") { (action) in
                self.deletePost(post)
            }
            
            return UIMenu(title: "", image: nil, identifier: nil, options: [], children: [edit, delete])
        }
        
        return config
    }
    
}
