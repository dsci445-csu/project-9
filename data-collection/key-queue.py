"""Manages API Keys"""

import time
import asyncio

RATE_LIMIT = 100
WINDOW = 120  # seconds
REQUEST_INTERVAL = WINDOW / RATE_LIMIT  # 1.2s (for 100 requests per 2 minutes)

class KeyTimePair:
    key: str
    last_request_time: float
    def __init__(self, key: str):
        self.key = key
        self.last_request_time = 0

class KeyQueue:
    keys = []

    def add(self, key: str):
        """Add a key to the end of the queue."""
        pair = KeyTimePair(key)
        self.keys.append(pair)

    async def get_next(self) -> str:
        """Returns the next available api key."""
        if len(self.keys) == 0 or self.keys is None:
            raise Exception("No Keys")

        pair: KeyTimePair = self.keys[0]
        remining_time: float = pair.last_request_time + REQUEST_INTERVAL - time.monotonic()
        if remining_time > 0:
            await asyncio.sleep(remining_time)

        pair: KeyTimePair = self.keys.pop(0)
        pair.last_request_time = time.monotonic()
        self.keys.append(pair)
        return pair.key

if __name__ == "__main__":
    queue: KeyQueue = KeyQueue

    for i in range(10):
        queue.add(queue, f"KEY_{i}")
    
    for i in range(30):
        print(asyncio.run(queue.get_next(queue)))