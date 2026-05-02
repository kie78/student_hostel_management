# Three-User Route Map And Guardrails

## Scope
This app module currently supports only:
- Student
- Landlord
- University

Admin functionality is intentionally out of scope and should be implemented in a separate folder/module.

## Active Entry Flow
- App start: Role selection gateway
- Role selection: Student, Landlord, University only
- Login routes into one of the 3 dashboards

## Role Route Map
- Student
  - Register -> Login -> Hostel List -> Room Details -> Booking -> Booking Success
- Landlord
  - Login -> Landlord Dashboard
  - Landlord Dashboard -> Add Hostel -> Add Room
  - Landlord Dashboard -> Bookings
  - Landlord Dashboard -> Notifications/Profile
- University
  - Login -> University Dashboard
  - University Dashboard -> Register Landlord
  - University Dashboard -> University Profile

## Guardrails
- Do not add Admin back into the role enum in this module.
- Do not import any admin screens into this module.
- Keep role switches exhaustive for only the 3 active roles.
- If admin work starts, place it in a separate module/folder and wire integration later.

## API Focus
- Student endpoints: register, universities, hostels
- Landlord endpoints: hostels, rooms, notifications, reset-password, logout
- University endpoints: landlords, students, hostels, register-landlord, reset-password, logout

## Merge Checklist
Before merging any role/auth changes:
1. Run analyzer.
2. Verify role selector still shows exactly 3 roles.
3. Verify login switch routes only to the 3 active dashboards.
4. Verify no admin imports exist under lib/screens.
