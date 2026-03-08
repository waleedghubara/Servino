<div align="center">
  <img src="assets/images/app_logo.png" alt="Servino Logo" width="150" height="auto" />
  <h1>Servino Client</h1>
  <p>A comprehensive Flutter application connecting users with service providers seamlessly.</p>

  <p>
    <a href="https://flutter.dev"><img src="https://img.shields.io/badge/Flutter-%2302569B.svg?logo=flutter&logoColor=white" alt="Flutter" /></a>
    <a href="https://dart.dev"><img src="https://img.shields.io/badge/Dart-%230175C2.svg?logo=dart&logoColor=white" alt="Dart" /></a>
  </p>
</div>

---

## 📖 Project Description

**Servino Client** is a feature-rich, multi-platform Flutter application designed to provide users with a seamless and intuitive service booking experience. Whether you need to find a professional, schedule an appointment, or communicate with a service provider, Servino has you covered. Built with Clean Architecture principles, this app ensures scalability, robust performance, and high code quality.

## ✨ Key Features

- **🛡️ Secure Authentication**: Supports traditional login methods and `Google Sign-In`.
- **🔍 Browse & Search**: Easily discover categories, services, and favorite providers.
- **📅 Booking & Scheduling**: Intuitive booking management for all your service needs.
- **💬 Real-Time Chat & Calls**: Built-in chat and full audio/video calling powered by `ZegoCloud`.
- **🔔 Smart Notifications**: Stay updated with push notifications through `Firebase Cloud Messaging (FCM)`.
- **💳 Secure Payments**: Integrated payment processing and in-app purchases.
- **🗺️ Interactive Maps**: Location-based features using Maps and `Geolocator`.
- **🌍 Multi-language & Localization**: Fully localizable with RTL support (`Easy Localization`).
- **🎨 Theming**: Automatic Light and Dark mode switching to match user preferences.
- **🔒 Advanced Security**: Includes SSL Pinning, Root/Jailbreak detection, and App Device Integrity checks to ensure user data safety.

## 🛠️ Tech Stack & Architecture

- **Framework**: [Flutter](https://flutter.dev/) (Dart)
- **Architecture**: Clean Architecture & MVVM
- **State Management**: `Provider` & Dependency Injection (`get_it`)
- **Networking**: `Dio` with interceptors and Pretty Logger
- **Local Storage**: `Hive` & `Flutter Secure Storage`
- **Real-time Comms**: `ZegoCloud` & `Firebase`
- **Location & Maps**: `flutter_map`

## 🚀 Getting Started

### Prerequisites

- Flutter SDK `^3.11.0-200.1.beta` or higher
- Dart SDK
- Android Studio / Xcode

### Installation

1. **Clone the repository**:
   ```bash
   git clone https://github.com/waleedghubara/Servino.git
   ```

2. **Navigate to the project directory**:
   ```bash
   cd servino_client
   ```

3. **Install dependencies**:
   ```bash
   flutter pub get
   ```

4. **Run the app**:
   ```bash
   flutter run
   ```

## 🔐 Security Information

This application employs industry-standard security measures, restricting its execution on jailbroken or rooted devices, and verifying SSL certificates to prevent man-in-the-middle attacks.

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---
<div align="center">
  <b>Developed by <a href="https://github.com/waleedghubara">Waleed Ghubara</a></b>
</div>
