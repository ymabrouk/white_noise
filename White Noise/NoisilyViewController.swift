//
//  ViewController.swift
//  White Noise
//
//  Created by Yasser Mabrouk on 4/9/17.
//  Copyright © 2018 Yasser Mabrouk. All rights reserved.
//

import UIKit
import AVFoundation
import MediaPlayer


class NoisilyViewController: UIViewController {
    lazy var player: AVAudioPlayer? = self.makePlayer()
    var presenter: NoisilyMainPresenter?
    var timer: Timer?
    
        var colorTimer: Timer!
    public static var constructedArrayOfTracks = [
                    "birds_in_rain",
                    "car",
                    "coffee",
                    "fan",
             "fire","leaves", "morning","night",  "rain" , "thunderstorm"
                ]
             public static   var tracksNames = [
                    "Urban rain - light thunder peel",
                    "Small street traffic with some car horns."
                , "Crowd in a Thong Sala cafe",
                    "Fan - flush mounted ceiling fan - air flow",
                    "Low, rumbling flame ambience.", "Forest ambience on a summer day with heavy wind", "Early morning quiet city street ambience with birds singing",
                   "Night time atmopshere", "Thunderstorm ambience " , "Thunderstorm"
                  ]
        
        
        private var numberOfSections = 1
         private var numberOfRows = 0
    private var selectedTrack = constructedArrayOfTracks[0]
    
    @IBOutlet weak var playButton: UIBarButtonItem!
    @IBOutlet weak var timerPicker: UIDatePicker!
    @IBOutlet weak var timerButton: UIButton!
    @IBOutlet weak var timerLabel: UILabel!
    @IBOutlet private weak var tableView: UITableView!
    
    let grey : UIColor = UIColor(red: 201, green: 201, blue: 201)
    let pink : UIColor = UIColor(red: 255, green: 207, blue: 203)
    let brown : UIColor = UIColor(red: 161, green: 136, blue: 127)
    

    
    override func viewDidLoad() {
        super.viewDidLoad()

        timerLabel.text = ""
        timerPicker.setValue(UIColor.white, forKey: "textColor")
        presenter = NoisilyMainPresenter(viewController: self)
        presenter?.loadStateFromDefaults()
        tableView.delegate = self
          tableView.dataSource = self
         
        
        
          numberOfRows = NoisilyViewController.constructedArrayOfTracks.count
          self.navigationController?.navigationBar.setValue(true, forKey: "hidesShadow")
          
          colorTimer = Timer.scheduledTimer(timeInterval: 10, target: self, selector: #selector(self.setRandomBackgroundColor), userInfo: nil, repeats: true)
             self.setRandomBackgroundColor()
          
          
        
    
    }
    
    
    
    
    
    @objc func setRandomBackgroundColor() {
             let colors = [
                 UIColor(red: 233/255, green: 203/255, blue: 198/255, alpha: 1),
                 UIColor(red: 38/255, green: 188/255, blue: 192/255, alpha: 1),
                 UIColor(red: 253/255, green: 221/255, blue: 164/255, alpha: 1),
                 UIColor(red: 235/255, green: 154/255, blue: 171/255, alpha: 1),
                 UIColor(red: 87/255, green: 141/255, blue: 155/255, alpha: 1)
             ]
             let randomColor = Int(arc4random_uniform(UInt32 (colors.count)))
          
           UIView.animate(withDuration: 1.0, delay: 0.0, options:[], animations: {
                   let selectedColor = colors[randomColor]
                    self.view.backgroundColor = selectedColor
               
                   let navBar = self.navigationController?.navigationBar

                     // change the bar tint color to change what the color of the bar itself looks like
                     navBar?.barTintColor = selectedColor

                     // tint color changes the color of the nav item colors eg. the back button
                     navBar?.tintColor = UIColor.white

                     // if you notice that your nav bar color is off by a bit, sometimes you will have to
                     // change it to not translucent to get correct color
                     navBar?.isTranslucent = false

                     // the following attribute changes the title color
                     navBar?.titleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.white]
               
               
              }, completion:nil)
         }
       
    
    @objc func update() {
        presenter?.tick()
    }
    
    public func makeActiveAudioSession() {
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(AVAudioSessionCategoryPlayback)
            try audioSession.setActive(true)
        } catch {
            print("Failed to set audio session category.  Error: \(error)")
        }
    }
    
    @available(iOS 12.0, *)
    public func onReceiveIntent(intent: PlayIntent) {
        presenter?.setIntent(intent: intent)
    }
    
    private func makePlayer() -> AVAudioPlayer? {
        let url = Bundle.main.url(forResource: selectedTrack,
                                  withExtension: "mp3")!
        let player = try? AVAudioPlayer(contentsOf: url)

        player?.numberOfLoops = -1
        return player
    }
    
    public func resetPlayer(restart: Bool) {
        player?.pause()
        player = makePlayer()
        if (restart) {
            player?.play()
        }
    }
    
    public func play() {
        makeActiveAudioSession()
        timer?.invalidate()
        timer = Timer.scheduledTimer(timeInterval: NoisilyMainPresenter.tickInterval,
                                     target: self,
                                     selector: #selector(self.update),
                                     userInfo: nil,
                                     repeats: true)
        player?.play()
        
        UIApplication.shared.beginReceivingRemoteControlEvents()
        let commandCenter = MPRemoteCommandCenter.shared()
        weak var weakSelf = self
        commandCenter.pauseCommand.addTarget { (event) -> MPRemoteCommandHandlerStatus in
            weakSelf?.presenter?.pause()
            return .success
        }
        
        commandCenter.playCommand.addTarget { (event) -> MPRemoteCommandHandlerStatus in
            weakSelf?.presenter?.play()
            return .success
        }
        
        playButton.image = UIImage(named: "pause")

        
    }
    
    public func setMediaTitle(title: String) {
        if let image = UIImage(named: "darkIcon") {
            let artwork = MPMediaItemArtwork
                .init(boundsSize: image.size,
                      requestHandler: { (size) -> UIImage in return image})
            
            let nowPlayingInfo = [MPMediaItemPropertyTitle : title,
                                  MPMediaItemPropertyArtwork : artwork]
                                        as [String : Any]
            MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
        }
    }

    public func pause() {
        timer?.invalidate()
        player?.pause()
        
        
        let btnImage = UIImage(named: "play")
        playButton.image = btnImage
        do {
            try AVAudioSession.sharedInstance().setActive(false)
        } catch {
            print("Error setting audio session active=false")
        }
    }
    
    public func setVolume(volume: Float) {
        player?.setVolume(volume, fadeDuration: 0)
    }
    
    public func getTimerPickerTime() -> Double {
       return timerPicker.countDownDuration
    }
    
    public func cancelTimer(timerText: String) {
        timerPicker.isEnabled = true
        timerButton.setImage(UIImage(named: "add"), for: .normal)
        setTimerText(text: timerText)
    }
    
    public func addTimer(timerText: String) {
        timerPicker.isEnabled = false
        timerButton.setImage(UIImage(named: "delete"), for: .normal)
        setTimerText(text: timerText)
    }
    
    public func setTimerText(text: String) {
        var actualText = text
        if !actualText.isEmpty {
            actualText.append("\t")
        }
        timerLabel.text = actualText
    }
    
//    public func setColor(color : NoisilyMainPresenter.NoiseColors) {
//        switch color {
//        case .White:
//            colorSegmented.selectedSegmentIndex = 0
//            wavesSwitch.onTintColor = grey
//            fadeSwitch.onTintColor = grey
//            break;
//        case .Pink:
//            colorSegmented.selectedSegmentIndex = 1
//            wavesSwitch.onTintColor = pink
//            fadeSwitch.onTintColor = pink
//            break;
//        case .Brown:
//            colorSegmented.selectedSegmentIndex = 2
//            wavesSwitch.onTintColor = brown
//            fadeSwitch.onTintColor = brown
//            break;
//        }
//    }
    
//    public func setWavesEnabled(enabled : Bool) {
//        wavesSwitch.setOn(enabled, animated: false)
//    }
//
//    public func setFadeEnabled(enabled : Bool) {
//        fadeSwitch.setOn(enabled, animated: false)
//    }
//
    public func setTimerPickerTime(seconds : Double) {
        timerPicker.countDownDuration = seconds
    }
    

    @IBAction func playPausePressedButton(_ sender: Any) {
             presenter?.playPause()
    }

    
    
    @IBAction func timerAddedAction(_ sender: UIButton) {
        presenter?.addDeleteTimer()
    }
    
    
}

extension UIColor {
    convenience init(red: Int, green: Int, blue: Int) {
        assert(red >= 0 && red <= 255, "Invalid red component")
        assert(green >= 0 && green <= 255, "Invalid green component")
        assert(blue >= 0 && blue <= 255, "Invalid blue component")
        
        self.init(red: CGFloat(red) / 255.0, green: CGFloat(green) / 255.0, blue: CGFloat(blue) / 255.0, alpha: 1.0)
    }
    
    convenience init(rgb: Int) {
        self.init(
            red: (rgb >> 16) & 0xFF,
            green: (rgb >> 8) & 0xFF,
            blue: rgb & 0xFF
        )
    }
}


extension NoisilyViewController: UITableViewDataSource, UITableViewDelegate {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return numberOfSections
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return numberOfRows
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let audioTabelCellView =  tableView.dequeueReusableCell(withIdentifier: "AudioTabelCellView", for: indexPath) as! AudioTabelCellView
        let trackName = NoisilyViewController.tracksNames[indexPath.row]
        audioTabelCellView.audioName.text = trackName
        audioTabelCellView.avatarImageView.image = UIImage(named: NoisilyViewController.constructedArrayOfTracks[indexPath.row])
        audioTabelCellView.avatarImageView.tag = indexPath.row
        audioTabelCellView.avatarImageView.alpha  = 0.8
        let backgroundView = UIView()
        backgroundView.backgroundColor = UIColor.black
        audioTabelCellView.selectedBackgroundView = backgroundView
        
        
      return audioTabelCellView
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        selectedTrack = NoisilyViewController.constructedArrayOfTracks[indexPath.row]
        playButton.isEnabled = true
        resetPlayer(restart: true)
        play()
    
    }
    

}
