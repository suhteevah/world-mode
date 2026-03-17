use chrono::{DateTime, Utc};
use serde::{Deserialize, Serialize};
use std::collections::HashMap;
use uuid::Uuid;

// ─────────────────────────────────────────────
// Game State (returned by FLE adapter /state)
// ─────────────────────────────────────────────

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct GameState {
    /// Unique snapshot ID
    pub snapshot_id: Uuid,
    /// When this state was captured
    pub timestamp: DateTime<Utc>,
    /// Current game tick
    pub tick: u64,
    /// Elapsed game time in seconds
    pub elapsed_time: f64,
    /// All entities in the game world
    pub entities: Vec<Entity>,
    /// Player inventory
    pub inventory: HashMap<String, u32>,
    /// Production statistics
    pub flows: ProductionFlows,
    /// Research state
    pub research: ResearchState,
    /// Raw text output from last action (stdout + stderr)
    pub raw_text: Option<String>,
    /// Task verification results
    pub task_verification: Option<TaskVerification>,
    /// Map image (base64 PNG, optional)
    pub map_image: Option<String>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Entity {
    pub entity_type: String,
    pub name: String,
    pub position: Position,
    pub direction: Option<u8>,
    pub health: Option<f64>,
    pub energy: Option<f64>,
    pub inventory: Option<HashMap<String, u32>>,
    pub recipe: Option<String>,
    pub warnings: Vec<String>,
    /// Additional properties (varies by entity type)
    pub properties: HashMap<String, serde_json::Value>,
}

#[derive(Debug, Clone, Copy, Serialize, Deserialize)]
pub struct Position {
    pub x: f64,
    pub y: f64,
}

impl Position {
    pub fn new(x: f64, y: f64) -> Self {
        Self { x, y }
    }

    pub fn distance_to(&self, other: &Position) -> f64 {
        ((self.x - other.x).powi(2) + (self.y - other.y).powi(2)).sqrt()
    }
}

#[derive(Debug, Clone, Serialize, Deserialize, Default)]
pub struct ProductionFlows {
    /// Items produced per minute by type
    pub output_rates: HashMap<String, f64>,
    /// Items consumed per minute by type
    pub input_rates: HashMap<String, f64>,
    /// Total items crafted
    pub crafted: HashMap<String, u64>,
    /// Total resources harvested
    pub harvested: HashMap<String, u64>,
}

#[derive(Debug, Clone, Serialize, Deserialize, Default)]
pub struct ResearchState {
    /// Technologies already researched
    pub researched: Vec<String>,
    /// Current research in progress
    pub current_research: Option<String>,
    /// Progress of current research (0.0 - 1.0)
    pub current_progress: f64,
    /// Available technologies and their prerequisites
    pub available: Vec<TechInfo>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct TechInfo {
    pub name: String,
    pub prerequisites: Vec<String>,
    pub ingredients: HashMap<String, u32>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct TaskVerification {
    pub success: bool,
    pub message: String,
    pub metadata: HashMap<String, serde_json::Value>,
}

// ─────────────────────────────────────────────
// Action Program (sent to FLE adapter /execute)
// ─────────────────────────────────────────────

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ActionProgram {
    /// Unique program ID for tracking
    pub program_id: Uuid,
    /// The Python code to execute
    pub code: String,
    /// Human-readable description of what this program does
    pub description: String,
    /// Which abstractions this program uses (for tracking)
    pub abstractions_used: Vec<String>,
    /// Expected outcomes (for reflection)
    pub expected_outcomes: Vec<String>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ActionResult {
    /// Matching program ID
    pub program_id: Uuid,
    /// Whether execution succeeded
    pub success: bool,
    /// Standard output from execution
    pub stdout: String,
    /// Standard error from execution
    pub stderr: String,
    /// Execution time in milliseconds
    pub execution_time_ms: u64,
    /// Errors encountered (parsed from stderr)
    pub errors: Vec<ExecutionError>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ExecutionError {
    pub error_type: ErrorCategory,
    pub message: String,
    pub line_number: Option<u32>,
    pub traceback: Option<String>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub enum ErrorCategory {
    /// Invalid Python syntax
    Syntactic,
    /// Wrong API usage (TypeError, AttributeError, etc.)
    Semantic,
    /// Wrong assumptions about world state
    Pragmatic,
    /// Higher-level planning failure
    Planning,
    /// Unknown error type
    Unknown,
}

// ─────────────────────────────────────────────
// Goal System
// ─────────────────────────────────────────────

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Goal {
    pub id: Uuid,
    pub description: String,
    pub priority: GoalPriority,
    pub status: GoalStatus,
    pub parent_id: Option<Uuid>,
    pub sub_goals: Vec<Uuid>,
    pub created_at: DateTime<Utc>,
    pub completed_at: Option<DateTime<Utc>>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub enum GoalPriority {
    Critical,  // Must do now (power failure, resource depletion)
    High,      // Current primary objective
    Medium,    // Queued task
    Low,       // Nice to have
    Background,// Ongoing monitoring
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub enum GoalStatus {
    Pending,
    Active,
    Blocked(String),  // reason
    Completed,
    Failed(String),   // reason
    Cancelled,
}

// ─────────────────────────────────────────────
// FLE Adapter API Types
// ─────────────────────────────────────────────

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct FleHealthResponse {
    pub status: String,
    pub connected: bool,
    pub server_address: String,
    pub game_tick: Option<u64>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ExecuteRequest {
    pub code: String,
    pub timeout_seconds: Option<u64>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ExecuteResponse {
    pub success: bool,
    pub stdout: String,
    pub stderr: String,
    pub execution_time_ms: u64,
}

// ─────────────────────────────────────────────
// Dashboard WebSocket Messages
// ─────────────────────────────────────────────

#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(tag = "type")]
pub enum WsMessage {
    StateUpdate(GameState),
    GoalUpdate { goals: Vec<Goal> },
    ActionTaken { program: ActionProgram, result: ActionResult },
    ClaudeThinking { content: String },
    ErrorAlert { error: ExecutionError },
    ProductionAlert { item: String, message: String },
    ChatMessage { role: String, content: String },
}
