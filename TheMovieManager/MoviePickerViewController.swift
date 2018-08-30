//
//  MoviePickerTableView.swift
//  TheMovieManager
//
//  Created by Jarrod Parkes on 2/11/15.
//  Copyright (c) 2015 Jarrod Parkes. All rights reserved.
//

import UIKit

// MARK: - MoviePickerViewControllerDelegate

protocol MoviePickerViewControllerDelegate {
    func moviePicker(_ moviePicker: MoviePickerViewController, didPickMovie movie: TMDBMovie?)
}

// MARK: - MoviePickerViewController: UIViewController

class MoviePickerViewController: UIViewController {
    
    // MARK: Properties
    
    // the data for the table
    var movies = [Movie]()
    
    // the delegate will typically be a view controller, waiting for the Movie Picker to return an movie
    var delegate: MoviePickerViewControllerDelegate?
    
    // the most recent data download task. We keep a reference to it so that it can be canceled every time the search text changes
    var searchTask: URLSessionDataTask?
    
    // MARK: Outlets
    
    @IBOutlet weak var movieTableView: UITableView!
    @IBOutlet weak var movieSearchBar: UISearchBar!
    
    // MARK: Life Cycle
    
    override func viewDidLoad() {
        
        // configure tap recognizer
        let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleSingleTap(_:)))
        tapRecognizer.numberOfTapsRequired = 1
        tapRecognizer.delegate = self
        view.addGestureRecognizer(tapRecognizer)
    }
    
    // MARK: Dismissals
    
    @objc func handleSingleTap(_ recognizer: UITapGestureRecognizer) {
        view.endEditing(true)
    }
    
    @IBAction func cancel(_ sender: Any) {
        delegate?.moviePicker(self, didPickMovie: nil)
        self.dismiss(animated: true, completion: nil)
    }

    
//    @objc func logout() {
//        dismiss(animated: true, completion: nil)
//    }
}

// MARK: - MoviePickerViewController: UIGestureRecognizerDelegate

extension MoviePickerViewController: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        return movieSearchBar.isFirstResponder
    }
}

// MARK: - MoviePickerViewController: UISearchBarDelegate

extension MoviePickerViewController: UISearchBarDelegate {

    // each time the search text changes we want to cancel any current download and start a new one
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        
        // cancel the last task
        if let task = searchTask {
            task.cancel()
        }
        
        // if the text is empty we are done
        if searchText == "" {
            movies = [Movie]()
            movieTableView?.reloadData()
            return
        }
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }
}

// MARK: - MoviePickerViewController: UITableViewDelegate, UITableViewDataSource

extension MoviePickerViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let CellReuseId = "MovieSearchCell"
        let movie = movies[(indexPath as NSIndexPath).row]
        let cell = tableView.dequeueReusableCell(withIdentifier: CellReuseId) as UITableViewCell?
        
        if let release_date = movie.release_date {
            cell?.textLabel!.text = "\(String(describing: movie.title)) (\(release_date))"
        } else {
            cell?.textLabel!.text = "\(String(describing: movie.title))"
        }
        
        return cell!
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return movies.count
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {        
        let movie = movies[(indexPath as NSIndexPath).row]
        let controller = storyboard!.instantiateViewController(withIdentifier: "MovieDetailViewController") as! MovieDetailViewController
        controller.movie = movie
        navigationController!.pushViewController(controller, animated: true)
    }
}
