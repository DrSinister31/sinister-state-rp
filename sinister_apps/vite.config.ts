import { defineConfig } from "vite";
import react from "@vitejs/plugin-react";
import topLevelAwait from "vite-plugin-top-level-await";
import federation from "@originjs/vite-plugin-federation";
import packageJson from "./package.json";
const { name } = packageJson;

export default defineConfig({
  plugins: [
    react(),
    federation({
      name: name,
      filename: "remoteEntry.js",
      exposes: {
        "./config": "./npwd.config.ts",
      },
      shared: [
        "react",
        "react-dom",
        "@emotion/react",
        "react-router-dom",
      ],
    }),
    topLevelAwait({
      promiseExportName: "__tla",
      promiseImportName: (i) => `__tla_${i}`,
    }),
  ],
  define: {
    process: {
      env: {
        VITE_REACT_APP_IN_GAME: process.env.VITE_REACT_APP_IN_GAME,
      },
    },
  },
  build: {
    outDir: "web/dist",
    emptyOutDir: true,
    modulePreload: false,
    assetsDir: "",
  },
});
