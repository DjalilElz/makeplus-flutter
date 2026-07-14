# MakePlus 2025 - Flutter Event Management App

A comprehensive event management application built with **Flutter**, **Django REST Framework**, and **Supabase**, featuring role-based access control and real-time updates.

## 📱 Features

### Four User Roles

1. **Organisation - Gestion des Salles (Organizer)**
   - Event dashboard with real-time statistics
   - Room and session management (CRUD)
   - QR code scanning for room access verification
   - Announcement creation and broadcasting
   - Participant tracking and analytics
   - Questions management

2. **Organisation - Contrôleur de Badge (Badge Controller)**
   - Badge scanning and validation
   - Participant verification (accept/reject)
   - Entry logging and statistics
   - Program viewing
   - Real-time access stats

3. **Participants**
   - Event program and schedule viewing
   - Personal QR badge display
   - Session details and live streaming
   - Exhibitor browsing and favorites
   - Event guide and maps
   - Q&A participation

4. **Exposants (Exhibitors)**
   - Booth management
   - Visitor QR scanning
   - Interested participants tracking
   - Booth statistics and analytics
   - Push notifications to subscribers

## 🏗️ Architecture

### Tech Stack

- **Frontend**: Flutter (Dart)
- **Backend**: Django REST Framework
- **Database**: Supabase (PostgreSQL)
- **State Management**: BLoC Pattern
- **Authentication**: Supabase Auth

### Project Structure

```
lib/
├── core/                      # Core utilities and constants
│   ├── constants/
│   │   ├── api_constants.dart
│   │   ├── app_constants.dart
│   │   ├── routes.dart
│   │   └── theme/
│   │       ├── app_colors.dart
│   │       └── app_theme.dart
│   └── utils/
│
├── data/                      # Data layer
│   ├── models/               # Data models
│   ├── repositories/         # Repository pattern
│   └── services/             # API services
│       ├── supabase_auth_service.dart
│       ├── django_api_service.dart
│       └── qr_code_service.dart
│
├── logic/                    # Business logic (BLoC)
│   ├── authentication/
│   ├── organizer/
│   ├── controller/
│   ├── participant/
│   └── exhibitor/
│
└── presentation/             # UI layer
    ├── screens/             # All app screens
    │   ├── splash/
    │   ├── auth/
    │   ├── organizer/
    │   ├── controller/
    │   ├── participant/
    │   ├── exhibitor/
    │   └── shared/
    ├── widgets/             # Reusable widgets
    │   ├── common/
    │   ├── navigation/
    │   ├── qr/
    │   └── cards/
    └── router/              # Navigation
```

## 🚀 Getting Started

### Prerequisites

- Flutter SDK (>=3.0.0)
- Dart SDK (>=3.0.0)
- Android Studio / Xcode
- Supabase Account
- Django Backend (setup separately)

### Installation

1. **Clone the repository**

```bash
git clone https://github.com/yourusername/makeplus.git
cd makeplus
```

2. **Install dependencies**

```bash
flutter pub get
```

3. **Configure Supabase**

Create a Supabase project and update `lib/main.dart`:

```dart
await Supabase.initialize(
  url: 'YOUR_SUPABASE_URL',
  anonKey: 'YOUR_SUPABASE_ANON_KEY',
);
```

4. **Configure Django Backend**

Update `lib/data/services/django_api_service.dart`:

```dart
static const String baseUrl = 'https://your-django-backend.com/api';
```

5. **Run the app**

```bash
flutter run
```

## 🗄️ Database Setup (Supabase)

### Tables Schema

**users**

```sql
CREATE TABLE users (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  email TEXT UNIQUE NOT NULL,
  name TEXT NOT NULL,
  role TEXT NOT NULL CHECK (role IN ('organizer', 'controller', 'participant', 'exhibitor')),
  photo_url TEXT,
  phone TEXT,
  organization TEXT,
  created_at TIMESTAMP DEFAULT NOW()
);
```

**notifications**

```sql
CREATE TABLE notifications (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES users(id),
  title TEXT NOT NULL,
  message TEXT NOT NULL,
  type TEXT,
  read BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP DEFAULT NOW()
);
```

**favorites**

```sql
CREATE TABLE favorites (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES users(id),
  exhibitor_id TEXT NOT NULL,
  created_at TIMESTAMP DEFAULT NOW(),
  UNIQUE(user_id, exhibitor_id)
);
```

## 🔧 Django REST API Endpoints

### Authentication

- `POST /api/auth/login/` - User login
- `POST /api/auth/register/` - User registration
- `POST /api/auth/logout/` - User logout

### Rooms Management

- `GET /api/rooms/` - List all rooms
- `POST /api/rooms/` - Create room
- `GET /api/rooms/{id}/` - Get room details
- `PATCH /api/rooms/{id}/` - Update room
- `DELETE /api/rooms/{id}/` - Delete room

### Sessions

- `GET /api/sessions/` - List sessions
- `POST /api/sessions/` - Create session
- `PATCH /api/sessions/{id}/` - Update session
- `DELETE /api/sessions/{id}/` - Delete session

### Participants

- `GET /api/participants/` - List participants
- `POST /api/participants/scan/` - Scan participant badge (for badge controllers)

### Events

- `GET /api/events/` - List events
- `GET /api/events/{id}/` - Event details

### Announcements

- `GET /api/announcements/` - List announcements
- `POST /api/announcements/` - Create announcement

### Exhibitors

- `GET /api/exhibitors/` - List exhibitors
- `GET /api/exhibitors/{id}/` - Exhibitor details

## 🎨 UI Components

### Shared Widgets

- **BottomNavBar**: Dynamic role-based navigation
- **QRScannerWidget**: QR code scanner with overlay
- **QRDisplayWidget**: Display user QR badge
- **SessionCard**: Display session information
- **CustomButton**: Reusable button component
- **LoadingIndicator**: Loading states

### Theme

- **Primary Color**: #9C27B0 (Purple)
- **Accent Color**: #E91E63 (Pink)
- **Success Color**: #4CAF50 (Green)
- **Error Color**: #E53935 (Red)

Both Light and Dark themes supported.

## 📦 Key Dependencies

```yaml
dependencies:
  flutter_bloc: ^8.1.3 # State management
  supabase_flutter: ^2.0.0 # Supabase client
  dio: ^5.3.3 # HTTP client
  qr_code_scanner: ^1.0.1 # QR scanning
  qr_flutter: ^4.1.0 # QR generation
  equatable: ^2.0.5 # Value equality
  cached_network_image: ^3.3.0 # Image caching
```

## 🔐 Authentication Flow

1. User opens app → **Splash Screen**
2. Check authentication status
3. If authenticated → Navigate to role-based home
4. If not → Navigate to **Login Screen**
5. After login → Fetch user role from Supabase
6. Navigate to appropriate home screen:
   - Organizer → `OrganizerHomeScreen`
   - Controller → `ControllerHomeScreen`
   - Participant → `ParticipantHomeScreen`
   - Exhibitor → `ExhibitorHomeScreen`

## 📱 Role-Based Navigation

Each role has a unique bottom navigation bar:

**Organizer**: Home | Annonces | QR Scanner | Salles | Questions  
**Controller**: Home | Annonces | QR Scanner | Programme | Stats  
**Participant**: Home | Programme | QR Badge | Guide | Exposants  
**Exhibitor**: Home | Plan | QR Scanner | Stats | Notifications

## 🧪 Testing

```bash
# Run all tests
flutter test

# Run with coverage
flutter test --coverage

# Integration tests
flutter drive --target=test_driver/app.dart
```

## 📝 Next Steps

### Currently Implemented

✅ Project structure  
✅ Authentication (Login screen, BLoC)  
✅ Organizer home screen  
✅ Room management (List, Detail)  
✅ Add session screen  
✅ QR Scanner & Display widgets  
✅ Theme and styling  
✅ Navigation system

### TODO

- [ ] Controller screens (Badge scanner, Stats)
- [ ] Participant screens (Program, My Badge, Guide, Exhibitors)
- [ ] Exhibitor screens (Booth, Scanner, Stats)
- [ ] Announcements management
- [ ] Notifications system
- [ ] Profile and settings
- [ ] Localization (EN/FR)
- [ ] Offline mode
- [ ] Push notifications
- [ ] Analytics integration
- [ ] Unit and integration tests

## 👥 Contributing

1. Fork the repository
2. Create feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit changes (`git commit -m 'Add AmazingFeature'`)
4. Push to branch (`git push origin feature/AmazingFeature`)
5. Open Pull Request

## 📄 License

This project is licensed under the MIT License.

## 🤝 Support

For support, email support@makeplus.com or open an issue.

---

**MakePlus 2025** - Making events better through technology 🚀
