"""从 Git 迁移前的文件与当前文件生成可核验的上游路径表。"""

import argparse
import csv
import hashlib
import io
import re
import subprocess
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
OUTPUT = ROOT / "catalog" / "upstream-file-map.csv"


def git(*args: str) -> bytes:
    return subprocess.run(
        ["git", *args], cwd=ROOT, check=True, capture_output=True
    ).stdout


def destination(old: str) -> tuple[str, str] | None:
    if re.fullmatch(r"D(?:[1-9]|1[0-5])\.R", old):
        return f"upstream/day-scripts/{old}", "逐日课程脚本"
    prefixes = {
        "dispersalENM/": ("upstream/topics/dispersal-enm/", "扩散专题"),
        "fruitfly.brain/": ("upstream/topics/fruitfly-brain/", "果蝇专题"),
        "scale_matters/": ("upstream/topics/scale-matters/", "尺度专题"),
        "r_statistics_course/": ("upstream/topics/r-statistics/", "统计基础"),
        "LightRAG/": ("upstream/tools/lightrag/", "辅助工具"),
    }
    for prefix, (new_prefix, category) in prefixes.items():
        if old.startswith(prefix):
            return new_prefix + old[len(prefix) :], category
    if old in {"Participants.R", "Participants_distribution_map_2.pdf"}:
        return f"upstream/auxiliary/participants/{old}", "参与者材料"
    if old in {"Pro.Tip.R", "Pro.Tip.2.R", "learning.curve.R"}:
        return f"upstream/auxiliary/examples/{old}", "辅助示例"
    if old == "README.html":
        return "upstream/reference/original-readme.html", "原始提纲"
    return None


def make_rows() -> list[dict[str, str]]:
    old_paths = git("ls-tree", "-r", "--name-only", "HEAD").decode().splitlines()
    rows = []
    for old in old_paths:
        mapped = destination(old)
        if mapped is None:
            continue
        new, category = mapped
        old_bytes = git("show", f"HEAD:{old}")
        new_bytes = (ROOT / new).read_bytes()
        before = hashlib.sha256(old_bytes).hexdigest()
        after = hashlib.sha256(new_bytes).hexdigest()
        if before != after:
            raise ValueError(f"原文件内容与迁移后不同：{old} -> {new}")
        rows.append(
            {
                "old_path": old,
                "new_path": new,
                "category_zh": category,
                "sha256_before": before,
                "sha256_after": after,
                "byte_identical": "yes",
            }
        )
    return rows


def render(rows: list[dict[str, str]]) -> str:
    stream = io.StringIO()
    writer = csv.DictWriter(stream, fieldnames=list(rows[0]), lineterminator="\n")
    writer.writeheader()
    writer.writerows(rows)
    return stream.getvalue()


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--check", action="store_true", help="核对现有表格，不改写")
    args = parser.parse_args()
    rows = make_rows()
    if len(rows) != 70:
        raise ValueError(f"预期迁移 70 个上游文件，实际为 {len(rows)}")
    content = render(rows)
    if args.check:
        if OUTPUT.read_bytes() != content.encode("utf-8"):
            raise ValueError("文件对照表与当前文件不一致")
    else:
        OUTPUT.write_text(content, encoding="utf-8")
    print(f"verified {len(rows)} original files; byte-identical SHA-256")


if __name__ == "__main__":
    main()
