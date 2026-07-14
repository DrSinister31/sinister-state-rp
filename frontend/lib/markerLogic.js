// lib/markerLogic.js
import L from 'leaflet';

// Calibration settings from Gateway_v0.21
const CAL = {
  unreal_to_simple_divisor: 1000,
  min_X: -607,
  max_X: 509,
  min_Y: -505,
  max_Y: 607,
  image_width_px: 7800,
  image_height_px: 7817,
  axis_X: "H"
};

const CAL_PX_PER_UNIT_H = CAL.image_width_px / (CAL.max_Y - CAL.min_Y);
const CAL_PX_PER_UNIT_V = CAL.image_height_px / (CAL.max_X - CAL.min_X);

/**
 * Transforms Unreal engine world coordinates to map pixel coordinates.
 * Strictly implements the calibration logic from the original project.
 */
export function worldToLatLng(wx, wy) {
  const sx = wx / CAL.unreal_to_simple_divisor;
  const sy = wy / CAL.unreal_to_simple_divisor;
  
  const rawX = (sx - CAL.min_X) * CAL_PX_PER_UNIT_V;
  const rawY = (sy - CAL.min_Y) * CAL_PX_PER_UNIT_H;
  
  // Apply coordinate axis flip logic
  const [px, py] = (CAL.axis_X === "H") ? [rawY, rawX] : [rawX, rawY];
  
  return L.latLng(CAL.image_height_px - py, px);
}

/**
 * Transforms map pixel coordinates (LatLng) back to Unreal engine world coordinates.
 */
export function latLngToWorld(lat, lng) {
  const py = CAL.image_height_px - lat;
  const px = lng;
  
  const rawX = (CAL.axis_X === "H") ? py : px;
  const rawY = (CAL.axis_X === "H") ? px : py;
  
  const sx = (rawX / CAL_PX_PER_UNIT_V) + CAL.min_X;
  const sy = (rawY / CAL_PX_PER_UNIT_H) + CAL.min_Y;
  
  const wx = sx * CAL.unreal_to_simple_divisor;
  const wy = sy * CAL.unreal_to_simple_divisor;
  
  return { x: Math.round(wx), y: Math.round(wy) };
}