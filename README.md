## render.sh guide

### Runtime dependencies
- Bash-compatible shell (script shebang is `/bin/bash`, but it also runs fine inside zsh): handles control flow, arithmetic, and heredocs without zsh-specific extensions.
- pandoc (with Lua filter support) + Chrome: Pandoc’s headless diagram rendering relies on Chrome via Puppeteer. First make sure Google Chrome is installed system-wide, then export `PUPPETEER_EXECUTABLE_PATH="/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"` before running the script.
- python3: used post-processing to inline the CSS file and inject the `img{max-width:100%;height:auto;}` safeguard.
- Coreutils (cp, mkdir, cd) that ship with macOS or GNU environments.
- Google Chrome: the binary referenced by `PUPPETEER_EXECUTABLE_PATH`.

### File-level dependencies
- `render/github-markdown.css`: provides GitHub-style Markdown theming; automatically staged into `output/media` and inlined into the generated HTML head during the build.
- `render/before.html` and `render/after.html`: HTML fragments Pandoc injects before and after the Markdown body.
- `render/diagram.lua`: Pandoc Lua filter that enables diagram rendering during the Markdown->HTML conversion.
- Target Markdown sources: any `.md` file you pass as the first argument.

### Execution flow
1. Resolve absolute paths for the input markdown, default output (`output/<stem>.html`), and `output/media` directory.
2. Copy CSS and HTML fragment assets from `render/` into `output/media` to keep Pandoc references local.
3. Run Pandoc inside the `output/` directory with `--extract-media` so images land in `output/media`, `--embed-resources` for base64 inlining, the Lua filter, and the before/after fragments.
4. Post-process the generated HTML via Python:
	- Inline the copied CSS (replacing the `<link>` tag when present, otherwise appending to `<head>`).
	- Ensure the `<style>img{max-width:100%;height:auto;}</style>` block exists once inside the document.
5. Open the resulting HTML via the default system handler (`open`).

### Usage
```sh
./render.sh path/to/input.md                # writes output/input.html
./render.sh notes.md custom/output.html     # custom target path
```

Arguments:
- `<input_markdown>` (required): absolute or relative path to the Markdown file to convert.
- `[output_html]` (optional): target HTML path. Defaults to `output/<input_stem>.html` relative to the repository root.

### Operational notes
- The script must run from within the repo because it relies on relative references to the `render/` folder.
- Ensure the `output/` directory is writable; it is automatically created along with any parent directories for the HTML file.
- If Pandoc cannot find `diagram.lua` or the CSS fragments, verify the `render/` folder matches the expected layout.
- Re-running the script on the same HTML is idempotent: the Python block replaces the previous inline CSS segment rather than duplicating it.

## render.sh 指南（简体中文）

### 运行时依赖
- Bash 兼容的 shell（脚本 shebang 为 `/bin/bash`，zsh 中也能运行）：负责常规流程控制与 heredoc，不再依赖 zsh 专属语法。
- pandoc（带 Lua filter 支持）+ Chrome：Pandoc 的无头图表渲染依赖 Chrome 与 Puppeteer。请先确认系统已安装 Google Chrome，再设置 `export PUPPETEER_EXECUTABLE_PATH="/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"`。
- python3：在 Pandoc 之后对 HTML 做二次处理，完成 CSS 内联和图片宽度限制。
- Coreutils：macOS/GNU 环境自带的 `cp`、`mkdir`、`cd` 等基础命令。
- Google Chrome：由 `PUPPETEER_EXECUTABLE_PATH` 指向的可执行文件。

### 文件级依赖
- `render/github-markdown.css`：提供 GitHub 风格的 Markdown 样式，会被自动复制到 `output/media` 并最终内联到 HTML `<head>` 中。
- `render/before.html` 与 `render/after.html`：Pandoc 在正文前/后插入的 HTML 片段。
- `render/diagram.lua`：Pandoc Lua 过滤器，用来渲染流程图等图示。
- 任意 Markdown 源文件：作为脚本的第一个参数传入。

### 执行流程
1. 解析输入 Markdown、默认输出路径（`output/<stem>.html`）以及 `output/media` 目录的绝对路径。
2. 将 CSS 和 HTML 片段从 `render/` 复制到 `output/media`，保证 Pandoc 在 `output/` 内运行时能找到它们。
3. 在 `output/` 目录内调用 Pandoc：开启 `--extract-media`、`--embed-resources`、加载 Lua filter，并注入 before/after 片段。
4. 使用 Python 做后处理：
	- 将复制过来的 CSS 内联到 HTML 头部（若存在 `<link>` 则替换，没有就追加）。
	- 确保文档中只存在一次 `<style>img{max-width:100%;height:auto;}</style>` 以限制图片宽度。
5. 通过 macOS `open` 命令自动打开最终 HTML。

### 用法示例
```sh
./render.sh path/to/input.md                # 输出到 output/input.html
./render.sh notes.md custom/output.html     # 使用自定义输出路径
```

参数说明：
- `<input_markdown>`（必填）：待转换的 Markdown 文件，支持相对或绝对路径。
- `[output_html]`（可选）：目标 HTML 路径，默认为 `output/<input_stem>.html`。

### 使用注意
- 必须在仓库根目录运行脚本，因为其依赖 `render/` 目录的相对路径。
- 需要确保 `output/` 可写，脚本会自动创建该目录以及输出文件所在的父目录。
- 若 Pandoc 找不到 `diagram.lua` 或 CSS 片段，请检查 `render/` 目录结构是否完整。
- 重复运行同一输入是幂等的：Python 会替换已有的 CSS 内联段，避免累积重复内容。
