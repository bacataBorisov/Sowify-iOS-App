//
//  ViewController.swift
//  Serial Over WiFi 
//
//  Created by Bacata (Vasil) Borisov on 25.12.22.
//

import UIKit
import CocoaMQTT
import AVFoundation
import SwiftTooltipKit
import UIDeviceModel

class ViewController: UIViewController {
    
    @IBOutlet weak var configurationButtonOutlet: UIButton!
    @IBOutlet weak var configurationInfo: UILabel! // that could be renamed tp status screen
    @IBOutlet weak var playButtonAppearance: UIButton!
    @IBOutlet weak var displayNMEA: UITextView!
    @IBOutlet weak var cmdTextField: UITextField!
    @IBOutlet weak var sendCmdRPi: UIButton!
    @IBOutlet weak var rebootRPi: UIButton!
    
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!

    //MARK: - Declaring Variables & Constants
    
    //get identifier - if you want to be more specific you need to MAP that in a separate
    //function. For the moment I will just use it to get the identifier and if I need
    //to find out what it is -> go to internet
    private static var identifier: String = {
        var systemInfo = utsname()
        uname(&systemInfo)
        let mirror = Mirror(reflecting: systemInfo.machine)
        let identifier = mirror.children.reduce("") { identifier, element in
            guard let value = element.value as? Int8, value != 0 else { return identifier }
            return identifier + String(UnicodeScalar(UInt8(value)))
        }
        return identifier
    }()
    //create a unique name for every different device
    private let mqttClient = CocoaMQTT(clientID: "[\(String(describing: UIDevice.current.identifierForVendor!.uuidString))] + [\(identifier)]", host: "raspberrypi.local", port: 1883)
    
    private let topic = "getData"
    private let topic_cmd = "command"
    private let topic_feedback = "feedback"
    private let topic_warning = "warning"
    private let ser_conf_topic = "configuration"
    private let topic_mediator = "mediator"
    
    
    private var connection_flag: Bool = false
    private var play_connect_flag: Bool = false
    private var background_flag: Bool = false
    private var foreground_flag: Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //enable idle timer - phone will not go to sleep
        UIApplication.shared.isIdleTimerDisabled = true
        //check the mode for the initial icon view
        if self.traitCollection.userInterfaceStyle == .dark {
            //is dark
            cmdTextField.setLeftView(image: UIImage(systemName: "terminal")!)
        } else {
            //is light
            cmdTextField.setLeftView(image: UIImage(systemName: "terminal.fill")!)
        }
        //shaping and coloring main window
        displayNMEA.layer.cornerRadius = 8
        displayNMEA.layer.masksToBounds = true
        displayNMEA.backgroundColor = UIColor(named: "display")
        displayNMEA.isScrollEnabled = true
        displayNMEA.font = .systemFont(ofSize: 16, weight: .semibold)
        //status bar
        configurationInfo.layer.cornerRadius = 8
        configurationInfo.layer.masksToBounds = true
        
        //think of a better name for the app and present it in better way
        configurationInfo.text = "Serial Over Wi-Fy"
        configurationInfo.font = .systemFont(ofSize: 24, weight: .semibold)
        
        //cmd field attributes
        cmdTextField.delegate = self
        cmdTextField.layer.cornerRadius = 8
        cmdTextField.layer.masksToBounds = true
        
        //display screen delegate in case I need to trigger methods
        displayNMEA.delegate = self
        
        //set up mqttClient delegate to itself, so it will trigger methods
        mqttClient.delegate = self
        
        /* cmdRPi power off button gesture */
        
        //Tap function will call when user tap on button
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector (tap))
        //Long function will call when user long press on button.
        let longGesture = UILongPressGestureRecognizer(target: self, action: #selector(long))
        tapGesture.numberOfTapsRequired = 1
        //tapGesture.cancelsTouchesInView = false
        sendCmdRPi.addGestureRecognizer(tapGesture)
        sendCmdRPi.addGestureRecognizer(longGesture)
        
        let tapGestureReboot = UITapGestureRecognizer(target: self, action: #selector (tapReboot))
        //Long function will call when user long press on button.
        let longGestureReboot = UILongPressGestureRecognizer(target: self, action: #selector(longReboot))
        tapGestureReboot.numberOfTapsRequired = 1
        //tapGestureReboot.cancelsTouchesInView = false
        
        rebootRPi.addGestureRecognizer(tapGestureReboot)
        rebootRPi.addGestureRecognizer(longGestureReboot)
        
        //Mark:- application DID move to background - it is very important, because
        //there is a difference between willResign and didEnter background
        
        let _: Void = NotificationCenter.default.addObserver(self, selector:#selector(appMovedToBackground), name: UIApplication.didEnterBackgroundNotification, object: nil)
        
        //Mark:- application move to foreground
        
        let _: Void = NotificationCenter.default.addObserver(self, selector:#selector(appMovedToForeground),name: UIApplication.willEnterForegroundNotification, object: nil)
        
        let _: Void = NotificationCenter.default.addObserver(self, selector:#selector(appTerminating),name: UIApplication.willTerminateNotification, object: nil)

        //SerialDataSettings.flag = false
        //viewDidLoad() closing bracket
    }
    
    //MARK: User Actions
    
    //MARK: - background method implementation
    
    @objc func appMovedToBackground() {
        print("App moved to background!")
        mqttClient.disconnect()
        background_flag = true
        //disable idle timer
        UIApplication.shared.isIdleTimerDisabled = false
    }
    
    //MARK: - foreground method implementation
    
    @objc func appMovedToForeground() {
        print("App moved to foreground!")
        _ = mqttClient.connect(timeout: 20)
        connection_flag = true
        foreground_flag = true
        //enable idle timer
        UIApplication.shared.isIdleTimerDisabled = true
    }
    
    @objc func appTerminating() {
        print("app is terminating")
        //close connection before the app exits
        mqttClient.disconnect()
    }
    
    //user single tap gesture
    @objc func tap() {
        //hint pop-up configuration
        sendCmdRPi.tooltip("hold for power off", orientation: .top, configuration: {configuration in
            configuration.labelConfiguration.font = .systemFont(ofSize: 18, weight: .semibold)
            configuration.labelConfiguration.textColor = UIColor(named: "running")!
            
            return configuration
        })
    }
    //user long tap gesture
    @objc func long() {
        UIDevice.vibration()
        mqttClient.publish(topic_mediator, withString: "shutdown", qos: .qos2)
    }
    
    //user single tap gesture
    @objc func tapReboot() {
        //hint pop-up configuration
        rebootRPi.tooltip("hold for reboot", orientation: .top, configuration: {configuration in
            configuration.labelConfiguration.font = .systemFont(ofSize: 18, weight: .semibold)
            configuration.labelConfiguration.textColor = UIColor(named: "running")!
            
            return configuration
        })
    }
    //user long tap gesture
    @objc func longReboot() {
        UIDevice.vibration()
        mqttClient.publish(topic_mediator, withString: "reboot", qos: .qos2)
    }
    
    
    func stopBlink(_: UIButton) {
        
    }
    //change attributes when dark and light modes are switched
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        
        if self.traitCollection.userInterfaceStyle == .dark {
            //is dark
            cmdTextField.setLeftView(image: UIImage(systemName: "terminal")!)
        } else {
            //is light
            cmdTextField.setLeftView(image: UIImage(systemName: "terminal.fill")!)
        }
    }
    
    //dismiss the keyboard
    @IBAction func userTapped(_ sender: UITapGestureRecognizer) {
        cmdTextField.resignFirstResponder()
    }

    @IBAction func clearScreenPressed(_ sender: UIButton) {
        displayNMEA.text = ""
    }
    
    //this is the pla/pause button - to be renamed
    @IBAction func connectButtonPressed(_ sender: UIButton) {
        
        //check initial conditions
        if SerialDataSettings.flag == true {
            // hold / resume screen
            if sender.isSelected == false {
                if mqttClient.connState == .connected {
                    //you only need to subscribe once - and probably in a different place to these topics
                    mqttClient.subscribe(topic_warning)
                    mqttClient.subscribe(topic_feedback)
                    mqttClient.subscribe(topic)
                    
                    mqttClient.publish(ser_conf_topic, withString: "\(SerialDataSettings.ser_configuration[0]),\(SerialDataSettings.ser_configuration[1]),\(SerialDataSettings.ser_configuration[2]),\(SerialDataSettings.ser_configuration[3]),\(SerialDataSettings.ser_configuration[4])")
                    
                    sender.isSelected = true
                    //buttons borders - it gives cerftain weight to the play button - I like it
                    playButtonAppearance.layer.borderWidth = 1.5
                    playButtonAppearance.layer.cornerRadius = 6
                    playButtonAppearance.layer.borderColor = UIColor(named: "running")?.cgColor
                    
                    //remove the blink from the button
                    playButtonAppearance.layer.removeAllAnimations()
                    playButtonAppearance.alpha = 1

                } else {
                    _ = mqttClient.connect(timeout: 20)
                    play_connect_flag = true
                    // while loop maybe here???
                    //display indeterminate activity indicator (spinner)

                }

            } else {
                mqttClient.unsubscribe(topic)
                self.playButtonAppearance.alpha = 0
                UIView.animate(withDuration: 0.80, delay: 0.0, options: [.curveEaseIn, .repeat, .autoreverse, .allowUserInteraction], animations: {() -> Void in
                    self.playButtonAppearance.alpha = 1.0
                })
                sender.isSelected = false
            }
        } else {

            playButtonAppearance.tooltip("choose IOIOI settings", orientation: .top, configuration: {configuration in
                configuration.labelConfiguration.font = .systemFont(ofSize: 18, weight: .semibold)
                configuration.labelConfiguration.textColor = UIColor(named: "running")!
                
                return configuration
            })
        }
    }
    
    //going to the second VC to select serial settings
    @IBAction func configurationButtonPressed(_ sender: UIButton) {
        
        playButtonAppearance.isSelected = false
        mqttClient.unsubscribe(topic)
        
        // implement prepare for segue - without sending any values
        DispatchQueue.main.async {
            self.performSegue(withIdentifier: "serial_configuration", sender: nil)
        }
    }
    
    //MARK: Functions go here
    
    //prepare for the segue so you can pass values
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "serial_configuration" {
            //if you want to use the function replace "_" with a real controller
            _ = segue.destination as! SerialConfiguration
        }
    }
    
    //class ViewController closing bracket
}

//MARK: Extensions Start Here!!!

//MARK: TextField Icon on the Left
extension UITextField {
    func setLeftView(image: UIImage) {
        let iconView = UIImageView(frame: CGRect(x: 5, y: 0, width: 50, height: 35))
        iconView.image = image
        let iconContainerView: UIView = UIView(frame: CGRect(x: 5, y: 0, width: 50, height: 35))
        iconContainerView.addSubview(iconView)
        leftView = iconContainerView
        leftViewMode = .always
        //need to play with the colors
        self.tintColor = .lightGray
    }
}
//MARK: UITextField Delegate Methods
extension ViewController: UITextFieldDelegate {
    //create extension for this later - return true if the textfield has to be editable
    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        return true
    }
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        
        if let text = cmdTextField.text {
            updateScreen(display: displayNMEA, message: text)
            mqttClient.publish(topic_cmd, withString: "\(text)" + "\r")
        }
        //dismiss the keyboard on pressing enter and clear the textfield
        textField.resignFirstResponder()
        textField.text = ""
        return true
    }
    //    func textFieldShouldEndEditing(_ textField: UITextField) -> Bool {
    //
    //    }
    
}

////MARK: - Flashing Status Bar
//extension UIView {
//    func blink(duration: TimeInterval = 0.5, delay: TimeInterval = 0.0, alpha: CGFloat = 1.0) {
//        UIView.animate(withDuration: duration, delay: delay, options: [.curveEaseInOut, .repeat, .autoreverse, .allowUserInteraction], animations: {
//            self.alpha = 0
//        })
//    }
//
//    func stopBlink() {
//        layer.removeAllAnimations()
//        alpha = 1
//    }
//}

//MARK: - Vibration & Sound
extension UIDevice {
    static func soundConnect() {
        
        // With vibration
        let systemSoundID: SystemSoundID = 1003
        AudioServicesPlaySystemSound(systemSoundID)
        AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
    }
    
    static func soundDisconnect() {
        
        // With vibration
        let systemSoundID: SystemSoundID = 1004
        AudioServicesPlaySystemSound(systemSoundID)
        AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
    }
    
    static func vibration() {
        AudioServicesPlayAlertSound(kSystemSoundID_Vibrate)
    }
}
//MARK: - Update Screen & AutoScroll

extension ViewController: UITextViewDelegate {
    
    //tells the delegate that the UITextView is not editable
    func textViewShouldBeginEditing(_ textView: UITextView) -> Bool {
        return false
    }
    
    func updateScreen(display: UITextView, message: String) {
        
        //displayNMEA.isEditable = false
        displayNMEA.text = ("\(displayNMEA.text ?? "")\(message)\n")
        
        //scroll to the bottom - this was done after a lot of attempts
        // use "bounds" and "content size" to find the proper size and limits
        // for the display
        if displayNMEA.text.count > 0 {
            let top = NSMakeRange(Int((displayNMEA.bounds.height - displayNMEA.contentSize.height)), 0)
            displayNMEA.scrollRangeToVisible(top)
        }
    }
}


//MARK: - CocoaMQTT Protocol Delegates

extension ViewController: CocoaMQTTDelegate {
    
    //handle different topics messages here
    
    func mqtt(_ mqtt: CocoaMQTT, didReceiveMessage message: CocoaMQTTMessage, id: UInt16) {
        
        let messageDecoded = String(bytes: message.payload, encoding: .utf8)
        
        if let messageDecodedSafe = messageDecoded {
            
            //receive the configuration back from the RPi & display it in the label
            //implement timer, so if it doesn't start after 10 secs, try again
            if message.topic == topic_feedback {
                configurationInfo.text = messageDecodedSafe
                configurationInfo.backgroundColor = UIColor(named: "running")
                configurationInfo.textColor = .systemBackground
            } else if message.topic == topic_warning {
                configurationInfo.text = messageDecodedSafe
                configurationInfo.backgroundColor = UIColor(named: "warning")
                configurationInfo.textColor = .systemBackground
                playButtonAppearance.isSelected = false
            } else {
                updateScreen(display: displayNMEA, message: messageDecodedSafe)
            }
        } else {
            updateScreen(display: displayNMEA, message: "could not decode message")
        }
        
    }
    
    func mqtt(_ mqtt: CocoaMQTT, didConnectAck ack: CocoaMQTTConnAck) {
        
    }
    
    func mqttDidDisconnect(_ mqtt: CocoaMQTT, withError err: Error?) {
        
//        //see how you can print this as useful information later
//        if let err {
//            print(err as Any)
//        }
//
        //playButtonAppearance.isSelected = false
        
    }
    
    func mqtt(_ mqtt: CocoaMQTT, didStateChangeTo state: CocoaMQTTConnState) {
        if state == .connecting {
            
            print("didEnter .connecting state")
            
            if foreground_flag == true {
                print("connecting")
                //start spinner activity indicator
                activityIndicator.startAnimating()
                foreground_flag = false
            } else {
                print("connecting")
                //start spinner activity indicator
                activityIndicator.startAnimating()
                configurationInfo.text = "{Trying to Connect}"
                configurationInfo.backgroundColor = UIColor(named: "warning")
            }

            
        } else if state == .disconnected {
            
            print("disconnected")
            //stop status bar animation
            //if it comes from the background - stop everything, else try to reconnect
            if background_flag == true {
                
                //reset flags
                connection_flag = false
                background_flag = false
                
            } else {
                _ = mqttClient.connect(timeout: 20)
            }

        } else {
            print("connected")
            //stop the spinner - activity indicator on top of the screen
            activityIndicator.stopAnimating()
            UIDevice.soundConnect()
            
            if SerialDataSettings.flag == true {
                
                if playButtonAppearance.isSelected == false {
                    playButtonAppearance.isSelected = false
                    self.playButtonAppearance.alpha = 0
                    UIView.animate(withDuration: 0.80, delay: 0.0, options: [.curveEaseIn, .repeat, .autoreverse, .allowUserInteraction], animations: {() -> Void in
                        self.playButtonAppearance.alpha = 1.0
                    })
                    
                    //you have to send configuration and be subscribed to the topics in order to remove the "trying to connect" message and display the configuration
                    //this can be wrapped in a function
                    mqttClient.subscribe(topic_warning)
                    mqttClient.subscribe(topic_feedback)
                    mqttClient.publish(ser_conf_topic, withString: "\(SerialDataSettings.ser_configuration[0]),\(SerialDataSettings.ser_configuration[1]),\(SerialDataSettings.ser_configuration[2]),\(SerialDataSettings.ser_configuration[3]),\(SerialDataSettings.ser_configuration[4])")
                                
                    //playButtonAppearance.blink()
                    
                } else {
                    playButtonAppearance.isSelected = true
                    //remove the blink from the button
                    playButtonAppearance.layer.removeAllAnimations()
                    playButtonAppearance.alpha = 1
                    
                    mqttClient.subscribe(topic_warning)
                    mqttClient.subscribe(topic_feedback)
                    mqttClient.subscribe(topic)
                    
                    mqttClient.publish(ser_conf_topic, withString: "\(SerialDataSettings.ser_configuration[0]),\(SerialDataSettings.ser_configuration[1]),\(SerialDataSettings.ser_configuration[2]),\(SerialDataSettings.ser_configuration[3]),\(SerialDataSettings.ser_configuration[4]) ")
                    
                    //buttons borders - it gives cerftain weight to the play button - I like it
                    playButtonAppearance.layer.borderWidth = 1.5
                    playButtonAppearance.layer.cornerRadius = 6
                    playButtonAppearance.layer.borderColor = UIColor(named: "running")?.cgColor
                    
                    //reset the flag which comec from the play button
                    play_connect_flag = false
                }

            } else {
                configurationInfo.text = "Serial Over Wi-Fy"
                configurationInfo.font = .systemFont(ofSize: 24, weight: .semibold)
                configurationInfo.backgroundColor = UIColor(named: "running")
            }
        }
    }
    
    func mqtt(_ mqtt: CocoaMQTT, didSubscribeTopics success: NSDictionary, failed: [String]) {
        
    }
    
    func mqtt(_ mqtt: CocoaMQTT, didPublishMessage message: CocoaMQTTMessage, id: UInt16) {
        
        print("message send \(message.topic)")
    }
    
    func mqtt(_ mqtt: CocoaMQTT, didPublishAck id: UInt16) {

        print(".didReceive publish ACK \(id)")

    }
    
    func mqtt(_ mqtt: CocoaMQTT, didUnsubscribeTopics topics: [String]) {
        
    }
    
    func mqttDidPing(_ mqtt: CocoaMQTT) {
        print("didSend .ping")
    }
    
    func mqttDidReceivePong(_ mqtt: CocoaMQTT) {
        print("didReceive .pong")
    }
}


