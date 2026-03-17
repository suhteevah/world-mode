use anyhow::{Context, Result};
use clap::{Parser, Subcommand};
use tracing::info;
use tracing_subscriber::{fmt, EnvFilter};

use wm_bridge::RconClient;
use wm_core::config::WorldModeConfig;
use wm_core::mcp::server::run_stdio_server;
use wm_core::state::AppState;

#[derive(Parser)]
#[command(name = "world-mode")]
#[command(about = "World Mode — MCP server for AI-cooperative Factorio gameplay")]
#[command(version = "0.1.0")]
struct Cli {
    /// Path to configuration file
    #[arg(short, long, default_value = "configs/world-mode.toml")]
    config: String,

    #[command(subcommand)]
    command: Commands,
}

#[derive(Subcommand)]
enum Commands {
    /// Run the MCP server over stdio (Claude Code connects to this)
    McpServe,

    /// Check FLE adapter and Factorio server status
    Status,

    /// Execute a single Python program via FLE (for testing)
    Exec {
        /// Python code or path to .py file
        code: String,
    },

    /// Fetch and display current game state
    State,
}

#[tokio::main]
async fn main() -> Result<()> {
    let cli = Cli::parse();

    // For MCP stdio mode, logs MUST go to stderr (stdout is the JSON-RPC channel)
    let is_mcp = matches!(cli.command, Commands::McpServe);

    let subscriber = fmt()
        .with_env_filter(
            EnvFilter::try_from_default_env()
                .unwrap_or_else(|_| EnvFilter::new("wm_core=debug,wm_bridge=debug,info")),
        )
        .with_target(true)
        .with_writer(if is_mcp {
            // MCP mode: ALL output to stderr
            std::io::stderr as fn() -> std::io::Stderr
        } else {
            // Normal mode: we can use stderr too for consistency
            std::io::stderr as fn() -> std::io::Stderr
        })
        .pretty()
        .finish();
    tracing::subscriber::set_global_default(subscriber).ok();

    let config = WorldModeConfig::load(&cli.config)
        .with_context(|| format!("Failed to load config: {}", cli.config))?;

    match cli.command {
        Commands::McpServe => cmd_mcp_serve(config).await,
        Commands::Status => cmd_status(config).await,
        Commands::Exec { code } => cmd_exec(config, code).await,
        Commands::State => cmd_state(config).await,
    }
}

async fn cmd_mcp_serve(config: WorldModeConfig) -> Result<()> {
    info!("╔══════════════════════════════════════════════════════╗");
    info!("║       WORLD MODE v0.1.0 — MCP Server Starting       ║");
    info!("║       Pure Rust + Lua. No Python. No FLE.            ║");
    info!("║       The factory must grow.                         ║");
    info!("╚══════════════════════════════════════════════════════╝");

    let rcon = RconClient::new(
        &config.factorio.rcon_host,
        config.factorio.rcon_port,
        &config.factorio.rcon_password,
        config.factorio.timeout_seconds,
    );

    // Test RCON connection
    match rcon.execute("/version") {
        Ok(version) => info!(version = %version.trim(), "Connected to Factorio server via RCON"),
        Err(e) => info!(error = %e, "Factorio not reachable yet — will retry on tool calls"),
    }

    let state = AppState::new(rcon, config.general.abstractions_path.clone());
    state.load_abstractions().await;

    info!("MCP server ready — waiting for Claude Code on stdio...");
    run_stdio_server(state).await
}

async fn cmd_status(config: WorldModeConfig) -> Result<()> {
    let rcon = RconClient::new(
        &config.factorio.rcon_host,
        config.factorio.rcon_port,
        &config.factorio.rcon_password,
        config.factorio.timeout_seconds,
    );

    eprintln!("Checking Factorio RCON at {}:{}...", config.factorio.rcon_host, config.factorio.rcon_port);
    match rcon.execute("/version") {
        Ok(version) => {
            eprintln!("  Connected: YES");
            eprintln!("  Version:   {}", version.trim());
            // Try the World Mode mod
            match rcon.get_state(true) {
                Ok(state) => eprintln!("  WM Mod:    Loaded (got state)"),
                Err(e) => eprintln!("  WM Mod:    NOT loaded — install world-mode-bridge mod"),
            }
        }
        Err(e) => {
            eprintln!("  Connected: NO — {}", e);
            eprintln!("  Start Factorio: docker compose up factorio");
        }
    }
    Ok(())
}

async fn cmd_exec(config: WorldModeConfig, code: String) -> Result<()> {
    let rcon = RconClient::new(
        &config.factorio.rcon_host,
        config.factorio.rcon_port,
        &config.factorio.rcon_password,
        config.factorio.timeout_seconds,
    );

    let program = if std::path::Path::new(&code).exists() {
        std::fs::read_to_string(&code)?
    } else {
        code
    };
    eprintln!("Executing Lua via RCON...");
    match rcon.exec_lua(&program) {
        Ok(result) => eprintln!("Result:\n{}", result),
        Err(e) => eprintln!("Error: {}", e),
    }
    Ok(())
}

async fn cmd_state(config: WorldModeConfig) -> Result<()> {
    let rcon = RconClient::new(
        &config.factorio.rcon_host,
        config.factorio.rcon_port,
        &config.factorio.rcon_password,
        config.factorio.timeout_seconds,
    );

    eprintln!("Fetching game state via RCON...");
    match rcon.get_state(false) {
        Ok(raw) => {
            match serde_json::from_str::<serde_json::Value>(&raw) {
                Ok(parsed) => eprintln!("{}", serde_json::to_string_pretty(&parsed)?),
                Err(_) => eprintln!("{}", raw),
            }
        }
        Err(e) => eprintln!("Error: {}", e),
    }
    Ok(())
}
