# NOTE: This module is currently unused. Redis infrastructure is configured
# in shared/config.py but no service currently imports or uses this client.
# If/when real-time pub/sub is needed between services, this is ready to go.

import redis.asyncio as aioredis
from .config import Config


_redis = None


async def get_redis(config: Config = None):
    global _redis
    if _redis is None:
        if config is None:
            config = Config.from_env()
        _redis = aioredis.from_url(config.redis_url)
    return _redis


async def publish(channel: str, message: str):
    r = await get_redis()
    await r.publish(channel, message)


async def subscribe(channel: str):
    r = await get_redis()
    pubsub = r.pubsub()
    await pubsub.subscribe(channel)
    return pubsub
