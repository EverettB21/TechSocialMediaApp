//
//  CommentsTableViewController.swift
//  techSocialMediaApp
//
//  Created by Everett Brothers on 12/1/23.
//

import UIKit

class CommentsTableViewController: UITableViewController {

    typealias DataSourceType = UITableViewDiffableDataSource<ViewModel.Section, ViewModel.Item>
    
    enum ViewModel {
        typealias Section = Int
        typealias Item = Comment
    }
    
    var dataSource: DataSourceType?
    var post: Post!
    
    var user = User.current!
    
    var pageNumber = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()

        title = "Comments"
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addComment))
        setUpTableView()
    }

    @IBSegueAction func toUserFromComments(_ coder: NSCoder, sender: Any?) -> UserViewController? {
        if let comment = sender as? Comment {
            let vc = UserViewController(coder: coder)
            vc?.userUUID = comment.userId
            return vc
        }
        return nil
    }
    
    @objc func addComment() {
        let ac = UIAlertController(title: "Create Comment", message: nil, preferredStyle: .alert)
        ac.addTextField { text in
            text.placeholder = "Leave a comment!"
        }
        
        let create = UIAlertAction(title: "Leave Comment", style: .default) { [weak self, weak ac] _ in
            guard let text = ac?.textFields?[0].text, !text.isEmpty else { return }
            self?.postComment(text: text)
        }
        
        ac.addAction(create)
        ac.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        present(ac, animated: true)
    }
    
    func postComment(text: String) {
        Task {
            do {
                try await CreateCommentRequest(userSecret: self.user.secret, commentBody: text, postid: self.post.postid).send()
                DispatchQueue.main.async {
                    self.getComments(for: self.post)
                }
            } catch {
                print("Error: \(error.localizedDescription)")
            }
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let comment = dataSource?.itemIdentifier(for: indexPath)!
        performSegue(withIdentifier: "toDetailFromComments", sender: comment)
    }
    
    @IBSegueAction func toDetailFromComments(_ coder: NSCoder, sender: Any?) -> DetailViewController? {
        if let comment = sender as? Comment {
            let vc = DetailViewController(coder: coder)
            vc?.comment = comment
            return vc
        }
        return nil
    }
    
}

private extension CommentsTableViewController {
    
    func setUpTableView() {
        tableView.register(UINib(nibName: CommentsTableViewCell.reuseIdentifier, bundle: nil), forCellReuseIdentifier: CommentsTableViewCell.reuseIdentifier)
        setUpDataSource()
        tableView.dataSource = dataSource
        getComments(for: post)
    }
    
    func setUpDataSource() {
        dataSource = DataSourceType(tableView: tableView) { tableView, indexPath, comment -> CommentsTableViewCell in
            let cell = tableView.dequeueReusableCell(withIdentifier: CommentsTableViewCell.reuseIdentifier, for: indexPath) as! CommentsTableViewCell
            cell.update(with: comment) {
                self.performSegue(withIdentifier: "toUserFromComments", sender: comment)
            }
            return cell
        }
    }
    
    func updateSnapshot(with comments: [Comment]) {
        var snapshot = NSDiffableDataSourceSnapshot<ViewModel.Section, ViewModel.Item>()
        snapshot.appendSections([0])
        if comments.isEmpty {
            title = "No Comments"
        } else {
            title = "Comments"
            snapshot.appendItems(comments)
        }
        dataSource?.apply(snapshot, animatingDifferences: true)
    }
    
    func getComments(for post: Post) {
        let queue = DispatchQueue(label: "loadComments")
        queue.async {
            Task {
                do {
                    let comments = try await CommentsRequest(userSecret: self.user.secret, postid: post.postid, pageNumber: self.pageNumber).send()
                    DispatchQueue.main.async {
                        self.updateSnapshot(with: comments)
                    }
                } catch {
                    print("Error: \(error.localizedDescription)")
                }
            }
        }
    }
}
