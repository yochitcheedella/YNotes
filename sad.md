# SYSTEM ANALYSIS AND DESIGN (SAD)

# Diaro – Secure Personal Diary and Journal Application with Biometric Authentication

---

# Document Information

| Item          | Details                              |
| ------------- | ------------------------------------ |
| Project Name  | Diaro                                |
| Document Type | System Analysis and Design (SAD)     |
| Version       | 1.0                                  |
| Prepared By   | Cheedella Bala Venkata Satya Yochit  |
| Platform      | Android                              |
| Technology    | Flutter + Firebase + SQLite          |
| Security      | AES-256 + Fingerprint Authentication |

---

# 1. Introduction

## 1.1 Purpose

The purpose of this System Analysis and Design (SAD) document is to describe the analysis, architecture, database structure, modules, workflows, and design specifications of the Diaro application.

Diaro is a privacy-first digital diary designed to help users capture thoughts, memories, and daily experiences securely. With end-to-end encryption, biometric authentication, cloud synchronization, and AI-powered insights, Diaro ensures your personal moments remain truly personal.

---

# 2. Existing System Analysis

## Existing System

Current diary solutions include:

* Traditional paper diaries
* Generic note-taking apps
* Basic journal applications

### Limitations

* No biometric security
* Weak privacy protection
* Lack of encryption
* Difficult searching
* No mood tracking
* Limited backup facilities

---

# 3. Proposed System Analysis

## Proposed System

Diaro introduces:

### Security

* Master Password
* Fingerprint Authentication
* AES-256 Encryption
* Auto Lock
* Fake Password Mode

### Diary Management

* Daily Journal Entries
* Calendar Navigation
* Monthly Archives
* Media Attachments

### Productivity

* Mood Tracking
* Search Engine
* Voice Diary
* Secure Backup

---

# 4. System Objectives

### Primary Objectives

* Secure diary storage
* Biometric authentication
* Date-wise journal management
* Encrypted data storage
* Easy diary retrieval

### Secondary Objectives

* Mood tracking
* Voice notes
* Cloud synchronization
* AI-based insights

---

# 5. Feasibility Analysis

## Technical Feasibility

Technologies:

* Flutter
* Firebase
* SQLite
* Android Biometric API

Status: Feasible

---

## Economic Feasibility

Uses open-source technologies.

Minimal development cost.

Status: Feasible

---

## Operational Feasibility

Simple interface suitable for all users.

Status: Feasible

---

# 6. System Architecture

```text
+---------------------+
|       USER          |
+----------+----------+
           |
           v
+---------------------+
| Authentication Layer|
+----------+----------+
           |
           v
+---------------------+
| Fingerprint Module  |
+----------+----------+
           |
           v
+---------------------+
| Application Layer   |
+----------+----------+
           |
    ---------------------
    |     |     |      |
    v     v     v      v

 Diary Calendar Search Backup

           |
           v
+---------------------+
| Encryption Layer    |
+----------+----------+
           |
           v
+---------------------+
| Database Layer      |
+----------+----------+
           |
           v
+---------------------+
| Cloud Backup Layer  |
+---------------------+
```

---

# 7. System Modules

## Module 1: Authentication Module

### Purpose

Provide secure access to users.

### Functions

* Register User
* Login User
* Validate Password
* Session Management

### Inputs

* Username
* Password

### Outputs

* Login Success
* Login Failure

---

## Module 2: Biometric Authentication Module

### Purpose

Verify user identity using fingerprint.

### Functions

* Fingerprint Registration
* Fingerprint Verification
* Biometric Login

### Inputs

* Fingerprint Data

### Outputs

* Authentication Result

---

## Module 3: Diary Management Module

### Purpose

Create and manage journal entries.

### Functions

* Create Entry
* Update Entry
* Delete Entry
* View Entry

### Inputs

* Title
* Content
* Date
* Mood

### Outputs

* Stored Entry

---

## Module 4: Calendar Module

### Purpose

Organize entries date-wise.

### Functions

* Calendar Display
* Date Selection
* Monthly Navigation

### Outputs

* Diary Entries By Date

---

## Module 5: Mood Tracking Module

### Purpose

Monitor emotional patterns.

### Functions

* Select Mood
* Store Mood
* Generate Reports

### Mood Categories

😊 Happy

😐 Neutral

😔 Sad

😡 Angry

😍 Excited

---

## Module 6: Media Module

### Purpose

Store multimedia memories.

### Functions

* Upload Images
* Record Audio
* Attach Documents

---

## Module 7: Search Module

### Purpose

Retrieve diary entries quickly.

### Functions

* Keyword Search
* Date Search
* Mood Search

---

## Module 8: Backup Module

### Purpose

Protect data from loss.

### Functions

* Create Backup
* Restore Backup
* Cloud Sync

---

# 8. Data Flow Diagram (DFD)

## Level 0 DFD

```text
+--------+
|  User  |
+----+---+
     |
     v
+------------+
|   Diaro    |
+------+-----+
       |
       v
+------------+
| Database   |
+------------+
```

---

## Level 1 DFD

```text
User
 |
 | Register/Login
 v

Authentication
 |
 v

Diary Module
 |
 +---- Create Entry
 |
 +---- Edit Entry
 |
 +---- Delete Entry
 |
 +---- Search Entry
 |
 v

Encrypted Database
```

---

# 9. Use Case Diagram

```text
                   User

                     |
------------------------------------------------

|        |         |         |        |         |

Login  Diary   Search   Backup   Settings Logout

          |
          |
    Create/Edit/Delete
```

---

# 10. Activity Diagram

```text
Start
  |
  v

Open App
  |
  v

Login
  |
  +---- Invalid Credentials
  |           |
  |           v
  |      Retry Login
  |
  v

Dashboard
  |
  +---- Create Entry
  |
  +---- Search Entry
  |
  +---- Backup Data
  |
  v

Logout
  |
  v

End
```

---

# 11. Sequence Diagram

```text
User
 |
 | Login
 v

Authentication Module
 |
 | Verify Credentials
 v

Database
 |
 | Success
 v

Dashboard
 |
 | Create Entry
 v

Diary Module
 |
 | Save Entry
 v

Database
 |
 | Confirmation
 v

User
```

---

# 12. Database Design

## Entity Relationship Diagram (ERD)

```text
Users
 |
 | 1
 |
 | M

DiaryEntries
 |
 | 1
 |
 | M

Attachments
```

---

## Users Table

| Attribute    | Type    |
| ------------ | ------- |
| UserID       | Integer |
| Username     | Varchar |
| PasswordHash | Varchar |
| CreatedDate  | Date    |

---

## DiaryEntries Table

| Attribute | Type      |
| --------- | --------- |
| EntryID   | Integer   |
| UserID    | Integer   |
| EntryDate | Date      |
| Title     | Text      |
| Content   | Long Text |
| Mood      | Text      |
| CreatedAt | Timestamp |

---

## Attachments Table

| Attribute    | Type    |
| ------------ | ------- |
| AttachmentID | Integer |
| EntryID      | Integer |
| FileType     | Text    |
| FilePath     | Text    |

---

# 13. User Interface Design

## Login Screen

Components:

* App Logo
* Username Field
* Password Field
* Login Button
* Fingerprint Button

---

## Dashboard Screen

Components:

* Calendar
* Recent Entries
* Search Bar
* Add Entry Button

---

## Diary Entry Screen

Components:

* Date
* Title
* Mood Selector
* Content Area
* Media Attachment Button
* Save Button

---

## Settings Screen

Components:

* Change Password
* Enable Fingerprint
* Backup Options
* Auto Lock Settings

---

# 14. Security Design

## Password Security

Algorithm:

```text
SHA-256 Hashing
```

---

## Data Security

Algorithm:

```text
AES-256 Encryption
```

---

## Biometric Security

Android Biometric API

---

## Session Security

Auto Lock:

* 30 Seconds
* 1 Minute
* 5 Minutes

---

## Privacy Protection

### Fake Password Mode

Real Password:

```text
Yochit@123
```

Fake Password:

```text
Demo@123
```

Opens an empty diary.

---

# 15. Testing Strategy

## Unit Testing

* Login Testing
* Entry Creation Testing
* Search Testing

---

## Integration Testing

* Authentication + Database
* Diary + Search
* Backup + Restore

---

## Security Testing

* Password Validation
* Encryption Verification
* Fingerprint Authentication

---

## User Acceptance Testing

Verify:

* Ease of use
* Security
* Performance

---

# 16. Future Enhancements

### AI Journal Assistant

Automatic diary summaries.

### Sentiment Analysis

Emotion detection from diary text.

### Voice-to-Text

Convert recordings into text.

### Cross Platform Support

* Android
* iOS
* Web
* Desktop

### AI Search

Example:

> "Show all memories related to college in 2026."

---

# 17. Conclusion

Diaro is a highly secure and user-friendly personal diary application designed to provide complete privacy through password protection, fingerprint authentication, and encryption. The system organizes memories by date, month, and year while supporting mood tracking, voice journals, media attachments, and backup facilities. Its modular architecture, strong security model, and scalable design make it suitable as a **Final Year B.Tech Project, Startup MVP, and production-ready mobile application.**
