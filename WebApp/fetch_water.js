const https = require('https');

function fetchUrl(url) {
  return new Promise((resolve, reject) => {
    const req = https.get(url, {
      headers: {
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)'
      }
    }, (res) => {
      if(res.statusCode >= 300 && res.statusCode < 400 && res.headers.location) {
        let redirect = res.headers.location;
        if(!redirect.startsWith('http')) {
           const urlObj = new URL(url);
           redirect = urlObj.origin + redirect;
        }
        return resolve(fetchUrl(redirect));
      }
      let data = '';
      res.on('data', chunk => data += chunk);
      res.on('end', () => resolve(data));
    });
    req.on('error', reject);
  });
}

async function run() {
  try {
    const html = await fetchUrl('https://vulnona.com/game/the_isle/');
    const jsFiles = html.match(/src="([^"]+\.js)"/gi) || [];
    let allText = html;
    
    for(let file of jsFiles) {
      let url = file.replace(/src="/i, '').replace(/"/, '');
      if(!url.startsWith('http')) {
        url = url.startsWith('/') ? 'https://vulnona.com' + url : 'https://vulnona.com/game/the_isle/' + url;
      }
      console.log('Fetching', url);
      try {
        const jsContent = await fetchUrl(url);
        allText += jsContent;
      } catch(err) { console.error('Failed', url) }
    }
    
    const imageLinks = allText.match(/(?:https?:\/\/)?(?:[a-zA-Z0-9_\-\.\/]+)\.(?:png|jpg|webp|svg)/gi) || [];
    const uniqueLinks = [...new Set(imageLinks)];
    const waterLinks = uniqueLinks.filter(l => l.toLowerCase().includes('water'));
    console.log('Water links:', waterLinks);
    console.log('Some other links:', uniqueLinks.slice(0, 10));
    
  } catch(e) {
    console.error(e);
  }
}
run();
