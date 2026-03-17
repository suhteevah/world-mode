use anyhow::Result;
use serde_json::json;
use std::io::{self, BufRead, Write};
use tracing::{debug, error, info, warn};

use crate::mcp::protocol::*;
use crate::mcp::tools;
use crate::state::AppState;

/// Run the MCP server over stdio.
/// Claude Code launches this as a subprocess and communicates via JSON-RPC over stdin/stdout.
/// All logging goes to stderr so it doesn't corrupt the JSON-RPC stream.
pub async fn run_stdio_server(state: AppState) -> Result<()> {
    // MCP uses newline-delimited JSON over stdio
    let stdin = io::stdin();
    let mut stdout = io::stdout();

    info!("World Mode MCP server starting on stdio...");
    info!("Waiting for Claude Code to connect...");

    for line in stdin.lock().lines() {
        let line = match line {
            Ok(l) => l,
            Err(e) => {
                error!(error = %e, "Failed to read from stdin");
                break;
            }
        };

        if line.trim().is_empty() {
            continue;
        }

        debug!(raw_input = %line, "Received JSON-RPC message");

        let request: JsonRpcRequest = match serde_json::from_str(&line) {
            Ok(r) => r,
            Err(e) => {
                warn!(error = %e, input = %line, "Failed to parse JSON-RPC request");
                let error_resp = JsonRpcResponse::error(None, -32700, "Parse error");
                write_response(&mut stdout, &error_resp)?;
                continue;
            }
        };

        let response = handle_request(&request, &state).await;

        if let Some(resp) = response {
            write_response(&mut stdout, &resp)?;
        }
    }

    info!("MCP server stdin closed, shutting down");
    // Persist state before exit
    state.save_abstractions().await;
    Ok(())
}

/// Handle a single JSON-RPC request and return an optional response.
/// Notifications (no id) don't get responses.
async fn handle_request(request: &JsonRpcRequest, state: &AppState) -> Option<JsonRpcResponse> {
    info!(method = %request.method, id = ?request.id, "Handling MCP request");

    match request.method.as_str() {
        // ── Lifecycle ──
        "initialize" => {
            info!("MCP initialize handshake");
            let result = InitializeResult {
                protocol_version: "2024-11-05".to_string(),
                capabilities: ServerCapabilities {
                    tools: Some(ToolsCapability { list_changed: false }),
                },
                server_info: ServerInfo {
                    name: "world-mode".to_string(),
                    version: "0.1.0".to_string(),
                },
            };
            Some(JsonRpcResponse::success(
                request.id.clone(),
                serde_json::to_value(result).unwrap(),
            ))
        }

        "notifications/initialized" => {
            info!("Claude Code confirmed initialization — World Mode is live!");
            None // Notification, no response
        }

        // ── Tool Discovery ──
        "tools/list" => {
            info!("Claude Code requesting tool list");
            let tool_list = ToolsListResult {
                tools: tools::all_tools(),
            };
            Some(JsonRpcResponse::success(
                request.id.clone(),
                serde_json::to_value(tool_list).unwrap(),
            ))
        }

        // ── Tool Execution ──
        "tools/call" => {
            let params: ToolCallParams = match &request.params {
                Some(p) => match serde_json::from_value(p.clone()) {
                    Ok(tc) => tc,
                    Err(e) => {
                        return Some(JsonRpcResponse::error(
                            request.id.clone(),
                            -32602,
                            format!("Invalid tool call params: {}", e),
                        ));
                    }
                },
                None => {
                    return Some(JsonRpcResponse::error(
                        request.id.clone(),
                        -32602,
                        "Missing params for tools/call",
                    ));
                }
            };

            info!(tool = %params.name, "Executing MCP tool call");
            let result = tools::handle_tool_call(
                &params.name,
                params.arguments,
                state,
            ).await;

            Some(JsonRpcResponse::success(
                request.id.clone(),
                serde_json::to_value(result).unwrap(),
            ))
        }

        // ── Ping ──
        "ping" => {
            Some(JsonRpcResponse::success(request.id.clone(), json!({})))
        }

        // ── Unknown ──
        method => {
            warn!(method = %method, "Unknown MCP method");
            Some(JsonRpcResponse::error(
                request.id.clone(),
                -32601,
                format!("Method not found: {}", method),
            ))
        }
    }
}

/// Write a JSON-RPC response to stdout (newline-delimited).
fn write_response(stdout: &mut io::Stdout, response: &JsonRpcResponse) -> Result<()> {
    let json = serde_json::to_string(response)?;
    debug!(response = %json, "Sending JSON-RPC response");
    writeln!(stdout, "{}", json)?;
    stdout.flush()?;
    Ok(())
}
