//
//  SerialConfiguration.swift
//  NMEAReader
//
//  Created by Vasil Borisov on 2.04.23.
//

import Foundation
import UIKit

class SerialConfiguration: UIViewController, UIPickerViewDelegate, UIPickerViewDataSource {
    
    @IBOutlet weak var typeAndSpeedPicker: UIPickerView!
    @IBOutlet weak var parityStopBytesizePickerData: UIPickerView!
    
    
    private var interfacePickerData: [String] = []
    private var baudratePickerData: [String] = []
    private var parityPickerData: [String] = []
    private var stopBitPickerData: [String] = []
    private var bytesizePickerData: [String] = []
    
    private var updatedConfiguration: [String] = ["", "", "", "", ""]
    
    override func viewDidLoad() {

        super.viewDidLoad()
        interfacePickerData = ["RS-232", "RS-422", "RS-485 2W", "RS-485 4W"]
        baudratePickerData = ["4800", "9600", "19200", "38400", "57600", "115200"]
        parityPickerData = ["None", "Even", "Odd"]
        stopBitPickerData = ["1", "1.5", "2"]
        bytesizePickerData = ["5", "6", "7", "8"]
        
        self.typeAndSpeedPicker.delegate = self
        self.typeAndSpeedPicker.dataSource = self
        self.parityStopBytesizePickerData.delegate = self
        self.parityStopBytesizePickerData.dataSource = self
        
        //default pickers settings - that will appear visually
        self.typeAndSpeedPicker.selectRow(SerialDataSettings.ser_configuration_return[0], inComponent: 0, animated: true)
        self.typeAndSpeedPicker.selectRow(SerialDataSettings.ser_configuration_return[1], inComponent: 1, animated: true)
        self.parityStopBytesizePickerData.selectRow(SerialDataSettings.ser_configuration_return[2], inComponent: 0, animated: true)
        self.parityStopBytesizePickerData.selectRow(SerialDataSettings.ser_configuration_return[3], inComponent: 1, animated: true)
        self.parityStopBytesizePickerData.selectRow(SerialDataSettings.ser_configuration_return[4], inComponent: 2, animated: true)
        // select rows after they have been set to default - if nothing has been touched
        // it will get the upper default values
        pickerView(typeAndSpeedPicker, didSelectRow: 0, inComponent: 0)
        pickerView(parityStopBytesizePickerData, didSelectRow: 0, inComponent: 0)
        
    }
    // Number of columns of data
    @IBAction func applySettings(_ sender: UIButton) {
        
        //apply color
        sender.backgroundColor = UIColor(named: "button")
        //update configuration if it is different from the previous one
        let currentConfiguration = SerialDataSettings.ser_configuration_raw
        if currentConfiguration != updatedConfiguration {

            SerialDataSettings.ser_configuration_raw = updatedConfiguration
            SerialDataSettings.updateConfiguration()
            //update settings in the ViewController
            SerialDataSettings.update_flag = true
        } else {
            //do not update settings again in the ViewController
            SerialDataSettings.update_flag = false
        }

        //dismiss the current controller
        dismiss(animated: true)
    }
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        if pickerView == typeAndSpeedPicker {
            return 2
        } else if pickerView == parityStopBytesizePickerData {
            return 3
        }
        return 0
    }
    
    // The number of rows of data
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        
        if pickerView == typeAndSpeedPicker {
            if component == 0 {
                return interfacePickerData.count
            } else {
                return baudratePickerData.count
            }
            
        } else if pickerView == parityStopBytesizePickerData {
            if component == 0 {
                return parityPickerData.count
            } else if component == 1 {
                return stopBitPickerData.count
            } else {
                return bytesizePickerData.count
            }
        }
        return 1
    }
    
    // The data to return fopr the row and component (column) that's being passed in
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        if pickerView == typeAndSpeedPicker {
            if component == 0 {
                return interfacePickerData[row]
            } else {
                return baudratePickerData[row]
            }

        } else if pickerView == parityStopBytesizePickerData {
            if component == 0 {
                return parityPickerData[row]
            } else if component == 1 {
                return stopBitPickerData[row]
            } else {
                return bytesizePickerData[row]
            }
        }
        return ""
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {

        if pickerView == typeAndSpeedPicker {
            
            let interface = interfacePickerData[pickerView.selectedRow(inComponent: 0)]
            let baudrate = baudratePickerData[pickerView.selectedRow(inComponent: 1)]
            
            updatedConfiguration[0] = interface
            updatedConfiguration[1] = baudrate
            
            //print(SerialDataSettings.ser_configuration)
            
        } else if pickerView == parityStopBytesizePickerData {
            
            let parity = parityPickerData[pickerView.selectedRow(inComponent: 0)]
            let stopbit = stopBitPickerData[pickerView.selectedRow(inComponent: 1)]
            let bytesize = bytesizePickerData[pickerView.selectedRow(inComponent: 2)]
            
            updatedConfiguration[2] = parity
            updatedConfiguration[3] = stopbit
            updatedConfiguration[4] = bytesize

        }
    }
    
}


