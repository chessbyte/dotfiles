# Code2Clip Oh My Zsh Plugin

Copies the text content of specified files and directories recursively into the system clipboard, formatted with file path comments. Especially useful for gathering code context to paste into Large Language Models (LLMs) or other prompts.

## Features

* Accepts multiple file and directory paths as arguments.
* Recursively scans directories for text-based files.
* Prepends each file's content with a comment indicating its relative path (e.g., `// path/to/your/file.js`).
* **Excludes:**
    * `.git/` directories.
    * `node_modules/` directories.
    * Common binary/media file extensions (images, videos, audio, fonts, pdfs, etc.).
* **JSON Handling:**
    * `.json` files within directories are **excluded** by default.
    * Use the `--include-json` flag to include `.json` files found during directory scans.
    * `.json` files explicitly listed as arguments (e.g., `code2clip config.json`) are **always included**, regardless of the flag.
* Copies the combined content to the system clipboard using `pbcopy` (macOS) or `xclip` (Linux).
* Outputs the total character count and estimated token count (chars/4) to standard error upon completion.

## Installation

**Prerequisites:**
* Zsh
* Oh My Zsh installed.
* Standard Unix utilities (`find`, `realpath`).
* Clipboard utility: `pbcopy` (macOS, usually pre-installed) or `xclip` (Linux, may need installation: e.g., `sudo apt install xclip`, `sudo yum install xclip`).

**Steps:**

1.  **Place Plugin Files:**
    Clone or copy this plugin's directory (`code2clip/`) into your Oh My Zsh custom plugins folder:
    ```bash
    # Example using Git (replace <repo_url> if applicable)
    # git clone <repo_url> ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/code2clip

    # Or manually copy the files:
    mkdir -p ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/code2clip
    # Copy code2clip.plugin.zsh and this README.md into the directory above
    cp path/to/code2clip.plugin.zsh ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/code2clip/
    cp path/to/README.md ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/code2clip/
    ```
    *(**Note for `chezmoi` users:** If you are managing your dotfiles with `chezmoi`, you would perform this step by adding the files to `dot_oh-my-zsh/custom/plugins/code2clip` within your `chezmoi` source directory).*

2.  **Enable Plugin:**
    Add `code2clip` to the `plugins=(...)` list in your `~/.zshrc` file.
    ```zsh
    plugins=(
        # other plugins...
        git
        code2clip
        # other plugins...
    )
    ```
    *(**Note for `chezmoi` users:** Edit the source version of your `.zshrc` within your `chezmoi` repository).*

3.  **Reload Zsh Configuration:**
    Open a new terminal session, or run:
    ```bash
    source ~/.zshrc
    ```

## Usage

The plugin provides the `code2clip` command (and potentially a `c2c` alias if defined in the plugin file).

**Syntax:**

```bash
code2clip [options] <path1> [path2] ...
```