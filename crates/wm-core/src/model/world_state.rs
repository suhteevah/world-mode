use tracing::{debug, info};
use wm_bridge::{GameState, Entity, Position};
use std::collections::HashMap;

/// Diff between two world states.
#[derive(Debug, Clone, Default)]
pub struct StateDiff {
    pub entities_added: usize,
    pub entities_removed: usize,
    pub entities_changed: usize,
    pub inventory_changes: Vec<(String, i64)>,
    pub tick_delta: u64,
}

/// Persistent world model that survives across agent loop iterations.
/// Tracks cumulative state, detects changes, and provides queryable access.
pub struct WorldModel {
    /// Most recent game state snapshot
    pub current_state: Option<GameState>,
    /// Previous game state (for diff computation)
    pub previous_state: Option<GameState>,
    /// Entity count by type (running summary)
    pub entity_counts: HashMap<String, usize>,
    /// Cumulative observations count
    pub observation_count: u64,
    /// Known resource patches and their last-known amounts
    pub resource_patches: HashMap<String, Vec<ResourcePatch>>,
    /// History of production rates for trend detection
    pub production_history: Vec<ProductionSnapshot>,
}

#[derive(Debug, Clone)]
pub struct ResourcePatch {
    pub resource_type: String,
    pub center: Position,
    pub last_known_amount: Option<u64>,
    pub last_observed_tick: u64,
}

#[derive(Debug, Clone)]
pub struct ProductionSnapshot {
    pub tick: u64,
    pub rates: HashMap<String, f64>,
}

impl WorldModel {
    pub fn new() -> Self {
        info!("World model initialized (empty)");
        Self {
            current_state: None,
            previous_state: None,
            entity_counts: HashMap::new(),
            observation_count: 0,
            resource_patches: HashMap::new(),
            production_history: Vec::new(),
        }
    }

    /// Update the world model with a new game state observation.
    /// Returns a diff describing what changed.
    pub fn update(&mut self, new_state: GameState) -> StateDiff {
        self.observation_count += 1;
        debug!(observation = self.observation_count, tick = new_state.tick, "Updating world model");

        let diff = if let Some(ref prev) = self.current_state {
            self.compute_diff(prev, &new_state)
        } else {
            StateDiff {
                entities_added: new_state.entities.len(),
                ..Default::default()
            }
        };

        // Update entity counts
        self.entity_counts.clear();
        for entity in &new_state.entities {
            *self.entity_counts.entry(entity.name.clone()).or_insert(0) += 1;
        }

        // Track production rates
        if !new_state.flows.output_rates.is_empty() {
            self.production_history.push(ProductionSnapshot {
                tick: new_state.tick,
                rates: new_state.flows.output_rates.clone(),
            });
            // Keep last 100 snapshots
            if self.production_history.len() > 100 {
                self.production_history.remove(0);
            }
        }

        // Rotate states
        self.previous_state = self.current_state.take();
        self.current_state = Some(new_state);

        info!(
            observation = self.observation_count,
            added = diff.entities_added,
            removed = diff.entities_removed,
            changed = diff.entities_changed,
            "World model updated"
        );

        diff
    }

    /// Compute the diff between two game states.
    fn compute_diff(&self, old: &GameState, new: &GameState) -> StateDiff {
        let old_entities: HashMap<String, &Entity> = old.entities.iter()
            .map(|e| (format!("{}@{},{}", e.name, e.position.x, e.position.y), e))
            .collect();

        let new_entities: HashMap<String, &Entity> = new.entities.iter()
            .map(|e| (format!("{}@{},{}", e.name, e.position.x, e.position.y), e))
            .collect();

        let added = new_entities.keys().filter(|k| !old_entities.contains_key(*k)).count();
        let removed = old_entities.keys().filter(|k| !new_entities.contains_key(*k)).count();
        // Simplified change detection — real implementation would compare properties
        let changed = 0;

        let mut inventory_changes = Vec::new();
        for (item, &new_count) in &new.inventory {
            let old_count = old.inventory.get(item).copied().unwrap_or(0);
            let delta = new_count as i64 - old_count as i64;
            if delta != 0 {
                inventory_changes.push((item.clone(), delta));
            }
        }

        StateDiff {
            entities_added: added,
            entities_removed: removed,
            entities_changed: changed,
            inventory_changes,
            tick_delta: new.tick.saturating_sub(old.tick),
        }
    }

    /// Generate a human-readable summary of current world state insights.
    pub fn summary(&self) -> String {
        let mut lines = Vec::new();

        if let Some(ref state) = self.current_state {
            lines.push(format!("Total entities: {}", state.entities.len()));

            // Top 5 entity types
            let mut counts: Vec<(&String, &usize)> = self.entity_counts.iter().collect();
            counts.sort_by(|a, b| b.1.cmp(a.1));
            for (name, count) in counts.iter().take(5) {
                lines.push(format!("  {} x{}", name, count));
            }
        }

        lines.push(format!("Observations: {}", self.observation_count));
        lines.join("\n")
    }
}
