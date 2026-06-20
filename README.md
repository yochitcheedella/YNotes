# 🔐 YNotes — Your Notes. Your Privacy.

A premium, encrypted personal notes web app built with React + Vite and Supabase.

## ✨ Features

- 🔐 **End-to-End Encryption** — AES-256 encryption in your browser. Plaintext never leaves your device.
- 📓 **Rich Note Editor** — Write diary entries, memories, and thoughts with ease.
- 🔍 **Search Memories** — Instantly search through your encrypted notes.
- 📊 **Mood Analytics** — Track your emotional patterns over time.
- 🎤 **Voice-to-Text** — Dictate your thoughts hands-free.
- 🖼️ **Media Vault** — Securely store images and files.
- 🌙 **Dark Mode** — Premium cybersecurity-inspired dark UI.
- 🔒 **Auto-Lock** — Automatically locks after inactivity.

## 🚀 Tech Stack

| Layer | Technology |
|-------|-----------|
| Frontend | React 19 + Vite |
| Styling | Tailwind CSS + Glassmorphism |
| Backend | Supabase (PostgreSQL) |
| Auth | Supabase Auth |
| Encryption | CryptoJS AES-256 + PBKDF2 |
| Deployment | Vercel |

## 🛠️ Local Development

```bash
# Install dependencies
npm install

# Create .env file
cp .env.example .env
# Add your Supabase URL and anon key

# Run dev server
npm run dev
```

Open [http://localhost:3000](http://localhost:3000)

## 🔧 Environment Variables

Create a `.env` file:

```env
VITE_SUPABASE_URL=https://your-project.supabase.co
VITE_SUPABASE_ANON_KEY=your-anon-key-here
```

> ⚠️ Never commit your `.env` file. It's already in `.gitignore`.

## 🏗️ Project Structure

```
YNotes/
├── src/
│   ├── components/
│   │   ├── Login.jsx          # Auth screen
│   │   ├── Dashboard.jsx      # Main notes dashboard
│   │   ├── EntryEditor.jsx    # Note editor
│   │   ├── SearchMemories.jsx # Search interface
│   │   ├── Analytics.jsx      # Mood analytics
│   │   ├── MediaVault.jsx     # Media storage
│   │   └── Settings.jsx       # App settings
│   ├── App.jsx                # Root component + routing
│   ├── supabaseClient.js      # Supabase connection
│   ├── cryptoHelper.js        # AES-256 encryption utils
│   └── index.css              # Global styles
├── mockups/                   # HTML design mockups
├── lib/                       # Flutter mobile app (WIP)
├── vercel.json                # Vercel SPA routing config
└── package.json
```

## 🔐 Security

- All note content is encrypted **before** being sent to Supabase
- Your master password is **never stored** — only a derived key
- Even Supabase admins cannot read your notes

## 📄 License

MIT License — © 2026 YNotes
