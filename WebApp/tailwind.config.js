/** @type {import('tailwindcss').Config} */
module.exports = {
  content: [
    "./app/**/*.{js,ts,jsx,tsx,mdx}",
    "./pages/**/*.{js,ts,jsx,tsx,mdx}",
    "./components/**/*.{js,ts,jsx,tsx,mdx}",
  ],
  theme: {
    extend: {
      colors: {
        'syn-bg': 'var(--syn-bg)',
        'syn-black': 'var(--syn-black)',
        'syn-charcoal': 'var(--syn-charcoal)',
        'syn-crimson': 'var(--syn-crimson)',
      }
    },
  },
  plugins: [],
}
