import json
import redis.asyncio as aioredis
from .config import Config

_redis: aioredis.Redis | None = None


async def get_redis(config: Config | None = None) -> aioredis.Redis:
    global _redis
    if _redis is None:
        if config is None:
            config = Config.from_env()
        _redis = aioredis.from_url(config.redis_url)
    return _redis


async def publish(channel: str, data: dict):
    r = await get_redis()
    await r.publish(channel, json.dumps(data))


async def subscribe(channel: str):
    r = await get_redis()
    pubsub = r.pubsub()
    await pubsub.subscribe(channel)
    return pubsub
