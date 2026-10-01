# codex-agent - deterministic board-refresh, no LLM call required.
#
# Mirrors .agents/skills/board-refresh/SKILL.md: scans data/ and regenerates
# web/board.json + web/stats.json. Safe to run on its own (read-only on data/)
# or have bridge.ps1 call it after every action so the UI never goes stale.
#
#   .\web\refresh-board.ps1

$ErrorActionPreference = "Stop"
$repo = Split-Path $PSScriptRoot -Parent
$dataDir = Join-Path $repo "data"

# folder -> canonical state (docs/03-data-model.md "States" table).
# Folder always wins over a ticket's own `state` field (REQ per board-refresh rule 1).
$folderState = [ordered]@{
    "01-inbox"                      = "new"
    "04-awaiting-info"              = "awaiting-info"
    "05-escalated"                  = "escalated"
    "06-resolved"                   = "resolved"
    "03-approval/pending-grouping"  = "pending-grouping"
    "03-approval/pending-action"    = "pending-action"
    "03-approval/approved"         = "approved"
    "03-approval/rejected"         = "rejected"
}

function Get-Thresholds {
    $cfg = Get-Content (Join-Path $repo "config.yaml") -Raw -Encoding UTF8
    [pscustomobject]@{
        grouping = [double]([regex]::Match($cfg, 'grouping:\s*([\d.]+)').Groups[1].Value)
        action   = [double]([regex]::Match($cfg, 'action:\s*([\d.]+)').Groups[1].Value)
    }
}

# @($null) yields a 1-element array [$null] in PowerShell, not []; this avoids that trap.
# The leading comma stops PowerShell unrolling a 1-element array back to a scalar on return.
function ToArray($v) {
    if ($null -eq $v) { return , @() }
    return , @($v)
}

function Read-Ticket($file, $state) {
    try {
        $t = Get-Content $file.FullName -Raw -Encoding UTF8 | ConvertFrom-Json
    } catch {
        # Not parseable JSON at all - surface it rather than crash the refresh.
        return [ordered]@{
            number = [IO.Path]::GetFileNameWithoutExtension($file.Name)
            state = $state; agent = $null; short_description = "Malformed ticket JSON"
            description = "Original ticket could not be parsed"; language = "ja"; caller = $null
            confidence = $null; alternatives = @(); match_reason = @(); runbook = $null
            plan = @(); plan_alternatives = @(); evidence = ""
            approval_reason = "invalid-ticket-json"; run_id = $null; created_at = $null; metrics = $null
        }
    }

    # Minimal/incomplete tickets (missing the schema's approval/confidence block)
    # are flagged rather than silently shown as "fine" (board-refresh rule: never
    # trust a ticket blindly - a missing block is itself evidence).
    $incomplete = -not ($t.PSObject.Properties.Name -contains "approval")

    [ordered]@{
        number            = $t.number
        state             = $state
        agent             = $t.agent
        short_description = $t.short_description
        description       = $t.description
        language          = $t.language
        caller            = $t.caller
        confidence        = $t.confidence
        alternatives      = ToArray $t.alternatives
        match_reason      = ToArray $t.match_reason
        runbook           = $t.runbook
        plan              = ToArray $t.plan
        plan_alternatives = ToArray $t.plan_alternatives
        evidence          = if ($incomplete) { "" } else { $t.evidence }
        approval_reason   = if ($incomplete) { "invalid-ticket-json" } elseif ($t.approval) { $t.approval.reason } else { $null }
        run_id            = $t.run_id
        created_at        = $t.created_at
        metrics           = $t.metrics
        has_human_history = @($t.history | Where-Object { $_.actor -eq "human" }).Count -gt 0
    }
}

function Tokens-ForRun($runId) {
    if (-not $runId) { return $null }
    $trace = Join-Path $dataDir "runs/$runId/trace.log"
    if (-not (Test-Path $trace)) { return $null }
    $sum = 0; $found = $false
    foreach ($m in [regex]::Matches((Get-Content $trace -Raw -Encoding UTF8), 'tokens=(\d+)')) {
        $sum += [int]$m.Groups[1].Value; $found = $true
    }
    if ($found) { $sum } else { $null }
}

function Median($nums) {
    $n = @($nums | Where-Object { $_ -ne $null } | Sort-Object)
    if ($n.Count -eq 0) { return $null }
    $mid = [math]::Floor(($n.Count - 1) / 2)
    if ($n.Count % 2 -eq 1) { $n[$mid] } else { [math]::Round((($n[$mid] + $n[$mid + 1]) / 2.0), 0) }
}

# ---- scan every ticket, derive canonical state from the folder it sits in ----
$tickets = @()
foreach ($rel in $folderState.Keys) {
    $dir = Join-Path $dataDir $rel
    if (-not (Test-Path $dir)) { continue }
    Get-ChildItem $dir -Filter *.json | ForEach-Object {
        $tickets += Read-Ticket $_ $folderState[$rel]
    }
}
# data/02-grouped/<agent>/*.json - state is "grouped" regardless of which agent folder.
$groupedRoot = Join-Path $dataDir "02-grouped"
if (Test-Path $groupedRoot) {
    Get-ChildItem $groupedRoot -Directory | ForEach-Object {
        Get-ChildItem $_.FullName -Filter *.json | ForEach-Object {
            $tickets += Read-Ticket $_ "grouped"
        }
    }
}

$tickets = $tickets | Sort-Object { [int]($_.number -replace '\D', '') }

# ---- board.json ----
$thr = Get-Thresholds
$countOf = { param($s) @($tickets | Where-Object { $_.state -eq $s }).Count }
$unprocessed  = & $countOf "new"
$groupedCount = & $countOf "grouped"
$needsYou     = (& $countOf "pending-grouping") + (& $countOf "pending-action")
$escalated    = & $countOf "escalated"
$awaitingInfo = & $countOf "awaiting-info"
$resolved     = @($tickets | Where-Object { $_.state -eq "resolved" })

# auto-handled = resolved with no history entry whose actor is "human"
$autoCount = @($resolved | Where-Object { -not $_.has_human_history }).Count

$board = [ordered]@{
    generated_at = (Get-Date -Format "yyyy-MM-ddTHH:mm:sszzz")
    counts = [ordered]@{
        unprocessed    = $unprocessed
        grouped        = $groupedCount
        needs_you      = $needsYou
        escalated      = $escalated
        awaiting_info  = $awaitingInfo
        resolved_today = $resolved.Count
    }
    auto_handled = [ordered]@{
        count = $autoCount
        total = $resolved.Count
        rate  = if ($resolved.Count -gt 0) { [math]::Round($autoCount / $resolved.Count, 2) } else { 0 }
    }
    thresholds = [ordered]@{ grouping = $thr.grouping; action = $thr.action }
    tickets = @($tickets | ForEach-Object {
        $o = [ordered]@{}
        foreach ($k in $_.Keys) { if ($k -ne "has_human_history") { $o[$k] = $_[$k] } }
        $o
    })
}

# ---- stats.json ----
$grouped      = @($tickets | Where-Object { $_.confidence -and $_.confidence.grouping -ne $null })
$groupingAuto = @($grouped | Where-Object { $_.state -ne "pending-grouping" })
$withWrite    = @($tickets | Where-Object { @($_.plan | Where-Object { $_.write }).Count -gt 0 })
$actionAuto   = @($withWrite | Where-Object {
    $d = Join-Path $dataDir "runs/$($_.run_id)/decision.json"
    (Test-Path $d) -and ((Get-Content $d -Raw -Encoding UTF8 | ConvertFrom-Json).decision -eq "auto")
})

$aiSecs    = $tickets | ForEach-Object { $_.metrics.ai_seconds } | Where-Object { $_ -ne $null }
$waitSecs  = $tickets | ForEach-Object { $_.metrics.human_wait_seconds } | Where-Object { $_ -ne $null }

$tokensByAgent = [ordered]@{}
$tokensTotal = 0; $tokenTicketCount = 0
foreach ($t in $tickets) {
    $tok = Tokens-ForRun $t.run_id
    if ($tok -eq $null) { $tok = $t.metrics.tokens }
    if ($tok -eq $null) { continue }
    $tokensTotal += $tok; $tokenTicketCount++
    $key = if ($t.agent) { $t.agent } else { "unknown" }
    $tokensByAgent[$key] = ($tokensByAgent[$key] | ForEach-Object { $_ } | Measure-Object -Sum).Sum + $tok
}

$dayCounts = [ordered]@{}
foreach ($r in $resolved) {
    $d = $r.created_at
    if (-not $d) { continue }
    $day = (Get-Date $d).ToString("ddd")
    $dayCounts[$day] = [int]($dayCounts[$day]) + 1
}

$stats = [ordered]@{
    generated_at = $board.generated_at
    window = "all"
    rates = [ordered]@{
        grouping_auto = [ordered]@{
            count = $groupingAuto.Count; total = $grouped.Count
            rate  = if ($grouped.Count -gt 0) { [math]::Round($groupingAuto.Count / $grouped.Count, 2) } else { 0 }
        }
        action_auto = [ordered]@{
            count = $actionAuto.Count; total = $withWrite.Count
            rate  = if ($withWrite.Count -gt 0) { [math]::Round($actionAuto.Count / $withWrite.Count, 2) } else { 0 }
        }
        escalated = [ordered]@{
            count = $escalated; total = $tickets.Count
            rate  = if ($tickets.Count -gt 0) { [math]::Round($escalated / $tickets.Count, 2) } else { 0 }
        }
    }
    time_seconds = [ordered]@{
        ai_median         = Median $aiSecs
        human_wait_median = Median $waitSecs
    }
    tokens = [ordered]@{
        total          = $tokensTotal
        per_ticket_avg = if ($tokenTicketCount -gt 0) { [math]::Round($tokensTotal / $tokenTicketCount, 0) } else { 0 }
        by_agent       = $tokensByAgent
    }
    resolved_by_day = @($dayCounts.Keys | ForEach-Object { [ordered]@{ day = $_; count = $dayCounts[$_] } })
}

# ---- write both files atomically: temp name then rename ----
foreach ($pair in @(@{ name = "board.json"; obj = $board }, @{ name = "stats.json"; obj = $stats })) {
    $tmp = Join-Path $PSScriptRoot ($pair.name + ".tmp")
    $dst = Join-Path $PSScriptRoot $pair.name
    ($pair.obj | ConvertTo-Json -Depth 12) | Set-Content $tmp -Encoding utf8
    Move-Item $tmp $dst -Force
}

Write-Host "board.json and stats.json refreshed from data/ ($($tickets.Count) tickets)."
