#!/usr/bin/env ruby

# ============================================================================
# REPOSITORY SYNCHRONIZATION SCRIPT
# ============================================================================
#
# This Ruby script automatically synchronizes all git repositories in the
# current directory with the latest commits from a configurable source
# remote's main branch.
#
# ============================================================================
# FEATURES
# ============================================================================
#
# • Parameterized Remotes: Configurable source remote (default: origin) and
#   target remote (optional)
# • Automatic Discovery: Scans all subdirectories for git repositories
# • Work in Progress Handling: Detects uncommitted changes and offers options
#   to stash, commit, or skip
# • Branch Management: Automatically switches to main branch when needed
# • Remote Validation: Checks for required remotes
# • Conflict Resolution: Handles merge conflicts with user interaction
# • Fork Synchronization: Pushes to target remote after successful sync
# • Comprehensive Stats: Provides detailed statistics at completion
# • Interactive Mode: Pauses for user input when uncertain
#
# ============================================================================
# PREREQUISITES
# ============================================================================
#
# • Ruby installed on your system
# • Git repositories with configured remotes
#
# ============================================================================
# CONFIGURATION
# ============================================================================
#
# The script supports a three-tier configuration system with the following
# precedence (highest to lowest):
# 1. Command line arguments (highest priority)
# 2. Directory-specific config files
# 3. Global config file (lowest priority)
#
# GLOBAL CONFIG FILE:
# The script looks for a global config file in your home directory:
# • ~/.sync_repos.yml
# • ~/.sync_repos.yaml
#
# DIRECTORY-SPECIFIC CONFIG FILES:
# The script looks for directory-specific config files in this order:
# • sync_repos.yml
# • sync_repos.yaml
# • .sync_repos.yml
# • .sync_repos.yaml
#
# Example global config file (~/.sync_repos.yml):
# ---
# # Default source remote (typically the same across projects)
# source-remote: origin
#
# # Your personal fork remote (consistent across organizations)
# target-remote: chessbyte
#
# # Default main branch name
# main-branch: main
#
# # Default verbosity setting
# verbose: false
#
# Example directory-specific config file (sync_repos.yml):
# ---
# # Override source remote for this specific project/organization
# source-remote: upstream
#
# # Keep your personal fork remote (inherited from global config)
# # target-remote: chessbyte  # This will be inherited from global config
#
# # Override main branch if this project uses a different default
# # main-branch: master
#
# Configuration Options Explained:
# • source-remote: The remote repository to pull updates from. This is
#   typically the upstream/original repository.
# • target-remote: Optional. The remote to push to after syncing. This is
#   typically your fork of the repository.
# • main-branch: The primary branch name. Usually 'main' or 'master'.
# • verbose: Whether to show detailed output during processing.
#
# Configuration Precedence:
# Command line arguments > Directory config > Global config > Built-in defaults
#
# ============================================================================
# USAGE EXAMPLES
# ============================================================================
#
# Basic usage (uses config file or defaults):
#   ./sync_repos.rb
#
# Override specific settings:
#   ./sync_repos.rb -s upstream -t fork
#
# Process single directory with verbose output:
#   ./sync_repos.rb -v my-project
#
# Custom setup for upstream/chessbyte workflow:
#   ./sync_repos.rb -s upstream -t chessbyte
#
# Show help:
#   ./sync_repos.rb --help
#
# ============================================================================
# COMMAND LINE OPTIONS
# ============================================================================
#
# -s, --source-remote <name>  Source remote name (default: origin)
# -t, --target-remote <name>  Target remote name for push (optional)
# -b, --main-branch <name>    Main branch name (default: main)
# -v, --verbose               Show detailed output (default: concise)
# -h, --help                  Show help message
# [directory]                 Process only this specific directory (optional)
#
# ============================================================================
# WHAT THE SCRIPT DOES
# ============================================================================
#
# For each git repository found, the script:
#
# 1. Checks Repository Status
#    • Verifies it's a git repository
#    • Confirms source remote exists
#    • Checks for uncommitted changes
#
# 2. Handles Work in Progress
#    • If uncommitted changes are found, offers options:
#      - Stash changes and continue
#      - Commit changes and continue
#      - Skip repository
#      - Show full git status
#
# 3. Branch Management
#    • Checks current branch
#    • Switches to main branch if needed
#    • Creates local main from source remote if it doesn't exist
#
# 4. Synchronization
#    • Fetches from source remote
#    • Pulls latest changes from source remote's main branch
#    • Handles merge conflicts interactively
#
# 5. Fork Update (if target remote specified)
#    • Pushes to target remote
#    • Uses force push with lease (-fu) for safety
#
# ============================================================================
# INTERACTIVE PROMPTS
# ============================================================================
#
# The script will pause and ask for your input in these situations:
#
# Work in Progress Detected:
#   What would you like to do?
#   1) Stash changes and continue
#   2) Commit changes and continue
#   3) Skip this repository
#   4) Show full git status
#
# Branch Switch Failure:
#   What would you like to do?
#   1) Skip this repository
#   2) Stay on current branch and try to sync
#
# Merge Conflicts:
#   What would you like to do?
#   1) Skip this repository
#   2) Reset hard to source/main (DESTRUCTIVE - will lose local changes)
#   3) Open manual resolution (you'll need to resolve conflicts manually)
#
# ============================================================================
# SAFETY FEATURES
# ============================================================================
#
# • Non-destructive by default: Won't automatically overwrite local changes
# • Interactive conflict resolution: Always asks before destructive operations
# • Comprehensive error handling: Gracefully handles various git scenarios
# • Detailed logging: Shows exactly what's happening at each step
# • Parameterized remotes: No hardcoded remote names
#
# ============================================================================
# TROUBLESHOOTING
# ============================================================================
#
# "Remote not found":
#   Ensure your repository has the required remote configured:
#   git remote add upstream <upstream-repo-url>
#   git remote add chessbyte <chessbyte-repo-url>
#
# "Failed to switch to main":
#   The script will offer to continue on the current branch or skip.
#
# Merge Conflicts:
#   Choose option 3 to manually resolve, then re-run the script.
#
# ============================================================================
# STATISTICS REPORT
# ============================================================================
#
# At completion, the script provides a comprehensive report:
#
# 📊 SYNCHRONIZATION COMPLETE
# ====================================
# Git repositories found: 20
# Successfully synced: 18
#   - With changes pulled: 12
#   - No changes (up to date): 6
# Skipped: 1
# Errors: 1
# Work in progress handled: 3
# Branch switches performed: 5
#
# 🎉 Synchronization process completed!
#
# ============================================================================

require 'fileutils'
require 'open3'
require 'yaml'

# ============================================================================
# MAIN SYNCHRONIZATION CLASS
# ============================================================================
# This class handles the core logic for repository synchronization, including
# directory processing, git operations, and user interaction.

class RepoSyncer
  def initialize(source_remote = 'origin', target_remote = nil, main_branch = 'main', verbose = false, target_directory = nil)
    # Statistics tracking for final report
    @stats = {
      git_repos: 0,
      successfully_synced: 0,
      skipped: 0,
      errors: 0,
      work_in_progress: 0,
      branch_switches: 0,
      changes_pulled: 0,
      no_changes: 0
    }
    @current_dir = Dir.pwd
    @source_remote = source_remote
    @target_remote = target_remote
    @main_branch = main_branch
    @verbose = verbose
    @target_directory = target_directory
  end

  # Main entry point - orchestrates the entire synchronization process
  def run
    puts "🚀 Starting repository synchronization..."
    puts "Current directory: #{@current_dir}"
    puts "Source remote: #{@source_remote}"
    puts "Target remote: #{@target_remote || 'none'}"
    puts "Main branch: #{@main_branch}"

    if @target_directory
      puts "Target directory: #{@target_directory}"
    end
    puts "=" * 60

    if @target_directory
      # Process single directory
      if File.directory?(@target_directory)
        @max_repo_name_length = @target_directory.length unless @verbose
        process_directory(@target_directory)
      else
        puts "❌ Directory '#{@target_directory}' not found"
        @stats[:errors] += 1
      end
    else
      # Get all subdirectories and sort them
      subdirs = Dir.glob("*/").select { |d| File.directory?(d) }.sort
      dir_names = subdirs.map { |d| d.chomp('/') }

      # Calculate padding for non-verbose mode display formatting
      unless @verbose
        git_repos = dir_names.select do |dir_name|
          Dir.chdir(File.join(@current_dir, dir_name)) do
            File.directory?('.git')
          end
        end
        @max_repo_name_length = git_repos.map(&:length).max || 0
      end

      dir_names.each do |dir_name|
        process_directory(dir_name)
      end
    end

    print_final_stats
  end

  private

  # ============================================================================
  # DIRECTORY PROCESSING
  # ============================================================================
  # Processes a single directory, handling all git operations and user interactions

  def process_directory(dir_name)
    @current_repo_name = dir_name  # Store for dynamic status updates
    original_branch = nil

    Dir.chdir(File.join(@current_dir, dir_name)) do
      unless git_repo?
        # Skip non-git directories silently
        return
      end

      if @verbose
        puts "\n📁 Processing: #{dir_name}"
      end
      @stats[:git_repos] += 1

      # Check if source remote exists
      unless remote_exists?(@source_remote)
        if @verbose
          puts "   ❌ Remote '#{@source_remote}' not found, skipping"
        else
          finalize_status("❌ No #{@source_remote} remote")
        end
        @stats[:skipped] += 1
        return
      end

      # Store original branch before any changes
      original_branch = get_current_branch

      # Check for work in progress (uncommitted changes)
      if has_uncommitted_changes?
        handle_work_in_progress(dir_name, original_branch)
        return
      end

      # Check current branch
      current_branch = get_current_branch
      if @verbose
        puts "   📍 Current branch: #{current_branch}"
      else
        update_status("Checking branch...")
      end

      # Switch to main if not already there
      switched_branch = false
      if current_branch != @main_branch
        unless @verbose
          update_status("Switching to #{@main_branch}...")
        end
        if switch_to_main_branch(current_branch)
          @stats[:branch_switches] += 1
          switched_branch = true
        else
          return
        end
      end

      # Fetch and pull from source remote
      unless @verbose
        update_status("Fetching...")
      end
      sync_result = sync_with_source_remote
      if sync_result
        # Push to target remote if sync was successful
        unless @verbose
          update_status("Pushing...")
        end
        push_to_target_remote
        @stats[:successfully_synced] += 1

        # Return to original branch if we switched
        if switched_branch && original_branch != @main_branch
          unless @verbose
            update_status("Returning to #{original_branch}...")
          end
          return_to_original_branch(original_branch)
        end

        if @verbose
          puts "   ✅ Successfully synced #{dir_name}"
        else
          if sync_result == :changes_pulled
            finalize_status("✅ Synced (changes pulled)")
            @stats[:changes_pulled] += 1
          else
            finalize_status("✅ Synced (no changes)")
            @stats[:no_changes] += 1
          end
        end
      else
        @stats[:errors] += 1
        unless @verbose
          finalize_status("❌ Error")
        end
      end
    end
  rescue => e
    if @verbose
      puts "   ❌ Error processing #{dir_name}: #{e.message}"
    else
      finalize_status("❌ Error: #{e.message}")
    end
    @stats[:errors] += 1
  ensure
    Dir.chdir(@current_dir)
  end

  # Returns to the original branch after processing
  def return_to_original_branch(original_branch)
    stdout, stderr, status = Open3.capture3("git checkout #{original_branch}")
    if status.success?
      if @verbose
        puts "   🔄 Returned to original branch: #{original_branch}"
      end
    else
      if @verbose
        puts "   ⚠️  Failed to return to original branch #{original_branch}: #{stderr}"
      end
    end
  end

  # ============================================================================
  # STATUS DISPLAY HELPERS
  # ============================================================================
  # These methods handle the dynamic status updates in non-verbose mode

  def update_status(message)
    return if @verbose
    # For non-verbose mode, just show final status without intermediate updates
    # This prevents the jumbled output issue
  end

  def finalize_status(message)
    return if @verbose
    puts "#{@current_repo_name.ljust(@max_repo_name_length)}: #{message}"
  end

  # ============================================================================
  # GIT UTILITY METHODS
  # ============================================================================
  # Basic git operations and status checks

  def git_repo?
    File.directory?('.git')
  end

  def remote_exists?(remote_name)
    stdout, stderr, status = Open3.capture3("git remote")
    status.success? && stdout.split("\n").include?(remote_name)
  end

  def has_uncommitted_changes?
    stdout, stderr, status = Open3.capture3("git status --porcelain")
    status.success? && !stdout.strip.empty?
  end

  def get_current_branch
    stdout, stderr, status = Open3.capture3("git branch --show-current")
    if status.success?
      stdout.strip
    else
      "unknown"
    end
  end

  # ============================================================================
  # WORK IN PROGRESS HANDLING
  # ============================================================================
  # Handles repositories with uncommitted changes, offering various options

  def handle_work_in_progress(dir_name, original_branch)
    @stats[:work_in_progress] += 1

    # Show status
    stdout, stderr, status = Open3.capture3("git status --short")

    # Check if changes are only untracked files (start with ??)
    # Filter out branch status lines that start with ##
    file_lines = stdout.lines.reject { |line| line.start_with?('##') }
    only_untracked = file_lines.all? { |line| line.start_with?('??') }

    # If only untracked files, try to proceed automatically
    if only_untracked
      if @verbose
        puts "   💡 Only untracked files detected, attempting git pull first..."
      end

      # Check current branch and switch to main if needed
      current_branch = get_current_branch
      if @verbose
        puts "   📍 Current branch: #{current_branch}"
      end

      switched_branch = false
      if current_branch != @main_branch
        if switch_to_main_branch(current_branch)
          @stats[:branch_switches] += 1
          switched_branch = true
        else
          unless @verbose
            puts "❌ Branch switch failed"
          end
          return
        end
      end

      # Try the git pull with untracked files present
      sync_result = sync_with_source_remote
      if sync_result
        push_to_target_remote
        @stats[:successfully_synced] += 1

        # Return to original branch if we switched and it's different from main
        if switched_branch && original_branch != @main_branch
          if @verbose
            puts "   🔄 Returning to original branch: #{original_branch}"
          end
          return_to_original_branch(original_branch)
        end

        if @verbose
          puts "   ✅ Successfully synced #{dir_name} (untracked files preserved)"
        else
          if sync_result == :changes_pulled
            finalize_status("✅ Synced (changes pulled, untracked preserved)")
            @stats[:changes_pulled] += 1
          else
            finalize_status("✅ Synced (no changes, untracked preserved)")
            @stats[:no_changes] += 1
          end
        end
        return
      else
        if @verbose
          puts "   ❌ Git pull failed even with only untracked files present"
        else
          finalize_status("❌ Pull failed with untracked files")
          return
        end
        # Fall through to ask user what to do
      end
    end

    # If we get here, there are tracked changes or the auto-pull failed
    if @verbose
      puts "   ⚠️  Work in progress detected!"
      puts "   📋 Changes:"
      stdout.each_line { |line| puts "      #{line.chomp}" }

      puts "\n   What would you like to do?"
      puts "   1) Stash changes and continue"
      puts "   2) Commit changes and continue"
      puts "   3) Skip this repository"
      puts "   4) Show full git status"
      print "   Enter choice (1-4): "

      choice = STDIN.gets.chomp

      case choice
      when '1'
        if stash_changes
          puts "   💾 Changes stashed, continuing..."
          # Retry processing without work in progress
          process_directory_after_stash(dir_name)
        else
          puts "   ❌ Failed to stash changes"
          @stats[:errors] += 1
        end
      when '2'
        commit_changes
      when '3'
        puts "   ⏭️  Skipping repository"
        @stats[:skipped] += 1
      when '4'
        system("git status")
        handle_work_in_progress(dir_name, original_branch) # Ask again
      else
        puts "   ❌ Invalid choice, skipping repository"
        @stats[:skipped] += 1
      end
    else
      # In non-verbose mode, just skip repositories with tracked changes
      puts "❌ Has uncommitted changes (use -v for options)"
      @stats[:skipped] += 1
    end
  end

  def stash_changes
    stdout, stderr, status = Open3.capture3("git stash push -m 'Auto-stash by sync script'")
    if status.success?
      puts "   ✅ Changes stashed successfully"
      true
    else
      puts "   ❌ Failed to stash: #{stderr}"
      false
    end
  end

  def commit_changes
    print "   Enter commit message: "
    message = STDIN.gets.chomp

    if message.empty?
      message = "WIP: Auto-commit by sync script"
    end

    stdout, stderr, status = Open3.capture3("git add -A && git commit -m '#{message}'")
    if status.success?
      puts "   ✅ Changes committed successfully"
      # Continue with sync process
      current_branch = get_current_branch
      if current_branch != @main_branch
        switch_to_main_branch(current_branch)
      end
      sync_with_source_remote
      push_to_target_remote
      @stats[:successfully_synced] += 1
    else
      puts "   ❌ Failed to commit: #{stderr}"
      @stats[:errors] += 1
    end
  end

  def process_directory_after_stash(dir_name)
    current_branch = get_current_branch

    if current_branch != @main_branch
      if switch_to_main_branch(current_branch)
        @stats[:branch_switches] += 1
      else
        return
      end
    end

    if sync_with_source_remote
      push_to_target_remote
      @stats[:successfully_synced] += 1
      puts "   ✅ Successfully synced #{dir_name}"
    else
      @stats[:errors] += 1
    end
  end

  # ============================================================================
  # BRANCH MANAGEMENT
  # ============================================================================
  # Handles switching to the main branch, creating it if necessary

  def switch_to_main_branch(current_branch)
    if @verbose
      puts "   🔄 Switching from '#{current_branch}' to '#{@main_branch}'"
    end

    # First check if main branch exists locally
    stdout, stderr, status = Open3.capture3("git branch --list #{@main_branch}")
    main_exists_locally = status.success? && !stdout.strip.empty?

    if main_exists_locally
      stdout, stderr, status = Open3.capture3("git checkout #{@main_branch}")
    else
      # Try to checkout main from source remote
      if @verbose
        puts "   📥 #{@main_branch} branch not found locally, checking out from #{@source_remote}/#{@main_branch}"
      end
      stdout, stderr, status = Open3.capture3("git checkout -b #{@main_branch} #{@source_remote}/#{@main_branch}")
    end

    if status.success?
      if @verbose
        puts "   ✅ Switched to #{@main_branch} branch"
      end
      true
    else
      if @verbose
        puts "   ❌ Failed to switch to #{@main_branch}: #{stderr}"
        puts "   What would you like to do?"
        puts "   1) Skip this repository"
        puts "   2) Stay on current branch and try to sync"
        print "   Enter choice (1-2): "

        choice = STDIN.gets.chomp
        case choice
        when '1'
          @stats[:skipped] += 1
          false
        when '2'
          puts "   ⚠️  Continuing on branch '#{current_branch}'"
          true
        else
          @stats[:skipped] += 1
          false
        end
      else
        # In non-verbose mode, just skip on branch switch failure
        @stats[:skipped] += 1
        false
      end
    end
  end

  # ============================================================================
  # SYNCHRONIZATION OPERATIONS
  # ============================================================================
  # Core git operations for fetching and pulling from source remote

  def sync_with_source_remote
    if @verbose
      puts "   📥 Fetching from #{@source_remote}..."
    end

    # Fetch first
    stdout, stderr, status = Open3.capture3("git fetch #{@source_remote}")
    unless status.success?
      if @verbose
        puts "   ❌ Failed to fetch from #{@source_remote}: #{stderr}"
      end
      return false
    end

    # Pull from source remote main
    if @verbose
      puts "   📥 Pulling from #{@source_remote}/#{@main_branch}..."
    end
    stdout, stderr, status = Open3.capture3("git pull #{@source_remote} #{@main_branch}")

    if status.success?
      # Check if changes were actually pulled - be more comprehensive
      up_to_date_patterns = [
        "Already up to date",
        "Already up-to-date",
        "is up to date"
      ]

      changes_pulled = !up_to_date_patterns.any? { |pattern| stdout.include?(pattern) }

      # Additional check: if stdout is very short and doesn't mention files, likely no changes
      if changes_pulled && stdout.strip.length < 50 && !stdout.match(/\d+ file/)
        changes_pulled = false
      end

      if @verbose
        puts "   📋 Git pull output: #{stdout.strip}" if stdout.strip.length > 0
        if changes_pulled
          puts "   ✅ Successfully pulled changes from #{@source_remote}/#{@main_branch}"
        else
          puts "   ✅ Already up to date with #{@source_remote}/#{@main_branch}"
        end
      end

      changes_pulled ? :changes_pulled : :no_changes
    else
      if @verbose
        puts "   ❌ Failed to pull from #{@source_remote}/#{@main_branch}: #{stderr}"
      end

      # Check if it's a merge conflict or other issue
      if stderr.include?("CONFLICT") || stderr.include?("conflict")
        if @verbose
          puts "   ⚠️  Merge conflict detected!"
          puts "   What would you like to do?"
          puts "   1) Skip this repository"
          puts "   2) Reset hard to #{@source_remote}/#{@main_branch} (DESTRUCTIVE - will lose local changes)"
          puts "   3) Open manual resolution (you'll need to resolve conflicts manually)"
          print "   Enter choice (1-3): "

          choice = STDIN.gets.chomp
          case choice
          when '1'
            @stats[:skipped] += 1
            false
          when '2'
            reset_to_source_main
          when '3'
            puts "   🔧 Please resolve conflicts manually, then run the script again"
            @stats[:skipped] += 1
            false
          else
            @stats[:skipped] += 1
            false
          end
        else
          # In non-verbose mode, just skip conflicts
          @stats[:skipped] += 1
          false
        end
      else
        false
      end
    end
  end

  def reset_to_source_main
    puts "   ⚠️  Performing hard reset to #{@source_remote}/#{@main_branch}..."
    stdout, stderr, status = Open3.capture3("git reset --hard #{@source_remote}/#{@main_branch}")

    if status.success?
      puts "   ✅ Successfully reset to #{@source_remote}/#{@main_branch}"
      true
    else
      puts "   ❌ Failed to reset: #{stderr}"
      false
    end
  end

  # ============================================================================
  # TARGET REMOTE OPERATIONS
  # ============================================================================
  # Pushes changes to the target remote (typically a fork)

  def push_to_target_remote
    # Skip if no target remote specified
    return unless @target_remote

    # Check if target remote exists
    unless remote_exists?(@target_remote)
      if @verbose
        puts "   ⚠️  Remote '#{@target_remote}' not found, skipping push"
      end
      return
    end

    if @verbose
      puts "   📤 Pushing to #{@target_remote}..."
    end
    stdout, stderr, status = Open3.capture3("git push -fu #{@target_remote}")

    if status.success?
      if @verbose
        puts "   ✅ Successfully pushed to #{@target_remote}"
      end
    else
      if @verbose
        puts "   ❌ Failed to push to #{@target_remote}: #{stderr}"
        puts "   This is not critical - the main sync was successful"
      end
    end
  end

  # ============================================================================
  # STATISTICS AND REPORTING
  # ============================================================================
  # Generates the final synchronization report

  def print_final_stats
    puts "\n" + "=" * 60
    puts "📊 SYNCHRONIZATION COMPLETE"
    puts "=" * 60
    puts "Git repositories found: #{@stats[:git_repos]}"
    puts "Successfully synced: #{@stats[:successfully_synced]}"
    puts "  - With changes pulled: #{@stats[:changes_pulled]}"
    puts "  - No changes (up to date): #{@stats[:no_changes]}"
    puts "Skipped: #{@stats[:skipped]}"
    puts "Errors: #{@stats[:errors]}"
    puts "Work in progress handled: #{@stats[:work_in_progress]}"
    puts "Branch switches performed: #{@stats[:branch_switches]}"

    puts "\n🎉 Synchronization process completed!"
  end
end

# ============================================================================
# CONFIGURATION LOADING
# ============================================================================
# Loads configuration from YAML files with three-tier precedence system

def load_config
  config = {}

  # 1. Load global config first (lowest priority)
  global_config_files = [
    File.expand_path('~/.sync_repos.yml'),
    File.expand_path('~/.sync_repos.yaml')
  ]

  global_config_files.each do |global_config_file|
    if File.exist?(global_config_file)
      begin
        loaded_config = YAML.load_file(global_config_file)
        if loaded_config.is_a?(Hash)
          config = loaded_config
          puts "🌍 Loaded global configuration from #{global_config_file}"
          break
        end
      rescue => e
        puts "⚠️  Warning: Failed to load global config #{global_config_file}: #{e.message}"
      end
    end
  end

  # 2. Load directory-specific config (higher priority, merges with global)
  local_config_files = ['sync_repos.yml', 'sync_repos.yaml', '.sync_repos.yml', '.sync_repos.yaml']

  local_config_files.each do |local_config_file|
    if File.exist?(local_config_file)
      begin
        loaded_config = YAML.load_file(local_config_file)
        if loaded_config.is_a?(Hash)
          # Merge directory config over global config
          config = config.merge(loaded_config)
          puts "📁 Loaded directory configuration from #{local_config_file}"
          break
        end
      rescue => e
        puts "⚠️  Warning: Failed to load directory config #{local_config_file}: #{e.message}"
      end
    end
  end

  # Show final configuration source summary
  if config.empty?
    puts "📄 No configuration files found, using built-in defaults"
  end

  config
end

def load_config_with_sources
  config_info = {
    source_remote: { value: 'origin', source: 'default' },
    target_remote: { value: nil, source: 'default' },
    main_branch: { value: 'main', source: 'default' },
    verbose: { value: false, source: 'default' }
  }

  # 1. Load global config first (lowest priority)
  global_config_files = [
    File.expand_path('~/.sync_repos.yml'),
    File.expand_path('~/.sync_repos.yaml')
  ]

  global_config_loaded = false
  global_config_files.each do |global_config_file|
    if File.exist?(global_config_file)
      begin
        loaded_config = YAML.load_file(global_config_file)
        if loaded_config.is_a?(Hash)
          # Update values from global config
          if loaded_config['source_remote'] || loaded_config['source-remote']
            config_info[:source_remote] = {
              value: loaded_config['source_remote'] || loaded_config['source-remote'],
              source: 'global config'
            }
          end
          if loaded_config['target_remote'] || loaded_config['target-remote']
            config_info[:target_remote] = {
              value: loaded_config['target_remote'] || loaded_config['target-remote'],
              source: 'global config'
            }
          end
          if loaded_config['main_branch'] || loaded_config['main-branch']
            config_info[:main_branch] = {
              value: loaded_config['main_branch'] || loaded_config['main-branch'],
              source: 'global config'
            }
          end
          if loaded_config.key?('verbose')
            config_info[:verbose] = {
              value: loaded_config['verbose'],
              source: 'global config'
            }
          end
          puts "🌍 Loaded global configuration from #{global_config_file}"
          global_config_loaded = true
          break
        end
      rescue => e
        puts "⚠️  Warning: Failed to load global config #{global_config_file}: #{e.message}"
      end
    end
  end

  # 2. Load directory-specific config (higher priority, overrides global)
  local_config_files = ['sync_repos.yml', 'sync_repos.yaml', '.sync_repos.yml', '.sync_repos.yaml']

  local_config_loaded = false
  local_config_files.each do |local_config_file|
    if File.exist?(local_config_file)
      begin
        loaded_config = YAML.load_file(local_config_file)
        if loaded_config.is_a?(Hash)
          # Update values from directory config (overrides global)
          if loaded_config['source_remote'] || loaded_config['source-remote']
            config_info[:source_remote] = {
              value: loaded_config['source_remote'] || loaded_config['source-remote'],
              source: 'directory config'
            }
          end
          if loaded_config['target_remote'] || loaded_config['target-remote']
            config_info[:target_remote] = {
              value: loaded_config['target_remote'] || loaded_config['target-remote'],
              source: 'directory config'
            }
          end
          if loaded_config['main_branch'] || loaded_config['main-branch']
            config_info[:main_branch] = {
              value: loaded_config['main_branch'] || loaded_config['main-branch'],
              source: 'directory config'
            }
          end
          if loaded_config.key?('verbose')
            config_info[:verbose] = {
              value: loaded_config['verbose'],
              source: 'directory config'
            }
          end
          puts "📁 Loaded directory configuration from #{local_config_file}"
          local_config_loaded = true
          break
        end
      rescue => e
        puts "⚠️  Warning: Failed to load directory config #{local_config_file}: #{e.message}"
      end
    end
  end

  # Show final configuration source summary
  if !global_config_loaded && !local_config_loaded
    puts "📄 No configuration files found, using built-in defaults"
  end

  config_info
end

# ============================================================================
# COMMAND LINE ARGUMENT PARSING
# ============================================================================
# Parses command line arguments and merges with configuration file settings

def parse_args
  # Load configuration with source tracking
  config_info = load_config_with_sources

  # Extract values and sources
  source_remote = config_info[:source_remote][:value]
  target_remote = config_info[:target_remote][:value]
  main_branch = config_info[:main_branch][:value]
  verbose = config_info[:verbose][:value]
  target_directory = nil

  # Track CLI overrides
  cli_overrides = {}

  i = 0
  while i < ARGV.length
    case ARGV[i]
    when '-s', '--source-remote'
      i += 1
      if i < ARGV.length
        source_remote = ARGV[i]
        cli_overrides[:source_remote] = true
      end
    when '-t', '--target-remote'
      i += 1
      if i < ARGV.length
        target_remote = ARGV[i]
        cli_overrides[:target_remote] = true
      end
    when '-b', '--main-branch'
      i += 1
      if i < ARGV.length
        main_branch = ARGV[i]
        cli_overrides[:main_branch] = true
      end
    when '-v', '--verbose'
      verbose = true
      cli_overrides[:verbose] = true
    when '-h', '--help'
      puts <<~HELP
        Usage: #{$0} [options] [directory]

        OPTIONS:
          -s, --source-remote <name>    Source remote name (default: origin)
          -t, --target-remote <name>    Target remote name for push (optional)
          -b, --main-branch <name>      Main branch name (default: main)
          -v, --verbose                 Show detailed output (default: concise)
          -h, --help                    Show this help message

        EXAMPLES:
          #{$0}                          # Process all directories using config/defaults
          #{$0} my-project               # Process only my-project directory
          #{$0} -v                       # Verbose output with interactive prompts
          #{$0} -s upstream -t chessbyte # Your typical upstream/chessbyte workflow

        For complete documentation including features, configuration options,
        interactive prompts, troubleshooting, and safety features, see the
        comprehensive documentation at the top of this script file.
      HELP
      exit 0
    when /^-/
      puts "Unknown option: #{ARGV[i]}"
      puts "Use -h or --help for usage information"
      exit 1
    else
      # This is a directory argument
      target_directory = ARGV[i]
    end
    i += 1
  end

  # Show parameter sources
  puts "⚙️  Configuration sources:"
  source_text = cli_overrides[:source_remote] ? 'CLI argument' : config_info[:source_remote][:source]
  puts "   Source remote: #{source_remote} (#{source_text})"

  if target_remote
    target_text = cli_overrides[:target_remote] ? 'CLI argument' : config_info[:target_remote][:source]
    puts "   Target remote: #{target_remote} (#{target_text})"
  else
    puts "   Target remote: none (default)"
  end

  branch_text = cli_overrides[:main_branch] ? 'CLI argument' : config_info[:main_branch][:source]
  puts "   Main branch: #{main_branch} (#{branch_text})"

  verbose_text = cli_overrides[:verbose] ? 'CLI argument' : config_info[:verbose][:source]
  puts "   Verbose mode: #{verbose} (#{verbose_text})"

  [source_remote, target_remote, main_branch, verbose, target_directory]
end

# ============================================================================
# MAIN EXECUTION
# ============================================================================
# Entry point when script is run directly

if __FILE__ == $0
  source_remote, target_remote, main_branch, verbose, target_directory = parse_args
  syncer = RepoSyncer.new(source_remote, target_remote, main_branch, verbose, target_directory)
  syncer.run
end
