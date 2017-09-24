//
//  MusicLibrarySelectionViewController.swift
//  WeJ
//
//  Created by Mohammad Ali Siddiqui on 8/9/17.
//  Copyright © 2017 Mohammad Ali Siddiqui. All rights reserved.
//

import UIKit
import BadgeSwift
import NVActivityIndicatorView

class MusicLibrarySelectionViewController: UIViewController, ViewControllerAccessDelegate {
    
    private weak var delegate: AddTracksTabBarController!

    @IBOutlet weak var headerHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var badge: BadgeSwift!
    
    @IBOutlet weak var spotifyActivityIndicator: NVActivityIndicatorView!
    private var libraryMusicService: MusicService!
    private var authorizationManager: AuthorizationManager!
    var processingLogin = false {
        didSet {
            DispatchQueue.main.async {
                if self.processingLogin && self.libraryMusicService == .spotify {
                    self.spotifyActivityIndicator.startAnimating()
                } else if self.libraryMusicService == .spotify{
                    self.spotifyActivityIndicator.stopAnimating()
                }
            }
        }
    }
    
    @IBOutlet weak var playlistsButton: UIButton!
    @IBOutlet weak var tracksTableView: UITableView!
    @IBOutlet weak var playlistsActivityIndicator: NVActivityIndicatorView!
    private let fetcher: Fetcher = Party.musicService == .spotify ? SpotifyFetcher() : AppleMusicFetcher()
    var tracksList = [Track]() {
        didSet {
            DispatchQueue.main.async {
                self.tracksTableView.reloadData()
                self.playlistsActivityIndicator.stopAnimating()
                self.fetchArtworkForRestOfTracks()
            }
        }
    }
    
    func setBadge(to count: Int) {
        badge.isHidden = count == 0
        badge.text = String(count)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        hideNavigationBar()
        initializeVariables()
        setDelegates()
        adjustViews()
        
        getTrending()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        initializeBadge()
    }
    
    private func initializeBadge() {
        let controller = tabBarController! as! AddTracksTabBarController
        setBadge(to: controller.tracksSelected.count + controller.libraryTracksSelected.count)
    }
    
    private func hideNavigationBar() {
        navigationController?.navigationBar.isHidden = true
    }
    
    private func initializeVariables() {
        NotificationCenter.default.addObserver(self, selector: #selector(createSession(withNotification:)), name: SpotifyConstants.spotifyPlayerDidLoginNotification, object: nil)
        SpotifyAuthorizationManager.storyboardSegue = "Show Spotify Library"
        AppleMusicAuthorizationManager.storyboardSegue = "Show Apple Music Library"
    }
    
    private func setDelegates() {
        delegate = navigationController?.tabBarController! as! AddTracksTabBarController
        
        SpotifyAuthorizationManager.delegate = self
        AppleMusicAuthorizationManager.delegate = self
        tracksTableView.delegate = delegate
        tracksTableView.dataSource = delegate
    }
    
    private func adjustViews() {
        tracksTableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 50, right: 0)
    }
    
    private func getTrending() {
        playlistsActivityIndicator.startAnimating()
        
        fetcher.getMostPlayed { [weak self] in
            self?.tracksList = self?.fetcher.tracksList ?? []
        }
    }
    
    private func fetchArtworkForRestOfTracks() {
        let tracksCaptured = tracksList
        for track in tracksList where tracksList == tracksCaptured && track.lowResArtwork == nil {
            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                Track.fetchImage(fromURL: track.lowResArtworkURL) { (image) in
                    track.lowResArtwork = image
                    self?.tracksTableView.reloadData()
                }
            }
        }
    }
    
    // MARK: - Callback
    
    @objc private func createSession(withNotification notification: NSNotification) {
        SpotifyAuthorizationManager.createSession(withNotification: notification)
    }

    // MARK: - Navigation 
    
    @IBAction func showSpotifyLibrary() {
        guard !processingLogin else { return }
        authorizationManager = SpotifyAuthorizationManager()
        libraryMusicService = .spotify
        authorizationManager.requestAuthorization()
    }
    
    @IBAction func showAppleMusicLibrary() {
        guard !processingLogin else { return }
        authorizationManager = AppleMusicAuthorizationManager()
        libraryMusicService = .appleMusic
        authorizationManager.requestAuthorization()
    }
    
    func tryAgain() {
        if libraryMusicService == .spotify {
            showSpotifyLibrary()
        } else {
            showAppleMusicLibrary()
        }
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let controller = segue.destination as? PlaylistSelectionViewController {
            controller.musicService = libraryMusicService
        }
    }
    
}