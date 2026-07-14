const https = require('https');
https.get('https://vulnona.com/game/the_isle/', (res) => {
  let data = '';
  res.on('data', chunk => data += chunk);
  res.on('end', () => {
    const matches = data.match(/[\w\/\.-]+\.(?:png|jpg|webp)/gi);
    if(matches) {
      console.log('Image links:', [...new Set(matches)].filter(m => m.includes('water')));
    } else {
      console.log('No matches');
    }
  });
});
