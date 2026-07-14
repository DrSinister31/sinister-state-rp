// lib/iconRegistry.js
export const iconRegistry = {
  // POIs (from README.txt categories)
  'sanctuaries': '/assets/icons/poi/sanctuary.png',
  'salt_licks': '/assets/icons/poi/salt_lick.png',
  'wallows': '/assets/icons/poi/wallow.png',
  
  // Dinos/Food (extendable)
  'deer': '/assets/icons/food/deer.png',
  'boar': '/assets/icons/food/boar.png',
  'goat': '/assets/icons/food/goat.png',
  
  // Fallback
  'default': '/assets/icons/poi/default.png'
};

export const getIcon = (type) => iconRegistry[type] || iconRegistry['default'];