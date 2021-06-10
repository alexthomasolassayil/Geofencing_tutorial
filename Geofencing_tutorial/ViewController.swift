//
//  ViewController.swift
//  Geofencing_tutorial
//
//  Created by Alex on 08/06/21.
//

import UIKit
import CoreLocation
import UserNotifications

enum GeofenceEvent {
    case didEnter
    case didExit
}
class ViewController: UIViewController {

    let locationManager = CLLocationManager()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        locationManager.delegate = self
        locationManager.requestAlwaysAuthorization()
        registerNotifications()
    }
    override func viewDidAppear(_ animated: Bool) {
        UIApplication.shared.applicationIconBadgeNumber = 0
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        UNUserNotificationCenter.current().removeAllDeliveredNotifications()
    }
    private func registerNotifications() {
        let options: UNAuthorizationOptions = [.badge, .sound, .alert]
        UNUserNotificationCenter.current()
            .requestAuthorization(options: options) { success, error in
                if let error = error {
                    print("Error: \(error)")
                }
            }
    }
    private func getRegionForMonitoring() -> CLCircularRegion {
        let someCoordinate = CLLocationCoordinate2DMake(37.33233141, -122.0312186)
        
        let region = CLCircularRegion(center: someCoordinate,
                                      radius: min(200, locationManager.maximumRegionMonitoringDistance),
                                      identifier: "someCoordinateIdentifier")
        
        region.notifyOnEntry = true
        region.notifyOnExit = true
        return region
    }
    @IBAction func startMonitoringButtonAction(_ sender: Any) {
        startMonitoring(region: getRegionForMonitoring())
    }
    func startMonitoring(region: CLCircularRegion) {
        if !CLLocationManager.isMonitoringAvailable(for: CLCircularRegion.self) {
            showAlert(with: "Error", message: "Geofencing is not supported on this device!")
            return
        }
        
        if locationManager.authorizationStatus != .authorizedAlways {
            let message = """
            Your geotification is saved but will only be activated once you grant
            Always permission to access the device location.
        """
            showAlert(with: "Warning", message: message)
        }
        
        locationManager.startMonitoring(for: region)
        showAlert(message: "Started monitoring region")
    }
    private func showAlert(with title: String = "Geofencing", message: String) {
        let alert = UIAlertController(title: title,
                                      message: message,
                                      preferredStyle: .alert)
        let okAction = UIAlertAction(title: "Ok",
                                     style: .default,
                                     handler: nil)
        alert.addAction(okAction)
        self.present(alert, animated: true, completion: nil)
    }
    
    func handleGeofenceEvent(with region: CLRegion, event: GeofenceEvent) {
        // Show an alert if application is active
        if UIApplication.shared.applicationState == .active {
            var message = region.identifier
            message += event == .didEnter ? "\nEntered" : "\nExited"
            showAlert(message: message)
        } else {
            // Otherwise present a local notification
            let notificationContent = UNMutableNotificationContent()
            notificationContent.body = event == .didEnter ? "Geofence enter triggered!" : "Geofence exit triggered!"
            notificationContent.sound = UNNotificationSound.default
            notificationContent.badge = UIApplication.shared.applicationIconBadgeNumber + 1 as NSNumber
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 0.5, repeats: false)
            let request = UNNotificationRequest(identifier: "geofenceId",
                                                content: notificationContent,
                                                trigger: trigger)
            UNUserNotificationCenter.current().add(request) { error in
                if let error = error {
                    print("Error: \(error)")
                }
            }
        }
    }
}

// MARK: CLLocationManagerDelegate
extension ViewController: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        handleGeofenceEvent(with: region, event: .didEnter)
    }
    func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
        handleGeofenceEvent(with: region, event: .didExit)
    }
    func locationManager(_ manager: CLLocationManager, monitoringDidFailFor region: CLRegion?, withError error: Error) {
        print("Monitoring failed for region with identifier: \(region!.identifier)")
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location Manager failed with the following error: \(error)")
    }
}
