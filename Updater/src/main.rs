use std::env;
use std::error::Error;
use std::fs::{self, File};
use std::io::{self, IsTerminal};
use std::path::{Path, PathBuf};

const LATEST_RELEASE_URL: &str = "https://api.github.com/repos/CBurlison/FULL_FFXIV_UI/releases/latest";
const ASSET_NAME: &str = "FFXIV_UI.zip";
const ADDON_FOLDER: &str = "FFXIV_UI";
const INSTALLED_TAG_FILE: &str = "installed.txt";
const USER_AGENT: &str = "FFXIV_UI-Updater";

type Result<T> = std::result::Result<T, Box<dyn Error>>;

fn main() {
    let code = match run() {
        Ok(()) => 0,
        Err(e) => {
            eprintln!("Update failed: {e}");
            1
        }
    };

    if io::stdin().is_terminal() {
        println!("\nPress Enter to close.");
        let mut line = String::new();
        let _ = io::stdin().read_line(&mut line);
    }

    std::process::exit(code);
}

fn run() -> Result<()> {
    let exe = env::current_exe()?;
    let updater_dir = exe.parent().ok_or("Cannot find the updater folder.")?.to_path_buf();
    let addon_dir = updater_dir.parent().ok_or("Cannot find the addon folder.")?.to_path_buf();

    if !addon_dir.join("FFXIV_UI.toc").is_file() {
        return Err(format!(
            "Run this updater from the {ADDON_FOLDER}\\updater folder. No FFXIV_UI.toc found in {}.",
            addon_dir.display()
        )
        .into());
    }

    if is_reparse_point(&addon_dir)? {
        return Err("The addon folder is a junction or symlink (development link). Refusing to overwrite it with a release.".into());
    }

    remove_stale_copies(&updater_dir);

    println!("Checking the latest release...");
    let release: serde_json::Value = serde_json::from_reader(get(LATEST_RELEASE_URL)?.into_reader())?;
    let tag = release["tag_name"].as_str().ok_or("Release has no tag.")?.to_string();

    let download_url = release["assets"]
        .as_array()
        .into_iter()
        .flatten()
        .find(|a| a["name"].as_str() == Some(ASSET_NAME))
        .and_then(|a| a["browser_download_url"].as_str())
        .ok_or_else(|| format!("Release {tag} has no asset named {ASSET_NAME}."))?
        .to_string();

    let installed_path = updater_dir.join(INSTALLED_TAG_FILE);
    let installed = fs::read_to_string(&installed_path).ok();
    if installed.as_deref().map(str::trim).is_some_and(|t| t.eq_ignore_ascii_case(&tag)) {
        println!("Already up to date ({tag}).");
        return Ok(());
    }

    let work = env::temp_dir().join(format!("FFXIV_UI_update_{}", std::process::id()));
    fs::create_dir_all(&work)?;
    let result = install(&work, &addon_dir, &exe, &download_url, &tag);
    let _ = fs::remove_dir_all(&work);
    result?;

    fs::write(&installed_path, &tag)?;
    println!("Updated to {tag}. Restart WoW or reload the UI to use the new version.");
    Ok(())
}

fn install(work: &Path, addon_dir: &Path, exe: &Path, download_url: &str, tag: &str) -> Result<()> {
    let zip_path = work.join(ASSET_NAME);
    println!("Downloading {tag}...");
    let mut reader = get(download_url)?.into_reader();
    io::copy(&mut reader, &mut File::create(&zip_path)?)?;

    let staging = work.join("staging");
    zip::ZipArchive::new(File::open(&zip_path)?)?.extract(&staging)?;

    let release_addon = staging.join(ADDON_FOLDER);
    if !release_addon.join("FFXIV_UI.toc").is_file() {
        return Err(format!("Archive does not contain {ADDON_FOLDER}\\FFXIV_UI.toc.").into());
    }

    println!("Installing {tag} into {}...", addon_dir.display());
    copy_tree(&release_addon, addon_dir, exe)
}

// A running exe can be renamed but not overwritten, so the copy of this updater is moved aside first.
fn copy_tree(src: &Path, dst: &Path, self_exe: &Path) -> Result<()> {
    for entry in fs::read_dir(src)? {
        let entry = entry?;
        let from = entry.path();
        let to = dst.join(entry.file_name());

        if entry.file_type()?.is_dir() {
            fs::create_dir_all(&to)?;
            copy_tree(&from, &to, self_exe)?;
            continue;
        }

        if to.to_string_lossy().eq_ignore_ascii_case(&self_exe.to_string_lossy()) {
            fs::rename(&to, PathBuf::from(format!("{}.old", to.display())))?;
        }

        fs::copy(&from, &to).map_err(|e| {
            format!("Could not replace {}. Close World of Warcraft and try again. ({e})", to.display())
        })?;
    }
    Ok(())
}

fn remove_stale_copies(updater_dir: &Path) {
    let Ok(entries) = fs::read_dir(updater_dir) else { return };
    for entry in entries.flatten() {
        if entry.file_name().to_string_lossy().ends_with(".exe.old") {
            let _ = fs::remove_file(entry.path());
        }
    }
}

fn get(url: &str) -> Result<ureq::Response> {
    Ok(ureq::get(url)
        .set("User-Agent", USER_AGENT)
        .set("Accept", "application/vnd.github+json")
        .call()?)
}

#[cfg(windows)]
fn is_reparse_point(path: &Path) -> io::Result<bool> {
    use std::os::windows::fs::MetadataExt;
    const FILE_ATTRIBUTE_REPARSE_POINT: u32 = 0x400;
    Ok(fs::symlink_metadata(path)?.file_attributes() & FILE_ATTRIBUTE_REPARSE_POINT != 0)
}

#[cfg(not(windows))]
fn is_reparse_point(_path: &Path) -> io::Result<bool> {
    Ok(false)
}
