# codex-agent - optional click-to-run bridge.
#
# A browser cannot launch a process, so this small listener sits between the UI
# and Codex. Without it the pages stay read-only, which is a fine way to run.
#
#   Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
#   .\web\bridge.ps1

$repo = Split-Path $PSScriptRoot -Parent
$listener = [System.Net.HttpListener]::new()
$listener.Prefixes.Add("http://localhost:8765/")
$listener.Start()
Write-Host "bridge listening on http://localhost:8765  (repo: $repo)"
Write-Host "Ctrl+C to stop."

while ($listener.IsListening) {
    $ctx = $listener.GetContext()
    $req = $ctx.Request
    $res = $ctx.Response
    try {
    $res.AddHeader("Access-Control-Allow-Origin", "*")
    $res.AddHeader("Access-Control-Allow-Headers", "Content-Type")

    if ($req.HttpMethod -eq "OPTIONS") { $res.StatusCode = 204; $res.Close(); continue }

    $body   = [System.IO.StreamReader]::new($req.InputStream).ReadToEnd() | ConvertFrom-Json
    $ticket = ($body.ticket -replace '[^A-Za-z0-9\-]', '')
    $action = ($body.action -replace '[^a-z\-]', '')
    $extra  = ($body.extra  -replace '[^A-Za-z0-9 \-\.,]', '')

    $prompt = switch ($action) {
        "process" {
            "Process every ticket in data/01-inbox end to end: run ticket-grouping, " +
            "then the matching agent skill, stopping at data/03-approval for anything " +
            "that needs a human. Then run board-refresh."
        }
        "group" {
            "Run approval-gate: the human confirmed group '$extra' for ticket $ticket. " +
            "Move it to data/02-grouped/$extra/, run that agent skill immediately, " +
            "then run board-refresh."
        }
        "approve" {
            "Run approval-gate: the human approved the recommended plan for ticket " +
            "$ticket. Run ticket-close to execute it, then board-refresh."
        }
        "alternative" {
            "Run approval-gate: the human chose the alternative plan '$extra' for " +
            "ticket $ticket. Run ticket-close with that plan, then board-refresh."
        }
        "advisory" {
            "Run approval-gate: the human chose the advisory action '$extra' for ticket " +
            "$ticket. Execute no tool. Write the comment, move the ticket to " +
            "data/04-awaiting-info/, then board-refresh."
        }
        "reject" {
            "Run approval-gate: the human rejected the plan for ticket $ticket. " +
            "Move it to data/05-escalated/ with reason 'rejected', then board-refresh."
        }
        "escalate" {
            "Run approval-gate: the human escalated ticket $ticket. Move it to " +
            "data/05-escalated/ with the reason recorded, then board-refresh."
        }
        default { $null }
    }

    if ($prompt) {
        Write-Host "[$action] $ticket - running codex exec, output below:"
        Push-Location $repo
        # Stream each line live instead of buffering until exit, so you can see it's working.
        $lines = & codex exec --sandbox workspace-write $prompt 2>&1 | ForEach-Object {
            Write-Host "  $_"
            $_
        }
        $out = $lines | Out-String
        Write-Host "[$action] $ticket - done."
        Pop-Location
        $payload = @{ ok = $true; action = $action; ticket = $ticket; output = $out }
    } else {
        $payload = @{ ok = $false; error = "unknown action: $action" }
    }

    $buf = [Text.Encoding]::UTF8.GetBytes(($payload | ConvertTo-Json -Depth 4))
    $res.ContentType = "application/json"
    $res.OutputStream.Write($buf, 0, $buf.Length)
    $res.Close()
    } catch {
        # The browser tab may have been closed or reloaded while codex exec was
        # still running, so the client connection is gone - nothing to write to.
        Write-Warning "request for $ticket failed: $($_.Exception.Message)"
        try { $res.Close() } catch {}
    }
}
