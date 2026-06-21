#Настройка переменных

if (!(Get-Command psql -ErrorAction SilentlyContinue)) {
    Write-Host "psql not found! Please add PostgreSQL to PATH." -ForegroundColor Red
    exit 1
}
#Название базы
$DB_NAME = "data_warehouse_project"
    
#Имя пользователя
$DB_USER = "postgres"

#Директория
$TEST_DIR = "tests"
Write-Host "--1--"
Write-Host "Running tests..." -ForegroundColor Cyan

#Пароль от пользователя
PGPASSWORD = Read-Host "Password for Postgres"

if(!(Test-Path $TEST_DIR)){
    Write-Host "Test dir does not exist" -ForegroundColor Red
    exit 1
}

$testfiles = Get-ChildItem -Path $TEST_DIR -Filter *.sql -Recurse 

Write-Host "--2--"
foreach($file in $testfiles){

    Write-Host "Testing $($file.Name)"

    $result = psql -d $DB_NAME -U $DB_USER -W $DB_PASS -t -A -f $file.FullName   
    Write-Host "--3--"
    if($null -eq $result){
        Write-Host "Failed to run tests" -ForegroundColor Red
        exit 1
    }
    Write-Host "--4--"
    if ($result -ne "0"){
        Write-Host "Test $($file.Name) failed" -ForegroundColor Red
        exit 1
    } else {
        Write-Host "Test $($file.Name) passed" -ForegroundColor Green
    }

    Write-Host "All tests passed" -ForegroundColor Green
}


