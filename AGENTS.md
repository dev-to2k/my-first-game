# Godot MCP & Project Guidelines

This is a Godot 4.7 project integrated with **Godot MCP** (`@keeveeg/godot-mcp`).

## Godot MCP Integration
- **Addon**: `addons/godot_mcp` is active in the Godot Editor.
- **Autoload**: `MCPRuntime` handles runtime inspection and game manipulation.
- **Server**: Configured via Antigravity `mcp_config.json`.
- **WebSocket Bridge**: Automatically connects on ports `6505-6514` between the Godot Editor plugin and the Node.js MCP server.

## Project Structure
- Main scene: `scenes/sao_starting_city.tscn`
- Shaders: `shaders/`
- Assets: `assets/`
- Documentation: `docs/SAO_STARTING_CITY_GRAPHICS_ROADMAP.md`
