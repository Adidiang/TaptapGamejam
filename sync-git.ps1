param(
    [string]$Message = ('Update game ' + (Get-Date -Format 'yyyy-MM-dd HH:mm')),
    [switch]$CheckOnly
)

$ErrorActionPreference = 'Stop'
$expectedRemote = 'https://github.com/Adidiang/TaptapGamejam.git'

function Invoke-Git {
    param([string[]]$GitArgs)
    & git @GitArgs
    if ($LASTEXITCODE -ne 0) {
        throw "Git failed (exit $LASTEXITCODE): git $($GitArgs -join ' ')"
    }
}

Push-Location -LiteralPath $PSScriptRoot
try {
    $root = Invoke-Git -GitArgs @('rev-parse', '--show-toplevel')
    if ([IO.Path]::GetFullPath($root) -ne [IO.Path]::GetFullPath($PSScriptRoot)) {
        throw 'Run this script from its own repository, not a parent repository.'
    }
    $remote = Invoke-Git -GitArgs @('remote', 'get-url', 'origin')
    if ($remote -ne $expectedRemote) { throw 'Unexpected origin URL. No upload performed.' }
    $branch = Invoke-Git -GitArgs @('symbolic-ref', '--short', 'HEAD')
    if ($branch -ne 'main') { throw 'Switch to main before using this sync script.' }
    if ([string]::IsNullOrWhiteSpace($Message)) { throw 'Commit message cannot be empty.' }
    $conflicts = Invoke-Git -GitArgs @('ls-files', '--unmerged')
    if ($conflicts) { throw 'Resolve merge conflicts before syncing.' }
    Invoke-Git -GitArgs @('status', '--short')
    if ($CheckOnly) { Write-Host 'Preview only: no files staged, committed or pushed.'; return }

    # Fetch before committing. Never silently merge, rebase or force-push.
    Invoke-Git -GitArgs @('fetch', '--prune', 'origin')
    $remoteMain = Invoke-Git -GitArgs @('branch', '--remotes', '--list', 'origin/main')
    if ($remoteMain) {
        & git merge-base --is-ancestor origin/main HEAD
        if ($LASTEXITCODE -ne 0) {
            throw 'Remote main has changes not in this checkout. Integrate them before syncing.'
        }
    }
    Invoke-Git -GitArgs @('add', '--all', '--', '.')
    & git diff --cached --quiet
    $diffCode = $LASTEXITCODE
    if ($diffCode -eq 1) {
        Invoke-Git -GitArgs @('commit', '-m', $Message)
    } elseif ($diffCode -ne 0) {
        throw 'Unable to inspect staged changes.'
    } else {
        Write-Host 'No new changes to commit. Uploading any existing local commits.'
    }
    Invoke-Git -GitArgs @('push', '--set-upstream', 'origin', 'main')
    Write-Host 'Sync complete.'
} catch {
    Write-Error $_
    exit 1
} finally {
    Pop-Location
}
