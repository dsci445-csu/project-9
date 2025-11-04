import asyncio
import sys
import aiohttp
from keyqueue import KeyQueue
from requesturls import page_url, match_ids_url, match_url, timeline_url

MAX_CONCURRENT_REQUESTS = 5

shutdown = asyncio.Event()
queue_lock = asyncio.Lock()
queue: KeyQueue = KeyQueue()
request_queue = asyncio.Queue(maxsize=100)

async def make_request(session, url: str, key: str):
    await asyncio.sleep(1)
    print(f"mock request with url: {url} and key: {key}")

async def request_loop():
    async with aiohttp.ClientSession() as session:
        while True:
            get_task = asyncio.create_task(request_queue.get())
            shutdown_task = asyncio.create_task(shutdown.wait())
            done, pending = await asyncio.wait({get_task, shutdown_task}, return_when=asyncio.FIRST_COMPLETED)
            for t in pending:
                t.cancel()

            if shutdown_task in done:
                break

            url = get_task.result()

            try:
                async with queue_lock:
                    key = await queue.get_next()
                await make_request(session, url, key)
            finally:
                request_queue.task_done()

async def control_loop():
    while not shutdown.is_set():
        print("Type 'quit' to exit program")
        print("> ", end="", flush=True)
        line = await asyncio.to_thread(sys.stdin.readline)
        if not line:
            shutdown.set()
            break

        input = line.strip().split()
        if not input:
            continue
        cmd, *args = input

        if cmd == "quit":
            shutdown.set()
        if cmd == "print":
            print(args)
        if cmd == "api":
            if args: 
                async with queue_lock:
                    queue.add(args[0])
                print(f"Key added. Total Keys: {len(queue.keys)}")
            else:
                print(f"Total Keys: {len(queue.keys)}")
        if cmd == "add":
            sample_type: str = args[0] # All divisions, specific division
            breadth = args[1]
            depth = args[2]
            await request_queue.put((sample_type, breadth, depth))


        


async def main():
    """Requests and saves data from the riot api given user specifications."""
    async with asyncio.TaskGroup() as tg:
        # make a rquest loop for each max concurrent request
        tg.create_task(request_loop())
        tg.create_task(control_loop())
        
        await shutdown.wait()

if __name__ == "__main__":
    asyncio.run(main())
