#!/bin/zsh
set -euo pipefail

PAYLOAD_URL="https://raw.githubusercontent.com/solidfox/widgit-print-workaround/main/Widgit_Print_Workaround_Vanilla_Mac_arm64.zip"
PAYLOAD_SHA256="3d66a0c92ca7e7ccca9e63546725d4973f1dfaaddc4fedfdb2ce0bb60db9c71b"

HOME_DIR="${HOME}"
INSTALL_ROOT="$HOME_DIR/Library/Application Support/Widgit Print Workaround"
PDF_SERVICES_DIR="$HOME_DIR/Library/PDF Services"
PDF_SERVICE_NAME="Widgit Print Workaround.scpt"
TEMP_DIR="/tmp/widgit-print-workaround-install"
PAYLOAD_ZIP="$TEMP_DIR/payload.zip"
PAYLOAD_EXTRACTED_DIR="$TEMP_DIR/Widgit_Print_Workaround_Vanilla_Mac_arm64"
HELPER_DIR="$INSTALL_ROOT/portable_payload_arm64"
TEMP_JS="$TEMP_DIR/widgit_print_workaround.js"

mkdir -p "$TEMP_DIR" "$INSTALL_ROOT" "$PDF_SERVICES_DIR"

curl -L --fail --silent --show-error "$PAYLOAD_URL" -o "$PAYLOAD_ZIP"

ACTUAL_SHA="$(shasum -a 256 "$PAYLOAD_ZIP" | awk '{print $1}')"
if [[ "$ACTUAL_SHA" != "$PAYLOAD_SHA256" ]]; then
  echo "Downloaded payload checksum mismatch." >&2
  exit 1
fi

ditto -x -k "$PAYLOAD_ZIP" "$TEMP_DIR"
ditto "$PAYLOAD_EXTRACTED_DIR/portable_payload_arm64" "$HELPER_DIR"
xattr -dr com.apple.quarantine "$HELPER_DIR" >/dev/null 2>&1 || true

INSTALL_ROOT_JS="${INSTALL_ROOT//\\/\\\\}"
INSTALL_ROOT_JS="${INSTALL_ROOT_JS//\"/\\\"}"

cat > "$TEMP_JS" <<EOF
ObjC.import('Foundation');
const installRoot = "$INSTALL_ROOT_JS";

function unwrapPath(item) {
  try { return ObjC.unwrap(item.toString()); } catch (error) {}
  try { return ObjC.unwrap(item.path()); } catch (error) {}
  return String(item);
}

function outputPathFor(srcPath) {
  const trimmed = String(srcPath).replace(/\/+$/, '');
  const slash = trimmed.lastIndexOf('/');
  const dir = slash >= 0 ? trimmed.slice(0, slash) : '.';
  const name = slash >= 0 ? trimmed.slice(slash + 1) : trimmed;
  const base = name.replace(/\.pdf$/i, '');
  return dir + '/' + base + '-PRINTSAFE.pdf';
}

function helperPath() {
  return installRoot + '/portable_payload_arm64/bin/pdftocairo';
}

function runCommand(args) {
  const task = $.NSTask.alloc.init;
  const pipe = $.NSPipe.pipe;
  task.setLaunchPath(args[0]);
  task.setArguments(args.slice(1));
  task.setStandardOutput(pipe);
  task.setStandardError(pipe);
  task.launch;
  task.waitUntilExit;
  const data = pipe.fileHandleForReading.readDataToEndOfFile;
  const text = ObjC.unwrap($.NSString.alloc.initWithDataEncoding(data, $.NSUTF8StringEncoding)) || '';
  if (task.terminationStatus !== 0) {
    throw new Error(text || ('Command failed with exit code ' + task.terminationStatus));
  }
  return text;
}

function processItem(item) {
  const srcPath = unwrapPath(item);
  if (!srcPath.toLowerCase().endsWith('.pdf')) { return; }
  const helper = helperPath();
  const dstPath = outputPathFor(srcPath);
  if (!$.NSFileManager.defaultManager.isExecutableFileAtPath(ObjC.wrap(helper))) {
    throw new Error('Bundled converter not found at: ' + helper);
  }
  runCommand([helper, '-pdf', srcPath, dstPath]);
  try { runCommand(['/usr/bin/open', '-a', 'Preview', dstPath]); } catch (error) {}
}

function openDocuments(items) {
  for (let i = 0; i < items.length; i += 1) { processItem(items[i]); }
}

function run(argv) {
  for (let i = 0; i < argv.length; i += 1) { processItem(argv[i]); }
}
EOF

osacompile -l JavaScript -o "$PDF_SERVICES_DIR/$PDF_SERVICE_NAME" "$TEMP_JS"
xattr -dr com.apple.quarantine "$PDF_SERVICES_DIR/$PDF_SERVICE_NAME" >/dev/null 2>&1 || true

echo "Installed Widgit Print Workaround."
