"""Manages API Keys"""

keys = set()

async def get_key() -> str:
    """Returns the next available api key."""

class KeyCooldownPair:
    key: str
    cooldown: float
    def __init__(self, key: str):
        self.key = key
        self.cooldown = 0


if __name__ == "__main__":
    print(keys)