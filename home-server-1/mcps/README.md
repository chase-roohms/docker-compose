# MCPs

Dedicated Docker Compose stack for Model Context Protocol servers on `home-server-1`. Initially this stack runs **Gramps Web MCP** only. Add other MCP services to this Compose file as needed.

Gramps Web itself remains in `../gramps/`, and LiteLLM remains in `../lite-llm/`. Neither existing stack needs to be modified.

## Setup

1. Ensure Gramps Web is running on host port **8991** and you can sign in.
2. Copy the example configuration, then fill in your credentials and tree UUID:

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

3. Validate and start:

   ```bash
   docker compose config --quiet
   docker compose pull
   docker compose up -d
   docker compose ps
   docker compose logs --tail=100 gramps-mcp
   ```

4. Confirm the MCP container is healthy (the `/health` endpoint checks Gramps Web authentication):

   ```bash
   curl -i "http://192.168.1.113:8992/health"
   ```

## Register in LiteLLM

Use **MCP Servers → Add** in your existing LiteLLM admin interface:

| Field | Value |
| --- | --- |
| Name | `gramps` |
| Transport | Streamable HTTP |
| URL | `http://192.168.1.113:8992/mcp` |
| Authentication | Bearer token |
| Token | The `MCP_API_KEY` value from your private `.env` |

If `MCP_BIND_IP` or `GRAMPS_MCP_PORT` changed, substitute your actual URL. LiteLLM already runs on the same server and can reach the published LAN endpoint without a new Docker network.

Then verify with your existing LiteLLM virtual key:

```bash
curl -sS http://localhost:4000/mcp-rest/tools/list \
  -H "Authorization: Bearer YOUR_LITELLM_VIRTUAL_KEY"
```

After LiteLLM lists Gramps tools, restart the existing OpenAI tunnel client to retry MCP initialization. ChatGPT's tunnel connects to LiteLLM; **do not point the OpenAI tunnel at this Gramps service directly** if you want one aggregated gateway.

## Security and future writes

- The MCP endpoint binds to the **LAN IP only**, not to a public reverse proxy. Do **not** forward port 8992 on the router. It still needs an `MCP_API_KEY`; keep it out of Git.
- `.env` is excluded by the repository's root `.gitignore`. Docker administrators can inspect container environment variables.
- **Read-only is enabled by default.** After backing up your tree, set `GRAMPS_READ_ONLY=false` and recreate the service to enable create/update tools.
- For safety, `GRAMPS_CONFIRMATION=required` with stateless HTTP prevents delete, merge and undo tools from executing even after read-only is disabled. Only revisit these settings if you deliberately want those operations and understand the confirmation behavior.
- There is no Gramps data volume in this MCP stack. Gramps Web stores the tree; the MCP service communicates with its API.

## Upstream

- [Scormave/gramps-web-mcp](https://github.com/Scormave/gramps-web-mcp)
- [Official MCP installation reference](https://github.com/Scormave/gramps-web-mcp/blob/main/GrampsWeb.Mcp/docs/INSTALLATION.md)
- [MCP HTTP authentication reference](https://github.com/Scormave/gramps-web-mcp/blob/main/GrampsWeb.Mcp/docs/CONFIGURATION.md#http-authentication)
