import NextAuth from "next-auth";
import DiscordProvider from "next-auth/providers/discord";

export const authOptions = {
  providers: [
    DiscordProvider({
      clientId: process.env.DISCORD_CLIENT_ID || "",
      clientSecret: process.env.DISCORD_CLIENT_SECRET || "",
      authorization: { params: { scope: 'identify' } },
    }),
  ],
  callbacks: {
    async session({ session, token }) {
      if (session?.user) {
        session.user.id = token.sub; // Attach discord ID to session
      }
      return session;
    },
    async jwt({ token, profile }) {
      if (profile) {
        token.sub = profile.id; // Discord ID
      }
      return token;
    }
  },
  secret: process.env.NEXTAUTH_SECRET || "fallback_secret_for_dev_only",
};

const handler = NextAuth(authOptions);

export { handler as GET, handler as POST };
