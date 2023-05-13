//
//  SerialSettings.swift
//  NMEAReader
//
//  Created by Vasil Borisov on 3.04.23.
//

import Foundation

//this is one method of creating a global variable. It can be accessed from the other classes
struct SerialDataSettings {
    
    //raw configuration is used just for check if the settings have changed
    static var ser_configuration_raw: [String] = ["", "", "", "", ""]
    //this array is used for sending the last settings used to the pickers in SerialConfiguration controller. Once it is loaded it will show you the last used settings
    // default settings for the pickers
    // {RS-232, 9600, None, 1, 8} - change if you want something else
    static var ser_configuration_return: [Int] = [0, 1, 0, 0, 3]
    //this one is used for sending the settings in the RPi format
    //initialize default settings
    static var ser_configuration: [String] = ["", "", "", "", ""]
    //used to check if settings were choose initially
    static var flag: Bool = false
    static var update_flag: Bool = false
    
    //if you want to access the variable you need to make the function static
    //READ MORE AB OUT IT and RECAP ABOUT CLASSES
    // I am not sure exactly what I am doing :))
    static func updateConfiguration() {
        
        ser_configuration = ser_configuration_raw
        //decoding configuration for serial RPi serial port usage
        //INTERFACE
        switch ser_configuration[0] {
        case "RS-485 2W":
            ser_configuration[0] = "1"
            ser_configuration_return[0] = 2
        case "RS-422":
            ser_configuration[0] = "2"
            ser_configuration_return[0] = 1
        case "RS-485 4W":
            ser_configuration[0] = "3"
            ser_configuration_return[0] = 3
        //case RS-232
        default:
            ser_configuration[0] = "0"
            ser_configuration_return[0] = 0
        }
        
        //BAUDRATE is being send as a string number and can be used straight forward
        // I se only the return array which is going to be used for keeping the last settings
        switch ser_configuration[1] {
        case "4800":
            ser_configuration_return[1] = 0
        case "19200":
            ser_configuration_return[1] = 2
        case "38400":
            ser_configuration_return[1] = 3
        case "57600":
            ser_configuration_return[1] = 4
        case "115200":
            ser_configuration_return[1] = 5
        default:
            ser_configuration_return[1] = 1
        }
        //PARITY
        switch ser_configuration[2] {
        case "Even":
            ser_configuration[2] = "E"
            ser_configuration_return[2] = 1
        case "Odd":
            ser_configuration[2] = "O"
            ser_configuration_return[2] = 2
        //case NONE
        default:
            ser_configuration[2] = "N"
            ser_configuration_return[2] = 0
        }
        //STOPBITS
        switch ser_configuration[3] {
        case "2":
            ser_configuration[3] = "2"
            ser_configuration_return[3] = 2
        case "1.5":
            ser_configuration[3] = "1.5"
            ser_configuration_return[3] = 1
        //ONE STOPBIT
        default:
            ser_configuration[3] = "1"
            ser_configuration_return[3] = 0
        }
        //BYTESIZE
        switch ser_configuration[4] {
        case "5":
            ser_configuration[4] = "5"
            ser_configuration_return[4] = 0
        case "6":
            ser_configuration[4] = "6"
            ser_configuration_return[4] = 1
        case "7":
            ser_configuration[4] = "7"
            ser_configuration_return[4] = 2
        //case 8 bits - 1 byte
        default:
            ser_configuration[4] = "8"
            ser_configuration_return[4] = 3
        }
        flag = true
        update_flag = false
    }
}


