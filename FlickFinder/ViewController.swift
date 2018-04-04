//
//  ViewController.swift
//  FlickFinder
//
//  Created by Jarrod Parkes on 11/5/15.
//  Copyright © 2015 Udacity. All rights reserved.
//

import UIKit

// MARK: - ViewController: UIViewController

class ViewController: UIViewController {
    
    // MARK: Properties
    
    var keyboardOnScreen = false
    
    // MARK: Outlets
    
    @IBOutlet weak var photoImageView: UIImageView!
    @IBOutlet weak var photoTitleLabel: UILabel!
    @IBOutlet weak var phraseTextField: UITextField!
    @IBOutlet weak var phraseSearchButton: UIButton!
    @IBOutlet weak var latitudeTextField: UITextField!
    @IBOutlet weak var longitudeTextField: UITextField!
    @IBOutlet weak var latLonSearchButton: UIButton!
    
    // MARK: Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        phraseTextField.delegate = self
        latitudeTextField.delegate = self
        longitudeTextField.delegate = self
        subscribeToNotification(.UIKeyboardWillShow, selector: #selector(keyboardWillShow))
        subscribeToNotification(.UIKeyboardWillHide, selector: #selector(keyboardWillHide))
        subscribeToNotification(.UIKeyboardDidShow, selector: #selector(keyboardDidShow))
        subscribeToNotification(.UIKeyboardDidHide, selector: #selector(keyboardDidHide))
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        unsubscribeFromAllNotifications()
    }
    
    // MARK: Search Actions
    
    @IBAction func searchByPhrase(_ sender: AnyObject) {

        userDidTapView(self)
        setUIEnabled(false)
        
        if !phraseTextField.text!.isEmpty {
            photoTitleLabel.text = "Searching..."
            // TODO: Set necessary parameters!
            let methodParameters = [
                Constants.FlickrParameterKeys.SafeSearch: Constants.FlickrParameterValues.UseSafeSearch,
                Constants.FlickrParameterKeys.Method: Constants.FlickrParameterValues.SearchMethod,
                Constants.FlickrParameterKeys.Text: phraseTextField.text!,
                Constants.FlickrParameterKeys.Extras: Constants.FlickrParameterValues.MediumURL,
                Constants.FlickrParameterKeys.Format: Constants.FlickrParameterValues.ResponseFormat,
                Constants.FlickrParameterKeys.NoJSONCallback: Constants.FlickrParameterValues.DisableJSONCallback,
                Constants.FlickrParameterKeys.APIKey: Credentials.apiKey
            ]
            displayImageFromFlickrBySearch(methodParameters as [String: AnyObject])
        } else {
            setUIEnabled(true)
            photoTitleLabel.text = "Phrase Empty."
        }
    }
    
    @IBAction func searchByLatLon(_ sender: AnyObject) {

        userDidTapView(self)
        setUIEnabled(false)
        
        if isTextFieldValid(latitudeTextField, forRange: Constants.Flickr.SearchLatRange) && isTextFieldValid(longitudeTextField, forRange: Constants.Flickr.SearchLonRange) {
            photoTitleLabel.text = "Searching..."
            // TODO: Set necessary parameters!
            let methodParameters = [
                Constants.FlickrParameterKeys.SafeSearch: Constants.FlickrParameterValues.UseSafeSearch,
                Constants.FlickrParameterKeys.Method: Constants.FlickrParameterValues.SearchMethod,
                Constants.FlickrParameterKeys.BoundingBox: bbox(),
                Constants.FlickrParameterKeys.Extras: Constants.FlickrParameterValues.MediumURL,
                Constants.FlickrParameterKeys.Format: Constants.FlickrParameterValues.ResponseFormat,
                Constants.FlickrParameterKeys.NoJSONCallback: Constants.FlickrParameterValues.DisableJSONCallback,
                Constants.FlickrParameterKeys.APIKey: Credentials.apiKey
            ]
            displayImageFromFlickrBySearch(methodParameters as [String: AnyObject])
        }
        else {
            setUIEnabled(true)
            photoTitleLabel.text = "Lat should be [-90, 90].\nLon should be [-180, 180]."
        }
    }
    
    
    private func bbox() -> String {
        if let latitude = Double(latitudeTextField.text!), let longitude = Double(longitudeTextField.text!) {
            let minLongitude = max(longitude - Constants.Flickr.SearchBBoxHalfWidth, Constants.Flickr.SearchLonRange.0)
            let minLatitude = max(latitude - Constants.Flickr.SearchBBoxHalfHeight, Constants.Flickr.SearchLatRange.0)
            let maxLongitude = min(longitude + Constants.Flickr.SearchBBoxHalfWidth, Constants.Flickr.SearchLonRange.1)
            let maxLatitude = min(latitude + Constants.Flickr.SearchBBoxHalfHeight, Constants.Flickr.SearchLatRange.1)
            return "\(minLongitude), \(minLatitude), \(maxLongitude), \(maxLatitude)"
        } else {
            return "0,0,0,0"
        }
    }
    
    // MARK: Flickr API
    
//    private func displayImageFromFlickrBySearch(_ methodParameters: [String: AnyObject]) {
//        // TODO: Make request to Flickr!
//
//        // create URLSession and URLRequest
//        let session = URLSession.shared
//        let request = URLRequest(url: flickrURLFromParameters(methodParameters))
//
//        // create network request
//        let task = session.dataTask(with: request) { (data, response, error) in
//
//            func displayError(_ error: String) {
//                print(error)
//                performUIUpdatesOnMain {
//                    self.setUIEnabled(true)
//                    self.photoTitleLabel.text = "No photo found. Please try again."
//                    self.photoImageView.image = nil
//                }
//            }
//
//            // Check if there was an error
//            guard (error == nil) else {
//                displayError("There was an error with your request: \(error ?? "Whoops, something went wrong" as! Error)")
//                return
//            }
//
//            // Check for successful response in the 2xx space
//            guard let statusCode = (response as? HTTPURLResponse)?.statusCode, statusCode >= 200 && statusCode <= 299 else {
//                displayError("Your request returned a status code other than 2xx!")
//                return
//            }
//
//            // Check if data was returned
//            guard let data = data else {
//                displayError("No data was returned by request!")
//                return
//            }
//
//            // parse the data
//            let parsedResult: [String:AnyObject]!
//            do {
//                parsedResult = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as! [String:AnyObject]
//            } catch {
//                displayError("Could not parse as JSON: \(data)")
//                return
//            }
//
//            // Did we recieve a return error (stat != ok)?
//            guard let stat = parsedResult[Constants.FlickrResponseKeys.Status] as? String, stat == Constants.FlickrResponseValues.OKStatus else {
//                displayError("Flickr API returned an error. See code and message in \(parsedResult)")
//                return
//            }
//
//
//            guard let photosDictionary = parsedResult[Constants.FlickrResponseKeys.Photos] as? [String:AnyObject], let photoArray = photosDictionary[Constants.FlickrResponseKeys.Photo] as? [[String:AnyObject]] else {
//                displayError("Cannot find keys '\(Constants.FlickrResponseKeys.Photos)' and '\(Constants.FlickrResponseKeys.Photo)' in \(parsedResult)")
//                return
//            }
//
//            // select a random photo
//            let randomPhotoIndex = Int(arc4random_uniform(UInt32(photoArray.count)))
//            let photoDictionary = photoArray[randomPhotoIndex] as [String:AnyObject]
//            let photoTitle = photoDictionary[Constants.FlickrResponseKeys.Title] as? String
//
//            // Does photo url contain our 'url_m'?
//            guard let imageUrlString = photoDictionary[Constants.FlickrResponseKeys.MediumURL] as? String else {
//                displayError("Key '\(Constants.FlickrResponseKeys.MediumURL)' in \(photoArray)")
//                return
//            }
//
//            // if an image exists at url, set the image an title
//            let imageURL = URL(string: imageUrlString)
//            if let imageData = try? Data(contentsOf: imageURL!) {
//                performUIUpdatesOnMain {
//                    self.setUIEnabled(true)
//                    self.photoImageView.image = UIImage(data: imageData)
//                    self.photoTitleLabel.text = photoTitle ?? "(Untitled)"
//                }
//            } else {
//                displayError("Image does not exist at \(String(describing: imageURL))")
//                }
//            }
//        task.resume()
//        }
//    }
//
//
//
//    // MARK: Helper for Creating a URL from Parameters
//
//    private func flickrURLFromParameters(_ parameters: [String: AnyObject]) -> URL {
//
//        var components = URLComponents()
//        components.scheme = Constants.Flickr.APIScheme
//        components.host = Constants.Flickr.APIHost
//        components.path = Constants.Flickr.APIPath
//        components.queryItems = [URLQueryItem]()
//
//        for (key, value) in parameters {
//            let queryItem = URLQueryItem(name: key, value: "\(value)")
//            components.queryItems!.append(queryItem)
//        }
//
//        return components.url!
//    }
//
//
//// MARK: - ViewController: UITextFieldDelegate
//
//extension ViewController: UITextFieldDelegate {
//
//    // MARK: UITextFieldDelegate
//
//    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
//        textField.resignFirstResponder()
//        return true
//    }
//
//    // MARK: Show/Hide Keyboard
//
//    func keyboardWillShow(_ notification: Notification) {
//        if !keyboardOnScreen {
//            view.frame.origin.y -= keyboardHeight(notification)
//        }
//    }
//
//    func keyboardWillHide(_ notification: Notification) {
//        if keyboardOnScreen {
//            view.frame.origin.y += keyboardHeight(notification)
//        }
//    }
//
//    func keyboardDidShow(_ notification: Notification) {
//        keyboardOnScreen = true
//    }
//
//    func keyboardDidHide(_ notification: Notification) {
//        keyboardOnScreen = false
//    }
//
//    func keyboardHeight(_ notification: Notification) -> CGFloat {
//        let userInfo = (notification as NSNotification).userInfo
//        let keyboardSize = userInfo![UIKeyboardFrameEndUserInfoKey] as! NSValue
//        return keyboardSize.cgRectValue.height
//    }
//
//    func resignIfFirstResponder(_ textField: UITextField) {
//        if textField.isFirstResponder {
//            textField.resignFirstResponder()
//        }
//    }
//
//    @IBAction func userDidTapView(_ sender: AnyObject) {
//        resignIfFirstResponder(phraseTextField)
//        resignIfFirstResponder(latitudeTextField)
//        resignIfFirstResponder(longitudeTextField)
//    }
//
//    // MARK: TextField Validation
//
//    func isTextFieldValid(_ textField: UITextField, forRange: (Double, Double)) -> Bool {
//        if let value = Double(textField.text!), !textField.text!.isEmpty {
//            return isValueInRange(value, min: forRange.0, max: forRange.1)
//        } else {
//            return false
//        }
//    }
//
//    func isValueInRange(_ value: Double, min: Double, max: Double) -> Bool {
//        return !(value < min || value > max)
//    }
    
    private func displayImageFromFlickrBySearch(_ methodParameters: [String:AnyObject], withPageNumber: Int) {
        
        // ad the page to the method's parameters
        var methodParametersWithPageNumber = methodParameters
        methodParametersWithPageNumber[Constants.FlickrParameterKeys.Page] = withPageNumber as AnyObject?
        
        
        
    }
}

// MARK: - ViewController (Configure UI)

private extension ViewController {
    
     func setUIEnabled(_ enabled: Bool) {
        photoTitleLabel.isEnabled = enabled
        phraseTextField.isEnabled = enabled
        latitudeTextField.isEnabled = enabled
        longitudeTextField.isEnabled = enabled
        phraseSearchButton.isEnabled = enabled
        latLonSearchButton.isEnabled = enabled
        
        // adjust search button alphas
        if enabled {
            phraseSearchButton.alpha = 1.0
            latLonSearchButton.alpha = 1.0
        } else {
            phraseSearchButton.alpha = 0.5
            latLonSearchButton.alpha = 0.5
        }
    }
}

// MARK: - ViewController (Notifications)

private extension ViewController {
    
    func subscribeToNotification(_ notification: NSNotification.Name, selector: Selector) {
        NotificationCenter.default.addObserver(self, selector: selector, name: notification, object: nil)
    }
    
    func unsubscribeFromAllNotifications() {
        NotificationCenter.default.removeObserver(self)
    }
}
