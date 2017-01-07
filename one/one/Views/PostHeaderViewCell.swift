//
//  PostHeaderViewCell.swift
//  one
//
//  Created by Kai Chen on 1/3/17.
//  Copyright © 2017 Kai Chen. All rights reserved.
//

import UIKit
import Parse

protocol PostHeaderViewCellDelegate {
    func navigateToUserPage(_ username: String?)
}

class PostHeaderViewCell: UITableViewCell {

    @IBOutlet var profileImageView: UIImageView!

    @IBOutlet var profileUsernameButton: UIButton!

    @IBOutlet var postTimeLabel: UILabel!

    @IBOutlet var postImageView: UIImageView!

    @IBOutlet var likeButton: UIButton!

    @IBOutlet var commentButton: UIButton!

    @IBOutlet var moreButton: UIButton!

    @IBOutlet var titleLabel: UILabel!

    @IBOutlet var heartImageView: UIImageView!

    var delegate: PostHeaderViewCellDelegate?

    var isLiked: Bool?
    var uuid: String?

    override func awakeFromNib() {
        super.awakeFromNib()

        let doubleTapLikeGesture = UITapGestureRecognizer(target: self, action: #selector(doubleTapLike))
        doubleTapLikeGesture.numberOfTapsRequired = 2
        postImageView.addGestureRecognizer(doubleTapLikeGesture)
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

    func configLike() {
        isLiked = false

        likeButton.setImage(UIImage(imageLiteralResourceName: "unlike"), for: .normal)

        let query = PFQuery(className: Like.modelName.rawValue)
        query.whereKey(Like.postID.rawValue, equalTo: uuid)
        let username = PFUser.current()?.username!
        query.whereKey(Like.username.rawValue, equalTo: username)
        query.findObjectsInBackground(block: { [weak self](objects: [PFObject]?, error: Error?) in
            guard error == nil else {
                return
            }

            guard let strongSelf = self else {
                return
            }

            guard let _ = objects?.first else {
                return
            }

            strongSelf.isLiked = true
            strongSelf.likeButton.setImage(UIImage(imageLiteralResourceName: "like"), for: .normal)
        })
    }

    func config(_ uuid: String) {
        self.uuid = uuid

        configLike()

        let postQuery = PFQuery(className: Post.modelName.rawValue)
        postQuery.whereKey(Post.uuid.rawValue, equalTo: uuid)
        postQuery.findObjectsInBackground { [weak self](objects: [PFObject]?, error: Error?) in
            guard error == nil else {
                print("error:\(error?.localizedDescription)")
                return
            }

            guard let object = objects?.first, let strongSelf = self else {
                return
            }

            let profileImageFile = object[Post.profileImage.rawValue] as? PFFile
            profileImageFile?.getDataInBackground(block: { (data: Data?, error: Error?) in
                guard error == nil else {
                    return
                }

                if let data = data {
                    strongSelf.profileImageView.image = UIImage(data: data)
                }
            })

            let username = object[Post.username.rawValue] as? String
            strongSelf.profileUsernameButton.setTitle(username, for: .normal)

            let createTime = object.createdAt
            strongSelf.postTimeLabel.text = strongSelf.timeDescription(createTime!)

            let postImageFile = object[Post.picture.rawValue] as? PFFile
            postImageFile?.getDataInBackground(block: { (data: Data?, error: Error?) in
                guard error == nil else {
                    return
                }

                if let data = data {
                    strongSelf.postImageView.image = UIImage(data: data)
                }
            })

            let title = object[Post.title.rawValue] as? String
            strongSelf.titleLabel.text = title
        }
    }

    func timeDescription(_ postTime: Date) -> String {
        let components = Set<Calendar.Component>([.second, .minute, .hour, .day, .weekOfMonth])
        let diff = NSCalendar.current.dateComponents(components, from: postTime)

        if diff.second! <= 0 {
            return "now"
        }

        if diff.minute == 0 {
            return "\(diff.second)s"
        }

        if diff.hour == 0 {
            return "\(diff.minute)m"
        }

        if diff.day == 0 {
            return "\(diff.hour)h"
        }

        if diff.weekOfMonth == 0 {
            return "\(diff.day)d"
        }

        return "\(diff.weekOfMonth)w"
    }

    // MARK: Actions

    func handleLikeAction() {
        guard let isLiked = isLiked, let uuid = uuid else {
            return
        }

        if isLiked {
            self.isLiked = false
            likeButton.setImage(UIImage(imageLiteralResourceName: "unlike"), for: .normal)

            // Unlike this post
            let query = PFQuery(className: Like.modelName.rawValue)
            query.whereKey(Like.postID.rawValue, equalTo: uuid)
            let username = PFUser.current()?.username!
            query.whereKey(Like.username.rawValue, equalTo: username)

            query.findObjectsInBackground(block: { (objects: [PFObject]?, error: Error?) in
                guard error == nil else {
                    return
                }

                guard let object = objects?.first else {
                    return
                }

                object.deleteInBackground(block: { (success: Bool, error: Error?) in
                    if (error != nil) {
                        print("error:\(error?.localizedDescription)")
                    }
                })
            })
        } else {
            // Like this post
            let object = PFObject(className: Like.modelName.rawValue)

            object[Like.postID.rawValue] = uuid
            object[Like.username.rawValue] = PFUser.current()?.username!

            self.isLiked = true
            likeButton.setImage(UIImage(imageLiteralResourceName: "like"), for: .normal)

            object.saveInBackground(block: { (success: Bool, error: Error?) in
                if (!success) {
                    print("error:\(error?.localizedDescription)")
                }
            })
        }

    }

    func doubleTapLike() {
        UIView.animate(withDuration: 0.3
            , animations: { [weak self] () in
                guard let strongSelf = self else {
                    return
                }
                strongSelf.heartImageView.isHidden = false
                strongSelf.heartImageView.transform = CGAffineTransform(scaleX: 0.1, y: 0.1)
        }, completion: { [weak self](success: Bool) in
            guard let strongSelf = self else {
                return
            }
            strongSelf.heartImageView.isHidden = true
            strongSelf.heartImageView.transform = CGAffineTransform(scaleX: 1.0, y: 1.0)
        })

        handleLikeAction()
    }

    @IBAction func likeButtonTapped(_ sender: UIButton) {
        handleLikeAction()
    }

    @IBAction func usernameButtonTapped(_ sender: UIButton) {
        let username = sender.title(for: .normal)
        delegate?.navigateToUserPage(username)
    }
}