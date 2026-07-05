local Locales = {}

Locales['en'] = {
    ['commands'] = {
        ['me'] = 'me',
        ['do'] = 'do',
        ['ooc'] = 'ooc',
        ['twt'] = 'twt',
        ['news'] = 'news',
        ['advert'] = 'advert',
        ['anon'] = 'anon',
        ['darkweb'] = 'darkweb',
    },
    ['chat'] = {
        ['prefix'] = '/',
        ['ooc_prefix'] = '[OOC]',
        ['me_prefix'] = '',
        ['do_prefix'] = '',
        ['twt_prefix'] = '[TWT]',
        ['news_prefix'] = '[NEWS]',
        ['advert_prefix'] = '[AD]',
        ['anon_prefix'] = '[ANON]',
        ['darkweb_prefix'] = '[DW]',
        ['job_prefix'] = '[%s]',
        ['join_message'] = '%s has arrived in Sinister H-Town.',
        ['leave_message'] = '%s has left Sinister H-Town.',
        ['channel_changed'] = 'You are now chatting in channel: %s',
        ['no_permission'] = 'You do not have access to this chat channel.',
        ['not_in_job'] = 'You are not currently on duty for this job.',
        ['auto_msg_prefix'] = '[SINISTER]',
        ['error_prefix'] = '[ERROR]',
        ['system_prefix'] = '[SYSTEM]',
        ['players_online'] = 'Players online: %s',
        ['type_suggestion'] = 'Type /help for a list of commands',
    },
    ['help'] = {
        ['title'] = 'Sinister H-Town Chat Commands',
        ['ooc'] = '/ooc [message] — Out of character chat (global)',
        ['me'] = '/me [action] — Describes your character\'s action (proximity)',
        ['do'] = '/do [description] — Describes a situation (proximity)',
        ['twt'] = '/twt [message] — Send a tweet (global)',
        ['news'] = '/news [message] — News announcement',
        ['advert'] = '/advert [message] — Post an advertisement',
        ['anon'] = '/anon [message] — Send an anonymous message',
        ['help'] = '/help — Show this help menu',
        ['clear'] = '/clear — Clear your chat window',
        ['channels_title'] = 'Job Chat Channels:',
    },
    ['errors'] = {
        ['empty_message'] = 'You cannot send an empty message.',
        ['command_not_found'] = 'Command "%s" not found.',
        ['message_too_long'] = 'Your message is too long (max 256 characters).',
        ['spam_warning'] = 'Please wait before sending another message.',
        ['chat_disabled'] = 'Chat is temporarily disabled.',
    },
    ['auto_messages'] = {
        [1] = 'Welcome to Sinister H-Town RP — Respect the RP!',
        [2] = 'Texas jobs available — /jobs to check listings',
        [3] = 'New to the city? Read the rules at discord.gg/sinisterhtown',
        [4] = 'Having fun? Bring your friends to Sinister H-Town RP!',
        [5] = 'Keep it Texas — Y\'all drive safe out there, partner!',
    },
}

Locales.Locale = 'en'

function Locales.L(key, subkey, default)
    local t = Locales[Locales.Locale]
    if not t then return default or 'MISSING_LOCALE' end
    if subkey then
        t = t[key]
        if not t then return default or 'MISSING_LOCALE' end
        return t[subkey] or default or ('MISSING_LOCALE: ' .. key .. '.' .. subkey)
    end
    return t[key] or default or ('MISSING_LOCALE: ' .. key)
end

return Locales
