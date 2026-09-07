# BBS Gold - iOS Deployment & App Review Guide

This document is for the iOS publishing team. It outlines the exact steps to pull the latest fixed Flutter repository, run it on a physical iPhone, and capture the screen recording required to pass Apple App Review (Guideline 2.1).

## Prerequisites (macOS)
1. **Flutter SDK** installed and added to your PATH.
2. **Xcode** installed with the latest iOS SDK.
3. A **Physical iPhone** connected to your Mac via USB cable (for Apple's physical device recording requirement).

---

## Step 1: Clone the Repository
Once you have accepted the GitHub invitation, open your Terminal on your Mac and run the following commands to create a clean folder and pull the codebase:

```bash
# Create a dedicated directory
mkdir BBS_Gold_Project
cd BBS_Gold_Project

# Clone the repository (replace the URL with the actual repo link)
git clone <YOUR_GITHUB_REPO_URL> .
```

---

## Step 2: Install Dependencies
Ensure you are in the root of the Flutter project (`BBS_Gold_Project`). Execute the following commands to get the Flutter dependencies and build the iOS CocoaPods locally:

```bash
flutter clean
flutter pub get

# 🚨 CRITICAL: The app uses Swift Package Manager (SPM).
# You MUST run this command to inject the SPM dependencies into Xcode automatically:
flutter build ios --config-only
```

---

## Step 3: Build & Test on Physical iPhone (Apple Review Requirement)
Apple App Review has explicitly requested a **physical-device screen recording** showing the complete working app flow because of a previous launch bug (which is now completely fixed in this codebase). 

To ensure the recording perfectly replicates the production environment, you must build the app in **Release Mode**.

1. Open Xcode by running:
   ```bash
   open ios/Runner.xcworkspace
   ```
2. In Xcode, look at the top device selector bar and select your **physically connected iPhone** (Do NOT select a Simulator).
3. In the top Menu Bar, go to **Product > Scheme > Edit Scheme**.
4. Select the **Run** tab on the left sidebar.
5. Change the **Build Configuration** dropdown from *Debug* to **Release**. Close the window.
6. Press the **Run (Play)** button in the top left of Xcode to install and launch the app exclusively on the physical iPhone.

---

## Step 4: Capture the Screen Recording
Once the app successfully opens on the physical iPhone without crashing, immediately start recording the screen.

1. Swipe down on your iPhone to open the **Control Center** and tap the **Screen Recording** icon.
2. Slowly and clearly navigate through the following exact flows Apple requested:
   - **App Launch**
   - **Login**
   - **Dashboard**
   - **Stock/Catalogue (Product list)**
   - **Product details** (Tap on a product)
   - **Orders / Order History**
   - **Profile**
   - **Logout**
   - **Registration and account deletion flow** (if available)
3. Stop the screen recording and save the `.mp4` / `.mov` file to your Mac.

---

## Step 5: Submission to Apple
1. **Archive:** In Xcode, ensure your device target is set to "Any iOS Device (arm64)", then go to **Product > Archive**.
2. Upload the new stable build to **TestFlight / App Store Connect**.
3. **Resolution Center:** Go to the App Store Connect page for BBS Gold. In the active Resolution Center thread regarding Guidelines 2.1, **attach the physical iPhone screen recording video** you just created and submit your reply indicating the launch crash is fixed.
