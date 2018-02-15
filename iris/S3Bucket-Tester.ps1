$AccessKey = "AKIAI2ZEWVIVKZHGYOHA"
$AccessSecret = "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"

Write-S3Object -BucketName "iris-templates-dev" -AccessKey $AccessKey -SecretKey $AccessSecret -Key test.txt -File .\iris-templates.json
