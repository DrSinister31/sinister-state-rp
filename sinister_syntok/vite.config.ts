import { defineConfig } from "vite";
import react from "@vitejs/plugin-react";
import topLevelAwait from "vite-plugin-top-level-await";
import federation from "@originjs/vite-plugin-federation";
const name = "sinister_syntok";
export default defineConfig({
  plugins: [react(), federation({name,filename:"remoteEntry.js",exposes:{"./config":"./npwd.config.ts"},shared:["react","react-dom","react/jsx-runtime"]}), topLevelAwait({promiseExportName:"__tla",promiseImportName:i=>`__tla_${i}`})],
  build: { outDir:"web/dist", emptyOutDir:true, modulePreload:false, assetsDir:"" },
});
