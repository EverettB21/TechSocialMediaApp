//
//  UserViewController.swift
//  techSocialMediaApp
//
//  Created by Everett Brothers on 12/4/23.
//

import UIKit

class UserViewController: UIViewController {

    typealias DataSourceType = UICollectionViewDiffableDataSource<ViewModel.Section, ViewModel.Item>
    
    enum ViewModel {
        typealias Section = Int
        typealias Item = Post
    }
    
    var dataSource: DataSourceType!
    
    var userUUID: UUID!
    let user = User.current!
    var pageNumber: Int = 0

    @IBOutlet weak var collectionView: UICollectionView!
    
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var bioLabel: UILabel!
    @IBOutlet weak var techInterestsLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setUpCollectionView()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        getUserProfile()
    }
    
    @IBSegueAction func toCommentsFromUser(_ coder: NSCoder, sender: Any?) -> CommentsTableViewController? {
        if let post = sender as? Post {
            let vc = CommentsTableViewController(coder: coder)
            vc?.post = post
            return vc
        }
        return nil
    }
    
}

private extension UserViewController {
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
                self.performSegue(withIdentifier: "toCommentsFromUser", sender: post)
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
                let posts = try await UserPostsRequest(userSecret: self.user.secret, userUUID: self.userUUID, pageNumber: pageNumber).send()
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
                let profile = try await UserProfileRequest(userUUID: self.userUUID, userSecret: self.user.secret).send()
                DispatchQueue.main.async {
                    self.loadProfile(profile)
                }
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

extension UserViewController: UICollectionViewDelegate {
    
    func collectionView(_ collectionView: UICollectionView, contextMenuConfigurationForItemsAt indexPaths: [IndexPath], point: CGPoint) -> UIContextMenuConfiguration? {
        guard let indexPath = indexPaths.first else { return nil }
        let post = self.dataSource.itemIdentifier(for: indexPath)!
        guard userUUID == user.userUUID else { return nil }
        let config = UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { _ in
            
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
