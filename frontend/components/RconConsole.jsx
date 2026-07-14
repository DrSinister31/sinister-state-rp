// components/RconConsole.jsx
import { useEffect, useState } from 'react';
import { getSupabase } from '../lib/supabaseClient';

export default function RconConsole() {
  const [logs, setLogs] = useState([]);

  useEffect(() => {
    const supabase = getSupabase();
    const fetchLogs = async () => {
      const { data } = await supabase
        .from('rcon_logs')
        .select('*')
        .order('created_at', { ascending: false })
        .limit(50);
      if (data) setLogs(data);
    };
    fetchLogs();

    const channel = supabase
      .channel('realtime:rcon_logs')
      .on('postgres_changes', { event: 'INSERT', schema: 'public', table: 'rcon_logs' }, payload => {
        setLogs(prev => [payload.new, ...prev].slice(0, 50));
      })
      .subscribe();

    return () => { supabase.removeChannel(channel); };
  }, []);

  // ... JSX unchanged
}