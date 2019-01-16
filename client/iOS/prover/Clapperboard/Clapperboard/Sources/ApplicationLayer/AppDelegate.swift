import Foundation
import UIKit
import Common

@UIApplicationMain
public class AppDelegate: BaseAppDelegate {

    override public func application(_ application: UIApplication, willFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {

        //SharedSettings.shared.appVersion = .new
        SharedSettings.shared.iosApp = "clapperboard"

        SharedSettings.shared.guidePages = [
            GuidePage(image: #imageLiteral(resourceName: "guide_1"), title: "Sign up or sign in to your account"),
            GuidePage(image: #imageLiteral(resourceName: "guide_2"), title: "Recharge your balance if needed"),
            GuidePage(image: #imageLiteral(resourceName: "guide_3"), title: "Enter your explanatory comment (it will be saved in blockchain)"),
            GuidePage(image: #imageLiteral(resourceName: "guide_4"), title: "Start the QR code generation process (takes up to 1 minute)"),
            GuidePage(image: #imageLiteral(resourceName: "guide_5"), title: "Show the QR code in close-up to any digital camera during filming/photographing"),
            GuidePage(image: #imageLiteral(resourceName: "guide_6"), title: "Continue filming"),
            GuidePage(image: #imageLiteral(resourceName: "guide_7"), title: "Finish filming and keep the file"),
            GuidePage(image: #imageLiteral(resourceName: "guide_8"), title: "For authentication, upload the file to the _product.prover.io_ validation service")
        ]

        SharedSettings.shared.shouldAskForAccessToCamera = false
        SharedSettings.shared.shouldAskForAccessToMicrophone = false
        SharedSettings.shared.shouldAskForAccessToPhotosGallery = false

        return super.application(application, willFinishLaunchingWithOptions: launchOptions)
    }
}