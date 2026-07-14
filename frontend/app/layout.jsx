import "./globals.css";
import { Providers } from "./Providers";
import NavBar from "../components/NavBar";
import AudioPlayer from "../components/AudioPlayer";

export const metadata = {
  title: "Sinister's Evrima",
  description: "Live map tracker and skin creator for Sinister's Evrima",
};

export default function RootLayout({ children }) {
  return (
    <html lang="en">
      <head>
        <meta name="viewport" content="width=device-width, initial-scale=1, maximum-scale=1, user-scalable=no" />
        <link rel="preconnect" href="https://fonts.googleapis.com" />
        <link rel="preconnect" href="https://fonts.gstatic.com" crossOrigin="anonymous" />
        <link href="https://fonts.googleapis.com/css2?family=Creepster&family=Nosifer&family=Orbitron:wght@400;700&display=swap" rel="stylesheet" />
      </head>
      <body>
        <Providers>
          <div className="flex flex-col min-h-dvh h-dvh">
          <NavBar />
          <AudioPlayer />
          <div className="flex-1 relative overflow-hidden">
            {children}
          </div>
          </div>
        </Providers>
      </body>
    </html>
  );
}
