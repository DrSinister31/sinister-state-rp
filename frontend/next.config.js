/** @type {import('next').NextConfig} */
const path = require('path');
require('dotenv').config({ path: path.resolve(__dirname, '../.env') });

const nextConfig = {
  reactStrictMode: true,
  // Required for Cloudflare Pages — no Node.js image optimization server
  images: {
    unoptimized: true,
  },
}

module.exports = nextConfig
