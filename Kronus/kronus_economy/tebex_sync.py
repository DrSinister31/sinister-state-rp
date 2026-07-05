def sync_tebex_purchases(supabase):
    """Pull Tebex purchases into economy tracking."""
    purchases = supabase.table('tebex_purchases') \
        .select('*') \
        .eq('status', 'completed') \
        .execute()

    for p in (purchases.data or []):
        supabase.table('transactions').insert({
            'citizenid': p.get('player_citizenid') or 'UNKNOWN',
            'source_citizenid': 'SYSTEM_TEBEX',
            'amount': float(p.get('price', 0)) * 100,
            'type': 'store_purchase',
            'description': f"Tebex: {p.get('package_name', 'Unknown')}",
            'status': 'completed'
        }).execute()

        supabase.table('tebex_purchases') \
            .update({'status': 'synced'}) \
            .eq('id', p['id']) \
            .execute()
