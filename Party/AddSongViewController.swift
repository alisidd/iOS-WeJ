//
//  AddSongViewController.swift
//  Party
//
//  Created by Ali Siddiqui on 1/19/17.
//  Copyright © 2017 Ali Siddiqui and Matthew Paletta. All rights reserved.
//

import UIKit

protocol ModifyTracksQueueDelegate: class {
    func addToQueue(track: Track)
    func removeFromQueue(track: Track)
}

class AddSongViewController: UIViewController, UITextFieldDelegate, UITableViewDataSource, UITableViewDelegate, ModifyTracksQueueDelegate {
    
    // MARK: - Storyboard Variables

    @IBOutlet weak var searchTracksField: UITextField!
    @IBOutlet weak var trackTableView: UITableView!
    
    // MARK: - General Variables
    
    var party = Party()
    private var tracksList = [Track]() {
        didSet {
            DispatchQueue.main.async {
                self.trackTableView.reloadData()
                self.indicator.stopAnimating()
                self.indicator.hidesWhenStopped = true
            }
        }
    }
    var tracksQueue = [Track]()
    private let APIManager = RestApiManager()
    private var indicator = UIActivityIndicatorView()
    private let noTracksFoundLabel = UILabel(frame: CGRect(x: 0, y: 0, width: 350, height: 30))
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setDelegates()
        initializeActivityIndicator()
        adjustViews()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        DispatchQueue.main.async {
            self.navigationController?.setNavigationBarHidden(true, animated: animated)
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        DispatchQueue.main.async {
            self.navigationController?.setNavigationBarHidden(false, animated: animated)
        }
    }
    
    // MARK: - Functions
    
    func setDelegates() {
        searchTracksField.delegate = self
        trackTableView.delegate    = self
        trackTableView.dataSource  = self
    }
    
    func initializeActivityIndicator() {
        indicator = UIActivityIndicatorView(frame: CGRect(x: 0, y: 0, width: 80, height: 80))
        indicator.activityIndicatorViewStyle = UIActivityIndicatorViewStyle.whiteLarge
        indicator.center = self.view.center
        view.addSubview(indicator)
    }
    
    func adjustViews() {
        trackTableView.backgroundColor = .clear
        trackTableView.tableFooterView = UIView()
        
        navigationItem.hidesBackButton = true
    }
    
    func textFieldShouldReturn(_ searchSongsField: UITextField) -> Bool {
        searchTracksField.resignFirstResponder()
        if !searchTracksField.text!.isEmpty {
            fetchResults(forQuery: searchSongsField.text!)
        }
        return true
    }
    
    func fetchResults(forQuery query: String) {
        indicator.startAnimating()
        if party.musicService == .appleMusic {
            APIManager.makeHTTPRequestToApple(withString: query)
        } else {
            APIManager.makeHTTPRequestToSpotify(withString: query)
        }
        
        DispatchQueue.global(qos: .userInitiated).async {
            self.APIManager.dispatchGroup.wait()
            self.tracksList = self.APIManager.tracksList
            if self.tracksList.count == 0 {
                DispatchQueue.main.async {
                    self.displayNoTracksFoundLabel()
                }
            } else {
                DispatchQueue.main.async {
                    self.removeNoTracksFoundLabel()
                }
            }
        }
    }
    
    func displayNoTracksFoundLabel() {
        noTracksFoundLabel.text = "No Tracks Found"
        noTracksFoundLabel.textColor = .white
        noTracksFoundLabel.textAlignment = .center
        
        noTracksFoundLabel.center = view.center
        view.addSubview(noTracksFoundLabel)
    }
    
    func removeNoTracksFoundLabel() {
        noTracksFoundLabel.removeFromSuperview()
    }
    
    // MARK: - Navigation

    func emptyArrays() {
        tracksList.removeAll()
        tracksQueue.removeAll()
    }
    
    // MARK: - Table
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tracksList.count
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        cell.backgroundColor = .clear
        if tracksQueue(hasTrack: tracksList[indexPath.row]) {
            cell.accessoryType = .checkmark
        } else {
            cell.accessoryType = .none
        }
    }
    
    func tracksQueue(hasTrack track: Track) -> Bool {
        for trackInQueue in party.tracksQueue {
            if track.id == trackInQueue.id {
                return true
            }
        }
        return false
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = trackTableView.dequeueReusableCell(withIdentifier: "Track", for: indexPath) as! TrackTableViewCell
        
        // MARK: - Cell Properties
        cell.trackName.text = tracksList[indexPath.row].name
        cell.artistName.text = tracksList[indexPath.row].artist

        if let unwrappedArtwork = tracksList[indexPath.row].artwork {
            cell.artworkImageView.image = unwrappedArtwork
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let cell = trackTableView.cellForRow(at: indexPath)!
        
        addToQueue(track: tracksList[indexPath.row])
        UIView.animate(withDuration: 0.35) {
            cell.accessoryType = .checkmark
        }
    }
    
    func addToQueue(track: Track) {
        tracksQueue.append(track)
    }
    
    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        let cell = trackTableView.cellForRow(at: indexPath)!
        removeFromQueue(track: tracksList[indexPath.section])
        
        UIView.animate(withDuration: 0.35) {
            cell.accessoryType = .none
        }
    }
    
    func removeFromQueue(track: Track) {
        for trackInQueue in tracksQueue {
            if trackInQueue.id == track.id {
                tracksQueue.remove(at: tracksQueue.index(of: trackInQueue)!)
            }
        }
    }
}
