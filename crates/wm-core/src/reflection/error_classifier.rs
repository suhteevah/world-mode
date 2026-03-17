use wm_bridge::ErrorCategory;
use tracing::debug;

/// Classify an execution error based on the stderr output.
/// Uses heuristics matching FLE's error taxonomy from the v0.3.0 paper.
pub fn classify_error(stderr: &str) -> ErrorCategory {
    let lower = stderr.to_lowercase();

    if lower.contains("syntaxerror") || lower.contains("indentationerror") {
        debug!(category = "Syntactic", "Error classified as syntactic");
        ErrorCategory::Syntactic
    } else if lower.contains("typeerror") || lower.contains("attributeerror")
        || lower.contains("nameerror") || lower.contains("importerror") {
        debug!(category = "Semantic", "Error classified as semantic");
        ErrorCategory::Semantic
    } else if lower.contains("not enough") || lower.contains("cannot place")
        || lower.contains("no buildable") || lower.contains("inventory")
        || lower.contains("not found") || lower.contains("assertionerror") {
        debug!(category = "Pragmatic", "Error classified as pragmatic");
        ErrorCategory::Pragmatic
    } else {
        debug!(category = "Unknown", stderr_preview = %&stderr[..stderr.len().min(200)], "Error category unknown");
        ErrorCategory::Unknown
    }
}
