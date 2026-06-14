
import type { NextConfig } from "next";

const nextConfig: NextConfig = {
  eslint: {
    ignoreDuringBuilds: true,
  },
  // output: 'export' and trailingSlash are only for Capacitor mobile builds
  // They are disabled here for server deployment (API routes require server runtime)
  images: {
    unoptimized: true,
    remotePatterns: [
      {
        hostname: "images.pexels.com",
      },
      {
        hostname: "images.unsplash.com",
      },
      {
        hostname: "chat2db-cdn.oss-us-west-1.aliyuncs.com",
      },
      {
        hostname: "cdn.chat2db-ai.com",
      },
    ],
  },
};

export default nextConfig;
