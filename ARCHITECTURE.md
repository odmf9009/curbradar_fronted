# CurbRadar Architecture

## Overview
CurbRadar is a community platform for finding and sharing free items on the street. It uses a hybrid architecture combining Firebase services with a custom REST backend and real-time updates via Socket.io.

## Components

### Frontend (Flutter)
- **Auth**: Firebase Auth (Google, Apple, Email/Password).
- **Guest Mode**: Allows browsing the map, viewing objects, and search/filtering without authentication. Actions like publishing, commenting, or claiming an object require login.
- **Maps**: Google Maps Flutter for spatial visualization.
- **Real-time**: Socket.io for live updates on object status and hunter locations.
- **REST API**: Custom backend for business logic, statistics, and persistence.

### Backend (Node.js)
- **Database**: MongoDB for storing objects, users, and activity.
- **Authentication**: Verifies Firebase ID Tokens.
- **Storage**: Custom upload service for object images.

## Authentication Flow
1. User logs in via Firebase (Native SDK).
2. ID Token is obtained and sent to `/auth/verify`.
3. Backend creates/retrieves the user profile and returns it.
4. Subsequent API calls include the Bearer Token in the `Authorization` header.
