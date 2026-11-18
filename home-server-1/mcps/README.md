# MCPs

Dedicated Docker Compose stack for Model Context Protocol servers on `home-server-1`. This stack runs **Gramps Web MCP** and **LegendKeeper MCP**.

Gramps Web itself remains in `../gramps/`, and LiteLLM remains in `../lite-llm/`. Neither existing stack needs to be modified.

## Setup

1. Ensure Gramps Web is running on host port **8991** and you can sign in. Have a LegendKeeper API key for your project ready.
2. Copy the example configuration, then fill in your Gramps credentials, tree UUID, and LegendKeeper API key:

   ```bash
   cd ~/docker/docker-compose/home-server-1/mcps
   cp .env.example .env
   chmod 600 .env
   nano .env
   ```

   - `GRAMPS_USERNAME` / `GRAMPS_PASSWORD`: a Gramps Web account with access to your family tree (prefer a dedicated account).
   - `GRAMPS_TREE_ID`: tree UUID from Gramps Web settings, or from `GET /api/metadata/`.
   - `MCP_API_KEY`: independently generated MCP server key, at least 16 characters; e.g. `openssl rand -base64 32`.
   - `MCP_BIND_IP`: the LAN address on which `home-server-1` should accept MCP connections. The example uses `192.168.1.113`, taken from the existing Gramps configuration.
   - `GRAMPS_READ_ONLY=true`: protects your tree while verifying the integration. Change to `false` only when ready to allow writes.
   - `LEGENDKEEPER_API_KEY`: project API key from LegendKeeper **Project Settings → Developers → API Keys** (a paid project owner is required by LegendKeeper's API).
   - `LEGENDKEEPER_MCP_AUTH_TOKEN`: separate random bearer token for the LegendKeeper HTTP endpoint, e.g. `openssl rand -hex 32`.
   - `LEGENDKEEPER_READ_ONLY=true`: starts with only read tools available. Change to `false` and recreate the service when you intentionally want editing capabilities.
   - `LEGENDKEEPER_MCP_PORT=8993`: published LAN port for LegendKeeper.

3. Validate and start:

   ```bash
   docker compose config --quiet
   docker compose pull
   docker compose up -d
   docker compose ps
   docker compose logs --tail=100 gramps-mcp legendkeeper-mcp
   ```

4. Confirm the MCP container is healthy (the `/health` endpoint checks Gramps Web authentication):

   ```bash
   curl -i "http://192.168.1.113:8992/health"
   curl -i "http://192.168.1.113:8993/healthz"
   ```

Before starting LegendKeeper, you can verify its credentials independently with `docker compose run --rm legendkeeper-mcp check`. The published `/healthz` endpoint checks process health; it is not a substitute for testing API credentials.

## Register in LiteLLM

Use **MCP Servers → Add** in your existing LiteLLM admin interface:

| Field | Value |
| --- | --- |
| Name | `gramps` |
| Transport | Streamable HTTP |
| URL | `http://192.168.1.113:8992/mcp` |
| Authentication | Bearer token |
| Token | The `MCP_API_KEY` value from your private `.env` |

Add a second MCP server in the LiteLLM UI:

| Field | Value |
| --- | --- |
| Name | `legendkeeper` |
| Transport | Streamable HTTP |
| URL | `http://192.168.1.113:8993/mcp` |
| Authentication | Bearer token |
| Token | The `LEGENDKEEPER_MCP_AUTH_TOKEN` value from `.env` |

If `MCP_BIND_IP`, `GRAMPS_MCP_PORT`, or `LEGENDKEEPER_MCP_PORT` changed, substitute your actual URLs. LiteLLM already runs on the same server and can reach the published LAN endpoint without a new Docker network.

Then verify with your existing LiteLLM virtual key:

```bash
curl -sS http://localhost:4000/mcp-rest/tools/list \
  -H "Authorization: Bearer YOUR_LITELLM_VIRTUAL_KEY"
```

After LiteLLM lists Gramps and LegendKeeper tools, grant the existing LiteLLM virtual key access to the new LegendKeeper tools, then restart the existing OpenAI tunnel client to retry MCP initialization. ChatGPT's tunnel connects to LiteLLM; **do not point the OpenAI tunnel at either MCP service directly** if you want one aggregated gateway.

## Security and future writes

- Both MCP endpoints bind to the **LAN IP only**, not to a public reverse proxy. Do **not** forward ports 8992 or 8993 on the router. Each has its own bearer token (`MCP_API_KEY` or `LEGENDKEEPER_MCP_AUTH_TOKEN`); keep them out of Git.
- `.env` is excluded by the repository's root `.gitignore`. Docker administrators can inspect container environment variables.
- **Read-only is enabled by default for both services.** After backing up your tree, set `GRAMPS_READ_ONLY=false` and recreate the Gramps service to enable create/update tools. Set `LEGENDKEEPER_READ_ONLY=false` and recreate LegendKeeper only when you want its write tools.
- For safety, `GRAMPS_CONFIRMATION=required` with stateless HTTP prevents delete, merge and undo tools from executing even after read-only is disabled. Only revisit these settings if you deliberately want those operations and understand the confirmation behavior.
- Neither service needs a local data volume here. Gramps Web stores the family tree; LegendKeeper stores the campaign data. The MCP services communicate with their APIs.
- LegendKeeper image uploading from local disk is not configured in this stack. URL-based upload support depends on LegendKeeper MCP settings.

## Upstream

- [Scormave/gramps-web-mcp](https://github.com/Scormave/gramps-web-mcp)
- [Official MCP installation reference](https://github.com/Scormave/gramps-web-mcp/blob/main/GrampsWeb.Mcp/docs/INSTALLATION.md)
- [MCP HTTP authentication reference](https://github.com/Scormave/gramps-web-mcp/blob/main/GrampsWeb.Mcp/docs/CONFIGURATION.md#http-authentication)

- [chase-roohms/legendkeeper-mcp](https://github.com/chase-roohms/legendkeeper-mcp)
