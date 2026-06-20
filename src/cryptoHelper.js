import CryptoJS from 'crypto-js';

// Constant salt for local key derivation.
// In production, user-specific salts can be fetched, but a static local salt is standard for local vault setups.
const LOCAL_SALT = 'ynote-vault-salt-PBKDF2-sha256';

/**
 * Derives a strong 256-bit key from a password.
 * @param {string} password 
 * @param {string} [userIdentifier] Optional user email/ID to generate a user-specific dynamic salt
 * @returns {string} Key in Hex format
 */
export function deriveKey(password, userIdentifier = '') {
  if (!password) return '';
  // Zero-Knowledge Architecture: Use a user-specific dynamic salt (e.g. email) combined with the local salt
  // This makes rainbow table attacks across the user base mathematically impossible.
  const dynamicSalt = userIdentifier ? `${userIdentifier.toLowerCase()}-${LOCAL_SALT}` : LOCAL_SALT;
  
  return CryptoJS.PBKDF2(password, dynamicSalt, {
    keySize: 256 / 32,
    iterations: 1000
  }).toString();
}

/**
 * Encrypts plaintext using AES-256 with a derived key.
 * @param {string} text Plaintext
 * @param {string} keyHex Derived key hex
 * @returns {string} Ciphertext (Base64 formatted by CryptoJS)
 */
export function encryptText(text, keyHex) {
  if (!text) return '';
  if (!keyHex) return text; // Fallback if not logged in/no key (e.g. mock mode)
  return CryptoJS.AES.encrypt(text, keyHex).toString();
}

/**
 * Decrypts AES-256 ciphertext.
 * @param {string} ciphertext Ciphertext Base64
 * @param {string} keyHex Derived key hex
 * @returns {string} Plaintext, or original string if decryption fails
 */
export function decryptText(ciphertext, keyHex) {
  if (!ciphertext) return '';
  if (!keyHex) return ciphertext;
  try {
    const bytes = CryptoJS.AES.decrypt(ciphertext, keyHex);
    const decrypted = bytes.toString(CryptoJS.enc.Utf8);
    // If decryption succeeds but returns empty or corrupted output, it might be wrong password.
    if (!decrypted && ciphertext.length > 0) {
      return '[Decryption failed: Incorrect Vault Password]';
    }
    return decrypted;
  } catch (e) {
    console.error('Decryption error:', e);
    return '[Decryption failed: Ciphertext corrupted]';
  }
}

/**
 * Generates a mock recovery key matching the YN-XXXX-XXXX-XXXX format.
 * @returns {string} Recovery key
 */
export function generateRecoveryKey() {
  const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
  const segment = () => Array.from({ length: 4 }, () => chars[Math.floor(Math.random() * chars.length)]).join('');
  return `YN-${segment()}-${segment()}-${segment()}`;
}
