# iOS Code Signing: Complete Guide

This is a detailed guide for configuring code signing for Flutter iOS apps.

## **Overview**

Code signing is Apple's security mechanism that proves your app comes from a verified developer. This is **required** to run apps on physical iPhone devices and is a **one-time setup per device**.

**Important**: This is only needed for **physical iPhone devices**. iOS Simulator doesn't require code signing.

---

## **Part 1: Apple ID in Xcode (One-time setup)**

### **Step 1: Open Xcode Accounts**
```
Xcode → Settings (or Preferences on older versions)
```

### **Step 2: Add Apple ID**
- Click on **"Accounts"** tab (at the top)
- Click **"+"** button (bottom left)
- Select **"Apple ID"**
- Enter your Apple ID (same as iCloud/App Store)
- Enter password

### **Step 3: Verify Team**
- Your Apple ID should now appear in the list
- Under **"Team"** it should show **"(Personal Team)"**
- This gives you **free developer certificates**

---

## **Part 2: Configure Flutter Project**

### **Step 4: Open iOS Project**
```bash
# In your Flutter project folder:
open ios/Runner.xcworkspace
```
**Important:** Open `.xcworkspace` (NOT `.xcodeproj`)

### **Step 5: Select Target**
- **Left column:** Click on **"Runner"** (blue project icon at the top)
- **Under TARGETS:** Click on **"Runner"** (white app icon)
- **Tabs at top:** Click on **"Signing & Capabilities"**

---

## **Part 3: Code Signing Settings**

### **Step 6: Enable Automatic Signing**
- Check **"Automatically manage signing"**
- This lets Xcode handle certificates automatically

### **Step 7: Select Team**
- **Team dropdown:** Select your Apple ID (Personal Team)
- If it's grayed out/inactive → add Apple ID first (Part 1)

### **Step 8: Bundle Identifier**
**Default:** `com.example.idrott_app`

**Problem:** May already be "taken" or cause conflicts

**Solution:** Change to something unique:
```
com.yourname.idrott_app
com.[yourname].idrott_app
se.[yourname].idrott_app
```

**Format rule:** 
- Reverse domain notation
- Only lowercase letters, numbers, dots
- Must be globally unique

### **Step 9: Verify Status**
After correct configuration you should see:
- **Team:** "[Your name] (Personal Team)" 
- **Provisioning Profile:** "Xcode Managed Profile"
- **Signing Certificate:** "Apple Development: your@email.com"

---

## **Part 4: Test Configuration**

### **Step 10: First Build**
```bash
flutter run -d "iPhone-ID"
```

**Expected prompts:**
1. **macOS password:** Enter to access keychain
2. **"Allow access":** Click "Always Allow"
3. **Trust Computer:** On iPhone, trust the computer

### **Step 11: iPhone Developer Mode**
- **iPhone:** Settings → Privacy & Security → Developer Mode
- **Enable:** Turn ON Developer Mode
- **Restart:** iPhone will restart automatically

---

## **Common Problems & Solutions**

### **"No Apple ID added"**
**Solution:** Go back to Part 1, add Apple ID

### **"Bundle ID already taken"** 
**Solution:** Change Bundle Identifier (Step 8)

### **"No profiles found"**
**Solution:** 
- Check that "Automatically manage signing" is checked
- Select correct Team

### **"Developer Mode not found"**
**Solution:**
- Connect iPhone with USB first
- Run any Xcode build to "trigger" Developer Mode

### **"Unable to install app"**
**Solution:**
- Try changing Bundle ID (add number: `com.yourname.idrott_app2`)
- Run `flutter clean` then `flutter run` again

### **"Provisioning profile expired"**
**Solution:**
- **Free Apple ID:** Normal after 7 days
- Run `flutter run` again to renew certificate

---

## **Free Apple ID Limitations**

### **7-day rule:**
- **Problem:** Apps stop working after 7 days
- **Solution:** Run `flutter run` again to renew
- **Alternative:** Pay $99/year for Apple Developer Program

### **Device limit:**
- **Free:** Max 10 devices per year
- **Paid:** Unlimited devices

---

## **Quick Checklist**

```
□ Apple ID added in Xcode → Accounts
□ Opened ios/Runner.xcworkspace (not .xcodeproj)
□ Selected Runner under TARGETS
□ Signing & Capabilities tab open
□ Automatically manage signing checked
□ Team: Personal Team selected
□ Bundle Identifier: Unique ID set
□ iPhone: Developer Mode enabled
□ iPhone: Lightning/USB-C cable connected
□ macOS: Allow keychain access
```

---

## **After this works:**

```bash
flutter run -d "iPhone-ID"
```

**Perfect for development!**

---

## **Related Guides**

- **[DEVICE_SETUP.md](DEVICE_SETUP.md)** - Complete device setup guide
- **[README.md](README.md)** - Main project documentation

---

## **Pro Tips**

1. **Keep your iPhone connected via cable** during development (more stable)
2. **Run `flutter run` once per week** to renew certificates (free Apple ID)
3. **Use the same Bundle ID** consistently to avoid certificate issues
4. **Consider paid Apple Developer Account** ($99/year) for production apps

---

**Note:** This setup is only needed once per device. After initial configuration, you can simply run `flutter run -d "iPhone-ID"` for daily development!
