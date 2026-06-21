/** @type {import('tailwindcss').Config} */
export default {
  content: [
    "./index.html",
    "./src/**/*.{js,ts,jsx,tsx}",
  ],
  theme: {
    extend: {
      colors: {
        diaroAccent: {
          50: '#fbf8f5',
          100: '#f5ece3',
          200: '#ebd7c4',
          300: '#ddba9b',
          400: '#ce966e',
          500: '#b87333', // Main accent (Copper Bronze)
          600: '#a76128',
          700: '#8b4b1f',
          800: '#713c1c',
          900: '#5d3219',
          950: '#331a0c',
        },
        bgDark: '#000000',      // Obsidian Pure Black
        surfaceDark: '#050505', // Deep Black card background
      },
      fontFamily: {
        sans: ['Outfit', 'sans-serif'],
        mono: ['JetBrains Mono', 'monospace'],
      }
    },
  },
  plugins: [],
}
