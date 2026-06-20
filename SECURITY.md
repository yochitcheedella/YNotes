# 🛡️ Diaro Data Security Measures

Diaro is designed from the ground up with a privacy-first approach. The following security measures ensure your personal moments remain truly personal.

> [!IMPORTANT]
> **Enterprise Grade Features**
> ✅ AES-256 End-to-End Encryption
> ✅ Zero-Knowledge Architecture
> ✅ Self-Destruct Notes
> ✅ Security Audit Logs

---

## 1. User Authentication
* **Email & Password Login:** Standard secure login.
* **Google Sign-In:** OAuth 2.0 integration for seamless access.
* **Strong Password Policy:**
  * Minimum 8 characters.
  * Must include uppercase, lowercase, numbers, and special characters.
* **Account Activation:** Email verification required before account activation.
* **Password Reset:** Secure password reset via email.

## 2. Password Security
* **Never store plain-text passwords.**
* **Secure Hashing Algorithms:** 
  * Argon2 (Recommended) or bcrypt.
* **Salting:** All passwords are salted before hashing.
* **Rate Limiting:** Protection against brute-force login attempts.

## 3. Session Security
* **JWT-based Authentication:** Secure, stateless session tokens.
* **Secure Refresh Tokens:** Short-lived tokens to mitigate interception risks.
* **Automatic Session Expiration:** Sessions timeout after periods of inactivity.
* **Device Management:** Option to "Logout from all devices".

## 4. Notes Encryption
### At Rest
* Note content is encrypted using **AES-256** before being stored in the database.
### In Transit
* All API communication and data transfers are protected via **HTTPS/TLS encryption**.

## 5. Biometric Authentication (Mobile App)
* **Fingerprint Unlock & Face Unlock** (on supported devices).
* Biometric verification is strictly required before viewing protected notes.

## 6. Secure Folder Protection
Users can create specialized protected folders:
* **Locked Folders**
* **PIN-Protected Folders**
* **Biometric-Protected Folders**

**Example:**
> 📁 **Personal Diary**
> └── 🔒 Protected by Fingerprint
> 
> 📁 **Finance Notes**
> └── 🔒 Protected by 6-digit PIN

## 7. Zero-Knowledge Architecture (Advanced)
* **Client-Side Encryption:** The encryption key is generated locally on the user's device.
* **Blind Storage:** The server only stores encrypted data payloads.
* **Absolute Privacy:** Even database administrators cannot read user notes.
*(Note: This is considered a premium/future roadmap feature).*

## 8. Database Security (Supabase)
* **Row Level Security (RLS):** Example policy ensures users can only access their own data: `auth.uid() = user_id`.
* **Database Backups & Encrypted Storage.**
* Strict access control policies on all tables.

## 9. API Security
* Rate limiting on all endpoints.
* Strict input validation and sanitization.
* Protection against **SQL Injection**, **XSS**, and **CSRF**.

## 10. Device Security
* Auto-lock after periods of inactivity.
* App lock on startup.
* **Screenshot Blocking** (Optional).
* Hide app content in the OS "Recent Apps" switcher view.

## 11. Backup Security
* **Encrypted Cloud Backups:** Safeguard your history safely.
* Restore workflows strictly tied to account authentication.
* Version history support for critical entries.

## 12. Self-Destruct Notes
Users can define expiration parameters for highly sensitive notes:
* Delete after reading.
* Delete after `X` days.
* Delete after `X` views.

**Example:**
> 📄 **Secret Note**
> Expiry: 24 Hours | Views Remaining: 1

## 13. Audit & Activity Logs
Maintain transparent security tracking:
* Track: Login attempts, device logins, password changes, backup restores.
* Users can view their own activity sessions:
  * *Device: Dell G16*
  * *Location: Bhimavaram*
  * *Last Login: 20 June 2026*

## 14. Privacy Features
* **No AI Training:** Note content is strictly excluded from machine learning models.
* **No Analytics:** Zero third-party analytics run on note content.
* **Data Portability:** User can export all data seamlessly.
* **Right to be Forgotten:** User can permanently delete their account and all associated data.

## 15. Compliance
* Built around **GDPR principles**.
* Data minimization.
* User consent management.
* Transparent right to delete data.
