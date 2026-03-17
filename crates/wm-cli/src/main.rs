// wm-cli is a thin alias for wm-core.
// The actual CLI logic lives in wm-core's main.rs with clap subcommands.
// This binary exists so `cargo install` creates a `world-mode` command.
//
// For now, just print a help message pointing to wm-core.

fn main() {
    eprintln!("World Mode CLI");
    eprintln!("Run the MCP server directly:");
    eprintln!("  cargo run --bin wm-core -- mcp-serve");
    eprintln!("  cargo run --bin wm-core -- status");
    eprintln!("  cargo run --bin wm-core -- state");
    eprintln!("  cargo run --bin wm-core -- exec \"print('hello')\"");
}
