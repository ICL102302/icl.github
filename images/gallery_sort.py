import os
import re

# 설정: 파이썬 스크립트는 현재 폴더 내의 "gallery" 폴더를 스캔합니다.
input_folder = "gallery"  
# HTML에서 사용될 이미지 경로는 "images/gallery"로 지정
output_folder_path = "images/gallery/"

output_file = "gallery.html"

# 허용할 확장자 목록 (소문자로 비교)
allowed_exts = {".png", ".jpg", ".jpeg", ".gif"}

# 파일명 패턴: 두 자리 연도, 언더스코어, 문자 'g', 숫자, 확장자 (예: 25_g68.png)
pattern = re.compile(r'^(\d{2})_g(\d+)(\.(png|jpg|jpeg|gif))$', re.IGNORECASE)

# 그룹화 딕셔너리: key는 전체 연도(예: "2025"), value는 (번호, filename) 튜플 리스트
groups = {}

# input_folder 내 파일 목록 읽기
for file in os.listdir(input_folder):
    file_path = os.path.join(input_folder, file)
    if not os.path.isfile(file_path):
        continue
    _, ext = os.path.splitext(file)
    if ext.lower() not in allowed_exts:
        continue
    m = pattern.match(file)
    if m:
        year_prefix = m.group(1)   # 예: "25"
        num_part = int(m.group(2)) # 예: 68
        full_year = "20" + year_prefix  # 예: "2025"
        groups.setdefault(full_year, []).append((num_part, file))

# 각 그룹 내에서 번호 내림차순 정렬
for year in groups:
    groups[year].sort(key=lambda x: x[0], reverse=True)

# 연도 그룹 전체를 내림차순(최신 연도 우선)으로 정렬
sorted_years = sorted(groups.keys(), key=lambda y: int(y), reverse=True)

# HTML 생성 시작
html_lines = []
html_lines.append("<!DOCTYPE html>")
html_lines.append("<html lang='en'>")
html_lines.append("<head>")
html_lines.append("  <meta charset='UTF-8'>")
html_lines.append("  <title>Gallery</title>")
html_lines.append("  <link rel='stylesheet' href='styles.css'>")  # 필요에 따라 CSS 추가
html_lines.append("</head>")
html_lines.append("<body>")
html_lines.append("<div id='fh5co-main'>")
html_lines.append("  <div class='fh5co-narrow-content'>")

# 각 연도 그룹별로 HTML 생성
for year in sorted_years:
    html_lines.append(f"    <h2 class='fh5co-heading animate-box' data-animate-effect='fadeInLeft'>{year}</h2>")
    html_lines.append("    <div class='row row-bottom-padded-md'>")
    
    for number, filename in groups[year]:
        # 파일명에서 base_name = 예: "25_g68" (확장자 제외)
        base_name = os.path.splitext(filename)[0]
        # 캡션: 예시로 파일명 그대로 또는 원하는 텍스트 (여기서는 파일명을 사용)
        caption =' '
        
        block = f"""
        <div class="col-md-custom col-sm-6 col-padding text-center animate-box">
            <a href="{output_folder_path}{filename}" data-toggle="lightbox" data-gallery="gallery">
                <div class="work g1" id="Journal-{base_name}" data-base-name="{base_name}" style="background-image: url({output_folder_path}{filename});"></div>
            </a>
            <div class="caption">
                <span class="p8">{caption}<br></span>
            </div>
        </div>
        """
        html_lines.append(block)
    html_lines.append("    </div>")  # row 닫기
html_lines.append("  </div>")      # fh5co-narrow-content 닫기
html_lines.append("</div>")         # fh5co-main 닫기
html_lines.append("</body>")
html_lines.append("</html>")

with open(output_file, "w", encoding="utf-8") as f:
    f.write("\n".join(html_lines))

print(f"Gallery HTML generated and saved to {output_file}")
