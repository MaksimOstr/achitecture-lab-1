$ErrorActionPreference = 'Stop'
$jar = Get-ChildItem -Path "$PSScriptRoot\\..\\build\\libs" -Filter "mywebapp*.jar" | Select-Object -First 1
if (-not $jar) {
    throw "Build the application first with .\\gradlew.bat bootJar"
}
java -jar $jar.FullName --spring.config.additional-location=file:/etc/mywebapp/config.yaml --spring.main.web-application-type=none --mywebapp.migrate-only=true
