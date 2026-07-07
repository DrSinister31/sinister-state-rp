// lib/iconMap.js
export const getIconUrl = (category, type) => {
  // If it's a food item, point to food folder
  if (category === 'food') return `/assets/icons/food/${type.toLowerCase()}.png`;
  
  // Otherwise point to POI folder
  const poiMap = {
    sanctuary: '/assets/icons/poi/sanctuary.png',
    salt_lick: '/assets/icons/poi/salt_lick.png',
    wallow: '/assets/icons/poi/wallow.png'
  };
  
  return poiMap[category] || '/assets/icons/poi/default.png';
};