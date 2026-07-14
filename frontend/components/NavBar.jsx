'use client';

import { useState, useEffect, createContext, useContext } from 'react';
import { useSession, signIn, signOut } from 'next-auth/react';
import Link from 'next/link';
import { usePathname } from 'next/navigation';
import { Paintbrush, Map, ShoppingBag, Menu, X, Shield } from 'lucide-react';

const AdminContext = createContext({ isAdmin: false, adminMode: false, toggleAdminMode: () => {} });
export const useAdmin = () => useContext(AdminContext);

export default function NavBar() {
  const { data: session } = useSession();
  const pathname = usePathname();
  const [menuOpen, setMenuOpen] = useState(false);
  const [isAdmin, setIsAdmin] = useState(false);
  const [adminMode, setAdminMode] = useState(false);
  const [balance, setBalance] = useState(null);
  const [steamId, setSteamId] = useState(null);

  useEffect(() => {
    if (typeof window !== 'undefined') {
      const stored = localStorage.getItem('sinisterAdminMode');
      if (stored === 'true') setAdminMode(true);
    }
  }, []);

  const toggleAdminMode = () => {
    const next = !adminMode;
    setAdminMode(next);
    if (typeof window !== 'undefined') {
      localStorage.setItem('sinisterAdminMode', String(next));
    }
  };

  useEffect(() => {
    if (session?.user?.id) {
      fetch(`/api/discord_link/${session.user.id}`)
        .then(r => r.json())
        .then(d => {
          if (d.steam_id) {
            setSteamId(d.steam_id);
            if (d.is_admin || d.is_mod) setIsAdmin(true);
          }
        })
        .catch(() => {});
    }
  }, [session]);

  useEffect(() => {
    if (steamId) {
      fetch(`/api/players/balance?steam_id=${steamId}`)
        .then(r => r.json())
        .then(d => { if (d.marks !== undefined) setBalance(d.marks); })
        .catch(() => {});
    }
  }, [steamId]);

  const linkClass = (href) =>
    `px-3 py-1.5 rounded text-xs font-bold uppercase tracking-wider transition-all border ${
      pathname === href
        ? 'bg-red-900/40 text-red-200 border-red-900/50 shadow-[0_0_10px_rgba(220,38,38,0.15)]'
        : 'text-neutral-500 border-transparent hover:text-neutral-300 hover:border-neutral-700'
    }`;

  const links = [
    { href: '/', icon: Map, label: 'Tracker' },
    { href: '/skin-creator', icon: Paintbrush, label: 'Skin Studio' },
    { href: '/store', icon: ShoppingBag, label: 'Store' },
  ];

  const adminLinks = [
    { href: '/admin/store', icon: Shield, label: 'Admin Store' },
  ];

  return (
    <nav className="h-11 bg-[#0e0e0e] border-b border-red-900/30 flex items-center justify-between px-3 shrink-0 select-none z-50">
      <div className="flex items-center gap-2">
        <Link href="/" className="font-['Orbitron'] text-sm font-bold tracking-widest text-white hover:text-red-400 transition-colors">
          SINISTER'S<span className="text-red-600">EVRIMA</span>
        </Link>
        {isAdmin && (
          <button
            onClick={toggleAdminMode}
            title={adminMode ? 'Switch to Player View' : 'Switch to Admin View'}
            className={`text-[9px] font-bold uppercase tracking-wider px-1.5 py-0.5 rounded border transition-all ${
              adminMode
                ? 'bg-yellow-900/30 text-yellow-400 border-yellow-700/50 shadow-[0_0_8px_rgba(234,179,8,0.2)]'
                : 'text-neutral-600 border-neutral-800 hover:text-yellow-400 hover:border-yellow-800/50'
            }`}
          >
            <Shield className={`w-3 h-3 inline mr-0.5 ${adminMode ? 'text-yellow-400' : ''}`} />
            ADMIN
          </button>
        )}
      </div>

      <div className="hidden md:flex items-center gap-1.5">
        {links.map(l => (
          <Link key={l.href} href={l.href} className={`${linkClass(l.href)} flex items-center gap-1.5`}>
            <l.icon className="w-3.5 h-3.5" /> <span>{l.label}</span>
          </Link>
        ))}
        {isAdmin && adminMode && adminLinks.map(l => (
          <Link key={l.href} href={l.href} className={`${linkClass(l.href)} flex items-center gap-1.5 ${pathname === l.href ? 'bg-yellow-900/30 text-yellow-300 border-yellow-700/50' : 'text-neutral-500'}`}>
            <l.icon className="w-3.5 h-3.5" /> <span>{l.label}</span>
          </Link>
        ))}
      </div>

      <div className="flex md:hidden items-center gap-2">
        <button onClick={() => setMenuOpen(!menuOpen)} className="p-1.5 text-neutral-400 hover:text-white transition-colors">
          {menuOpen ? <X className="w-5 h-5" /> : <Menu className="w-5 h-5" />}
        </button>
      </div>

      <div className="hidden md:flex items-center gap-2">
        {session && balance !== null && (
          <span className="text-[10px] font-bold text-red-400 font-['Orbitron'] bg-red-900/20 border border-red-900/30 px-2 py-1 rounded">
            {balance.toLocaleString()} Ⓜ
          </span>
        )}
        {session ? (
          <button onClick={() => signOut()} className="text-[10px] text-neutral-500 hover:text-red-400 transition-colors border border-neutral-800 hover:border-red-900/50 px-2 py-1 rounded font-bold uppercase tracking-wider">
            {session.user?.name || 'User'}
          </button>
        ) : (
          <button onClick={() => signIn('discord')} className="text-[10px] text-neutral-500 hover:text-white transition-colors bg-[#5865F2]/20 hover:bg-[#5865F2]/40 border border-[#5865F2]/30 px-2 py-1 rounded font-bold uppercase tracking-wider">
            Login
          </button>
        )}
      </div>

      {menuOpen && (
        <div className="absolute top-11 left-0 right-0 bg-[#0e0e0e] border-b border-red-900/30 p-3 flex flex-col gap-2 md:hidden z-[9999] shadow-2xl">
          {links.map(l => (
            <Link key={l.href} href={l.href} onClick={() => setMenuOpen(false)}
              className={`${linkClass(l.href)} flex items-center gap-2 w-full justify-center py-2`}>
              <l.icon className="w-4 h-4" /> {l.label}
            </Link>
          ))}
          {isAdmin && adminMode && adminLinks.map(l => (
            <Link key={l.href} href={l.href} onClick={() => setMenuOpen(false)}
              className={`${linkClass(l.href)} flex items-center gap-2 w-full justify-center py-2 ${pathname === l.href ? 'bg-yellow-900/30 text-yellow-300' : ''}`}>
              <l.icon className="w-4 h-4" /> {l.label}
            </Link>
          ))}
          <div className="border-t border-neutral-800 pt-2 mt-1 flex justify-center gap-2 flex-wrap">
            {session && balance !== null && (
              <span className="text-[10px] font-bold text-red-400 font-['Orbitron'] bg-red-900/20 border border-red-900/30 px-2 py-1 rounded">
                {balance.toLocaleString()} Ⓜ
              </span>
            )}
            {session ? (
              <button onClick={() => { signOut(); setMenuOpen(false); }} className="text-[10px] text-neutral-500 hover:text-red-400 transition-colors border border-neutral-800 hover:border-red-900/50 px-3 py-1.5 rounded font-bold uppercase tracking-wider">
                {session.user?.name || 'Logout'}
              </button>
            ) : (
              <button onClick={() => { signIn('discord'); setMenuOpen(false); }} className="text-[10px] text-neutral-500 hover:text-white transition-colors bg-[#5865F2]/20 hover:bg-[#5865F2]/40 border border-[#5865F2]/30 px-3 py-1.5 rounded font-bold uppercase tracking-wider">
                Login with Discord
              </button>
            )}
          </div>
        </div>
      )}
    </nav>
  );
}
