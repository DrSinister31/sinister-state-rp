from datetime import datetime
from typing import Optional
from uuid import UUID
from pydantic import BaseModel, Field


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
