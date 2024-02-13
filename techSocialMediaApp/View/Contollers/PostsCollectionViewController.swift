//
//  PostsCollectionViewController.swift
//  techSocialMediaApp
//
//  Created by Everett Brothers on 12/1/23.
//

import UIKit

private let reuseIdentifier = "Cell"

class PostsCollectionViewController: UICollectionViewController {
    
    typealias DataSourceType = UICollectionViewDiffableDataSource<ViewModel.Section, ViewModel.Item>
    
    enum ViewModel {
        typealias Section = Int
        typealias Item = Post
    }
    
    var dataSource: DataSourceType!
    
    let user = User.current!
    var pageNumber: Int = 0
    
    var postsRequestTask: Task<Void, Never>? = nil
    
    var userLikedRequestTask: Task<Void, Never>? = nil
    deinit {
        postsRequestTask?.cancel()
        userLikedRequestTask?.cancel()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.title = "Posts"
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(createPost))
        
        setUpCollectionView()
    }
    
    @objc func createPost() {
        createsPost()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        getPosts(pageNumber: pageNumber)
    }
    
    @IBSegueAction func toComments(_ coder: NSCoder, sender: Any?) -> CommentsTableViewController? {
        if let post = sender as? Post {
            let vc = CommentsTableViewController(coder: coder)
            vc?.post = post
            return vc
        }
        return nil
    }
    
    @IBAction func minusPageNumber(_ sender: Any) {
        pageNumber -= 1
        if pageNumber == -1 {
            pageNumber = 0
            return
        }
        getPosts(pageNumber: pageNumber)
    }
    
    @IBAction func addPageNumber(_ sender: Any) {
        pageNumber += 1
        getPosts(pageNumber: pageNumber)
    }
    
    @IBSegueAction func toUserFromPosts(_ coder: NSCoder, sender: Any?) -> UserViewController? {
        if let post = sender as? Post {
            let vc = UserViewController(coder: coder)
            vc?.userUUID = post.authorUserId
            return vc
        }
        return nil
    }
    
    override func collectionView(_ collectionView: UICollectionView, contextMenuConfigurationForItemsAt indexPaths: [IndexPath], point: CGPoint) -> UIContextMenuConfiguration? {
        guard let indexPath = indexPaths.first else { return nil }
        let post = self.dataSource.itemIdentifier(for: indexPath)!
        guard post.authorUserId == user.userUUID else { return nil }
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
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let post = dataSource.itemIdentifier(for: indexPath)!
        performSegue(withIdentifier: "toDetailFromPosts", sender: post)
    }
    
    @IBSegueAction func toDetailFromPosts(_ coder: NSCoder, sender: Any?) -> DetailViewController? {
        if let post = sender as? Post {
            let vc = DetailViewController(coder: coder)
            vc?.post = post
            return vc
        }
        return nil
    }
    
}

private extension PostsCollectionViewController {
    
    func setUpCollectionView() {
        setUpDataSource()
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
                self.performSegue(withIdentifier: "toUserFromPosts", sender: post)
            }
            cell.setComment {
                self.performSegue(withIdentifier: "toCommentsFromPosts", sender: post)
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
    
    func updateLiked(post: Post) {
        userLikedRequestTask?.cancel()
        let queue = DispatchQueue(label: "userLiked")
        queue.async {
            self.userLikedRequestTask = Task {
                do {
                    try await UpdatePostLikesRequest(userSecret: self.user.secret, postid: post.postid).send()
                } catch {
                    print("Error: \(error.localizedDescription)")
                }
                self.userLikedRequestTask = nil
            }
        }
    }
    
    func createsPost() {
        let ac = UIAlertController(title: "Create Post", message: nil, preferredStyle: .alert)
        ac.addTextField { text in
            text.placeholder = "Title"
        }
        ac.addTextField { text in
            text.placeholder = "Write Your Thoughts!"
        }
        
        let create = UIAlertAction(title: "Create", style: .default) { [weak self, weak ac] _ in
            guard let textFields = ac?.textFields, let title = textFields[0].text, let body = textFields[1].text else {
                return
            }
            self?.sendPost(title: title, body: body)
        }
        
        ac.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        ac.addAction(create)
        
        present(ac, animated: true)
    }
    
    func sendPost(title: String, body: String) {
        let queue = DispatchQueue(label: "sendPost")
        let createPost = CreatePost(title: title, body: body)
        queue.async {
            Task {
                do {
                    try await CreatePostRequest(userSecret: self.user.secret, post: createPost).send()
                    self.getPosts(pageNumber: self.pageNumber)
                } catch {
                    print("Error: \(error.localizedDescription)")
                }
            }
        }
    }
    
    func getPosts(pageNumber: Int) {
        postsRequestTask?.cancel()
        postsRequestTask = Task {
            do {
                let posts = try await PostsRequest(userSecret: self.user.secret, pageNumber: pageNumber).send()
                DispatchQueue.main.async {
                    self.updateSnapshot(with: posts)
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
