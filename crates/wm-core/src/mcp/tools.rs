use serde_json::{json, Value};
use tracing::{debug, info, warn, instrument};

use crate::mcp::protocol::{ToolCallResult, ToolDefinition};
use crate::state::AppState;

/// Parse a JSON string from RCON, returning a friendly error on failure.
fn parse_rcon_json(raw: &str) -> Result<Value, String> {
    let trimmed = raw.trim();
    if trimmed.is_empty() {
        return Err("Empty response from Factorio".into());
    }
    serde_json::from_str(trimmed)
        .map_err(|e| format!("Failed to parse Factorio response as JSON: {} — raw: {}", e, &trimmed[..trimmed.len().min(500)]))
}

/// Register all World Mode MCP tools.
pub fn all_tools() -> Vec<ToolDefinition> {
    vec![
        // ── SENSE tools ──
        ToolDefinition {
            name: "observe_state".into(),
            description: "Get the current full game state from Factorio. Returns entities, inventory, production flows, research status, and game tick. Call this to understand what's happening in the world right now.".into(),
            input_schema: json!({
                "type": "object",
                "properties": {
                    "include_entities": {
                        "type": "boolean",
                        "description": "Include full entity list (can be large). Default true.",
                        "default": true
                    },
                    "include_map": {
                        "type": "boolean",
                        "description": "Include base64 map image. Default false.",
                        "default": false
                    }
                }
            }),
        },
        ToolDefinition {
            name: "get_world_diff".into(),
            description: "Get what changed since the last observation. Shows entities added/removed, inventory changes, and tick delta. Use this to understand the impact of your last action or what the human player did.".into(),
            input_schema: json!({ "type": "object", "properties": {} }),
        },
        ToolDefinition {
            name: "get_entities".into(),
            description: "Query entities by type and/or area. More targeted than observe_state when you know what you're looking for.".into(),
            input_schema: json!({
                "type": "object",
                "properties": {
                    "entity_type": {
                        "type": "string",
                        "description": "Filter by entity type name (e.g., 'electric-mining-drill', 'transport-belt')"
                    },
                    "near_x": { "type": "number", "description": "Center X for area query" },
                    "near_y": { "type": "number", "description": "Center Y for area query" },
                    "radius": { "type": "number", "description": "Search radius from (near_x, near_y). Default 50.", "default": 50.0 }
                }
            }),
        },
        ToolDefinition {
            name: "get_inventory".into(),
            description: "Get the player's current inventory contents.".into(),
            input_schema: json!({ "type": "object", "properties": {} }),
        },
        ToolDefinition {
            name: "get_production".into(),
            description: "Get production rates (items/min) and trends. Shows current throughput for all tracked items and recent history.".into(),
            input_schema: json!({
                "type": "object",
                "properties": {
                    "item": {
                        "type": "string",
                        "description": "Filter to a specific item. Omit for all items."
                    }
                }
            }),
        },
        ToolDefinition {
            name: "get_power_status".into(),
            description: "Get power grid health: generation capacity, current consumption, satisfaction percentage.".into(),
            input_schema: json!({ "type": "object", "properties": {} }),
        },

        // ── ACT tools ──
        ToolDefinition {
            name: "execute_lua".into(),
            description: "Execute Lua code in the Factorio world via the World Mode Bridge mod. This is how you build things, place entities, connect pipes/belts, and interact with the game. Use the wm.* API: wm.place(), wm.connect(), wm.move_to(), wm.nearest_resource(), wm.insert(), etc. Always include wm.print() statements for debugging.".into(),
            input_schema: json!({
                "type": "object",
                "properties": {
                    "code": {
                        "type": "string",
                        "description": "Lua code using the wm.* API to execute in the game world"
                    },
                    "description": {
                        "type": "string",
                        "description": "Human-readable description of what this code does"
                    }
                },
                "required": ["code", "description"]
            }),
        },
        ToolDefinition {
            name: "rcon_command".into(),
            description: "Send a raw RCON command to the Factorio server console.".into(),
            input_schema: json!({
                "type": "object",
                "properties": {
                    "command": { "type": "string", "description": "RCON command to execute" }
                },
                "required": ["command"]
            }),
        },
        ToolDefinition {
            name: "send_chat".into(),
            description: "Send an in-game chat message visible to the human player. Use this to communicate during gameplay.".into(),
            input_schema: json!({
                "type": "object",
                "properties": {
                    "message": { "type": "string", "description": "Chat message to send" }
                },
                "required": ["message"]
            }),
        },

        // ── GOAL tools ──
        ToolDefinition {
            name: "push_goal".into(),
            description: "Add a new goal to the goal stack. Goals can be hierarchical (sub-goals reference a parent).".into(),
            input_schema: json!({
                "type": "object",
                "properties": {
                    "description": { "type": "string", "description": "What needs to be accomplished" },
                    "priority": {
                        "type": "string",
                        "enum": ["critical", "high", "medium", "low", "background"],
                        "description": "Goal priority. Default: high.",
                        "default": "high"
                    },
                    "parent_id": {
                        "type": "string",
                        "description": "UUID of parent goal if this is a sub-goal"
                    }
                },
                "required": ["description"]
            }),
        },
        ToolDefinition {
            name: "list_goals".into(),
            description: "View all current goals and their status.".into(),
            input_schema: json!({ "type": "object", "properties": {} }),
        },
        ToolDefinition {
            name: "complete_goal".into(),
            description: "Mark a goal as completed.".into(),
            input_schema: json!({
                "type": "object",
                "properties": {
                    "goal_id": { "type": "string", "description": "UUID of the goal to complete" }
                },
                "required": ["goal_id"]
            }),
        },

        // ── ABSTRACTION LIBRARY tools ──
        ToolDefinition {
            name: "list_abstractions".into(),
            description: "List all available abstraction library functions you've previously saved. These are reusable Python functions for common Factorio patterns.".into(),
            input_schema: json!({
                "type": "object",
                "properties": {
                    "level": {
                        "type": "integer",
                        "description": "Filter by level (0=primitives, 1=patterns, 2=subsystems, 3=strategies)"
                    }
                }
            }),
        },
        ToolDefinition {
            name: "get_abstraction".into(),
            description: "Get the full source code of a saved abstraction function.".into(),
            input_schema: json!({
                "type": "object",
                "properties": {
                    "name": { "type": "string", "description": "Function name" }
                },
                "required": ["name"]
            }),
        },
        ToolDefinition {
            name: "save_abstraction".into(),
            description: "Save a new reusable Lua function to the abstraction library. Include comments explaining what it does, its parameters, and usage examples.".into(),
            input_schema: json!({
                "type": "object",
                "properties": {
                    "name": { "type": "string", "description": "Function name (snake_case)" },
                    "level": {
                        "type": "integer",
                        "description": "Abstraction level: 1=pattern, 2=subsystem, 3=strategy"
                    },
                    "code": { "type": "string", "description": "Python function source code" },
                    "description": { "type": "string", "description": "What this function does" },
                    "tags": {
                        "type": "array",
                        "items": { "type": "string" },
                        "description": "Tags for searchability (e.g., ['power', 'steam', 'boiler'])"
                    }
                },
                "required": ["name", "level", "code", "description"]
            }),
        },

        // ── MAP tools ──
        ToolDefinition {
            name: "get_map_image".into(),
            description: "Get a rendered image of the current factory layout. Returns base64 PNG.".into(),
            input_schema: json!({
                "type": "object",
                "properties": {
                    "center_x": { "type": "number", "description": "Map center X. Default: player position." },
                    "center_y": { "type": "number", "description": "Map center Y. Default: player position." },
                    "zoom": { "type": "number", "description": "Zoom level. Default: 1.0", "default": 1.0 }
                }
            }),
        },
    ]
}

/// Dispatch a tool call to the appropriate handler.
#[instrument(skip(state, arguments), fields(tool = %name))]
pub async fn handle_tool_call(
    name: &str,
    arguments: Option<Value>,
    state: &AppState,
) -> ToolCallResult {
    let args = arguments.unwrap_or(json!({}));
    info!(tool = %name, args = %args, "MCP tool call received");

    let result = match name {
        "observe_state" => handle_observe_state(&args, state).await,
        "get_world_diff" => handle_get_world_diff(state).await,
        "get_entities" => handle_get_entities(&args, state).await,
        "get_inventory" => handle_get_inventory(state).await,
        "get_production" => handle_get_production(&args, state).await,
        "get_power_status" => handle_get_power_status(state).await,
        "execute_lua" => handle_execute_lua(&args, state).await,
        "rcon_command" => handle_rcon_command(&args, state).await,
        "send_chat" => handle_send_chat(&args, state).await,
        "push_goal" => handle_push_goal(&args, state).await,
        "list_goals" => handle_list_goals(state).await,
        "complete_goal" => handle_complete_goal(&args, state).await,
        "list_abstractions" => handle_list_abstractions(&args, state).await,
        "get_abstraction" => handle_get_abstraction(&args, state).await,
        "save_abstraction" => handle_save_abstraction(&args, state).await,
        "get_map_image" => handle_get_map_image(&args, state).await,
        _ => {
            warn!(tool = %name, "Unknown tool called");
            ToolCallResult::error(format!("Unknown tool: {}", name))
        }
    };

    info!(tool = %name, is_error = ?result.is_error, "MCP tool call completed");
    result
}

// ─────────────────────────────────────────────
// Tool Handlers
// ─────────────────────────────────────────────

async fn handle_observe_state(args: &Value, state: &AppState) -> ToolCallResult {
    let compact = args.get("include_entities")
        .and_then(|v| v.as_bool())
        .map(|include| !include)
        .unwrap_or(false);

    match state.rcon.get_state(compact) {
        Ok(raw) => {
            match parse_rcon_json(&raw) {
                Ok(parsed) => ToolCallResult::json(&parsed),
                Err(e) => ToolCallResult::error(e),
            }
        }
        Err(e) => ToolCallResult::error(format!("Failed to observe state: {}", e)),
    }
}

async fn handle_get_world_diff(state: &AppState) -> ToolCallResult {
    // For now, just get compact state — diffing will be enhanced in Phase 2
    match state.rcon.get_state(true) {
        Ok(raw) => match parse_rcon_json(&raw) {
            Ok(parsed) => ToolCallResult::json(&parsed),
            Err(e) => ToolCallResult::error(e),
        },
        Err(e) => ToolCallResult::error(format!("Failed to get state for diff: {}", e)),
    }
}

async fn handle_get_entities(args: &Value, state: &AppState) -> ToolCallResult {
    let entity_type = args.get("entity_type").and_then(|v| v.as_str());
    let near_x = args.get("near_x").and_then(|v| v.as_f64());
    let near_y = args.get("near_y").and_then(|v| v.as_f64());
    let radius = args.get("radius").and_then(|v| v.as_f64());

    let center = match (near_x, near_y) {
        (Some(x), Some(y)) => Some((x, y)),
        _ => None,
    };

    match state.rcon.get_entities(entity_type, center, radius) {
        Ok(raw) => match parse_rcon_json(&raw) {
            Ok(parsed) => ToolCallResult::json(&parsed),
            Err(e) => ToolCallResult::error(e),
        },
        Err(e) => ToolCallResult::error(format!("Failed to query entities: {}", e)),
    }
}

async fn handle_get_inventory(state: &AppState) -> ToolCallResult {
    match state.rcon.get_inventory() {
        Ok(raw) => match parse_rcon_json(&raw) {
            Ok(parsed) => ToolCallResult::json(&parsed),
            Err(e) => ToolCallResult::error(e),
        },
        Err(e) => ToolCallResult::error(format!("Failed to get inventory: {}", e)),
    }
}

async fn handle_get_production(args: &Value, state: &AppState) -> ToolCallResult {
    // Production data is part of the full state — get it from there
    match state.rcon.get_state(true) {
        Ok(raw) => match parse_rcon_json(&raw) {
            Ok(parsed) => {
                // Extract just the production-relevant fields
                let item_filter = args.get("item").and_then(|v| v.as_str());
                if let Some(_item) = item_filter {
                    // TODO: filter production data to specific item
                    ToolCallResult::json(&parsed)
                } else {
                    ToolCallResult::json(&parsed)
                }
            },
            Err(e) => ToolCallResult::error(e),
        },
        Err(e) => ToolCallResult::error(format!("Failed to get production: {}", e)),
    }
}

async fn handle_get_power_status(state: &AppState) -> ToolCallResult {
    match state.rcon.get_power() {
        Ok(raw) => match parse_rcon_json(&raw) {
            Ok(parsed) => ToolCallResult::json(&parsed),
            Err(e) => ToolCallResult::error(e),
        },
        Err(e) => ToolCallResult::error(format!("Failed to get power status: {}", e)),
    }
}

async fn handle_execute_lua(args: &Value, state: &AppState) -> ToolCallResult {
    let code = match args.get("code").and_then(|v| v.as_str()) {
        Some(c) => c,
        None => return ToolCallResult::error("Missing required parameter: code"),
    };
    let description = args.get("description").and_then(|v| v.as_str()).unwrap_or("(no description)");

    info!(
        description = %description,
        code_len = code.len(),
        "Executing Lua via RCON /wm-exec"
    );

    // Log to action history
    {
        let mut history = state.action_history.write().await;
        history.push(json!({
            "description": description,
            "code": code,
            "timestamp": chrono::Utc::now().to_rfc3339(),
        }));
    }

    match state.rcon.exec_lua(code) {
        Ok(raw) => match parse_rcon_json(&raw) {
            Ok(parsed) => ToolCallResult::json(&parsed),
            Err(_) => {
                // If it's not JSON, return as raw text (might be a simple success)
                ToolCallResult::text(raw)
            }
        },
        Err(e) => ToolCallResult::error(format!("Lua execution failed: {}", e)),
    }
}

async fn handle_rcon_command(args: &Value, state: &AppState) -> ToolCallResult {
    let command = match args.get("command").and_then(|v| v.as_str()) {
        Some(c) => c,
        None => return ToolCallResult::error("Missing required parameter: command"),
    };

    match state.rcon.execute(command) {
        Ok(response) => ToolCallResult::text(response),
        Err(e) => ToolCallResult::error(format!("RCON failed: {}", e)),
    }
}

async fn handle_send_chat(args: &Value, state: &AppState) -> ToolCallResult {
    let message = match args.get("message").and_then(|v| v.as_str()) {
        Some(m) => m,
        None => return ToolCallResult::error("Missing required parameter: message"),
    };

    match state.rcon.chat(message) {
        Ok(_) => ToolCallResult::text(format!("Chat sent: {}", message)),
        Err(e) => ToolCallResult::error(format!("Failed to send chat: {}", e)),
    }
}

async fn handle_push_goal(args: &Value, state: &AppState) -> ToolCallResult {
    let description = match args.get("description").and_then(|v| v.as_str()) {
        Some(d) => d,
        None => return ToolCallResult::error("Missing required parameter: description"),
    };
    let priority = args.get("priority").and_then(|v| v.as_str()).unwrap_or("high");

    let goal = wm_bridge::Goal {
        id: uuid::Uuid::new_v4(),
        description: description.to_string(),
        priority: match priority {
            "critical" => wm_bridge::GoalPriority::Critical,
            "high" => wm_bridge::GoalPriority::High,
            "medium" => wm_bridge::GoalPriority::Medium,
            "low" => wm_bridge::GoalPriority::Low,
            "background" => wm_bridge::GoalPriority::Background,
            _ => wm_bridge::GoalPriority::High,
        },
        status: wm_bridge::GoalStatus::Active,
        parent_id: args.get("parent_id").and_then(|v| v.as_str())
            .and_then(|s| uuid::Uuid::parse_str(s).ok()),
        sub_goals: Vec::new(),
        created_at: chrono::Utc::now(),
        completed_at: None,
    };

    let id = goal.id;
    state.goals.write().await.push(goal);
    ToolCallResult::text(format!("Goal created: {} (id: {})", description, id))
}

async fn handle_list_goals(state: &AppState) -> ToolCallResult {
    let goals = state.goals.read().await;
    ToolCallResult::json(&*goals)
}

async fn handle_complete_goal(args: &Value, state: &AppState) -> ToolCallResult {
    let goal_id = match args.get("goal_id").and_then(|v| v.as_str()) {
        Some(id) => match uuid::Uuid::parse_str(id) {
            Ok(uuid) => uuid,
            Err(_) => return ToolCallResult::error("Invalid goal_id UUID"),
        },
        None => return ToolCallResult::error("Missing required parameter: goal_id"),
    };

    let mut goals = state.goals.write().await;
    if let Some(goal) = goals.iter_mut().find(|g| g.id == goal_id) {
        goal.status = wm_bridge::GoalStatus::Completed;
        goal.completed_at = Some(chrono::Utc::now());
        ToolCallResult::text(format!("Goal completed: {}", goal.description))
    } else {
        ToolCallResult::error(format!("Goal not found: {}", goal_id))
    }
}

async fn handle_list_abstractions(args: &Value, state: &AppState) -> ToolCallResult {
    let registry = state.abstraction_registry.read().await;
    let level_filter = args.get("level").and_then(|v| v.as_u64());

    let filtered: Vec<_> = registry.iter()
        .filter(|a| level_filter.map_or(true, |l| a.get("level").and_then(|v| v.as_u64()) == Some(l)))
        .collect();

    ToolCallResult::json(&filtered)
}

async fn handle_get_abstraction(args: &Value, state: &AppState) -> ToolCallResult {
    let name = match args.get("name").and_then(|v| v.as_str()) {
        Some(n) => n,
        None => return ToolCallResult::error("Missing required parameter: name"),
    };

    let registry = state.abstraction_registry.read().await;
    if let Some(entry) = registry.iter().find(|a| a.get("name").and_then(|v| v.as_str()) == Some(name)) {
        ToolCallResult::json(entry)
    } else {
        ToolCallResult::error(format!("Abstraction not found: {}", name))
    }
}

async fn handle_save_abstraction(args: &Value, state: &AppState) -> ToolCallResult {
    let name = match args.get("name").and_then(|v| v.as_str()) {
        Some(n) => n,
        None => return ToolCallResult::error("Missing: name"),
    };
    let level = args.get("level").and_then(|v| v.as_u64()).unwrap_or(1);
    let code = match args.get("code").and_then(|v| v.as_str()) {
        Some(c) => c,
        None => return ToolCallResult::error("Missing: code"),
    };
    let description = args.get("description").and_then(|v| v.as_str()).unwrap_or("");
    let tags = args.get("tags").cloned().unwrap_or(json!([]));

    let entry = json!({
        "name": name,
        "level": level,
        "code": code,
        "description": description,
        "tags": tags,
        "created_at": chrono::Utc::now().to_rfc3339(),
    });

    // Save to registry
    {
        let mut registry = state.abstraction_registry.write().await;
        // Upsert — replace if exists
        registry.retain(|a| a.get("name").and_then(|v| v.as_str()) != Some(name));
        registry.push(entry.clone());
    }

    // Also save to filesystem
    let level_dir = match level {
        1 => "level1",
        2 => "level2",
        3 => "level3",
        _ => "level1",
    };
    let path = format!("{}/{}/{}.py", state.abstractions_path, level_dir, name);
    if let Err(e) = tokio::fs::write(&path, code).await {
        warn!(path = %path, error = %e, "Failed to write abstraction file (non-fatal)");
    } else {
        info!(path = %path, "Abstraction saved to filesystem");
    }

    ToolCallResult::text(format!("Abstraction saved: {} (level {})", name, level))
}

async fn handle_get_map_image(_args: &Value, _state: &AppState) -> ToolCallResult {
    // Map rendering requires the headless renderer (Phase 2+)
    ToolCallResult::text("Map image not yet available. This feature requires the headless renderer (Phase 2). Use observe_state and get_entities to understand the factory layout.")
}
