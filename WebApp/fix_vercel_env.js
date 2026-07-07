const { execSync } = require('child_process');

const vars = {
  DISCORD_CLIENT_ID: '1518564934185652275',
  DISCORD_CLIENT_SECRET: 'uyJOkGnbjhdpx6kz9SPVf2dJGae0pbDv',
  NEXTAUTH_SECRET: 'e936c5b9f7d0c35478419eb7664673db874f6de48a43f8ab347517173e61a6c0',
  NEXTAUTH_URL: 'https://sinistersparkmap.vercel.app'
};

for (const [key, val] of Object.entries(vars)) {
  console.log(`Fixing ${key}...`);
  try {
    execSync(`npx vercel env rm ${key} production -y`, { stdio: 'ignore' });
  } catch (e) {} // ignore if it doesn't exist
  execSync(`npx vercel env add ${key} production --value "${val}" -y`, { stdio: 'inherit' });
}
console.log('Finished fixing environment variables!');
