#!/bin/bash

set -euo pipefail

SCRIPT_PATH="$0"
if [ "${SCRIPT_PATH%/*}" != "$SCRIPT_PATH" ]; then
    SCRIPT_DIR="$(cd "$(dirname "$SCRIPT_PATH")" && pwd)"
else
    SCRIPT_DIR="$PWD"
fi
cd "$SCRIPT_DIR"

if [ $# -lt 1 ]; then
	echo "Usage: $0 <input_markdown> [output_html]" >&2
	exit 1
fi

INPUT_MD_RAW=$1
INPUT_MD="$(cd "$(dirname "$INPUT_MD_RAW")" && pwd)/$(basename "$INPUT_MD_RAW")"
INPUT_FILENAME=$(basename "$INPUT_MD")
INPUT_STEM=${INPUT_FILENAME%.*}
if [ -z "$INPUT_STEM" ]; then
	INPUT_STEM="$INPUT_FILENAME"
fi

if [ $# -ge 2 ]; then
	OUTPUT_HTML_RAW=$2
else
	OUTPUT_HTML_RAW="output/${INPUT_STEM}.html"
fi
OUTPUT_HTML="$(cd "$(dirname "$OUTPUT_HTML_RAW")" && pwd)/$(basename "$OUTPUT_HTML_RAW")"


mkdir -p "$(dirname "$OUTPUT_HTML")"
mkdir -p output/media

(
	cd output
	cp "../render/github-markdown.css" ./media/github-markdown.css
	cp "../render/before.html" ./media/before.html
	cp "../render/after.html" ./media/after.html
	pandoc "$INPUT_MD" \
		--lua-filter=../render/diagram.lua \
		--extract-media=./media \
		-f gfm -t html5 -s \
		--css=./media/github-markdown.css \
		--include-before-body=./media/before.html \
		--include-after-body=./media/after.html \
	    --embed-resources \
		-o "$OUTPUT_HTML"

	python3 <<PY
from pathlib import Path

html_path = Path("$OUTPUT_HTML")
css_path = Path("media/github-markdown.css")
img_style_block = "<style>img{max-width:100%;height:auto;}</style>"
inline_start = "<!-- INLINE_GITHUB_MARKDOWN_CSS_START -->"
inline_end = "<!-- INLINE_GITHUB_MARKDOWN_CSS_END -->"

html = html_path.read_text()
css = css_path.read_text()
inline_css_block = f"{inline_start}\n<style>\n{css}\n</style>\n{inline_end}"

if inline_start in html and inline_end in html:
	start = html.index(inline_start)
	end = html.index(inline_end) + len(inline_end)
	html = html[:start] + inline_css_block + html[end:]
else:
	link_patterns = [
		'<link rel="stylesheet" href="media/github-markdown.css" />',
		'<link rel="stylesheet" href="media/github-markdown.css"/>',
		'<link rel="stylesheet" href="./media/github-markdown.css" />',
		'<link rel="stylesheet" href="./media/github-markdown.css"/>'
	]
	replaced = False
	for pattern in link_patterns:
		if pattern in html:
			html = html.replace(pattern, inline_css_block, 1)
			replaced = True
			break
	if not replaced:
		if "</head>" in html:
			html = html.replace("</head>", f"{inline_css_block}\n</head>", 1)
		else:
			html = inline_css_block + "\n" + html

if img_style_block not in html:
	if "</head>" in html:
		html = html.replace("</head>", f"  {img_style_block}\n</head>", 1)
	else:
		html += "\n" + img_style_block + "\n"

html_path.write_text(html)
PY
)

open "$OUTPUT_HTML"
