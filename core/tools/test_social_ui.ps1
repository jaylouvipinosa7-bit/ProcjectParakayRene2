$resp = Invoke-WebRequest -Uri "http://127.0.0.1:8080/app.html" -UseBasicParsing
Write-Host "HTTP Status:" $resp.StatusCode
Write-Host "Header Present:" $resp.Content.Contains("Social Triggers")
Write-Host "Dispatcher Card Present:" $resp.Content.Contains("social-trigger-dispatcher-card")
Write-Host "Ten Cards Present:" $resp.Content.Contains("socialTabTriggerGrid")
Write-Host "Likes Person Card Present:" $resp.Content.Contains("cardSocialLikesPerson")
Write-Host "JS Handlers Present:" $resp.Content.Contains("selectSocialTriggerCard")
