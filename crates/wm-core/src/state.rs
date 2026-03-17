use std::sync::Arc;
use tokio::sync::RwLock;
use serde_json::Value;

use wm_bridge::{RconClient, Goal};
use crate::model::world_state::WorldModel;

/// Shared state accessible by all MCP tool handlers.
/// Wrapped in Arc for cheap cloning across async tasks.
pub struct AppState {
    /// RCON client to Factorio server (via World Mode Bridge Lua mod)
    pub rcon: RconClient,
    /// Persistent world model
    pub world_model: Arc<RwLock<WorldModel>>,
    /// Goal stack
    pub goals: Arc<RwLock<Vec<Goal>>>,
    /// Action history (for reflection)
    pub action_history: Arc<RwLock<Vec<Value>>>,
    /// Abstraction library registry
    pub abstraction_registry: Arc<RwLock<Vec<Value>>>,
    /// Path to abstractions directory
    pub abstractions_path: String,
}

impl AppState {
    pub fn new(rcon: RconClient, abstractions_path: String) -> Self {
        Self {
            rcon,
            world_model: Arc::new(RwLock::new(WorldModel::new())),
            goals: Arc::new(RwLock::new(Vec::new())),
            action_history: Arc::new(RwLock::new(Vec::new())),
            abstraction_registry: Arc::new(RwLock::new(Vec::new())),
            abstractions_path,
        }
    }

    /// Load abstraction registry from disk on startup.
    pub async fn load_abstractions(&self) {
        let registry_path = format!("{}/registry.json", self.abstractions_path);
        match tokio::fs::read_to_string(&registry_path).await {
            Ok(content) => {
                match serde_json::from_str::<Vec<Value>>(&content) {
                    Ok(entries) => {
                        let count = entries.len();
                        *self.abstraction_registry.write().await = entries;
                        tracing::info!(count = count, "Loaded abstraction registry from disk");
                    }
                    Err(e) => tracing::warn!(error = %e, "Failed to parse registry.json"),
                }
            }
            Err(_) => tracing::info!("No existing abstraction registry found (fresh start)"),
        }
    }

    /// Persist abstraction registry to disk.
    pub async fn save_abstractions(&self) {
        let registry_path = format!("{}/registry.json", self.abstractions_path);
        let registry = self.abstraction_registry.read().await;
        match serde_json::to_string_pretty(&*registry) {
            Ok(json) => {
                if let Err(e) = tokio::fs::write(&registry_path, json).await {
                    tracing::error!(error = %e, "Failed to save registry.json");
                } else {
                    tracing::debug!("Abstraction registry saved to disk");
                }
            }
            Err(e) => tracing::error!(error = %e, "Failed to serialize registry"),
        }
    }
}
