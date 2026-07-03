import os
from dataclasses import dataclass


@dataclass
class Config:
    supabase_url: str
    supabase_key: str
    discord_token: str
    discord_guild_id: int
    deepseek_api_key: str
    redis_url: str
    rcon_host: str
    rcon_port: int
    rcon_password: str
    owner_discord_id: int
    admin_discord_ids: list[int]
    log_channel_id: int
    chronicles_channel_id: int
    support_channel_id: int
    business_owner_role_id: int
    business_employee_role_id: int
    staff_role_id: int
    tebex_secret: str

    @classmethod
    def from_env(cls) -> "Config":
        missing = []
        def get(key: str, default=None) -> str:
            val = os.getenv(key, default)
            if val is None and default is None:
                missing.append(key)
            return val

        cfg = cls(
            supabase_url=get("SUPABASE_URL"),
            supabase_key=get("SUPABASE_SERVICE_KEY"),
            discord_token=get("DISCORD_TOKEN"),
            discord_guild_id=int(get("DISCORD_GUILD_ID", "0")),
            deepseek_api_key=get("DEEPSEEK_API_KEY"),
            redis_url=get("REDIS_URL", "redis://localhost:6379"),
            rcon_host=get("RCON_HOST"),
            rcon_port=int(get("RCON_PORT", "30120")),
            rcon_password=get("RCON_PASSWORD"),
            owner_discord_id=int(get("OWNER_ID", "0")),
            admin_discord_ids=[int(x.strip()) for x in get("ADMIN_IDS", "").split(",") if x.strip()],
            log_channel_id=int(get("LOG_CHANNEL_ID", "0")),
            chronicles_channel_id=int(get("CHRONICLES_CHANNEL_ID", "0")),
            support_channel_id=int(get("SUPPORT_CHANNEL_ID", "0")),
            business_owner_role_id=int(get("BUSINESS_OWNER_ROLE_ID", "0")),
            business_employee_role_id=int(get("BUSINESS_EMPLOYEE_ROLE_ID", "0")),
            staff_role_id=int(get("STAFF_ROLE_ID", "0")),
            tebex_secret=get("TEBEX_SECRET", ""),
        )
        if missing:
            raise EnvironmentError(f"Missing required environment variables: {', '.join(missing)}")
        return cfg
