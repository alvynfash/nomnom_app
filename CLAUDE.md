# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

NomNom is a Flutter-based meal planning SaaS application focused on personal and family meal organization. The app helps users manage recipes, create reusable meal plans, generate grocery lists, and collaborate with family members.

## Key Architecture

- **Flutter Framework**: Cross-platform mobile app development
- **Material Design**: Uses Flutter's Material components
- **Food-inspired Design System**: Custom color palette with warm, culinary-focused aesthetics
- **Family-centric Model**: Built around shared family entities (recipes, plans, grocery lists)

## Development Commands

### Flutter Development
```bash
# Run on connected device/emulator
flutter run

# Build for specific platforms
flutter build apk          # Android APK
flutter build appbundle   # Android App Bundle
flutter build ios         # iOS
flutter build web         # Web

# Test commands
flutter test              # Run all tests
flutter test test/unit/   # Run specific test directory
flutter test --coverage   # Run tests with coverage

# Code analysis
flutter analyze           # Static code analysis
flutter format .          # Format code

# Dependency management
flutter pub get           # Get dependencies
flutter pub upgrade       # Upgrade dependencies
```

### Linting and Formatting
```bash
# Run linting (configured via flutter_lints)
flutter analyze

# Format code
flutter format .
```

## Project Structure

- `lib/`: Main Dart source code
- `android/`: Android platform-specific code
- `ios/`: iOS platform-specific code
- `web/`: Web platform-specific code
- `linux/`, `macos/`, `windows/`: Desktop platform support
- `test/`: Test files (to be created)

## Design System

Refer to `design-system.md` for comprehensive design guidelines:
- Warm, food-inspired color palette (cinnamon brown, cream, herb green)
- Mobile-first responsive design
- Dark mode support
- Consistent typography and spacing

## Key Features (from PRD.md)

- Recipe management with ingredients and instructions
- 4-week meal plan templates with configurable meal slots
- Automated grocery list generation with weekly splits
- Family sharing and collaboration features
- Community recipe discovery and sharing

## Development Notes

- This is a new Flutter project starting with basic "Hello World" structure
- Follow the design system guidelines for consistent UI implementation
- Implement family sharing features as core functionality
- Focus on mobile-first responsive design
- Use Flutter's built-in testing framework for unit and widget tests