# AGENTS.md

GFWList2AGH is a Bash DNS configuration generator that fetches domain lists from multiple sources, processes them, and generates DNS config files for various DNS servers (AdGuard Home and others). See [README.md](README.md).

## HANDOVER.md

When a multi-step task is interrupted, write progress to `HANDOVER.md` so the next session can pick up where you left off. Include: what was done, what remains, key decisions made, and the next concrete step. Delete the file when the task is complete.

## Behavioral Guidelines

**Tradeoff:** These guidelines bias toward caution over speed. For trivial tasks, use judgment.

### 1. Think Before Coding

**Don't assume. Don't hide confusion. Surface tradeoffs.**

Before implementing:
- State your assumptions explicitly. If uncertain, ask.
- If multiple interpretations exist, present them — don't pick silently.
- If a simpler approach exists, say so. Push back when warranted.
- If something is unclear, stop. Name what's confusing. Ask.

### 2. Simplicity First

**Minimum code that solves the problem. Nothing speculative.**

- No features beyond what was asked.
- No abstractions for single-use code.
- No "flexibility" or "configurability" that wasn't requested.
- No error handling for impossible scenarios.
- If you write 200 lines and it could be 50, rewrite it.

Ask yourself: "Would a senior engineer say this is overcomplicated?" If yes, simplify.

### 3. Surgical Changes

**Touch only what you must. Clean up only your own mess.**

When editing existing code:
- Don't "improve" adjacent code, comments, or formatting.
- Don't refactor things that aren't broken.
- Match existing style, even if you'd do it differently.
- If you notice unrelated dead code, mention it — don't delete it.

When your changes create orphans:
- Remove imports/variables/functions that YOUR changes made unused.
- Don't remove pre-existing dead code unless asked.

The test: Every changed line should trace directly to the user's request.

### 4. Goal-Driven Execution

**Define success criteria. Loop until verified.**

Transform tasks into verifiable goals:
- "Add validation" → "Write tests for invalid inputs, then make them pass"
- "Fix the bug" → "Write a test that reproduces it, then make it pass"
- "Refactor X" → "Ensure tests pass before and after"

For multi-step tasks, state a brief plan:
```
1. [Step] → verify: [check]
2. [Step] → verify: [check]
3. [Step] → verify: [check]
```

Strong success criteria let you loop independently. Weak criteria ("make it work") require constant clarification.

**These guidelines are working if:** fewer unnecessary changes in diffs, fewer rewrites due to overcomplication, and clarifying questions come before implementation rather than after mistakes.

**Additional rules:**
- Be concise in output but thorough in reasoning.
- Do not re-read files you have already read.
- User instructions always override this file.
- Don't wrestle with indentation in the Edit tool — focus on logic, let the project's formatter fix formatting. Use `sed` or `python3` freely when the Edit tool struggles with whitespace.

## Git commit convention

Every commit subject starts with a type prefix — `feat` / `fix` / `chore` / `docs` / `revert` / `refactor` / `perf` / `test` / `build` — optionally scoped: `fix(toolbar): ...`. Subject: imperative, lowercase start, no trailing period, aim ≤ 72 chars; detail goes in the body after a blank line (why, not what); breaking changes take `!` before the colon or a `BREAKING CHANGE:` body footer. Never rewrite pushed history.

- Commit incrementally — one logical change per commit, after lint and tests pass. Present changes for review before committing.
- PRs: link the issue, summarize the change and verification (tests/benchmarks), and include config/log/pprof evidence for bug fixes.

### Co-Author Format

- Always add co-author information. If closing an issue in commit text, verify against `main` first: `gh issue view <issue-id>`.
- Only ONE co-author line is allowed. If multiple agents contributed, aggregate into ONE entry.

Format: `Co-authored-by: <AgentName> <Email>`

Valid examples (choose EXACTLY ONE):

```
Co-authored-by: ZCode <noreply@z.ai>
```

## Documentation format

Family-wide Markdown rules, shared verbatim across all ZJ projects:

- **Language**: AGENTS.md, AUDIT.md, DESIGN.md and other agent-facing docs are English; README.md is Chinese (human-facing). Keep literal UI strings and code identifiers verbatim.
- **AGENTS.md skeleton** — generic sections first, then project; omit sections that don't apply, keep the order:
  `# AGENTS.md` → 1–2 sentence intro (what the project is + key doc links) → Behavioral Guidelines → Git commit convention → Documentation format → Project → Commands → Architecture → Conventions (Gotchas as a subsection) → project-specific sections → Key Docs.
- **README.md skeleton**: `# <project>` → badge block → one-line positioning + stack + key links → 特性 → 快速开始 → 配置 / 用法 → 文档 → License (omit as needed).
- **README badges** (shields.io, after the title, in order): Version (only where a real version exists, linked to the repo's GitHub releases), License (Apache 2.0 with Commons Clause — every project), primary-language badge (Go / TypeScript / Bash / Python / Docker), Biome for TypeScript projects; pure data/config repos get License only. Version links use the real GitHub repo name.
- **Formatting**: ATX headings (`#`), never skip a level; code fences always carry a language tag (`bash`, `go`, `json`, `text` for trees); tables for structured reference; no decorative emoji in headings or bullets; bold for key terms only.

## Project

**Type**: Shell script-based DNS configuration generator  
**Language**: Bash (POSIX-compliant shell scripts)  
**License**: Apache License 2.0 with Commons Clause v1.0  
**Purpose**: Fetch domain lists from multiple sources, process them, and generate DNS configuration files for various DNS servers

## Commands

### Primary Build Command
```bash
# Run the complete build process (fetches data, processes, generates all outputs)
bash release.sh
```

### Testing Individual Components
```bash
# Test data fetching only (creates Temp directory with intermediate files)
bash release.sh  # Then Ctrl+C after GetData completes, inspect ./Temp

# Validate generated output format for AdGuard Home
head -20 gfwlist2adguardhome/blacklist_full.txt

# Validate generated output format for DNSMasq
head -20 gfwlist2dnsmasq/blacklist_full.conf

# Check output file counts (should be 8 files per directory)
ls -1 gfwlist2adguardhome/ | wc -l
```

### Validation Commands
```bash
# Verify no duplicate domains in output files
sort gfwlist2domain/blacklist_full.txt | uniq -d

# Check domain format validity (basic regex test)
grep -v -E '^[a-z0-9]([a-z0-9-]*[a-z0-9])?(\.[a-z0-9]([a-z0-9-]*[a-z0-9])?)*$' gfwlist2domain/blacklist_full.txt

# Verify output directories were created
ls -ld gfwlist2* | grep ^d
```

### CI/CD
- **GitHub Actions**: `.github/workflows/main.yml`
- **Schedule**: Daily at 00:00 UTC via cron
- **Manual trigger**: Available via workflow_dispatch

## Conventions

### Shell Script Conventions

#### File Structure
- **Single file architecture**: All logic in `release.sh`
- **Function-based**: Organized into `GetData()`, `AnalyseData()`, `GenerateRules()`, `OutputData()`
- **No external dependencies**: Pure bash + standard Unix tools (curl, sed, grep, awk, sort, base64)

#### Naming Conventions
- **Functions**: PascalCase (e.g., `GetData`, `GenerateRules`, `FileName`)
- **Variables**: snake_case (e.g., `cnacc_domain`, `gfwlist_data`, `software_name`)
- **Arrays**: snake_case with plural names (e.g., `domestic_dns`, `foreign_dns`)
- **Loop counters**: `<array_name>_task` (e.g., `cnacc_domain_task`, `foreign_dns_task`)

#### Variable Scope
```bash
# Global arrays for data sources (defined at function start)
cnacc_domain=(...)
gfwlist_base64=(...)

# Local function variables (no explicit 'local' keyword used in this codebase)
# Variables are scoped by function context

# Parameters passed via environment variables
software_name="adguardhome"
generate_file="black"
generate_mode="full"
dns_mode="default"
```

#### String Quoting
- **URLs and paths**: Always use double quotes `"${variable}"`
- **Commands**: Use quotes for arguments: `sed "s/^\.//g"`
- **Array expansion**: Use `"${!array[@]}"` for indices, `"${array[@]}"` for values

#### Array Iteration
```bash
# Correct pattern used throughout codebase
for array_name_task in "${!array_name[@]}"; do
    process "${array_name[$array_name_task]}"
done
```

#### Pipes and Redirects
- **Append to temp files**: `>> ./file.tmp`
- **Overwrite with echo**: `echo "content" > "${file_path}"`
- **Inline processing**: `curl | sed | grep | sort | uniq`
- **Silent curl**: Always use `-s --connect-timeout 15`

### Data Processing Patterns

#### Domain Filtering
```bash
# Standard domain regex (used throughout)
domain_regex="^(([a-z]{1})|([a-z]{1}[a-z]{1})|([a-z]{1}[0-9]{1})|([0-9]{1}[a-z]{1})|([a-z0-9][-\.a-z0-9]{1,61}[a-z0-9]))\.([a-z]{2,13}|[a-z0-9-]{2,30}\.[a-z]{2,3})$"

# Lite domain regex (for top-level domains only)
lite_domain_regex="^([a-z]{2,13}|[a-z0-9-]{2,30}\.[a-z]{2,3})$"
```

#### Custom Rule Syntax (data/data_modify.txt)
- **Add to both lists**: `(@@@)example.org`
- **Remove from both**: `(!!!)example.org`
- **Exclude pattern**: `(***)example.org`
- **Add to China list only**: `(@%@)example.org`
- **Add to GFW list only**: `(@&@)example.org`
- **Cross-list operations**: `(@%!)`, `(!%@)`, `(@&!)`, `(!&@)`

### Output Format Generation

#### Case Statement Structure
```bash
case ${software_name} in
    adguardhome)
        # Define DNS servers
        domestic_dns=(...)
        foreign_dns=(...)
        
        # Define format functions
        function GenerateRulesHeader() { ... }
        function GenerateRulesBody() { ... }
        function GenerateRulesFooter() { ... }
    ;;
    other_software)
        # Similar structure
    ;;
    *)
        exit 1
    ;;
esac
```

#### Output File Naming
- **Pattern**: `{blacklist|whitelist}_{full|lite}[_combine].{txt|conf}`
- **Full**: Complete domain list with all subdomains
- **Lite**: Top-level domains only
- **Combine**: Single-line format (for AdGuard Home)

### Error Handling

#### Current Practice
- **No explicit error checking** for curl/network failures
- **Silent failures**: Most commands use `|| true` implicitly via pipes
- **Exit on unknown software**: `*) exit 1 ;;` in case statements

#### Best Practices for New Code
```bash
# Add error checking for critical operations
if ! curl -s --connect-timeout 15 "${url}" > file.tmp; then
    echo "Error: Failed to fetch ${url}" >&2
fi

# Validate intermediate files exist before processing
if [ ! -f "./cnacc_domain.tmp" ]; then
    echo "Error: Missing intermediate file" >&2
    exit 1
fi
```

### Comments

#### Function Documentation
```bash
## Function
# Get Data
function GetData() {
    # Array definitions with source URLs
    cnacc_domain=(...)
}
```

#### Inline Comments
- **Minimal**: Code is mostly self-documenting via function names
- **Section markers**: Use `##` for major sections
- **Commented code**: DNS server options shown as examples with `#` prefix

### File Organization

#### Directory Structure
```text
.
├── .github/workflows/main.yml    # CI/CD configuration
├── data/data_modify.txt          # Custom domain rules
├── release.sh                    # Main build script
├── LICENSE                       # Apache 2.0 + Commons Clause
├── gfwlist2adguardhome/          # Generated AdGuard Home configs
├── gfwlist2adguardhome_new/      # New AdGuard Home format
├── gfwlist2bind9/                # Generated Bind9 configs
├── gfwlist2dnsmasq/              # Generated DNSMasq configs
├── gfwlist2domain/               # Plain domain lists
├── gfwlist2smartdns/             # Generated SmartDNS configs
└── gfwlist2unbound/              # Generated Unbound configs
```

#### Temporary Files
- **Location**: `./Temp/` (created during build, deleted after)
- **Naming**: `*.tmp` suffix
- **Cleanup**: `rm -rf ./Temp` at start and end

## Making Changes

### Adding New Data Sources
1. Add URL to appropriate array in `GetData()` function
2. Ensure download loop appends to correct `.tmp` file
3. Test with full build to verify data integration

### Adding New DNS Software Support
1. Add new case in `GenerateRules()` function
2. Define DNS server arrays (domestic_dns, foreign_dns)
3. Implement three functions: `GenerateRulesHeader()`, `GenerateRulesBody()`, `GenerateRulesFooter()`
4. Add output calls in `OutputData()` function
5. Test all modes: full, lite, black, white, combine

### Modifying Custom Rules
- Edit `data/data_modify.txt` following syntax patterns
- Use markers: `@` (add), `!` (remove), `*` (exclude)
- Combine markers for cross-list operations: `%` (China only), `&` (GFW only)

### Output Format Changes
1. Locate the relevant case block in `GenerateRules()`
2. Modify `GenerateRulesHeader()`, `GenerateRulesBody()`, or `GenerateRulesFooter()`
3. Test with: `bash release.sh && head -50 gfwlist2{software}/{type}.{ext}`

## Common Pitfalls

1. **Long lines**: The script has very long lines (6000+ chars). Be careful with line continuations.
2. **Array indices**: Always use `"${!array[@]}"` for indices, not `"${array[@]}"`.
3. **Temp directory**: Ensure `./Temp` cleanup doesn't break if script exits early.
4. **Silent failures**: Network errors are not caught; add validation if critical.
5. **Regex escaping**: Domain regexes use `\.` for literal dots; be careful with escaping.

## Testing Checklist

- [ ] Run `bash release.sh` completes without errors
- [ ] All 6 output directories contain 4-8 files each
- [ ] Sample files from each directory have correct format
- [ ] No duplicate domains in output (test with `sort | uniq -d`)
- [ ] File sizes are reasonable (>100KB for full lists, >50KB for lite)
- [ ] Custom rules in `data/data_modify.txt` are applied correctly
- [ ] GitHub Actions workflow validates changes
