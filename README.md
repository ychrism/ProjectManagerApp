# Project Manager App

## Table of Contents
1. [Introduction](#introduction)
2. [Prerequisites](#prerequisites)
3. [Backend Setup](#backend-setup)
    - [Python Environment](#python-environment)
    - [Database Configuration](#database-configuration)
    - [Redis Configuration](#redis-configuration)
    - [Django Configuration](#django-configuration)
4. [Frontend Setup](#frontend-setup)
5. [Running the Application](#running-the-application)
6. [Testing](#testing)
7. [Project Structure](#project-structure)
8. [Key Features](#key-features)
9. [Troubleshooting](#troubleshooting)
10. [Contributing](#contributing)
11. [License](#license)

## Introduction

This project is a comprehensive project management application featuring a Flutter frontend and a Django REST Framework backend. It offers robust functionalities including user authentication, real-time chat, task management, and workspace organization.

## Prerequisites

Ensure you have the following installed on your system:

- Python 3.8 or higher
- Flutter 3.4.4 or higher
- MySQL 5.7 or higher
- Redis 5.0 or higher
- Node.js 14.0 or higher (for certain frontend dependencies)

## Backend Setup

### Python Environment

1. Navigate to the backend directory:
   ```bash
   cd backend/rest_api
   ```

2. Create and activate a virtual environment:
   ```bash
   python -m venv venv
   source venv/bin/activate  # On Windows use `venv\Scripts\activate`
   ```

3. Install the required Python packages:
   ```bash
   pip install -r requirements.txt
   ```

   If `requirements.txt` is not available, install the following packages manually:
   ```bash
   pip install django==3.2.19 \
               djangorestframework==3.14.0 \
               django-cors-headers==3.14.0 \
               channels==3.0.5 \
               daphne==3.0.2 \
               mysqlclient==2.1.1 \
               django-redis==5.2.0 \
               channels-redis==3.4.1 \
               djangorestframework-simplejwt==5.2.2 \
               django-channels-jwt==0.0.4
   ```

### Database Configuration

1. Install MySQL and create a new database:
   ```sql
   CREATE DATABASE project_manager_app_db CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
   ```

2. Update the `DATABASES` configuration in `rest_api/settings.py`:
   ```python
   DATABASES = {
       'default': {
           'ENGINE': 'django.db.backends.mysql',
           'NAME': 'project_manager_app_db',
           'USER': 'your_mysql_username',
           'PASSWORD': 'your_mysql_password',
           'HOST': 'localhost',
           'PORT': '3306',
           'OPTIONS': {'charset': 'utf8mb4'},
       }
   }
   ```

### Redis Configuration

1. Install and start Redis:
   ```bash
   sudo apt-get install redis-server  # For Ubuntu
   sudo systemctl start redis.service
   ```

2. Ensure Redis is running on `localhost:6379`. If using a different configuration, update the `CHANNEL_LAYERS` in `settings.py`:
   ```python
   CHANNEL_LAYERS = {
      'default': {
          'BACKEND': 'channels_redis.core.RedisChannelLayer',
          'CONFIG': {
              "hosts": [('127.0.0.1', 6379)],
          },
      },
   }
   ```

### Django Configuration

1. Apply database migrations:
   ```bash
   python manage.py migrate
   ```

2. Create an admin user:
   ```bash
   python manage.py createadmin
   ```

3. Create a superuser for API admin access:
   ```bash
   python manage.py createsuperuser
   ```

4. Collect static files:
   ```bash
   python manage.py collectstatic
   ```

## Frontend Setup

1. Navigate to the project root directory.

2. Install Flutter dependencies:
   ```bash
   flutter pub get
   ```

3. If you encounter any issues with package versions, update `pubspec.yaml` and run `flutter pub upgrade`.

## Running the Application

### Backend

1. Start the Django development server:
   ```bash
   python manage.py runserver
   ```

   The server will start on `http://127.0.0.1:8000`.

2. For production, use a production-grade server like Gunicorn with Nginx.

### Frontend

1. Run the Flutter application:
   ```bash
   flutter run
   ```

2. Choose your target device (e.g., Android emulator, iOS simulator, or web browser).

3. For production builds:
    - Android: `flutter build apk --release`
    - iOS: `flutter build ios --release`
    - Web: `flutter build web --release`

## Testing

### Unit Tests

1. Backend:
   ```bash
   python manage.py test
   ```

2. Frontend:
   ```bash
   flutter test
   ```

### Chat Feature Testing

1. Build the app on two separate devices (e.g., Android device and Linux desktop).
2. Ensure both devices are connected to the same network as the backend server.
3. Log in with different user accounts on each device.
4. Navigate to the chat feature and start a conversation.

## Project Structure

```
project_root/
├── backend/
│   └── rest_api/
│       ├── api/
│       │   ├── models.py
│       │   ├── serializers.py
│       │   ├── views.py
│       │   └── urls.py
│       ├── rest_api/
│       │   ├── settings.py
│       │   ├── urls.py
│       │   └── asgi.py
│       └── manage.py
├── lib/
│   ├── screens/
│   │   ├── board.dart
│   │   ├── chat.dart
│   │   ├── dashboard.dart
│   │   ├── messages_screen.dart
│   │   ├── sign_in.dart
│   │   ├── sign_up.dart
│   │   ├── welcome_screen.dart
│   │   └── workspace.dart
│   ├── services/
│   │   ├── api.dart
│   │   ├── navigation.dart
│   │   └── websocket.dart
│   └── main.dart
├── assets/
│   ├── default_chat_background.png
│   └── default_photo_profile.jpg
├── fonts/
│   ├── Comfortaa-Bold.ttf
│   ├── Comfortaa-Light.ttf
│   ├── Comfortaa-Medium.ttf
│   ├── Comfortaa-Regular.ttf
│   └── Comfortaa-SemiBold.ttf
└── pubspec.yaml
```

## Key Features

- Secure user authentication (JWT-based)
- Interactive project management dashboard
- Kanban-style task board
- Real-time chat functionality with WebSocket support
- Customizable workspace management
- File sharing and collaboration tools
- Responsive design for multi-platform support

## Troubleshooting

- If you encounter CORS issues, ensure the frontend URL is added to `CORS_ALLOWED_ORIGINS` in `settings.py`.
- For WebSocket connection problems, check if Daphne is running and the WebSocket URL is correct in the frontend code.
- Database connection issues: Verify MySQL service is running and credentials are correct.

## Contributing

Please read [CONTRIBUTING.md](CONTRIBUTING.md) for details on our code of conduct and the process for submitting pull requests.

## License

This project is licensed under the MIT License - see the [LICENSE.md](LICENSE.md) file for details.