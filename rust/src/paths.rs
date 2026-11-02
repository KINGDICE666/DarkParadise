use once_cell::sync::Lazy;
use std::path::{Path, PathBuf};

static GAME_ROOT: Lazy<PathBuf> = Lazy::new(|| std::env::current_dir().unwrap());

pub fn game_path(path: impl AsRef<Path>) -> PathBuf {
    GAME_ROOT.join(path)
}
