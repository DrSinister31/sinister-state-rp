// lib/mapConfig.js
export const MAP_CONFIG = {
  imageUrl: '/assets/gateway.webp',
  bounds: [[0, 0], [7817, 7800]],
  cal: {
    unreal_to_simple_divisor: 1000,
    min_X: -607,
    max_X: 509,
    min_Y: -505,
    max_Y: 607,
    axis_X: "H"
  },
  // Map categories to your public/assets/ icons
  categoryIcons: {
    sanctuaries: '/assets/icons/sanctuary.png',
    food_deer: '/assets/icons/food_deer.png',
    tp_points: '/assets/icons/pin.png',
    default: '/assets/icons/marker.png'
  }
};