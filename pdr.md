# PROJECT DESIGN REPORT (PDR)

# YNote – Secure Personal Diary and Journal Application with Biometric Authentication

---

# 1. Project Information

### Project Title

**YNote – Secure Personal Diary and Journal Application with Biometric Authentication**

### Project Domain

* Mobile Application Development
* Cyber Security
* Personal Productivity

### Project Type

Android Application

### Development Methodology

Agile Development Model

---

# 2. Project Overview

YNote is a secure diary and journaling application that allows users to record daily thoughts, memories, experiences, goals, and personal notes in an encrypted environment.

The application uses password authentication and fingerprint verification to prevent unauthorized access. All diary entries are organized date-wise and month-wise through an interactive calendar interface.

Users can also attach images, voice recordings, and documents to their diary entries while maintaining complete privacy through encryption.

---

# 3. Project Vision

To provide users with a highly secure, private, and organized digital diary system where memories and personal information can be stored safely without fear of unauthorized access.

---

# 4. Problem Identification

Traditional diary applications face several limitations:

### Existing Problems

* Weak security systems
* Lack of biometric authentication
* Limited privacy protection
* Poor diary organization
* No encrypted storage
* Difficult memory retrieval

### Impact

* Personal information leaks
* Unauthorized access
* Data theft
* Poor user experience

---

# 5. Proposed System

The proposed YNote system introduces:

### Security Features

* Master Password Authentication
* Fingerprint Authentication
* AES-256 Encryption
* Auto Lock System
* Fake Password Mode

### Diary Features

* Date-wise Entries
* Monthly Diary Organization
* Calendar Navigation
* Mood Tracking
* Voice Diary
* Media Attachments

### Backup Features

* Local Backup
* Cloud Backup
* Secure Restore

---

# 6. Project Objectives

## Primary Objectives

* Develop a secure diary application.
* Implement biometric authentication.
* Organize entries by date and month.
* Encrypt sensitive user data.
* Create an intuitive interface.

## Secondary Objectives

* Voice note support.
* Mood tracking system.
* Backup and recovery.
* AI-powered diary insights.

---

# 7. Project Scope

The application can be used by:

### Students

* Academic journals
* Study tracking

### Professionals

* Work logs
* Daily planning

### Travelers

* Travel memories
* Trip journals

### General Users

* Personal diaries
* Goal tracking
* Emotional journaling

---

# 8. System Modules

## Module 1 – User Authentication

### Functions

* Registration
* Login
* Password Validation
* Password Recovery

---

## Module 2 – Biometric Security

### Functions

* Fingerprint Enrollment
* Fingerprint Verification
* Device Authentication

---

## Module 3 – Diary Management

### Functions

* Create Entry
* Edit Entry
* Delete Entry
* View Entry

---

## Module 4 – Calendar Management

### Functions

* Monthly View
* Date Selection
* Entry Highlighting

---

## Module 5 – Mood Tracking

### Functions

* Mood Selection
* Mood History
* Monthly Analytics

---

## Module 6 – Media Management

### Functions

* Image Upload
* Audio Recording
* File Attachments

---

## Module 7 – Search Engine

### Functions

* Keyword Search
* Date Search
* Mood Search

---

## Module 8 – Backup System

### Functions

* Local Backup
* Cloud Backup
* Restore Backup

---

# 9. System Architecture

```text
+-------------------+
|       User        |
+---------+---------+
          |
          v
+-------------------+
| Authentication    |
+---------+---------+
          |
          v
+-------------------+
| Fingerprint Auth  |
+---------+---------+
          |
          v
+-------------------+
| Application Layer |
+---------+---------+
          |
  -------------------
  |   |   |   |   |
  v   v   v   v   v

Diary
Calendar
Mood
Search
Backup

          |
          v
+-------------------+
| Encrypted Storage |
+---------+---------+
          |
          v
+-------------------+
| Cloud Backup      |
+-------------------+
```

---

# 10. Data Flow Diagram (DFD)

## Level 0 DFD

```text
User
 |
 |
 v
YNote System
 |
 |
 v
Encrypted Database
```

---

## Level 1 DFD

```text
User
 |
 +---- Login/Register
 |
 +---- Create Entry
 |
 +---- Search Entry
 |
 +---- Backup Data
 |
 v
YNote Application
 |
 +---- Authentication
 +---- Diary Module
 +---- Search Module
 +---- Backup Module
 |
 v
Database
```

---

# 11. Use Case Diagram

```text
                User
                  |
    --------------------------------
    |       |      |      |       |
 Login  Create  Search Backup Logout
         Diary
```

---

# 12. Database Design

## Users Table

| Attribute    | Type    |
| ------------ | ------- |
| UserID       | Integer |
| Username     | Text    |
| PasswordHash | Text    |
| CreatedDate  | Date    |

---

## DiaryEntries Table

| Attribute | Type      |
| --------- | --------- |
| EntryID   | Integer   |
| UserID    | Integer   |
| EntryDate | Date      |
| Title     | Text      |
| Content   | Text      |
| Mood      | Text      |
| CreatedAt | Timestamp |

---

## Media Table

| Attribute | Type    |
| --------- | ------- |
| MediaID   | Integer |
| EntryID   | Integer |
| MediaType | Text    |
| FilePath  | Text    |

---

# 13. Technology Stack

## Frontend

Flutter

### UI Components

* Material Design
* Calendar Widget
* Fingerprint UI

---

## Backend

Firebase

### Services

* Firebase Authentication
* Cloud Firestore
* Firebase Storage

---

## Database

SQLite

Cloud Firestore

---

## Security

* AES-256 Encryption
* SHA-256 Hashing
* Android Biometric API

---

# 14. Hardware Requirements

### Development System

Processor:
Intel i5 or higher

RAM:
8 GB Minimum

Storage:
256 GB SSD

---

### User Device

Android 8.0+

Fingerprint Sensor

Internet Connection (Optional)

---

# 15. Software Requirements

### Development Tools

Android Studio

VS Code

Flutter SDK

Firebase Console

GitHub

---

### Operating System

Windows 10/11

Linux

macOS

---

# 16. Feasibility Study

## Technical Feasibility

The project can be implemented using Flutter and Firebase technologies.

### Status

Feasible

---

## Economic Feasibility

Open-source technologies reduce development costs.

### Status

Feasible

---

## Operational Feasibility

Simple user interface ensures easy adoption.

### Status

Feasible

---

# 17. Security Considerations

### Password Encryption

Passwords stored using secure hashing.

### Data Encryption

AES-256 encryption applied to diary data.

### Biometric Security

Fingerprint verification before access.

### Auto Lock

Automatic lock after inactivity.

### Fake Password

Opens a dummy diary to protect privacy.

---

# 18. Expected Results

After implementation:

* Secure diary storage
* Fast retrieval of entries
* Password and fingerprint protection
* Organized date-wise journals
* Encrypted backups
* Improved user privacy

---

# 19. Future Enhancements

### AI Journal Assistant

Automatic diary summarization.

### AI Mood Detection

Emotion analysis from journal text.

### Voice-to-Text

Automatic transcription.

### Cross Platform Sync

Android, Web, Desktop.

### Smart Search

Example:

> "Show my gym entries from January 2027"

---

# 20. Conclusion

YNote is a secure and intelligent digital diary platform that combines strong security mechanisms with an easy-to-use journaling experience. By integrating password protection, fingerprint authentication, encrypted storage, calendar-based organization, and multimedia support, YNote provides a modern solution for secure personal diary management and serves as an excellent **B.Tech Final Year Project and Startup MVP.**
