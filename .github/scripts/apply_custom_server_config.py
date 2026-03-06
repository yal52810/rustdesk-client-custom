#!/usr/bin/env python3
import os
import pathlib
import re
import sys


def rust_str(value: str) -> str:
    return value.replace("\\", "\\\\").replace('"', '\\"')


def main() -> int:
    rendezvous_server = os.getenv("RENDEZVOUS_SERVER", "").strip()
    relay_server = os.getenv("RELAY_SERVER", "").strip()
    api_server = os.getenv("API_SERVER", "").strip()
    rs_pub_key = os.getenv("RS_PUB_KEY", "").strip()

    if not any([rendezvous_server, relay_server, api_server, rs_pub_key]):
        print("No custom server values detected, skip patch.")
        return 0

    path = pathlib.Path("libs/hbb_common/src/config.rs")
    if not path.exists():
        raise FileNotFoundError(f"Cannot find {path}")

    text = path.read_text(encoding="utf-8")

    def replace_once(pattern: str, replacement: str, label: str) -> None:
        nonlocal text
        updated, count = re.subn(pattern, replacement, text, count=1, flags=re.MULTILINE)
        if count != 1:
            raise RuntimeError(f"Failed to patch {label}")
        text = updated

    if rendezvous_server:
        replace_once(
            r'pub const RENDEZVOUS_SERVERS: &\[&str\] = &\[[^\n]*\];',
            f'pub const RENDEZVOUS_SERVERS: &[&str] = &["{rust_str(rendezvous_server)}"];',
            "RENDEZVOUS_SERVERS",
        )

    if rs_pub_key:
        replace_once(
            r'pub const RS_PUB_KEY: &str = "[^"]*";',
            f'pub const RS_PUB_KEY: &str = "{rust_str(rs_pub_key)}";',
            "RS_PUB_KEY",
        )

    settings_lines = []
    if rendezvous_server:
        settings_lines.append(
            f'        defaults.insert("custom-rendezvous-server".to_owned(), "{rust_str(rendezvous_server)}".to_owned());\n'
        )
    if relay_server:
        settings_lines.append(
            f'        defaults.insert("relay-server".to_owned(), "{rust_str(relay_server)}".to_owned());\n'
        )
    if api_server:
        settings_lines.append(
            f'        defaults.insert("api-server".to_owned(), "{rust_str(api_server)}".to_owned());\n'
        )

    if settings_lines:
        defaults_block = (
            "    pub static ref DEFAULT_SETTINGS: RwLock<HashMap<String, String>> = {\n"
            "        let mut defaults = HashMap::new();\n"
            f"{''.join(settings_lines)}"
            "        RwLock::new(defaults)\n"
            "    };"
        )

        if re.search(
            r'    pub static ref DEFAULT_SETTINGS: RwLock<HashMap<String, String>> = Default::default\(\);',
            text,
            flags=re.MULTILINE,
        ):
            replace_once(
                r'    pub static ref DEFAULT_SETTINGS: RwLock<HashMap<String, String>> = Default::default\(\);',
                defaults_block,
                "DEFAULT_SETTINGS",
            )
        else:
            replace_once(
                r'    pub static ref DEFAULT_SETTINGS: RwLock<HashMap<String, String>> = \{[\s\S]*?    \};',
                defaults_block,
                "DEFAULT_SETTINGS(existing)",
            )

    path.write_text(text, encoding="utf-8")
    print("Applied custom server config patch.")
    return 0


if __name__ == "__main__":
    sys.exit(main())