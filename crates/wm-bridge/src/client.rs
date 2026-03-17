use anyhow::{Context, Result};
use std::io::{Read, Write};
use std::net::TcpStream;
use std::time::Duration;
use tracing::{debug, error, info, instrument, warn};

/// Factorio RCON client.
/// Communicates directly with the Factorio server — no Python, no FLE.
/// Sends commands to the World Mode Bridge Lua mod.
pub struct RconClient {
    host: String,
    port: u16,
    password: String,
    timeout: Duration,
}

// RCON packet types (Source RCON protocol)
const SERVERDATA_AUTH: i32 = 3;
const SERVERDATA_AUTH_RESPONSE: i32 = 2;
const SERVERDATA_EXECCOMMAND: i32 = 2;
const _SERVERDATA_RESPONSE_VALUE: i32 = 0;

impl RconClient {
    pub fn new(host: &str, port: u16, password: &str, timeout_secs: u64) -> Self {
        info!(host = %host, port = port, "RCON client initialized");
        Self {
            host: host.to_string(),
            port,
            password: password.to_string(),
            timeout: Duration::from_secs(timeout_secs),
        }
    }

    /// Open a connection, authenticate, send a command, return the response.
    /// Each call opens a fresh TCP connection (Factorio RCON is simple enough for this).
    #[instrument(skip(self, command), fields(cmd_preview = %&command[..command.len().min(120)]))]
    pub fn execute(&self, command: &str) -> Result<String> {
        debug!(command_len = command.len(), "Opening RCON connection");

        let addr = format!("{}:{}", self.host, self.port);
        let mut stream = TcpStream::connect(&addr)
            .with_context(|| format!("Failed to connect to RCON at {}", addr))?;
        stream.set_read_timeout(Some(self.timeout))?;
        stream.set_write_timeout(Some(self.timeout))?;

        // Authenticate
        debug!("RCON authenticating...");
        self.send_packet(&mut stream, 1, SERVERDATA_AUTH, &self.password)?;
        let auth_resp = self.read_packet(&mut stream)?;
        if auth_resp.2 != SERVERDATA_AUTH_RESPONSE || auth_resp.0 == -1 {
            error!("RCON authentication failed");
            anyhow::bail!("RCON authentication failed — check password");
        }
        debug!("RCON authenticated");

        // Send command
        debug!("Sending RCON command...");
        self.send_packet(&mut stream, 2, SERVERDATA_EXECCOMMAND, command)?;

        // Read response — may come in multiple packets for large JSON payloads
        let mut full_response = String::new();
        loop {
            match self.read_packet(&mut stream) {
                Ok((_id, body, _ptype)) => {
                    if body.is_empty() {
                        break;
                    }
                    full_response.push_str(&body);
                    // For non-JSON responses (e.g. /version), one packet is enough.
                    // For JSON responses, check bracket completeness since large
                    // state dumps might be split across packets.
                    let trimmed = full_response.trim();
                    let is_json = trimmed.starts_with('{') || trimmed.starts_with('[');
                    if !is_json || looks_complete(&full_response) {
                        break;
                    }
                }
                Err(e) => {
                    // Timeout usually means we've got all the data
                    if full_response.is_empty() {
                        return Err(e);
                    }
                    break;
                }
            }
        }

        debug!(response_len = full_response.len(), "RCON response received");
        Ok(full_response)
    }

    /// Send a Source RCON packet.
    fn send_packet(&self, stream: &mut TcpStream, id: i32, ptype: i32, body: &str) -> Result<()> {
        let body_bytes = body.as_bytes();
        let size: i32 = 4 + 4 + body_bytes.len() as i32 + 2; // id + type + body + 2 null terminators

        let mut packet = Vec::with_capacity(size as usize + 4);
        packet.extend_from_slice(&size.to_le_bytes());
        packet.extend_from_slice(&id.to_le_bytes());
        packet.extend_from_slice(&ptype.to_le_bytes());
        packet.extend_from_slice(body_bytes);
        packet.push(0); // body null terminator
        packet.push(0); // packet null terminator

        stream.write_all(&packet)?;
        stream.flush()?;
        Ok(())
    }

    /// Read a Source RCON response packet.
    /// Returns (id, body_string, packet_type).
    fn read_packet(&self, stream: &mut TcpStream) -> Result<(i32, String, i32)> {
        // Read size (4 bytes, little-endian)
        let mut size_buf = [0u8; 4];
        stream.read_exact(&mut size_buf)?;
        let size = i32::from_le_bytes(size_buf);

        if size < 10 || size > 4096 * 16 {
            anyhow::bail!("Invalid RCON packet size: {}", size);
        }

        // Read rest of packet
        let mut payload = vec![0u8; size as usize];
        stream.read_exact(&mut payload)?;

        let id = i32::from_le_bytes([payload[0], payload[1], payload[2], payload[3]]);
        let ptype = i32::from_le_bytes([payload[4], payload[5], payload[6], payload[7]]);

        // Body is everything after id+type, minus 2 null terminators
        let body_end = (size as usize) - 2; // subtract 2 null bytes
        let body_start = 8; // after id (4) + type (4)
        let body = if body_end > body_start {
            String::from_utf8_lossy(&payload[body_start..body_end]).to_string()
        } else {
            String::new()
        };

        Ok((id, body, ptype))
    }

    // ── Convenience methods for World Mode mod commands ──

    /// Get full game state JSON.
    pub fn get_state(&self, compact: bool) -> Result<String> {
        let cmd = if compact { "/wm-state compact" } else { "/wm-state" };
        self.execute(cmd)
    }

    /// Get player inventory JSON.
    pub fn get_inventory(&self) -> Result<String> {
        self.execute("/wm-inventory")
    }

    /// Query entities by type and/or area.
    pub fn get_entities(&self, name: Option<&str>, center: Option<(f64, f64)>, radius: Option<f64>) -> Result<String> {
        let mut cmd = "/wm-entities".to_string();
        if let Some(n) = name {
            cmd.push_str(&format!(" {}", n));
        } else {
            cmd.push_str(" *");
        }
        if let (Some((cx, cy)), Some(r)) = (center, radius) {
            cmd.push_str(&format!(" {} {} {}", cx, cy, r));
        }
        self.execute(&cmd)
    }

    /// Execute Lua code in the game.
    pub fn exec_lua(&self, code: &str) -> Result<String> {
        let cmd = format!("/wm-exec {}", code);
        self.execute(&cmd)
    }

    /// Get power grid status.
    pub fn get_power(&self) -> Result<String> {
        self.execute("/wm-power")
    }

    /// Send in-game chat message.
    pub fn chat(&self, message: &str) -> Result<String> {
        self.execute(&format!("/wm-chat {}", message))
    }

    /// Get action log.
    pub fn get_action_log(&self) -> Result<String> {
        self.execute("/wm-action-log")
    }

    /// Get lieutenant status.
    pub fn lieutenant_status(&self) -> Result<String> {
        self.execute("/wm-lieutenant")
    }

    /// Walk lieutenant to position.
    pub fn walk_to(&self, x: f64, y: f64) -> Result<String> {
        self.execute(&format!("/wm-walk {} {}", x, y))
    }

    /// Craft items.
    pub fn craft(&self, recipe: &str, count: u32) -> Result<String> {
        self.execute(&format!("/wm-craft {} {}", recipe, count))
    }

    /// Place entity from inventory.
    pub fn place_entity(&self, name: &str, x: f64, y: f64, direction: &str) -> Result<String> {
        self.execute(&format!("/wm-place {} {} {} {}", name, x, y, direction))
    }

    /// Mine entity at position.
    pub fn mine_at(&self, x: f64, y: f64, name: Option<&str>) -> Result<String> {
        let mut cmd = format!("/wm-mine {} {}", x, y);
        if let Some(n) = name {
            cmd.push_str(&format!(" {}", n));
        }
        self.execute(&cmd)
    }

    /// Place a ghost entity.
    pub fn place_ghost(&self, name: &str, x: f64, y: f64, direction: &str) -> Result<String> {
        self.execute(&format!("/wm-ghost {} {} {} {}", name, x, y, direction))
    }

    /// Place a blueprint string at position.
    pub fn place_blueprint(&self, x: f64, y: f64, bp_string: &str) -> Result<String> {
        self.execute(&format!("/wm-blueprint {} {} {}", x, y, bp_string))
    }

    /// Capture area as blueprint string.
    pub fn capture_blueprint(&self, x1: f64, y1: f64, x2: f64, y2: f64) -> Result<String> {
        self.execute(&format!("/wm-capture {} {} {} {}", x1, y1, x2, y2))
    }

    /// Insert items into entity at position.
    pub fn insert_items(&self, x: f64, y: f64, item: &str, count: u32) -> Result<String> {
        self.execute(&format!("/wm-insert {} {} {} {}", x, y, item, count))
    }

    /// Extract items from entity at position.
    pub fn extract_items(&self, x: f64, y: f64, item: &str, count: u32) -> Result<String> {
        self.execute(&format!("/wm-extract {} {} {} {}", x, y, item, count))
    }

    /// Pick up entity at position.
    pub fn pickup_entity(&self, x: f64, y: f64, name: Option<&str>) -> Result<String> {
        let mut cmd = format!("/wm-pickup {} {}", x, y);
        if let Some(n) = name {
            cmd.push_str(&format!(" {}", n));
        }
        self.execute(&cmd)
    }
}

/// Heuristic: check if a JSON response looks complete.
fn looks_complete(s: &str) -> bool {
    let trimmed = s.trim();
    if trimmed.is_empty() {
        return false;
    }
    // Simple bracket matching
    let first = trimmed.chars().next().unwrap_or(' ');
    let last = trimmed.chars().last().unwrap_or(' ');
    (first == '{' && last == '}') || (first == '[' && last == ']')
}
