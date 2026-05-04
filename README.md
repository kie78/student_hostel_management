# Student Hostel Management

Student Hostel Management is a Flutter mobile app for hostel discovery, booking, and role-based management across three user types:

- Student
- Landlord
- University

The app uses Clerk for authentication and a REST API hosted at `https://hostel-booking-api.onrender.com/api` for application data.

## Current App Flow

- App launch opens a role-selection gateway.
- Supported roles are Student, Landlord, and University only.
- Authenticated users are routed based on the `role` value in Clerk public metadata.
- Student users can browse hostels, inspect rooms, and place bookings.
- Landlords can manage hostels, rooms, and bookings.
- Universities can manage landlords and view university-level data.

Admin is intentionally out of scope for this mobile app.

## Tech Stack

- Flutter
- Dart
- Clerk Flutter SDK for authentication
- Dio for API requests
- Provider for state management
- Shared Preferences for local persistence
- Image Picker for uploads

## Project Structure

```text
lib/
	main.dart
	screens/
		bookings/
		landlord/
		university/
		login_screen.dart
		register_screen.dart
		reset_password_screen.dart
		role_select_screen.dart
	services/
		api_client.dart
		api_service.dart
		auth_service.dart
		clerk_config.dart
```

## Setup

### Prerequisites

- Flutter SDK installed
- Android Studio or a connected Android device
- A Clerk project with a valid publishable key

### Install dependencies

```bash
flutter pub get
```

### Configure authentication

The app currently reads the Clerk publishable key from source code.

Update the key in these files before running against your own Clerk instance:

- `lib/main.dart`
- `lib/services/clerk_config.dart`

Use a publishable key only. Do not place a Clerk secret key in the Flutter app.

### Run the app

```bash
flutter run
```

## Backend Integration Notes

- Base API URL: `https://hostel-booking-api.onrender.com/api`
- The Dio client injects a fresh Clerk JWT before protected requests.
- Clerk session tokens are short-lived, so token refresh is handled per request.
- Public student registration and university lookup are available through the mobile client.

## Main Functional Areas

### Student

- Register and sign in
- View available universities
- Browse hostels and room details
- Create bookings and view booking status
- View notifications

### Landlord

- Sign in with landlord credentials or code-based flow
- Manage hostels and rooms
- Review landlord bookings

### University

- Sign in to the university dashboard
- Register landlords
- View landlords, students, and hostels
- Access university profile data

## Quality Checks

Run static analysis before merging changes:

```bash
flutter analyze
```

## Notes

- The app entry point is the role-selection startup gate, not direct registration.
- Role handling in this module should remain limited to Student, Landlord, and University.
- Admin work should live in a separate module or app.
