# PowerShell script to replace all PCC occurrences with PCI DSS in markdown files
# This script will systematically replace all instances of PCC with PCI DSS

Write-Host "🚀 Starting PCC to PCI DSS replacement across all markdown files..." -ForegroundColor Green

# Define the files to process
$markdownFiles = @(
    "PROJECT_PROGRESS.md",
    "README.md", 
    "PCI_DSS_COMPLIANCE_CHECKLIST.md",
    "InvoicePe_TESTING_STRATEGY.md",
    "FLUTTER_SUPABASE_PATTERNS.md",
    "PROJECT_DEBUG_GUIDE.md"
)

# Define replacement patterns
$replacements = @{
    "PCC" = "PCI DSS"
    "PCC-ready" = "PCI DSS-ready"
    "PCC-compliant" = "PCI DSS-compliant"
    "post-PCC" = "post-PCI DSS"
    "PCC certification" = "PCI DSS certification"
    "PCC compliance" = "PCI DSS compliance"
    "PCC submission" = "PCI DSS submission"
    "PCC review" = "PCI DSS review"
    "PCC-certified" = "PCI DSS-certified"
    "for PCC" = "for PCI DSS"
    "to PCC" = "to PCI DSS"
    "PCC_COMPLIANCE_CHECKLIST.md" = "PCI_DSS_COMPLIANCE_CHECKLIST.md"
}

$totalReplacements = 0

foreach ($file in $markdownFiles) {
    if (Test-Path $file) {
        Write-Host "📝 Processing $file..." -ForegroundColor Yellow
        
        $content = Get-Content $file -Raw -Encoding UTF8
        $originalContent = $content
        $fileReplacements = 0
        
        foreach ($pattern in $replacements.Keys) {
            $replacement = $replacements[$pattern]
            $matches = [regex]::Matches($content, [regex]::Escape($pattern))
            $beforeCount = $matches.Count
            $content = $content -replace [regex]::Escape($pattern), $replacement
            $matchesAfter = [regex]::Matches($content, [regex]::Escape($pattern))
            $afterCount = $matchesAfter.Count
            $replaced = $beforeCount - $afterCount

            if ($replaced -gt 0) {
                Write-Host "  ✅ Replaced '$pattern' → '$replacement' ($replaced occurrences)" -ForegroundColor Cyan
                $fileReplacements += $replaced
            }
        }
        
        if ($content -ne $originalContent) {
            Set-Content $file -Value $content -Encoding UTF8 -NoNewline
            Write-Host "  💾 Saved $file with $fileReplacements replacements" -ForegroundColor Green
            $totalReplacements += $fileReplacements
        } else {
            Write-Host "  ℹ️  No changes needed in $file" -ForegroundColor Gray
        }
    } else {
        Write-Host "  ⚠️  File not found: $file" -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "🎉 PCC to PCI DSS replacement complete!" -ForegroundColor Green
Write-Host "📊 Total replacements made: $totalReplacements" -ForegroundColor Cyan
Write-Host ""
Write-Host "✅ All markdown files have been updated to use 'PCI DSS' instead of 'PCC'" -ForegroundColor Green
Write-Host "🔒 Payment Card Industry Data Security Standard (PCI DSS) is now correctly referenced" -ForegroundColor Green
