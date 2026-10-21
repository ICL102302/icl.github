# 관리자 페이지 처음 설정 (한 번만 실행)
#  1) GitHub의 최신 내용을 받고
#  2) nppBackup, backup_log.txt, .DS_Store 를 git 관리에서 뺀 뒤 (PC의 파일은 지우지 않음)
#  3) 관리자 페이지와 data 폴더를 함께 커밋해서 GitHub에 올립니다.

$repoPath = "G:\icl.github"
Set-Location -Path $repoPath
$ErrorActionPreference = 'Continue'

function Step($msg) { Write-Host ""; Write-Host "== $msg" -ForegroundColor Cyan }
function Fail($msg) { Write-Host ""; Write-Host $msg -ForegroundColor Red; exit 1 }

Step "1/4 GitHub에서 최신 내용 받기"
git pull --ff-only origin main
if ($LASTEXITCODE -ne 0) { Fail "최신 내용을 받지 못했습니다. 위 메시지를 확인하세요. (아무것도 바뀌지 않았습니다)" }

Step "2/4 백업 파일을 git 관리에서 빼기 (PC의 파일은 그대로 둡니다)"
git rm -r --cached --quiet --ignore-unmatch -- nppBackup css/nppBackup js/nppBackup images/nppBackup backup_log.txt "*.DS_Store"

Step "3/4 관리자 페이지 파일 추가하고 커밋"
git add -A
git status --short | Select-Object -First 15
$msg = "$(Get-Date -Format 'yyMMdd') admin page added, data folder added, nppBackup untracked"
git commit -m $msg
if ($LASTEXITCODE -ne 0) { Fail "커밋하지 못했습니다. 위 메시지를 확인하세요." }

Step "4/4 GitHub에 올리기"
git push origin main
if ($LASTEXITCODE -ne 0) { Fail "GitHub에 올리지 못했습니다. 인터넷 연결을 확인하고 git_push_backup.bat 를 실행해 다시 올리세요." }

Write-Host ""
Write-Host "완료했습니다. 1~2분 뒤 https://icl.cau.ac.kr/admin.html 에서 관리자 페이지를 열 수 있습니다." -ForegroundColor Green
