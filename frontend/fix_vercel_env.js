const { execSync } = require('child_process');

const vars = {
  DISCORD_CLIENT_ID: process.env.DISCORD_CLIENT_ID || '',
  DISCORD_CLIENT_SECRET: process.env.DISCORD_CLIENT_SECRET || '',
  NEXTAUTH_SECRET: process.env.NEXTAUTH_SECRET || '',
  NEXTAUTH_URL: process.env.NEXTAUTH_URL || 'https://sinistersparkmap.vercel.app'
};

for (const [key, val] of Object.entries(vars)) {
  console.log(`Fixing ${key}...`);
  try {
    execSync(`npx vercel env rm ${key} production -y`, { stdio: 'ignore' });
  } catch (e) {} // ignore if it doesn't exist
  execSync(`npx vercel env add ${key} production --value "${val}" -y`, { stdio: 'inherit' });
}
console.log('Finished fixing environment variables!');
