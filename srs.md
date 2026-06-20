# SOFTWARE REQUIREMENT SPECIFICATION (SRS)

# Diaro – Secure Personal Diary and Journal Application with Biometric Authentication

---

# Document Information

| Item             | Details                                  |
| ---------------- | ---------------------------------------- |
| Project Name     | Diaro                                    |
| Version          | 1.0                                      |
| Document Type    | Software Requirement Specification (SRS) |
| Prepared By      | Cheedella Bala Venkata Satya Yochit      |
| Project Category | Mobile Application                       |
| Platform         | Android                                  |
| Date             | June 2026                                |

---

# 1. Introduction

## 1.1 Purpose

The purpose of this Software Requirement Specification (SRS) document is to define the functional and non-functional requirements for the Diaro application.

Diaro is a privacy-first digital diary designed to help users capture thoughts, memories, and daily experiences securely. With end-to-end encryption, biometric authentication, cloud synchronization, and AI-powered insights, Diaro ensures your personal moments remain truly personal.

---

## 1.2 Scope

Diaro provides:

* Password-based login
* Fingerprint authentication
* Date-wise diary management
* Calendar-based navigation
* Mood tracking
* Voice diary recording
* Media attachments
* Secure backup and recovery
* Search functionality
* Encrypted storage

The application is designed primarily for Android smartphones and tablets.

---

## 1.3 Definitions

| Term                     | Meaning                               |
| ------------------------ | ------------------------------------- |
| Diary Entry              | Daily journal content created by user |
| AES                      | Advanced Encryption Standard          |
| Biometric Authentication | Authentication using fingerprint      |
| Backup                   | Secure copy of user data              |
| Cloud Storage            | Online storage service                |
| User                     | Registered application user           |

---

# 2. Overall Description

## 2.1 Product Perspective

Diaro is a standalone mobile application that stores diary information securely and allows users to access it using passwords and fingerprint authentication.

The application consists of:

* Authentication Module
* Diary Management Module
* Calendar Module
* Mood Tracking Module
* Media Management Module
* Backup Module
* Search Module

---

## 2.2 Product Functions

The system shall provide:

### Authentication

* User Registration
* Login
* Password Validation
* Fingerprint Verification

### Diary Operations

* Create Diary Entry
* View Entry
* Edit Entry
* Delete Entry

### Calendar Features

* Monthly Calendar View
* Date Selection
* Entry Indicators

### Media Features

* Image Upload
* Audio Recording
* File Attachment

### Backup Features

* Backup Creation
* Backup Restore

### Security Features

* Encryption
* Auto Lock
* Fake Password Mode

---

## 2.3 User Characteristics

### Students

* Daily learning records
* Study notes

### Professionals

* Work journals
* Task reflections

### Travelers

* Travel memories

### General Users

* Personal diary writing
* Emotional journaling

---

## 2.4 Operating Environment

### Mobile Platform

Android 8.0 and Above

### Development Environment

Flutter SDK

Android Studio

Firebase

---

## 2.5 Assumptions and Dependencies

### Assumptions

* User owns an Android device.
* Device supports fingerprint authentication.
* User remembers master password.

### Dependencies

* Firebase Services
* Android Biometric API
* Internet connection for cloud backup

---

# 3. System Features

---

# Feature 1: User Authentication

## Description

Allows users to securely access the application.

### Inputs

* Username
* Password

### Processing

* Validate credentials
* Authenticate user

### Outputs

* Successful login
* Error message

### Priority

High

---

# Feature 2: Fingerprint Authentication

## Description

Allows users to unlock the application using biometric verification.

### Inputs

* Registered fingerprint

### Processing

* Verify fingerprint

### Outputs

* Access Granted
* Access Denied

### Priority

High

---

# Feature 3: Diary Entry Management

## Description

Allows users to create and manage diary entries.

### Functions

* Create Entry
* View Entry
* Edit Entry
* Delete Entry

### Inputs

* Title
* Content
* Date
* Mood

### Outputs

* Saved diary record

### Priority

High

---

# Feature 4: Calendar Navigation

## Description

Displays diary entries according to selected dates.

### Inputs

* Date Selection

### Outputs

* Corresponding diary entries

### Priority

High

---

# Feature 5: Mood Tracking

## Description

Tracks emotional status of users.

### Mood Types

* Happy
* Sad
* Angry
* Excited
* Neutral

### Outputs

* Monthly mood reports

### Priority

Medium

---

# Feature 6: Voice Diary

## Description

Allows users to record voice memories.

### Inputs

* Audio Recording

### Outputs

* Audio File

### Priority

Medium

---

# Feature 7: Media Attachments

## Description

Allows users to attach media files.

### Supported Formats

* JPG
* PNG
* MP4
* PDF
* MP3

### Outputs

* Stored media attachment

### Priority

Medium

---

# Feature 8: Search Functionality

## Description

Allows users to search diary content.

### Search Criteria

* Keywords
* Dates
* Mood

### Outputs

* Matching entries

### Priority

High

---

# Feature 9: Backup and Restore

## Description

Creates secure backups of user data.

### Functions

* Local Backup
* Cloud Backup
* Restore Backup

### Outputs

* Backup File

### Priority

Medium

---

# Feature 10: Security Features

## Description

Protects user privacy.

### Security Mechanisms

* AES-256 Encryption
* SHA-256 Hashing
* Auto Lock
* Fake Password Mode

### Priority

High

---

# 4. External Interface Requirements

## 4.1 User Interface Requirements

### Login Screen

Fields:

* Username
* Password

Buttons:

* Login
* Register
* Fingerprint Login

---

### Home Screen

Displays:

* Calendar
* Recent Entries
* Search Bar

---

### Diary Screen

Displays:

* Title
* Date
* Mood
* Content

Buttons:

* Save
* Edit
* Delete

---

## 4.2 Hardware Interface

### Supported Hardware

* Android Smartphone
* Android Tablet
* Fingerprint Sensor

---

## 4.3 Software Interface

### Firebase

Used for:

* Authentication
* Cloud Storage
* Database

### SQLite

Used for:

* Local Storage

---

# 5. Functional Requirements

| Requirement ID | Description                                     |
| -------------- | ----------------------------------------------- |
| FR-01          | System shall allow user registration            |
| FR-02          | System shall allow user login                   |
| FR-03          | System shall support fingerprint authentication |
| FR-04          | System shall create diary entries               |
| FR-05          | System shall edit diary entries                 |
| FR-06          | System shall delete diary entries               |
| FR-07          | System shall display calendar view              |
| FR-08          | System shall support mood tracking              |
| FR-09          | System shall support media attachments          |
| FR-10          | System shall allow searching diary entries      |
| FR-11          | System shall generate backups                   |
| FR-12          | System shall restore backups                    |
| FR-13          | System shall encrypt stored data                |
| FR-14          | System shall auto-lock after inactivity         |
| FR-15          | System shall support fake password mode         |

---

# 6. Non-Functional Requirements

## Performance

* Login time less than 3 seconds
* Search response less than 2 seconds
* Backup creation less than 10 seconds

---

## Security

* AES-256 Encryption
* SHA-256 Password Hashing
* Fingerprint Verification
* Secure Cloud Storage

---

## Reliability

* 99% uptime
* Data consistency guaranteed

---

## Availability

* Available 24×7
* Offline diary access

---

## Usability

* User-friendly interface
* Easy navigation

---

## Maintainability

* Modular architecture
* Easy updates

---

## Scalability

* Support 100,000+ diary entries
* Support large media files

---

# 7. Database Requirements

## Users Table

| Field        | Type    |
| ------------ | ------- |
| UserID       | Integer |
| Username     | Varchar |
| PasswordHash | Varchar |
| CreatedDate  | Date    |

---

## DiaryEntries Table

| Field     | Type      |
| --------- | --------- |
| EntryID   | Integer   |
| UserID    | Integer   |
| EntryDate | Date      |
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
| FilePath     | Text    |
| FileType     | Text    |

---

# 8. System Constraints

* Requires Android 8.0+
* Requires fingerprint sensor for biometric login
* Cloud backup requires internet connection
* Storage depends on device capacity

---

# 9. Future Requirements

### AI Journal Assistant

Automatic daily summary generation.

### Sentiment Analysis

Mood prediction from diary text.

### AI Search

Example:

> "Show my happy memories from last year."

### Cross Platform Synchronization

* Android
* iOS
* Web
* Desktop

---

# 10. Conclusion

The Diaro application provides a secure and intelligent platform for digital journaling. Through password protection, fingerprint authentication, encrypted storage, calendar-based organization, mood tracking, voice recording, and backup capabilities, the system ensures that users can safely preserve their personal memories and experiences while maintaining complete privacy.

**Project Name:** Diaro
**Application Type:** Secure Personal Diary & Journal App
**Platform:** Android
**Technology:** Flutter + Firebase + SQLite + AES Encryption + Biometric Authentication
**Project Level:** Final Year B.Tech Project / Startup MVP / Production-Ready Mobile Application.
