/** @type {import('tailwindcss').Config} */
module.exports = {
  content: [
    "./app/**/*.{js,jsx}",
    "./components/**/*.{js,jsx}",
  ],
  theme: {
    extend: {
      colors: {
        ink: "#14151A",
        paper: "#FAF9F6",
        accent: "#3E5C4E",   // deep sage — matches an "office hours" learning feel
        accentSoft: "#E7EEE9",
        line: "#E4E2DC",
      },
      fontFamily: {
        display: ["Fraunces", "serif"],
        body: ["Inter", "sans-serif"],
      },
      borderRadius: {
        card: "10px",
      },
    },
  },
  plugins: [],
};
