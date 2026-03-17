use anyhow::{Context, Result};
use serde::Deserialize;
use std::path::Path;
use tracing::{info, debug};

#[derive(Debug, Clone, Deserialize)]
pub struct WorldModeConfig {
    pub general: GeneralConfig,
    pub claude: ClaudeConfig,
    pub factorio: FactorioConfig,
    pub dashboard: DashboardConfig,
    pub logging: LoggingConfig,
}

#[derive(Debug, Clone, Deserialize)]
pub struct GeneralConfig {
    /// How often the agent loop runs (milliseconds between cycles)
    pub loop_interval_ms: u64,
    /// Maximum number of consecutive errors before pausing
    pub max_consecutive_errors: u32,
    /// Path to the abstractions library
    pub abstractions_path: String,
    /// Path to the world model database
    pub db_path: String,
}

#[derive(Debug, Clone, Deserialize)]
pub struct ClaudeConfig {
    /// API key (can also be set via ANTHROPIC_API_KEY env var)
    pub api_key: Option<String>,
    /// Model to use
    pub model: String,
    /// Maximum tokens in response
    pub max_tokens: u32,
    /// Path to system prompt template
    pub system_prompt_path: String,
    /// Path to personality overlay
    pub personality_path: String,
    /// Maximum conversation history messages to include
    pub max_history_messages: usize,
    /// Temperature for generation
    pub temperature: Option<f64>,
}

#[derive(Debug, Clone, Deserialize)]
pub struct FactorioConfig {
    /// RCON host
    pub rcon_host: String,
    /// RCON port
    pub rcon_port: u16,
    /// RCON password
    pub rcon_password: String,
    /// Game server port (for human connection)
    pub server_port: u16,
    /// RCON read/write timeout in seconds (increase for megabases)
    pub timeout_seconds: u64,
}

#[derive(Debug, Clone, Deserialize)]
pub struct DashboardConfig {
    /// WebSocket port for pushing state to dashboard
    pub ws_port: u16,
    /// Dashboard HTTP port
    pub http_port: u16,
}

#[derive(Debug, Clone, Deserialize)]
pub struct LoggingConfig {
    /// Log level filter (e.g., "world_mode=trace")
    pub filter: String,
    /// Log format: "pretty" or "json"
    pub format: String,
}

impl WorldModeConfig {
    /// Load configuration from a TOML file.
    pub fn load(path: impl AsRef<Path>) -> Result<Self> {
        let path = path.as_ref();
        info!(path = %path.display(), "Loading configuration");

        let content = std::fs::read_to_string(path)
            .with_context(|| format!("Failed to read config file: {}", path.display()))?;

        let config: WorldModeConfig = toml::from_str(&content)
            .with_context(|| format!("Failed to parse config file: {}", path.display()))?;

        // Override API key from env if not in config
        let config = if config.claude.api_key.is_none() {
            let mut config = config;
            config.claude.api_key = std::env::var("ANTHROPIC_API_KEY").ok();
            config
        } else {
            config
        };

        debug!(
            loop_interval_ms = config.general.loop_interval_ms,
            model = %config.claude.model,
            rcon_host = %config.factorio.rcon_host,
            rcon_port = config.factorio.rcon_port,
            "Configuration loaded successfully"
        );

        Ok(config)
    }
}
