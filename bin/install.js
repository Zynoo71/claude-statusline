#!/usr/bin/env node

const fs = require("fs");
const path = require("path");
const os = require("os");
const { execSync, spawn } = require("child_process");

const CLAUDE_DIR = path.join(os.homedir(), ".claude");
const SETTINGS_FILE = path.join(CLAUDE_DIR, "settings.json");
const STATUSLINE_SRC = path.resolve(__dirname, "statusline.sh");

const blue = "\x1b[38;2;0;153;255m";
const green = "\x1b[38;2;0;175;80m";
const red = "\x1b[38;2;255;85;85m";
const yellow = "\x1b[38;2;230;200;0m";
const dim = "\x1b[2m";
const reset = "\x1b[0m";

function log(msg) {
  console.log(`  ${msg}`);
}

function success(msg) {
  console.log(`  ${green}✓${reset} ${msg}`);
}

function warn(msg) {
  console.log(`  ${yellow}!${reset} ${msg}`);
}

function fail(msg) {
  console.error(`  ${red}✗${reset} ${msg}`);
}

// ── Statusline runner mode ──────────────────────────────
// When stdin is piped (Claude Code feeds JSON), run the bash script directly

function runStatusline() {
  const barStyle = process.env.CLAUDE_STATUSLINE_BAR_STYLE || "";
  const env = { ...process.env };
  if (barStyle) {
    env.CLAUDE_STATUSLINE_BAR_STYLE = barStyle;
  }

  const child = spawn("bash", [STATUSLINE_SRC], {
    stdio: ["pipe", "inherit", "inherit"],
    env,
  });

  process.stdin.pipe(child.stdin);

  child.on("close", (code) => {
    process.exit(code || 0);
  });
}

// ── Installer mode ──────────────────────────────────────

function checkDeps() {
  const missing = [];

  try {
    execSync("which jq", { stdio: "ignore" });
  } catch {
    missing.push("jq");
  }

  try {
    execSync("which curl", { stdio: "ignore" });
  } catch {
    missing.push("curl");
  }

  try {
    execSync("which git", { stdio: "ignore" });
  } catch {
    missing.push("git");
  }

  return missing;
}

function uninstall() {
  console.log();
  console.log(`  ${blue}Claude Line Uninstaller${reset}`);
  console.log(`  ${dim}───────────────────────${reset}`);
  console.log();

  if (fs.existsSync(SETTINGS_FILE)) {
    try {
      const settings = JSON.parse(fs.readFileSync(SETTINGS_FILE, "utf-8"));
      if (settings.statusLine) {
        delete settings.statusLine;
        fs.writeFileSync(SETTINGS_FILE, JSON.stringify(settings, null, 2) + "\n");
        success(`Removed statusLine from ${dim}settings.json${reset}`);
      } else {
        success("Settings already clean");
      }
    } catch {
      fail(`Could not parse ${SETTINGS_FILE} — fix it manually`);
      process.exit(1);
    }
  }

  console.log();
  log(`${green}Done!${reset} Restart Claude Code to apply changes.`);
  console.log();
}

const VALID_BAR_STYLES = ["diamond", "block", "dot", "arrow", "square", "shade"];

function getArg(name) {
  const idx = process.argv.indexOf(name);
  if (idx === -1 || idx + 1 >= process.argv.length) return null;
  return process.argv[idx + 1];
}

function install() {
  if (process.argv.includes("--uninstall")) {
    uninstall();
    return;
  }

  const barStyle = getArg("--bar-style");
  if (barStyle && !VALID_BAR_STYLES.includes(barStyle)) {
    fail(`Invalid bar style: ${barStyle}`);
    log(`  Valid styles: ${VALID_BAR_STYLES.join(", ")}`);
    process.exit(1);
  }

  console.log();
  console.log(`  ${blue}Claude Line Installer${reset}`);
  console.log(`  ${dim}─────────────────────${reset}`);
  console.log();

  const missing = checkDeps();
  if (missing.length > 0) {
    fail(`Missing required dependencies: ${missing.join(", ")}`);
    log(`  Install them and try again.`);
    if (missing.includes("jq")) {
      log(`  ${dim}brew install jq${reset}`);
    }
    process.exit(1);
  }
  success("Dependencies found (jq, curl, git)");

  if (!fs.existsSync(CLAUDE_DIR)) {
    fs.mkdirSync(CLAUDE_DIR, { recursive: true });
    success(`Created ${CLAUDE_DIR}`);
  }

  let settings = {};
  if (fs.existsSync(SETTINGS_FILE)) {
    try {
      settings = JSON.parse(fs.readFileSync(SETTINGS_FILE, "utf-8"));
    } catch {
      fail(`Could not parse ${SETTINGS_FILE} — fix it manually`);
      process.exit(1);
    }
  }

  const styleEnv = barStyle ? `CLAUDE_STATUSLINE_BAR_STYLE=${barStyle} ` : "";
  const statusLineConfig = {
    type: "command",
    command: `${styleEnv}bunx @zynoo/claude-statusline`,
  };

  if (
    settings.statusLine &&
    settings.statusLine.type === "command" &&
    settings.statusLine.command === statusLineConfig.command
  ) {
    success("Settings already configured");
  } else {
    settings.statusLine = statusLineConfig;
    fs.writeFileSync(SETTINGS_FILE, JSON.stringify(settings, null, 2) + "\n");
    success(`Updated ${dim}settings.json${reset} with statusLine config`);
  }

  if (barStyle) {
    success(`Bar style set to ${dim}${barStyle}${reset}`);
  }

  console.log();
  log(`${green}Done!${reset} Restart Claude Code to see your new status line.`);
  if (!barStyle) {
    log(`${dim}Tip: use --bar-style <${VALID_BAR_STYLES.join("|")}> to change the progress bar style${reset}`);
  }
  console.log();
}

// ── Entry point ─────────────────────────────────────────

if (!process.stdin.isTTY) {
  // Piped input from Claude Code → run statusline
  runStatusline();
} else {
  // Interactive terminal → run installer
  install();
}
