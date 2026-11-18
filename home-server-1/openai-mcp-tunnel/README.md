# OpenAI Secure MCP Tunnel

Outbound-only tunnel from ChatGPT to the existing LiteLLM MCP gateway on `home-server-1`.

## Setup

1. Create a tunnel in [OpenAI Platform tunnel settings](https://platform.openai.com/settings/organization/tunnels).
2. Create a **separate runtime API key** with Tunnels Read + Use permissions.
3. Create a dedicated **LiteLLM virtual key** limited to the MCP tools you intend ChatGPT to access. Do not use the LiteLLM master key.
4. Copy `.env.example` to `.env` and fill in the three required values.
5. Start the stack:

   ```bash
   cp .env.example .env
   # Edit .env first
   chmod 600 .env
   docker compose config --quiet
   docker compose up -d
   docker compose logs -f tunnel-client
   ```

6. Add a custom MCP plugin in ChatGPT. Choose **Tunnel**, select this tunnel ID, and select **No authentication** for the plugin transport. The tunnel itself authenticates to LiteLLM using the dedicated key.
7. Verify that your expected MCP tools appear. Begin with read-only tools before enabling writes.

## Networking

The container makes outbound connections to OpenAI and contacts the host's LiteLLM server through `host.docker.internal:4000` (mapped to the Docker host gateway). No inbound ports are published by this stack.

This relies on LiteLLM already listening on host port 4000. Override `MCP_SERVER_URL` in `.env` if that changes.

## Security

- `.env` is excluded by the repository's root `.gitignore` and must never be committed.
- Compose environment variables are visible to administrators with access to the Docker daemon or container metadata. If that is unacceptable, switch to secret files.
- Scope the LiteLLM virtual key to only the necessary MCP tools.
- The tunnel reaches the MCP gateway, not Gramps Web directly; upstream MCP servers must be registered in LiteLLM separately.
- This stack makes **no changes** to the existing LiteLLM or Gramps containers.

Official docs: https://github.com/openai/tunnel-client/blob/master/docs/deployment/docker.md
