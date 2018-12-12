//
//  DetailViewController.swift
//  BoxOffice
//
//  Created by Hyeontae on 09/12/2018.
//  Copyright © 2018 onemoon. All rights reserved.
//
// 평점 별 표시
// 누적 관객수 , 표시
// 아래 comments 구현

import UIKit

class DetailViewController: UIViewController {
    
    @IBOutlet weak var detailTable: UITableView!
    @IBOutlet weak var loadingIndicator: UIActivityIndicatorView!
    
    let movieDetailCellIndicator: String = "movieDetailCell"
    let commentCellIdentifier: String = "commentCell"
    var movieId: String = ""
    var movieDetailData: MovieDetail = MovieDetail()
//    var movieDetailData: [MovieDetail] = [MovieDetail()]
    var moviePosterData: Data = Data()
    var movieComments: [MovieComment] = []
    var networkErrorAlert: UIAlertController = UIAlertController()
    var commentNetworkErrorAlert: UIAlertController = UIAlertController()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.didRecieveDetailData(_:)), name: didReceiveMovieDetailData, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.didReceiveCommentsData(_:)), name: didRecieveCommentData, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.didReceiveNetworkError(_:)), name: detailNetworkError, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.didReceiveCommentNetworkError(_:)), name: detailCommentsNetworkError, object: nil)
        loadingIndicator.startAnimating()
        
        networkErrorAlert = UIAlertController(title: "네트워크 에러", message: "네트워크를 확인하신 뒤 다시 시도해주세요", preferredStyle: .alert)
        let okAction = UIAlertAction(title: "확인", style: .default, handler: { _ in
            self.loadingIndicator.stopAnimating()
            self.networkErrorCallback()
        })
        networkErrorAlert.addAction(okAction)
        
        commentNetworkErrorAlert = UIAlertController(title: "네트워크 에러", message: "한줄평을 불러올 수 없습니다.", preferredStyle: .alert)
        let commentOkAction = UIAlertAction(title: "확인", style: .default, handler: nil)
        commentNetworkErrorAlert.addAction(commentOkAction)
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        detailRequest(movieId)
        detailCommentRequest(movieId)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        self.networkErrorAlert.dismiss(animated: true, completion: nil)
    }
    
    @objc func didRecieveDetailData(_ noti: Notification) {
        DispatchQueue.main.async {
            guard let detailData = noti.userInfo?["apiResponse"] as? MovieDetail else { return }
            guard let imageData = noti.userInfo?["imageData"] as? Data else { return }
            
            self.movieDetailData = detailData
            self.moviePosterData = imageData
            self.detailTable.reloadSections(IndexSet(0...0), with: .automatic)
            self.loadingIndicator.stopAnimating()
        }
    }
    
    @objc func didReceiveCommentsData(_ noti: Notification) {
        DispatchQueue.main.async {
            guard let commentsData: [MovieComment] = noti.userInfo?["commentDatas"] as? [MovieComment] else { return }
            self.movieComments = commentsData
            self.detailTable.reloadSections(IndexSet(1...1), with: .automatic)
        }
    }
    
    @objc func didReceiveNetworkError(_ noti: Notification) {
        DispatchQueue.main.async {
            self.present(self.networkErrorAlert, animated: true)
        }
    }
    
    @objc func didReceiveCommentNetworkError(_ noti: Notification) {
        DispatchQueue.main.async {
            self.present(self.commentNetworkErrorAlert, animated: true)
        }
    }
    
    func networkErrorCallback() {
        self.networkErrorAlert.dismiss(animated: true, completion: nil)
        self.navigationController?.popViewController(animated: true)
    }
}

extension DetailViewController: UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0:
            return 1
        case 1:
            return movieComments.count
        default:
            return 0
        }
        
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            // detailInformation
            guard let movieDetailCell: MovieDetailInformationCell = tableView.dequeueReusableCell(withIdentifier: movieDetailCellIndicator, for: indexPath) as? MovieDetailInformationCell else { return UITableViewCell() }            
            let movieDetailData = self.movieDetailData
            
            movieDetailCell.mainPosterImageView.image = UIImage.init(data: self.moviePosterData)
            movieDetailCell.mainTitleLabel.text = movieDetailData.title
//            // 0 12 15 19
            movieDetailCell.mainGradeImage.image = UIImage(named: "ic_\(movieDetailData.grade)")
            movieDetailCell.mainDateLabel.text = movieDetailData.openingString
            movieDetailCell.mainGenreLabel.text = movieDetailData.genreAndRunningTimeString
            movieDetailCell.leftInfoReservationRateLabel.text = movieDetailData.reservationString
            movieDetailCell.midInfoUserRatingLabel.text = String(movieDetailData.user_rating)
            guard let mainStars = movieDetailCell.mainStarsView as? FiveStars else { return UITableViewCell() }
            mainStars.fillStarWithImage(movieDetailData.user_rating)
            movieDetailCell.rightInfoAudienceLabel.text = movieDetailData.audienceString
            movieDetailCell.synopsisLabel.text = movieDetailData.synopsis
            movieDetailCell.directorLabel.text = movieDetailData.director
            movieDetailCell.actorsLabel.text = movieDetailData.actor
            
            movieDetailCell.selectionStyle = .none
            return movieDetailCell
        } else {
            // comments
            tableView.separatorColor = UIColor.white
            guard let commentCell: MovieCommentCell = tableView.dequeueReusableCell(withIdentifier: self.commentCellIdentifier, for: indexPath) as? MovieCommentCell else { return UITableViewCell() }
            let commentData: MovieComment = movieComments[indexPath.row]
            commentCell.writer.text = commentData.writer
            commentCell.timeString.text = commentData.timeString
            commentCell.comment.text = commentData.contents
            commentCell.fillStarWithImageInt(commentData.rating)
            
            commentCell.selectionStyle = .none
            return commentCell
        }
    }
    
//    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
//
//        return "check Date"
//
//    }
    
}

extension DetailViewController: UITableViewDelegate {
//    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
//        tableView.deselectRow(at: indexPath, animated: true)
//    }
}