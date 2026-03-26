#!/usr/bin/env python3
"""Sync files from reMarkable over SSH without MCP runtime."""

from __future__ import annotations

import argparse
import hashlib
import importlib
import io
import json
import os
import sys
import zipfile
from dataclasses import dataclass
from datetime import datetime
from pathlib import Path
from typing import Any

DEFAULT_DEST = Path("/Users/rajitkhanna/Library/CloudStorage/Dropbox/notes/remarkable_sync")
DEFAULT_REPO = Path("/Users/rajitkhanna/dotfiles/remarkable-mcp")


def _load_remarkable_modules(repo_path: Path):
    pkg_root = repo_path
    if not pkg_root.exists():
        raise RuntimeError(
            f"remarkable-mcp repo not found at {repo_path}. "
            "Clone it first to reuse existing SSH code."
        )
    sys.path.insert(0, str(pkg_root))
    api_module = importlib.import_module("remarkable_mcp.api")
    ssh_module = importlib.import_module("remarkable_mcp.ssh")

    return ssh_module.create_ssh_client, api_module.get_items_by_id, api_module.get_item_path


def _iso(value: Any) -> str:
    if value is None:
        return ""
    if isinstance(value, datetime):
        return value.isoformat()
    return str(value)


def _file_sha256(content: bytes) -> str:
    return hashlib.sha256(content).hexdigest()


def _safe_extract_zip(content: bytes, out_dir: Path) -> int:
    out_dir.mkdir(parents=True, exist_ok=True)
    extracted = 0
    with zipfile.ZipFile(io.BytesIO(content)) as zf:
        for member in zf.infolist():
            member_path = Path(member.filename)
            if member_path.is_absolute():
                continue
            if any(part == ".." for part in member_path.parts):
                continue
            target = (out_dir / member_path).resolve()
            if not str(target).startswith(str(out_dir.resolve())):
                continue
            if member.is_dir():
                target.mkdir(parents=True, exist_ok=True)
                continue
            target.parent.mkdir(parents=True, exist_ok=True)
            with zf.open(member) as src, open(target, "wb") as dst:
                dst.write(src.read())
            extracted += 1
    return extracted


def _load_manifest(dest: Path) -> dict[str, Any]:
    manifest_path = dest / ".remarkable_manifest.json"
    if not manifest_path.exists():
        return {"documents": {}}
    try:
        return json.loads(manifest_path.read_text())
    except Exception:
        return {"documents": {}}


def _save_manifest(dest: Path, data: dict[str, Any]) -> None:
    manifest_path = dest / ".remarkable_manifest.json"
    manifest_path.write_text(json.dumps(data, indent=2, sort_keys=True))


@dataclass
class SyncResult:
    id: str
    path: str
    name: str
    file_type: str
    archive_path: str | None
    local_path: str | None
    bytes_written: int
    extracted_files: int
    status: str


def _ensure_suffix(path: Path, suffix: str) -> Path:
    if path.suffix.lower() == f".{suffix.lower()}":
        return path
    return path.with_name(f"{path.name}.{suffix}")


def _collect_items(client, get_items_by_id, get_item_path):
    collection = client.get_meta_items()
    items_by_id = get_items_by_id(collection)
    rows = []
    for item in collection:
        item_path = get_item_path(item, items_by_id)
        rows.append(
            {
                "id": item.ID,
                "name": item.VissibleName,
                "path": item_path,
                "is_folder": bool(item.is_folder),
                "modified": _iso(getattr(item, "ModifiedClient", None)),
                "archived": bool(getattr(item, "is_cloud_archived", False)),
                "item": item,
            }
        )
    return rows


def _resolve_document(rows: list[dict[str, Any]], target: str):
    docs = [r for r in rows if not r["is_folder"] and not r["archived"]]
    target_norm = target.strip().lower()
    if not target_norm:
        return None, []

    exact_path = [r for r in docs if r["path"].lower() == target_norm]
    if len(exact_path) == 1:
        return exact_path[0], []
    if len(exact_path) > 1:
        return None, exact_path

    exact_name = [r for r in docs if r["name"].lower() == target_norm.strip("/")]
    if len(exact_name) == 1:
        return exact_name[0], []
    if len(exact_name) > 1:
        return None, exact_name

    partial = [r for r in docs if target_norm in r["path"].lower() or target_norm in r["name"].lower()]
    return None, partial[:10]


def _pull_one(client, row: dict[str, Any], dest: Path, force: bool, manifest: dict[str, Any]) -> SyncResult:
    doc = row["item"]
    doc_id = row["id"]
    doc_path = row["path"]
    rel = doc_path.lstrip("/")
    modified = row["modified"]
    file_type = client.get_file_type(doc) or "notebook"

    previous = manifest.get("documents", {}).get(doc_id, {})
    if not force and previous.get("modified") == modified and previous.get("path") == doc_path:
        return SyncResult(
            id=doc_id,
            path=doc_path,
            name=row["name"],
            file_type=file_type,
            archive_path=previous.get("archive_path"),
            local_path=previous.get("local_path"),
            bytes_written=0,
            extracted_files=0,
            status="skipped",
        )

    if file_type in ("pdf", "epub"):
        raw = client.download_raw_file(doc, file_type)
        if raw is None:
            payload = client.download(doc)
            archive_path = dest / f"{rel}.rmdoc.zip"
            archive_path.parent.mkdir(parents=True, exist_ok=True)
            archive_path.write_bytes(payload)
            extract_dir = dest / f"{rel}.rmdoc"
            extracted = _safe_extract_zip(payload, extract_dir)
            sha = _file_sha256(payload)
            result = SyncResult(
                id=doc_id,
                path=doc_path,
                name=row["name"],
                file_type=file_type,
                archive_path=str(archive_path),
                local_path=str(extract_dir),
                bytes_written=len(payload),
                extracted_files=extracted,
                status="downloaded",
            )
        else:
            local = _ensure_suffix(dest / rel, file_type)
            local.parent.mkdir(parents=True, exist_ok=True)
            local.write_bytes(raw)
            sha = _file_sha256(raw)
            result = SyncResult(
                id=doc_id,
                path=doc_path,
                name=row["name"],
                file_type=file_type,
                archive_path=None,
                local_path=str(local),
                bytes_written=len(raw),
                extracted_files=0,
                status="downloaded",
            )
    else:
        payload = client.download(doc)
        archive_path = dest / f"{rel}.rmdoc.zip"
        extract_dir = dest / f"{rel}.rmdoc"
        archive_path.parent.mkdir(parents=True, exist_ok=True)
        archive_path.write_bytes(payload)
        extracted = _safe_extract_zip(payload, extract_dir)
        sha = _file_sha256(payload)
        result = SyncResult(
            id=doc_id,
            path=doc_path,
            name=row["name"],
            file_type=file_type,
            archive_path=str(archive_path),
            local_path=str(extract_dir),
            bytes_written=len(payload),
            extracted_files=extracted,
            status="downloaded",
        )

    manifest.setdefault("documents", {})[doc_id] = {
        "name": row["name"],
        "path": doc_path,
        "file_type": file_type,
        "modified": modified,
        "local_path": result.local_path,
        "archive_path": result.archive_path,
        "sha256": sha,
        "synced_at": datetime.now().isoformat(timespec="seconds"),
    }
    return result


def cmd_status(args):
    create_ssh_client, get_items_by_id, get_item_path = _load_remarkable_modules(Path(args.repo_path))
    client = create_ssh_client(host=args.host, user=args.user, port=args.port, password=args.password)
    connected = client.check_connection()
    if not connected:
        print(json.dumps({"connected": False, "host": args.host}, indent=2))
        return 1

    rows = _collect_items(client, get_items_by_id, get_item_path)
    docs = [r for r in rows if not r["is_folder"] and not r["archived"]]
    folders = [r for r in rows if r["is_folder"]]
    print(
        json.dumps(
            {
                "connected": True,
                "host": args.host,
                "user": args.user,
                "port": args.port,
                "documents": len(docs),
                "folders": len(folders),
                "destination": str(Path(args.dest).expanduser()),
            },
            indent=2,
        )
    )
    return 0


def cmd_list(args):
    create_ssh_client, get_items_by_id, get_item_path = _load_remarkable_modules(Path(args.repo_path))
    client = create_ssh_client(host=args.host, user=args.user, port=args.port, password=args.password)
    rows = _collect_items(client, get_items_by_id, get_item_path)
    output = []
    for row in sorted(rows, key=lambda r: r["path"].lower()):
        if row["archived"]:
            continue
        if args.documents_only and row["is_folder"]:
            continue
        payload = {
            "path": row["path"],
            "name": row["name"],
            "type": "folder" if row["is_folder"] else "document",
            "modified": row["modified"],
            "id": row["id"],
        }
        if not row["is_folder"]:
            payload["file_type"] = client.get_file_type(row["item"]) or "notebook"
        output.append(payload)
    print(json.dumps({"count": len(output), "items": output}, indent=2))
    return 0


def cmd_pull(args):
    dest = Path(args.dest).expanduser()
    dest.mkdir(parents=True, exist_ok=True)
    create_ssh_client, get_items_by_id, get_item_path = _load_remarkable_modules(Path(args.repo_path))
    client = create_ssh_client(host=args.host, user=args.user, port=args.port, password=args.password)
    rows = _collect_items(client, get_items_by_id, get_item_path)
    row, suggestions = _resolve_document(rows, args.path)
    if row is None:
        print(
            json.dumps(
                {
                    "error": "document_not_found_or_ambiguous",
                    "target": args.path,
                    "suggestions": [s["path"] for s in suggestions],
                },
                indent=2,
            )
        )
        return 2

    manifest = _load_manifest(dest)
    result = _pull_one(client, row, dest, args.force, manifest)
    _save_manifest(dest, manifest)
    print(json.dumps(result.__dict__, indent=2))
    return 0


def cmd_sync(args):
    dest = Path(args.dest).expanduser()
    dest.mkdir(parents=True, exist_ok=True)
    create_ssh_client, get_items_by_id, get_item_path = _load_remarkable_modules(Path(args.repo_path))
    client = create_ssh_client(host=args.host, user=args.user, port=args.port, password=args.password)
    rows = _collect_items(client, get_items_by_id, get_item_path)
    docs = [r for r in rows if not r["is_folder"] and not r["archived"]]
    docs = sorted(docs, key=lambda r: r["path"].lower())
    if args.limit:
        docs = docs[: args.limit]

    manifest = _load_manifest(dest)
    results = []
    for row in docs:
        try:
            result = _pull_one(client, row, dest, args.force, manifest)
            results.append(result)
        except Exception as err:
            results.append(
                SyncResult(
                    id=row["id"],
                    path=row["path"],
                    name=row["name"],
                    file_type=client.get_file_type(row["item"]) or "notebook",
                    archive_path=None,
                    local_path=None,
                    bytes_written=0,
                    extracted_files=0,
                    status=f"failed: {err}",
                )
            )

    _save_manifest(dest, manifest)
    downloaded = [r for r in results if r.status == "downloaded"]
    skipped = [r for r in results if r.status == "skipped"]
    failed = [r for r in results if r.status.startswith("failed")]
    summary = {
        "destination": str(dest),
        "total": len(results),
        "downloaded": len(downloaded),
        "skipped": len(skipped),
        "failed": len(failed),
        "results": [r.__dict__ for r in results],
    }
    print(json.dumps(summary, indent=2))
    return 0 if not failed else 3


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description="Sync reMarkable files over SSH.")
    parser.add_argument("--host", default=os.environ.get("REMARKABLE_SSH_HOST", "10.11.99.1"))
    parser.add_argument("--user", default=os.environ.get("REMARKABLE_SSH_USER", "root"))
    parser.add_argument("--port", default=int(os.environ.get("REMARKABLE_SSH_PORT", "22")), type=int)
    parser.add_argument("--password", default=os.environ.get("REMARKABLE_SSH_PASSWORD"))
    parser.add_argument("--dest", default=str(DEFAULT_DEST))
    parser.add_argument("--repo-path", default=str(DEFAULT_REPO))

    sub = parser.add_subparsers(dest="command", required=True)

    status = sub.add_parser("status", help="Check SSH connectivity and basic counts.")
    status.set_defaults(func=cmd_status)

    ls_cmd = sub.add_parser("list", help="List reMarkable folders/documents.")
    ls_cmd.add_argument("--documents-only", action="store_true")
    ls_cmd.set_defaults(func=cmd_list)

    pull = sub.add_parser("pull", help="Pull one document by exact path or name.")
    pull.add_argument("--path", required=True, help="Document path (preferred) or unique name.")
    pull.add_argument("--force", action="store_true", help="Download even if unchanged in manifest.")
    pull.set_defaults(func=cmd_pull)

    sync = sub.add_parser("sync", help="Sync all documents incrementally.")
    sync.add_argument("--force", action="store_true", help="Download all, ignore manifest.")
    sync.add_argument("--limit", type=int, default=0, help="Limit number of docs for test runs.")
    sync.set_defaults(func=cmd_sync)

    return parser


def main() -> int:
    parser = build_parser()
    args = parser.parse_args()
    return args.func(args)


if __name__ == "__main__":
    raise SystemExit(main())
