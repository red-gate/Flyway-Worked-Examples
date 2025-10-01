# Use case: Combine reports from multiple servers into a single file (e.g., aggregating drift checks across environments).
# This script updates the dropdown label in the Reports tab, replacing the default timestamp with a custom value (e.g., database or server name) from the $replacementText variable.

# Set your file paths
$htmlPath = "C:\Projects\DemoDB\report.html"
$outputPath = "C:\Projects\DemoDB\report.html"
$replacementText = "Latest Production DB Name"

# Read the HTML file
$htmlContent = Get-Content -Path $htmlPath -Raw

# Find the <select id="dropdown"> element
$selectPattern = '<select[^>]*id\s*=\s*["'']dropdown["''][^>]*>(.*?)</select>'
$selectMatch = [regex]::Match($htmlContent, $selectPattern, [System.Text.RegularExpressions.RegexOptions]::Singleline)

if ($selectMatch.Success) {
    Write-Host "Found <select id='dropdown'>"

    $selectInnerHtml = $selectMatch.Groups[1].Value

    # Find all <option> elements inside it
    $optionPattern = '<option\s+value="([^"]+)"(?:\s+selected="true")?>(.*?)</option>'
    $optionMatches = [regex]::Matches($selectInnerHtml, $optionPattern)

    if ($optionMatches.Count -gt 0) {
        $lastMatch = $optionMatches[$optionMatches.Count - 1]
        $originalOption = $lastMatch.Value
        $timestamp = $lastMatch.Groups[1].Value
        $newOption = "<option value=""$timestamp"">$replacementText</option>"

        # Replace the last <option> element
        $newSelectInnerHtml = $selectInnerHtml.Substring(0, $lastMatch.Index) + 
                              $newOption + 
                              $selectInnerHtml.Substring($lastMatch.Index + $lastMatch.Length)

        # Reconstruct full <select> block
        $newSelectBlock = $selectMatch.Value -replace [regex]::Escape($selectInnerHtml), [regex]::Escape($newSelectInnerHtml) -replace '\\', ''

        # Replace the entire <select> block in the HTML
        $htmlContent = $htmlContent -replace [regex]::Escape($selectMatch.Value), [regex]::Escape($newSelectBlock) -replace '\\', ''

        # Save modified HTML
        Set-Content -Path $outputPath -Value $htmlContent -Encoding UTF8
        Write-Host "Replaced last <option> with '$replacementText'."
    }
    else {
        Write-Host "No <option> elements found inside #dropdown."
    }
}
else {
    Write-Host "Could not find <select id='dropdown'> in HTML."
}
