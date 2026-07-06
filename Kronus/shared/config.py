import os
from pathlib import Path
from dataclasses import dataclass, field

try:
    from dotenv import load_dotenv
    env_path = Path(__file__).resolve().parent.parent / ".env"
    if env_path.exists():
        load_dotenv(env_path)
    else:
        load_dotenv()
except ImportError:
    pass


@dataclass
class Config:
    supabase_url: str
    supabase_key: str
    discord_token: str
    discord_guild_id: int
    deepseek_api_key: str
    owner_discord_id: int
    admin_discord_ids: list[int]

    dm_session_role_id: int = 0
    dm_voice_channel_id: int = 0
    dm_text_channel_id: int = 0
    dnd_category_id: int = 0
    campaign_channel_prefix: str = "rp"
    character_sheets_channel_id: int = 0
    dm_dice_channel_id: int = 0
    dm_create_vc_channel_id: int = 0
    dm_create_cmd_channel_id: int = 0
    dm_role_id: int = 0
    dm_guide_channel_id: int = 0

    redis_url: str = "redis://localhost:6379"
    log_channel_id: int = 0
    chronicles_channel_id: int = 0
    support_channel_id: int = 0
    business_owner_role_id: int = 0
    business_employee_role_id: int = 0
    staff_role_id: int = 0

    @classmethod
    def from_env(cls) -> "Config":
        missing = []
        def require(key: str) -> str:
            val = os.getenv(key)
            if not val:
                missing.append(key)
            return val or ""

        cfg = cls(
            supabase_url=require("SUPABASE_URL"),
            supabase_key=require("SUPABASE_SERVICE_KEY"),
            discord_token=require("DISCORD_TOKEN"),
            discord_guild_id=int(require("DISCORD_GUILD_ID") or "0"),
            deepseek_api_key=require("DEEPSEEK_API_KEY"),
            owner_discord_id=int(require("OWNER_ID") or "0"),
            admin_discord_ids=[int(x.strip()) for x in (require("ADMIN_IDS")).split(",") if x.strip()],
            dm_session_role_id=int(os.getenv("DM_SESSION_ROLE_ID") or "0"),
            dm_voice_channel_id=int(os.getenv("DM_VOICE_CHANNEL_ID") or "0"),
            dm_text_channel_id=int(os.getenv("DM_TEXT_CHANNEL_ID") or "0"),
            dnd_category_id=int(os.getenv("DND_CATEGORY_ID") or "0"),
            campaign_channel_prefix=os.getenv("CAMPAIGN_CHANNEL_PREFIX") or "rp",
            character_sheets_channel_id=int(os.getenv("CHARACTER_SHEETS_CHANNEL_ID") or "0"),
            dm_dice_channel_id=int(os.getenv("DM_DICE_CHANNEL_ID") or "0"),
            dm_create_vc_channel_id=int(os.getenv("DM_CREATE_VC_CHANNEL_ID") or "0"),
            dm_create_cmd_channel_id=int(os.getenv("DM_CREATE_CMD_CHANNEL_ID") or "0"),
            dm_role_id=int(os.getenv("DM_ROLE_ID") or "0"),
            dm_guide_channel_id=int(os.getenv("DM_GUIDE_CHANNEL_ID") or "0"),
            redis_url=os.getenv("REDIS_URL") or "redis://localhost:6379",
            log_channel_id=int(os.getenv("LOG_CHANNEL_ID") or "0"),
            chronicles_channel_id=int(os.getenv("CHRONICLES_CHANNEL_ID") or "0"),
            support_channel_id=int(os.getenv("SUPPORT_CHANNEL_ID") or "0"),
            business_owner_role_id=int(os.getenv("BUSINESS_OWNER_ROLE_ID") or "0"),
            business_employee_role_id=int(os.getenv("BUSINESS_EMPLOYEE_ROLE_ID") or "0"),
            staff_role_id=int(os.getenv("STAFF_ROLE_ID") or "0"),
        )
        if missing:
            raise EnvironmentError(f"Missing: {', '.join(missing)}")
        return cfg
