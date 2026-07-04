import { defineConfig } from 'vite';

export default defineConfig({
  esbuild: {
    jsx: 'automatic',
  },
  build: {
    target: 'esnext',
    outDir: '../dist/web',
    emptyOutDir: true,
    minify: false,
    lib: {
      entry: './src/index.tsx',
      formats: ['iife'],
      name: '__npwd_ext_sinister_apps',
      fileName: () => 'app.js',
    },
    rollupOptions: {
      external: [
        'react',
        'react/jsx-runtime',
        'react-dom',
        'lucide-react',
        '@npwd/sdk',
        '@npwd/keyos',
        'motion/react',
      ],
      output: {
        globals: {
          'react': '__npwd_React',
          'react/jsx-runtime': '__npwd_jsxRuntime',
          'react-dom': '__npwd_ReactDOM',
          'lucide-react': '__npwd_lucideReact',
          '@npwd/sdk': '__npwd_sdk',
          '@npwd/keyos': '__npwd_keyos',
          'motion/react': '__npwd_motionReact',
        },
      },
    },
  },
});
