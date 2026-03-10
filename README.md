<div align="center">
  <img src="assets/images/app_logo.png" alt="Servino Logo" width="150" height="auto" />
  <h1>🚀 Servino Client App</h1>
  <p><b>A Next-Generation, Secure, & Feature-Rich Service Booking Platform</b></p>
  
  <p>
    <a href="https://flutter.dev"><img src="https://img.shields.io/badge/Flutter-%2302569B.svg?style=for-the-badge&logo=flutter&logoColor=white" alt="Flutter" /></a>
    <a href="https://dart.dev"><img src="https://img.shields.io/badge/Dart-%230175C2.svg?style=for-the-badge&logo=dart&logoColor=white" alt="Dart" /></a>
    <img src="https://img.shields.io/badge/Clean_Architecture-Awesome-orange?style=for-the-badge" alt="Clean Architecture" />
    <img src="https://img.shields.io/badge/Security-A+-success?style=for-the-badge" alt="Security Rating" />
  </p>
</div>

---

## 📖 Overview

**Servino Client** is a comprehensive, multi-platform Flutter application tailored to deliver a seamless, intuitive, and highly secure service booking experience. Designed with cutting-edge mobile development practices, **Clean Architecture**, and an immaculate User Interface, it effortlessly connects users with professional service providers. 

Whether scheduling a future appointment, locating a nearby professional on the interactive map, or conducting a real-time consultation via high-quality video call, Servino sets the absolute gold standard for on-demand service applications.

---

## ✨ Outstanding Features

### 🛠️ Core Functionality
- **Dynamic Service Discovery:** Easily browse categories, filter specific services, and save favorite providers for quick access.
- **Advanced Booking System:** Intuitive scheduling, real-time tracking, and sophisticated management of upcoming and past appointments.
- **Interactive Maps & Geolocation:** Discover nearby providers seamlessly using `flutter_map` coupled with real-time location tracking via `Geolocator`.
- **Intelligent Rating Engine:** A built-in robust rating and review ecosystem (`flutter_rating_bar`) to ensure high-quality service standards.

### 💬 Real-Time Communication
- **Instant Interactive Messaging:** Fluid text chat experiences powered by `chat_bubbles`, `flutter_chat_types`, and Firebase Firestore.
- **High-Fidelity Audio/Video Calls:** Enterprise-grade rich communication powered by `ZegoCloud` with advanced signaling support.
- **Smart Push Notifications:** Instant, reliable updates and alerts powered by `Firebase Cloud Messaging (FCM)` and `flutter_local_notifications`.
- **Audio Recording & Playback:** Send rich voice notes utilizing `record`, `audioplayers`, and `just_audio`.

### 🔐 Uncompromised Security
- **SSL Certificate Pinning:** Employs `http_certificate_pinning` to strictly protect against Man-In-The-Middle (MITM) attacks and packet sniffing.
- **Jailbreak & Root Detection:** Completely prevents app execution on compromised or tampered devices using `jailbreak_root_detection`.
- **App Device Integrity Verification:** Deeply validates app authenticity and instantly blocks unauthorized modifications via `app_device_integrity`.
- **Versatile Authentication:** Supports traditional JWT-based secure flows alongside decentralized `Google Sign-In`.
- **Encrypted Sandboxed Storage:** Sensitive user preferences, session tokens, and data are securely encrypted locally using `Flutter Secure Storage`.

### 🎨 Beautiful UI & Flawless UX
- **Stunning Fluid Animations:** Eye-catching micro-interactions and screen transitions utilizing `Lottie` and `animate_do`.
- **Adaptive Theming Engine:** Intelligent, system-aware Light & Dark mode automatic switching.
- **Pixel-Perfect Responsiveness:** UI meticulously scales across diverse screen sizes effortlessly using `flutter_screenutil`.
- **Global Localization (i18n):** Full Multi-language capability alongside native RTL (Right-to-Left) support powered by `Easy Localization`.
- **Elegant Loaders:** Smooth perceived performance using skeleton screens via `shimmer`.

### 💳 Monetization & Payments
- **Secure Digital Payments:** Native IAP (In-App Purchases) integration for seamless transaction handling.
- **Targeted Mobile Ads:** Intelligently embedded `Google Mobile Ads` for optimized ad revenue generation.

---

## 📸 App Previews

<div align="center">
  <img src="assets/images/onboarding1.png" alt="Onboarding 1" width="230" style="margin: 10px; border-radius: 12px; box-shadow: 0px 4px 10px rgba(0,0,0,0.1);"/>
  <img src="assets/images/onboarding2.png" alt="Onboarding 2" width="230" style="margin: 10px; border-radius: 12px; box-shadow: 0px 4px 10px rgba(0,0,0,0.1);"/>
  <img src="assets/images/onboarding3.png" alt="Onboarding 3" width="230" style="margin: 10px; border-radius: 12px; box-shadow: 0px 4px 10px rgba(0,0,0,0.1);"/>
</div>

> *A beautifully crafted onboarding experience setting the tone for the Servino mobile journey.*

---

## 🏗️ Technical Architecture

<details open>
<summary><b>View Architecture Blueprint</b></summary>
<br>

Servino Client is strictly built following **Clean Architecture** conventions layered over the **MVVM (Model-View-ViewModel)** design pattern. This ensures massive testability, predictable maintainability, and enterprise-level scalability.

```text
lib/
 ┣ core/              # Global Utilities, Navigation Routing, Themes, HTTP Interceptors
 ┣ features/          # App feature modules (Auth, Home, Booking, Chat, Profile, etc.)
 ┃  ┣ data/           # Repositories Impl, Remote APIs, Local Databases (Hive), Models
 ┃  ┣ domain/         # Core Business Logic: Use Cases, Entities, Repository Interfaces
 ┃  ┗ presentation/   # UI Screens, Widgets, State Management (Providers), ViewModels
 ┣ firebase_options.dart    # Firebase Auto-Generated configurations
 ┣ injection_container.dart # Global Dependency Injection (Service Locator via 'get_it')
 ┗ main.dart          # Main application entry point & initialization runner
```
</details>

### 🔥 Tech Stack Breakdown
- **Architecture & DI:** Clean Architecture, `provider`, `get_it`, `dartz`, `equatable`
- **Networking:** `dio`, `pretty_dio_logger`, `internet_connection_checker`
- **Local Persistence Database:** `hive`, `hive_flutter`, `shared_preferences`
- **Media & Camera:** `image_picker`, `video_player`, `chewie`, `flutter_svg`, `cached_network_image`
- **Firebase Infrastructure:** `firebase_core`, `firebase_messaging`, `cloud_firestore`

---

## 🚀 Getting Started

Follow these instructions to get a copy of the project up and running locally for development and comprehensive testing purposes.

### Prerequisites

Please ensure your development environment is fully setup:
- [Flutter SDK](https://flutter.dev/docs/get-started/install) (`^3.11.0-200.1.beta` or higher)
- [Dart SDK](https://dart.dev/get-dart)
- Android Studio / VS Code / Xcode
- A valid Firebase Project (You must inject your `google-services.json` and `GoogleService-Info.plist` files into their respective platform folders).

### Installation & Launch Steps

1. **Clone the repository securely:**
   ```bash
   git clone https://github.com/waleedghubara/Servino.git
   ```

2. **Navigate to the Client Application Directory:**
   ```bash
   cd servino_client
   ```

3. **Install & Sync Platform Dependencies:**
   ```bash
   flutter pub get
   ```

4. **Verify Android Configurations (If necessary):**
   ```bash
   cd android && ./gradlew clean && cd ..
   ```

5. **Run the Application:**
   ```bash
   flutter run
   ```

---

## 🛡️ Enterprise Security Statement
Servino prioritizes user data protection and application integrity above all else. By aggressively implementing SSL pinning at the network layer, hardened JWT lifecycle management, dynamic Root/Jailbreak detection, and on-device Integrity Verification, the application creates a virtually impenetrable secure sandbox environment that defends against reverse engineering, malicious code injection, and persistent data interception.

---

## 📄 Licensing & Rights
This software application is distributed and protected under the terms of the [MIT License](LICENSE) - see the LICENSE file for more exhaustive details.

---
<div align="center">
  <b>Architected & Built with ❤️ by <a href="https://github.com/waleedghubara">Waleed Ghubara</a></b><br>
  For professional inquiries, collaborations, or bug reporting, please reach out via GitHub.
</div>
