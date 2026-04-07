# 💸 Smart Expense Tracker

![Smart Expense Tracker Banner](https://img.shields.io/badge/Smart%20Expense%20Tracker-Flutter-blue?style=for-the-badge&logo=flutter)
![State Management](https://img.shields.io/badge/State-ValueNotifier-orange?style=for-the-badge)
![Database](https://img.shields.io/badge/Database-SQLite-lightgrey?style=for-the-badge&logo=sqlite)
![Theme](https://img.shields.io/badge/Theme-Dark%20%2F%20Light-black?style=for-the-badge)

A beautifully crafted, offline-first personal finance management application built with **Flutter**. Track your daily transactions, monitor your monthly budget, and gain insights into your spending habits through elegant data visualizations.

---

## ✨ Features

- **📊 Dashboard & Analytics**: Get a clear overview of your income and expenses with stunning charts powered by `fl_chart`.
- **💰 Transaction Management**: Easily add, edit, search, and delete your daily transactions (Income & Expenses).
- **🏷️ Smart Categories**: Organize your spending with visually distinct, customizable categories (complete with material icons and colors).
- **🎯 Budget Control**: Set monthly spending limits and monitor your progress automatically.
- **🌓 Dark/Light Mode**: Full support for seamless system and manual theme toggling, ensuring accessibility and comfort day and night.
- **📴 Offline First**: 100% functional without an internet connection using local SQLite database (`sqflite`). No data leaves your device.
- **🧭 Responsive UI**: Beautifully adapts to all screen sizes using the `sizer` package.

---

## 🛠️ Technology Stack

| Technology | Package | Purpose |
| ---------- | ------- | ------- |
| **Framework** | Flutter (`sdk: flutter`) | Core UI framework |
| **Local Storage** | [`sqflite`](https://pub.dev/packages/sqflite) | Offline relational database for transactions and budgets |
| **Preferences** | [`shared_preferences`](https://pub.dev/packages/shared_preferences) | Persistent storage for app settings (e.g., Theme mode) |
| **Data Viz** | [`fl_chart`](https://pub.dev/packages/fl_chart) | Rich, customizable charts for the analytics screen |
| **Responsive UI** | [`sizer`](https://pub.dev/packages/sizer) | Percentage-based UI sizing for cross-device consistency |
| **Typography** | [`google_fonts`](https://pub.dev/packages/google_fonts) | Modern, high-quality typography |

---

## 📂 Project Structure

```text
lib/
├── core/             # Application-wide constants, utilities, and exports
├── database/         # SQLite DB Helper, Migrations, and CRUD operations
├── models/           # Data models (Transaction, Category, Budget)
├── presentation/     # UI Layer: Screens (Home, Analytics, Add Expense, Settings, etc)
├── routes/           # App navigation mapping
├── service/          # Config Services (Theme/Settings)
├── theme/            # App styles, Light & Dark mode configurations
├── widgets/          # Reusable custom UI components 
└── main.dart         # Entry point and provider initialization
```

---

## 🚀 Getting Started

Follow these instructions to get a copy of the project up and running on your local machine.

### Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) (`^3.9.0` or higher)
- Android Studio / Xcode (for device emulation)
- A connected physical device or emulator

### Installation

1. **Clone the repository:**
   ```bash
   git clone https://github.com/your-username/smartexpensetracker.git
   cd smartexpensetracker
   ```

2. **Install Dependencies:**
   ```bash
   flutter pub get
   ```

3. **Run the App:**
   ```bash
   flutter run
   ```

---


<p align="center">
  <em>Taking control of your finances, one transaction at a time.</em>
</p>
