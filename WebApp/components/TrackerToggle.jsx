'use client';
import { useState } from 'react';

export default function TrackerToggle({ onToggle }) {
  const [active, setActive] = useState(false);

  const handleClick = () => {
    setActive(!active);
    onToggle(!active);
  };

  return (
    <button 
      onClick={handleClick}
      className={`w-full py-2 border ${active ? 'bg-purple-900 border-purple-500' : 'bg-gray-800 border-gray-600'}`}
    >
      {active ? 'Disable Tracker' : 'Enable Tracker'}
    </button>
  );
}