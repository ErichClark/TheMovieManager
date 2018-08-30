//
//  TMDBAuthViewController.swift
//  TheMovieManager
//
//  Created by Jarrod Parkes on 2/11/15.
//  Copyright (c) 2015 Jarrod Parkes. All rights reserved.
//

import UIKit
import WebKit

// MARK: - TMDBAuthViewController: UIViewController

class TMDBAuthViewController: UIViewController {

    // MARK: Properties
    
    var urlRequest: URLRequest? = nil
    var requestToken: RequestToken? = nil
    var completionHandlerForView: ((_ success: Bool, _ errorString: String?) -> Void)? = nil
    let webConfiguration = WKWebViewConfiguration()
    
    // MARK: Outlets
    
    @IBOutlet weak var webView: WKWebView!
    
    // MARK: Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        webView.navigationDelegate = self
        view = webView
        
        navigationItem.title = "TheMovieDB Auth"
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Cancel", style: .plain, target: self, action: #selector(cancelAuth))
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if let urlRequest = urlRequest {
            webView.load(urlRequest)
        }
    }
    
    // MARK: Cancel Auth Flow
    
    @objc func cancelAuth() {
        dismiss(animated: true, completion: nil)
    }
}

// MARK: - TMDBAuthViewController: UIWebViewDelegate

extension TMDBAuthViewController: WKNavigationDelegate {
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        let webString = "** Web String Abs Value = \(String(describing: webView.url?.absoluteURL))"
//        print(webString)
        if webString.contains("allow") {
            dismiss(animated: true) {
                self.completionHandlerForView!(true, nil)
            }
        }
    }

    // TODO: Add implementation here
}
