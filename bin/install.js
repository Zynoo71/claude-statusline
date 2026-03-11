#!/usr/bin/env node

const path = require("path");
const { spawn } = require("child_process");

const STATUSLINE_SRC = path.resolve(__dirname, "statusline.sh");

const args = process.argv.slice(2);
const child = spawn("bash", [STATUSLINE_SRC, ...args], {
  stdio: ["pipe", "inherit", "inherit"],
  env: process.env,
});

process.stdin.pipe(child.stdin);

child.on("close", (code) => {
  process.exit(code || 0);
});
