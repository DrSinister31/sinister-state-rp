import esbuild from "esbuild";

const isWatch = process.argv.includes("--watch");

const ctx = await esbuild.context({
  entryPoints: { "client": "client/client.ts", "server": "server/server.ts" },
  tsconfig: "tsconfig.json",
  outdir: "dist",
  format: "esm",
  platform: "node",
  target: "esnext",
  bundle: true,
  external: ["@citizenfx/server", "@citizenfx/client"],
  logLevel: "info",
});

if (isWatch) {
  await ctx.watch();
  console.log("Watching for changes...");
} else {
  await ctx.rebuild();
  await ctx.dispose();
}
