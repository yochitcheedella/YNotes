# PROJECT PROPOSAL

## Project Title

# **Diaro – Secure Personal Diary and Journal Application with Biometric Authentication**

### Tagline

**Your Thoughts. Your Memories. Your Privacy. 🔐**

---

# 1. Abstract

Diaro is a secure digital diary and journaling application designed to help users record their daily thoughts, memories, experiences, goals, and personal information in a private environment. The application uses password protection, fingerprint authentication, and data encryption to ensure complete privacy.

Unlike traditional diary applications, Diaro organizes entries based on dates, months, and years through an interactive calendar interface. Users can write journal entries, attach images, record voice notes, track moods, and search past memories instantly.

The application aims to provide a safe digital space where users can preserve their personal experiences while maintaining complete control over their data.

---

# 2. Problem Statement

Many existing diary and note-taking applications suffer from:

* Weak security mechanisms
* Lack of biometric authentication
* Limited privacy controls
* Poor organization of diary entries
* Dependence on cloud storage
* Risk of unauthorized access

Users require a secure digital diary system that provides both privacy and ease of use.

---

# 3. Proposed Solution

Diaro provides:

* Password-based authentication
* Fingerprint authentication
* Encrypted diary storage
* Date-wise journal management
* Calendar-based navigation
* Mood tracking
* Voice diary recording
* Media attachments
* Secure backup and restore functionality

The system ensures that only authorized users can access their personal information.

---

# 4. Objectives

### Primary Objectives

* Develop a secure digital diary application.
* Implement biometric authentication.
* Organize entries by date, month, and year.
* Encrypt all user data.
* Provide a user-friendly interface.

### Secondary Objectives

* Enable voice diary recording.
* Implement mood tracking.
* Provide backup and restore functionality.
* Generate diary statistics and insights.

---

# 5. Scope of the Project

The project can be used by:

* Students
* Professionals
* Travelers
* Journal Writers
* Researchers
* Personal Users

The application will support:

* Android Devices
* Tablets
* Future Web Version

---

# 6. Features

## Authentication Module

### User Registration

* Create Master Password
* Password Recovery Setup

### Login

* Password Authentication
* Fingerprint Authentication
* Face Unlock (Future)

---

## Diary Management Module

### Create Entry

Users can create:

* Daily Journal
* Personal Notes
* Travel Logs
* Study Notes

### Edit Entry

Modify previous diary records.

### Delete Entry

Remove unwanted entries.

---

## Calendar Module

### Monthly View

```text
June 2026

1 2 3 4 5
6 7 8 9 10
```

### Date Selection

Select any date to view diary entries.

---

## Media Attachment Module

Users can attach:

* Images
* Videos
* Audio Recordings
* Documents

---

## Mood Tracking Module

Available moods:

😊 Happy

😐 Normal

😔 Sad

😡 Angry

😍 Excited

Monthly mood reports can be generated.

---

## Voice Diary Module

Users can:

* Record voice notes
* Store recordings securely
* Convert speech to text

---

## Search Module

Search by:

* Date
* Keywords
* Mood
* Month
* Year

---

## Security Module

### Encryption

* AES-256 Encryption

### Biometric Security

* Fingerprint Authentication

### Auto Lock

* Lock after inactivity

### Fake Password Mode

Fake password opens a dummy diary.

---

## Backup Module

### Local Backup

Encrypted backup file.

### Cloud Backup

* Google Drive
* OneDrive

---

# 7. System Architecture

```text
User
 |
 v
Authentication Layer
 |
 v
Biometric Verification
 |
 v
Application Layer
 |
 |---- Diary Module
 |---- Calendar Module
 |---- Mood Module
 |---- Search Module
 |---- Backup Module
 |
 v
Encrypted Database
 |
 v
Cloud Backup (Optional)
```

---

# 8. Functional Requirements

### FR1

System shall allow user registration.

### FR2

System shall authenticate users using passwords.

### FR3

System shall support fingerprint authentication.

### FR4

System shall create diary entries.

### FR5

System shall edit diary entries.

### FR6

System shall delete diary entries.

### FR7

System shall store media attachments.

### FR8

System shall organize entries by date.

### FR9

System shall encrypt user data.

### FR10

System shall generate backup files.

---

# 9. Non-Functional Requirements

## Security

* AES-256 Encryption
* Secure Password Storage

## Performance

* Entry retrieval < 2 seconds
* Search results < 1 second

## Reliability

* 99% data consistency

## Usability

* Beginner-friendly UI

## Scalability

* Support thousands of diary entries

---

# 10. Technology Stack

## Frontend

Flutter

OR

React Native

---

## Backend

Firebase

---

## Database

Cloud Firestore

SQLite (Offline)

---

## Security

* AES Encryption
* SHA-256 Hashing
* Android Biometric API

---

## Storage

Firebase Storage

---

# 11. Database Design

## Users Table

| Field        | Type    |
| ------------ | ------- |
| UserID       | Integer |
| Username     | Text    |
| PasswordHash | Text    |
| CreatedDate  | Date    |

---

## DiaryEntries Table

| Field     | Type      |
| --------- | --------- |
| EntryID   | Integer   |
| UserID    | Integer   |
| Date      | Date      |
| Title     | Text      |
| Content   | Text      |
| Mood      | Text      |
| CreatedAt | Timestamp |

---

## Attachments Table

| Field        | Type    |
| ------------ | ------- |
| AttachmentID | Integer |
| EntryID      | Integer |
| FileType     | Text    |
| FilePath     | Text    |

---

# 12. Expected Outcomes

After completion, Diaro will:

* Securely store diary entries.
* Protect data using biometrics.
* Allow date-wise journaling.
* Generate mood analytics.
* Support multimedia memories.
* Maintain user privacy.

---

# 13. Future Enhancements

### AI Diary Assistant

Automatically summarize daily journals.

### Emotion Analysis

Detect emotional patterns.

### Handwriting Recognition

Convert handwritten notes into text.

### Cross Platform Sync

Android ↔ Web ↔ Desktop

### AI Memory Search

Search memories using natural language.

Example:

> "Show my gym entries from last month."



