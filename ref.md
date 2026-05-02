## Hostel Booking Project
- This is a backend-api aimed to help students get accomodation for the University stay. The Primary users of this system are The university, LandLord, the Students and the General Admin.

### Functional Requirements
- The Landlords regsiter with the university that they will be having students as tenants ; they receive a verfication code.
- The Land Lord signs in and uploads the hostel and rooms with name, description, location, image, price.
- The Student then can get this app register and login and see the avaliable rooms and receive or book and make payments using mobile money or contact the landlord with available details for inquiry.
- On payment user should be notified
- Once a room is booked it should reflect as unavaliable in the system
- Student should be able to terminate their stay.

### The LandLord
- User will sign in with temporary credentials that is landlord code, username and password. (User is created by the University and give temp credentials )
- User can then reset their password on first sign in
- For the sign in it will be username or landlord code and password.
- User should be able to logout.
- User should be able to create and upload Hostels using the following hostel_name, location, room_number, room_type(single self contained, double self_contained), images, price, whatsapp_number to contact and for calls booking and payments.
- User will be able to receive notifications of the booking , payments and termination actions that are performed by the user.

### Student
- User signs up with registration number , surname, university, other names, gender (male, female), student_email
- User logins in with student email and passsword
- User should be able to login and logout.
- User should be able to view all hostels in under their university whether booked or not
- User should be able to get all hostels and also get hostel by ID (all hostel details)
- User should be able to either make a partial percentage payment or a full payment.
- User should be receive notifications for bookings payments and termination
- User can only termiate after booking
- The payment options are mtn mobile money and airtel mobile money.

### University
- User is onboarded by the General Admin using the following details university_name, location, type (Governmentm private), email, password.
- User gets temporary login credentials in the email (email and password)
- User resets their password after logging in for their first time
- User can login and logout.
- User can register landlords ( full_name, gender, NIN, marital status, ownership documents).
- User can register landlords and they get an email after being registered.
- User can view all the students in the their university
- User can view all hostels in / around their university according to the system.
- User can view all landlords in the system tagged to his university.

### NB
- When a student user is signing up they have to choose a university that is already in the system.
- By default the landlords that a university add are under his university according to the system.
