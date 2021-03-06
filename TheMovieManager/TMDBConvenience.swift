//
//  TMDBConvenience.swift
//  TheMovieManager
//
//  Created by Jarrod Parkes on 2/11/15.
//  Copyright (c) 2015 Jarrod Parkes. All rights reserved.
//

import UIKit
import Foundation

// MARK: - TMDBClient (Convenient Resource Methods)

extension TMDBClient {
    
    // MARK: Authentication (GET) Methods
    /*
     Steps for Authentication...
     https://www.themoviedb.org/documentation/api/sessions
     
     Step 1: Create a new request token
     Step 2a: Ask the user for permission via the website
     Step 3: Create a session ID
     Bonus Step: Go ahead and get the user id 😄!
     */
    func authenticateWithViewController(_ hostViewController: UIViewController, completionHandlerForAuth: @escaping (_ success: Bool, _ errorString: String?) -> Void) {
        
        // chain completion handlers for each request so that they run one after the other
        getRequestToken() { (success, requestToken, errorString) in
            
            if success {
                
                // success! we have the requestToken!
                print("** SUCCESS! new requestToken = \(requestToken!)")
                self.requestToken = requestToken
                
                self.loginWithToken(requestToken, hostViewController: hostViewController) { (success, errorString) in
                    
                    if success {
                        self.getSessionID(requestToken) { (success, sessionID, errorString) in
                            
                            if success {
                                
                                // success! we have the sessionID!
                                self.sessionID = sessionID
                                
                                self.getUserID() { (success, userID, errorString) in
                                    
                                    if success {
                                        
                                        if let userID = userID {
                                            
                                            // and the userID 😄!
                                            self.userID = userID
                                        }
                                    }
                                    
                                    completionHandlerForAuth(success, errorString)
                                }
                            } else {
                                completionHandlerForAuth(success, errorString)
                            }
                        }
                    } else {
                        completionHandlerForAuth(success, errorString)
                    }
                }
            } else {
                completionHandlerForAuth(success, errorString)
            }
        }
    }
    
    private func getRequestToken(_ completionHandlerForToken: @escaping (_ success: Bool, _ requestToken: RequestToken?, _ errorString: String?) -> Void) {
        
        /* 1. Specify parameters, method (if has {key}), and HTTP body (if POST) */
        /* 2. Make the request */
        /* 3. Send the desired value(s) to completion handler */
        
        let parameters: [String:AnyObject] = [:]
        let method = TMDBClient.Methods.AuthenticationTokenNew
        
        let _ = taskForGETMethod(method, parameters: parameters as [String : AnyObject]) { (results:RequestToken?, error:Error?) in

            if let error = error {
                let errorString = "There was an error gettign token: \(error)"
                completionHandlerForToken(false, nil, errorString)
            } else {
                completionHandlerForToken(true, results, nil)
            }
            
         }

        
    }
    private func loginWithToken(_ requestToken: RequestToken?, hostViewController: UIViewController, completionHandlerForLogin: @escaping (_ success: Bool, _ errorString: String?) -> Void) {
        
        let request_token: String = requestToken!.request_token!
        let authorizationURL = URL(string: "\(TMDBClient.Constants.AuthorizationURL)\(request_token)")
        let request = URLRequest(url: authorizationURL!)
        let webAuthViewController = hostViewController.storyboard!.instantiateViewController(withIdentifier: "TMDBAuthViewController") as! TMDBAuthViewController
        webAuthViewController.urlRequest = request
        webAuthViewController.requestToken = requestToken
        webAuthViewController.completionHandlerForView = completionHandlerForLogin
        
        let webAuthNavigationController = UINavigationController()
        webAuthNavigationController.pushViewController(webAuthViewController, animated: false)
        
        performUIUpdatesOnMain {
            hostViewController.present(webAuthNavigationController, animated: true, completion: nil)
        }
    }
    
    private func getSessionID(_ requestToken: RequestToken?, completionHandlerForSession: @escaping (_ success: Bool, _ sessionID: String?, _ errorString: String?) -> Void) {
        
        /* 1. Specify parameters, the API method, and the HTTP body (if POST) */
        let parameters: [String:AnyObject] = [:]
        let method = TMDBClient.Methods.AuthenticationSessionNew
        
        /* 2. Make the request */
        let _ = taskForPOSTMethod(method, parameters: parameters as [String : AnyObject], postObject: requestToken) { (results:SessionID?, error:NSError?) in
            
            if let error = error  {
                let errorString = "There was an error getting Session ID: \(error)"
                completionHandlerForSession(false, nil, errorString)
            } else if results?.session_id == nil {
                let errorString = "No Session ID was returned."
                completionHandlerForSession(false, nil, errorString)
            } else {
                let sessionId = results?.session_id
                print("** SUCCESS Session ID = \(String(describing: sessionId))")
                completionHandlerForSession(true, sessionId, nil)
            }
            
        }
    }
    
    private func getUserID(_ completionHandlerForUserID: @escaping (_ success: Bool, _ userID: Int?, _ errorString: String?) -> Void) {
        
        /* 1. Specify parameters, the API method, and the HTTP body (if POST) */
        let method = TMDBClient.Methods.Account
        let parameters: [String:AnyObject] = ["session_id": self.sessionID as AnyObject]

        let _ = taskForGETMethod(method, parameters: parameters as [String:AnyObject]) { (results:Account?, error:Error?) in
            
            if let error = error  {
                let errorString = "There was an error getting Account ID: \(error)"
                completionHandlerForUserID(false, nil, errorString)
            } else if results?.id == nil {
                let errorString = "No Account ID was returned."
                completionHandlerForUserID(false, nil, errorString)
            } else {
                let userId = results?.id
                print("** SUCCESS Account ID = \(String(describing: userId))")
                completionHandlerForUserID(true, userId, nil)
            }
        }

    }
    
    // MARK: GET Convenience Methods
    
    func getFavoriteMovies(_ completionHandlerForFavMovies: @escaping (_ result: Movies?, _ error: String?) -> Void) {
        
        var mutableMethod: String = Methods.AccountIDWatchlistMovies
        mutableMethod = substituteKeyInMethod(mutableMethod, key: TMDBClient.URLKeys.UserID, value: String(TMDBClient.sharedInstance().userID!))!
        let parameters: [String:AnyObject] = ["session_id": self.sessionID as AnyObject]
        /* 1. Specify parameters, the API method, and the HTTP body (if POST) */
        
        let _ = taskForGETMethod(mutableMethod, parameters: parameters as [String:AnyObject]) { (results:Movies?, error:Error?) in
            
            if let error = error  {
                let errorString = "There was an error getting Favorite Movies: \(error)"
                completionHandlerForFavMovies(nil, errorString)
            } else if results == nil {
                let errorString = "No Favorite Movies were returned."
                completionHandlerForFavMovies(nil, errorString)
            } else {
                let movies: Movies = results!
                print("** SUCCESS Favorite Movies = \(String(describing: movies))")
                completionHandlerForFavMovies(movies, nil)
            }
        }
        /* 2. Make the request */
        /* 3. Send the desired value(s) to completion handler */
        
    }
    
    func getWatchlistMovies(_ completionHandlerForWatchlist: @escaping (_ result: Movies?, _ error: String?) -> Void) {
       
        /* 1. Specify parameters, the API method, and the HTTP body (if POST) */
        var mutableMethod: String = Methods.AccountIDWatchlistMovies
        mutableMethod = substituteKeyInMethod(mutableMethod, key: TMDBClient.URLKeys.UserID, value: String(TMDBClient.sharedInstance().userID!))!
        let parameters: [String:AnyObject] = ["session_id": self.sessionID as AnyObject]
        /* 2. Make the request */
        
        let _ = taskForGETMethod(mutableMethod, parameters: parameters as [String:AnyObject]) { (results:Movies?, error:Error?) in
            
            if let error = error {
                let errorString = "There was an error getting Watchlist Movies: \(error)"
                completionHandlerForWatchlist(nil, errorString)
            } else if results == nil {
                let errorString = "No Watchlist Movies were returned"
                completionHandlerForWatchlist(nil, errorString)
            } else {
                let movies: Movies = results!
                print("** SUCCESS! Watchlist Movies Loaded")
                completionHandlerForWatchlist(movies, nil)
            }
        }
        /* 3. Send the desired value(s) to completion handler */
        
    }
    
    func getMoviesForSearchString(_ searchString: String, completionHandlerForMovies: @escaping (_ result: [TMDBMovie]?, _ error: NSError?) -> Void) -> URLSessionDataTask? {
        
        /* 1. Specify parameters, the API method, and the HTTP body (if POST) */
        /* 2. Make the request */
        /* 3. Send the desired value(s) to completion handler */
        return nil
    }
    
    func getConfig(_ completionHandlerForConfig: @escaping (_ didSucceed: Bool, _ error: NSError?) -> Void) {
        
        /* 1. Specify parameters, the API method, and the HTTP body (if POST) */
        /* 2. Make the request */
        /* 3. Send the desired value(s) to completion handler */
        
    }
    
    // MARK: POST Convenience Methods
    
    func postToFavorites(_ movie: TMDBMovie, favorite: Bool, completionHandlerForFavorite: @escaping (_ result: Int?, _ error: NSError?) -> Void)  {
        
        /* 1. Specify parameters, the API method, and the HTTP body (if POST) */
        /* 2. Make the request */
        /* 3. Send the desired value(s) to completion handler */
        
    }
    
    func postToWatchlist(_ movie: TMDBMovie, watchlist: Bool, completionHandlerForWatchlist: @escaping (_ result: Int?, _ error: NSError?) -> Void) {
        
        /* 1. Specify parameters, the API method, and the HTTP body (if POST) */
        /* 2. Make the request */
        /* 3. Send the desired value(s) to completion handler */
        
    }
}
