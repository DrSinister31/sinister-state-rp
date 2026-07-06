import os
from pathlib import Path
from dataclasses import dataclass

try:
    from dotenv import load_dotenv
    env_path = Path(__file__).resolve().parent.parent / "Kronus" / ".env"
    if env_path.exists():
        load_dotenv(env_path)
    else:
        load_dotenv()
except ImportError:
    pass


@dataclass
class GtaConfig:
    rcon_host: str
    rcon_port: int
    rcon_password: str
    tebex_secret: str = ""

    @classmethod
    def from_env(cls) -> "GtaConfig":
        missing = []
        def require(key: str) -> str:
            val = os.getenv(key)
            if not val:
                missing.append(key)
            return val or ""

        cfg = cls(
            rcon_host=require("RCON_HOST"),
            rcon_port=int(require("RCON_PORT") or "30120"),
            rcon_password=require("RCON_PASSWORD"),
            tebex_secret=os.getenv("TEBEX_SECRET") or "",
        )
        if missing:
            raise EnvironmentError(f"Missing: {', '.join(missing)}")
        return cfg
