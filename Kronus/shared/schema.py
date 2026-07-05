from datetime import datetime
from typing import Optional
from uuid import UUID
from pydantic import BaseModel, Field


class DiscordPlayer(BaseModel):
    discord_id: int
    citizenid: str
    discord_username: Optional[str] = None
    linked_at: Optional[datetime] = None
    last_seen: Optional[datetime] = None
    fivem_license: Optional[str] = None


class Character(BaseModel):
    citizenid: str
    first_name: str
    last_name: str
    dob: Optional[datetime] = None
    gender: Optional[str] = None
    nationality: Optional[str] = None
    job_name: Optional[str] = None
    job_grade: int = 0
    gang_name: Optional[str] = None
    gang_grade: int = 0
    active: bool = True


class PlayerEconomy(BaseModel):
    citizenid: str
    cash: int = 0
    bank: int = 0
    crypto: int = 0
    dirty_money: int = 0
    savings: int = 0
    debt_owed: int = 0
    wealth_bracket: str = "Lower"


class Transaction(BaseModel):
    id: Optional[UUID] = None
    from_citizenid: Optional[str] = None
    to_citizenid: Optional[str] = None
    amount: int
    account_type: str
    reason: Optional[str] = None
    channel: Optional[str] = None
    business_id: Optional[UUID] = None


class Business(BaseModel):
    id: Optional[UUID] = None
    owner_citizenid: str
    name: str
    business_type: str
    revenue: int = 0
    employee_count: int = 0
    location: Optional[dict] = None
    active: bool = True
    delinquent: bool = False
    ai_placeholder: bool = False


class CriminalRecord(BaseModel):
    id: Optional[UUID] = None
    citizenid: str
    charge: str
    severity: str = "Misdemeanor"
    officer_citizenid: Optional[str] = None
    convicted: bool = False
    fine_amount: int = 0
    jail_time: int = 0


class Warrant(BaseModel):
    id: Optional[UUID] = None
    citizenid: str
    reason: str
    issuing_officer: Optional[str] = None
    active: bool = True


class Strike(BaseModel):
    id: Optional[UUID] = None
    citizenid: str
    discord_id: Optional[int] = None
    violation: str
    strike_count: int = 1
    fine_amount: int = 0
    moderator_id: Optional[str] = None


class Ban(BaseModel):
    id: Optional[UUID] = None
    citizenid: Optional[str] = None
    discord_id: Optional[int] = None
    reason: str
    moderator_id: Optional[str] = None
    duration: Optional[str] = None
    active: bool = True


class KronusLog(BaseModel):
    id: Optional[UUID] = None
    service: str
    action: str
    context_json: dict = {}
    result: Optional[str] = None


class KronusPolicy(BaseModel):
    id: Optional[UUID] = None
    policy_key: str
    value: dict
    confidence: float = 0.0
    applied: bool = False
    reviewed_by: Optional[int] = None


class RconCommand(BaseModel):
    id: Optional[UUID] = None
    command: str
    source: Optional[str] = None
    status: str = "pending"


class CompendiumMonsterStats(BaseModel):
    strength: int = Field(default=10, alias="str")
    dexterity: int = Field(default=10, alias="dex")
    constitution: int = Field(default=10, alias="con")
    intelligence: int = Field(default=10, alias="int")
    wisdom: int = Field(default=10, alias="wis")
    charisma: int = Field(default=10, alias="cha")

    model_config = {"populate_by_name": True}


class CompendiumMonsterTrait(BaseModel):
    name: str
    desc: str


class CompendiumAetherCore(BaseModel):
    tier: str = "None"
    element: str = "None"
    value_gc: int = 0


class CompendiumMonster(BaseModel):
    id: Optional[UUID] = None
    name: str
    size: str = "Medium"
    type: str
    alignment: str = "unaligned"
    ac: int = 10
    hp: str = "1 (1d4-1)"
    speed: str = "30 ft."
    stats: CompendiumMonsterStats = CompendiumMonsterStats()
    saving_throws: Optional[dict] = None
    skills: Optional[dict] = None
    damage_vulnerabilities: Optional[str] = None
    damage_resistances: Optional[str] = None
    damage_immunities: Optional[str] = None
    condition_immunities: Optional[str] = None
    senses: str = "passive Perception 10"
    languages: Optional[str] = None
    cr: float = 0
    xp: int = 0
    traits: list[CompendiumMonsterTrait] = []
    actions: list[CompendiumMonsterTrait] = []
    legendary_actions: list[CompendiumMonsterTrait] = []
    lair_actions: list[CompendiumMonsterTrait] = []
    reactions: list[CompendiumMonsterTrait] = []
    lore: str = ""
    aether_core: CompendiumAetherCore = CompendiumAetherCore()
    source_tags: list[str] = ["solis-grave"]
    biome_tags: list[str] = []
    public: bool = False


class CompendiumSessionState(BaseModel):
    id: int = 1
    session_active: bool = False
    player_access_enabled: bool = True
    dm_discord_id: Optional[int] = None
