# validate-phase-artifact.ps1
# Phase 산출물 Markdown 파일의 필수 구조를 검증한다 (PowerShell 등가본).
# 사용: pwsh -File scripts/validate-phase-artifact.ps1 <artifact_file>
# 종료 코드: 0 = 통과, 1 = 형식 실패
#
# ============================================================================
# 본 스크립트는 validate-phase-artifact.sh 의 Windows/PowerShell 등가본이다.
# 작동 SSoT 는 .sh 본체. 본 .ps1 은 bash 미가용 환경에서의 fallback 이며
# .sh 와 동일 항목·동일 종료 코드를 보장해야 한다 (변경 시 양쪽 동기화 의무).
# ============================================================================

param(
    [Parameter(Mandatory=$true, Position=0)]
    [string]$ArtifactFile
)

$ErrorActionPreference = 'Stop'

if (-not (Test-Path -LiteralPath $ArtifactFile -PathType Leaf)) {
    Write-Error "파일 없음: $ArtifactFile"
    exit 1
}

$base = Split-Path -Leaf $ArtifactFile
$lines = Get-Content -LiteralPath $ArtifactFile -Raw -Encoding UTF8
$lineArr = Get-Content -LiteralPath $ArtifactFile -Encoding UTF8
$fail = 0

function Write-Err($msg)  { Write-Host "❌ $msg" -ForegroundColor Red; $script:fail = 1 }
function Write-Warn($msg) { Write-Host "⚠️  $msg" -ForegroundColor Yellow }
function Write-Ok($msg)   { Write-Host "✅ $msg" -ForegroundColor Green }

# --- YAML frontmatter 필수 필드 (4개) ---
$firstLine = $lineArr[0]
if ($firstLine -eq '---') {
    $fmEnd = 0
    for ($i = 1; $i -lt $lineArr.Length; $i++) {
        if ($lineArr[$i] -eq '---') { $fmEnd = $i; break }
    }
    if ($fmEnd -gt 0) {
        $fmText = ($lineArr[1..($fmEnd-1)] -join "`n")
        foreach ($field in @('phase','completed','status','advisor_status')) {
            if ($fmText -notmatch "(?m)^${field}:") {
                Write-Err "frontmatter 필드 누락: $field — $base"
            }
        }
    } else {
        Write-Err "YAML frontmatter 종료 마커 없음 — $base"
    }
} else {
    Write-Err "YAML frontmatter 없음 — $base"
}

# --- 필수 섹션 헤더 (5개) ---
$requiredSections = @(
    '^## Summary$',
    '^## Files Generated$',
    '^## Context for Next Phase$',
    '^## Escalations$',
    '^## Next Steps$'
)
foreach ($pat in $requiredSections) {
    if ($lines -notmatch "(?m)$pat") {
        Write-Err "필수 섹션 누락: $pat — $base"
    }
}

# --- Phase 9 전용 (3개) ---
if ($base -eq '07-validation-report.md') {
    foreach ($pat in @('^## File Inventory$','^## Security Audit$','^## Simulation Trace$')) {
        if ($lines -notmatch "(?m)$pat") {
            Write-Err "Phase 9 필수 섹션 누락: $pat — $base"
        }
    }
}

# --- Phase 3 전용 운영 가드 ---
if ($base -eq '02-workflow-design.md') {
    if ($lines -notmatch '(?m)^## Session Recovery Protocol$') {
        Write-Err "Phase 3 필수 섹션 누락: ^## Session Recovery Protocol$ — $base"
    }
}

# --- Phase 4 전용 운영 가드 ---
if ($base -eq '03-pipeline-design.md') {
    if ($lines -notmatch '(?m)^## Failure Recovery & Artifact Versioning$') {
        Write-Err "Phase 4 필수 섹션 누락: ^## Failure Recovery & Artifact Versioning$ — $base"
    }
}

# --- Phase 0 전용 Pre-collected Answers 검증 ---
if ($base -eq '00-target-path.md') {
    if ($lines -notmatch '(?m)^## Pre-collected Answers$') {
        Write-Err "Phase 0 필수 섹션 누락: ^## Pre-collected Answers$ — silent inference 차단 게이트"
    } else {
        # Pre-collected Answers 섹션 추출
        $pcaMatch = [regex]::Match($lines, '(?ms)^## Pre-collected Answers$\s*(.+?)(?=^## |\z)')
        $pcaBlock = if ($pcaMatch.Success) { $pcaMatch.Groups[1].Value } else { '' }

        # 9개 필수 행 존재 확인
        foreach ($item in @('A1','A2','A3','A5','A6','A7','A8','A9','A10')) {
            if ($pcaBlock -notmatch "(?m)\| $item\s") {
                Write-Err "Phase 0 Pre-collected Answers 누락 항목: $item"
            }
        }

        # 금지 출처 토큰 검출
        if ($pcaBlock -match '(?i)(발화 추출|발화 기반|AI 추정|자동 결정|기본값 적용|self-inferred|silently inferred|inferred from utterance)') {
            Write-Err "Phase 0 Pre-collected Answers 금지 출처 토큰 발견 — AskUserQuestion#N 또는 `$ARGUMENTS prefill 만 허용"
        }

        # 각 행에 출처 토큰 존재 확인
        foreach ($item in @('A1','A2','A3','A5','A6','A7','A8','A9','A10')) {
            $line = ($pcaBlock -split "`n" | Where-Object { $_ -match "(?m)\| $item\s" } | Select-Object -First 1)
            if ($line -and $line -notmatch '(AskUserQuestion#[1-3]|\$ARGUMENTS prefill)') {
                Write-Err "Phase 0 Pre-collected Answers ${item} 행에 유효한 출처 토큰 없음"
            }
        }

        # 고정 카탈로그 항목 라벨 N/A 변형 차단
        foreach ($item in @('A2','A3','A5','A7','A8','A9','A10')) {
            $line = ($pcaBlock -split "`n" | Where-Object { $_ -match "(?m)\| $item\s" } | Select-Object -First 1)
            if (-not $line) { continue }
            if ($line -match '(?i)\|\s?(N/A|NA|n/a|none|null|미정|미상|없음|모름|불명|자유 텍스트|label N/A|TBD|todo|TODO|undecided)\s?\|') {
                Write-Err "Phase 0 Pre-collected Answers ${item} 행에 placeholder 값 (N/A 변형) — 카탈로그 라벨 정확 인용 필수"
            }
            if ($line -match '\|\s*\|\s*$') {
                Write-Err "Phase 0 Pre-collected Answers ${item} 행 마지막 열 빈 셀"
            }
            if ($line -match '\|\s*[—\-]\s*\|') {
                Write-Err "Phase 0 Pre-collected Answers ${item} 행 라벨 셀이 dash 만 — placeholder 우회 의심"
            }
        }
    }
}

# --- Escalations 카운트 ---
$escMatch = [regex]::Match($lines, '(?ms)^## Escalations$\s*(.+?)(?=^## |\z)')
$escBlock = if ($escMatch.Success) { $escMatch.Groups[1].Value } else { '' }

$askTotal = ([regex]::Matches($escBlock, '\[ASK\]')).Count
$blockTotal = ([regex]::Matches($escBlock, '\[BLOCKING\]')).Count
$resolvedTotal = ([regex]::Matches($escBlock, '\[RESOLVED\]')).Count

# 단순 추정 — .sh 와 동일 정도의 정확도
$askResolved = [Math]::Min($askTotal, $resolvedTotal)
$blockResolved = [Math]::Min($blockTotal, [Math]::Max(0, $resolvedTotal - $askResolved))
$askOpen = $askTotal - $askResolved
$blockOpen = $blockTotal - $blockResolved

Write-Host ("ESCALATION_COUNT: ASK={0}, BLOCKING={1}, RESOLVED_ASK={2}, RESOLVED_BLOCKING={3}" -f $askOpen, $blockOpen, $askResolved, $blockResolved)

if ($fail -eq 0) {
    Write-Ok "Phase 산출물 구조 검증 통과: $base (미해결: ASK=$askOpen, BLOCKING=$blockOpen)"
    exit 0
}
exit 1
