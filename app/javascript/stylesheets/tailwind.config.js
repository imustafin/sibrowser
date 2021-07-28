module.exports = {
  purge: {
    // from https://github.com/rails/tailwindcss-rails/pull/40/commits/6cdb6cd5d2d07f1affa08fd9d57720d3cd00416d
    enabled: ["production"].includes(process.env.NODE_ENV),
    content: [
      './app/views/**/*.*',
      './app/helpers/**/*.rb',
      './app/components/**/*.*',
    ],
  },
  darkMode: false, // or 'media' or 'class'
  theme: {
    extend: {},
  },
  variants: {
    extend: {},
  },
  plugins: [],
}
