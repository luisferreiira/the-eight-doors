"""Use the installed stdio attach bridge, which reuses the existing backend."""
import asyncio
import json
import sys
from pathlib import Path
from mcp import ClientSession, StdioServerParameters
from mcp.client.stdio import stdio_client

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / 'docs/expansao_2026-10-30'

async def main():
    params = StdioServerParameters(command=sys.executable, args=['-m','godot_ai','attach','--port','8001','--ws-port','8002'])
    async with stdio_client(params) as (read,write):
        async with ClientSession(read,write) as session:
            await session.initialize()
            catalog = await session.list_tools()
            (OUT/'mcp_catalogo.json').write_text(catalog.model_dump_json(indent=2),encoding='utf-8')
            if len(sys.argv)>1:
                calls = json.loads(Path(sys.argv[1]).read_text(encoding='utf-8-sig'))
            else:
                calls = [{'name':'editor_state','arguments':{}}]
            for i, call in enumerate(calls):
                result = await session.call_tool(call['name'],call.get('arguments',{}))
                (OUT/f"mcp_{call.get('label',call['name'])}.json").write_text(result.model_dump_json(indent=2),encoding='utf-8')
                print(call['name'],result.model_dump_json()[:8000],flush=True)
                data = json.loads(result.model_dump_json())
                if data.get('is_error',data.get('isError',False)):
                    raise RuntimeError('MCP call failed; dependent calls stopped: ' + call['name'])

asyncio.run(main())
