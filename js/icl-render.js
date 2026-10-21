/*
 * ICL 홈페이지 렌더러
 * data/*.json 의 내용을 각 페이지의 HTML 조각으로 바꿉니다.
 * admin.html 이 저장할 때 이 파일을 사용해 페이지의
 * <!-- ADMIN:이름 --> ... <!-- /ADMIN:이름 --> 사이를 다시 씁니다.
 * (이 표시 사이는 직접 고치지 마세요. 관리자 페이지에서 저장하면 덮어써집니다.)
 */
(function (root) {
  'use strict';

  function esc(s) {
    return String(s == null ? '' : s)
      .replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;')
      .replace(/"/g, '&quot;');
  }
  // 제목에는 <sub>, <sup>, <i>, <b> 태그만 허용
  function richText(s) {
    return esc(s).replace(/&lt;(\/?)(sub|sup|i|b)&gt;/gi, '<$1$2>');
  }
  function plain(s) {
    return String(s == null ? '' : s).replace(/<[^>]*>/g, '');
  }
  function baseName(file) {
    return String(file).replace(/\.[^.]+$/, '');
  }

  // ---------- Publications (icl_publications.xlsx / pub_html.py 와 같은 규칙) ----------
  // 항목: no(Paper No.), authors, title, year, source(Source title), volume, issue,
  //       artNo(Art. No.), pageStart, pageEnd, doi, image
  function citation(p) {
    var parts = [];
    if (p.title) parts.push(richText(p.title));
    if (p.source) parts.push('<i>' + esc(p.source) + '</i>');
    if (p.year) parts.push('<b>' + esc(p.year) + '</b>');
    if (p.volume) parts.push('<i>' + esc(p.volume) + '</i>');
    if (p.artNo) {
      parts.push(esc(p.artNo));
    } else {
      if (p.issue) parts.push(esc(p.issue));
      if (p.pageStart && p.pageEnd) parts.push(esc(p.pageStart) + '–' + esc(p.pageEnd));
      else if (p.pageStart) parts.push(esc(p.pageStart));
    }
    return parts.join(', ');
  }
  function doiUrl(p) { return p.doi ? 'https://doi.org/' + p.doi : '#'; }

  function sortPubs(list) {
    return list.slice().sort(function (a, b) { return b.no - a.no; });
  }

  function groupByYear(list) {
    var groups = [];
    list.forEach(function (x) {
      var g = groups[groups.length - 1];
      if (!g || g.year !== x.year) { g = { year: x.year, items: [] }; groups.push(g); }
      g.items.push(x);
    });
    return groups;
  }

  function publications(list) {
    return groupByYear(sortPubs(list)).map(function (g) {
      return '<div class="journal-item" data-year="' + esc(g.year) + '">\n' + g.items.map(function (p) {
        var link = doiUrl(p);
        var cite = citation(p);
        var id = baseName(p.image || (String(p.year).slice(2) + '_' + p.no));
        var pic = p.image
          ? '            <div class="pic">\n' +
            '                <a href="' + esc(link) + '" target="_blank" class="title-link">\n' +
            '                    <img id="Journal-' + esc(id) + '" data-base-name="' + esc(id) + '" src="images/publications/' + esc(p.image) + '" alt="' + esc(plain(cite)) + '" loading="lazy">\n' +
            '                </a>\n' +
            '            </div>\n'
          : '';
        return '    <div class="animate-box" data-animate-effect="fadeInLeft">\n' +
          '        <div class="journals_box">\n' +
          '            <div class="tbox">\n' +
          '                <h4>\n' +
          '                    <a href="' + esc(link) + '" target="_blank" class="title-link">' + cite + '</a>\n' +
          '                </h4>\n' +
          '                <div class="smt">' + esc(p.authors) + '</div>\n' +
          '            </div>\n' +
          '            <div class="number-box">' + esc(p.no) + '</div>\n' +
          pic +
          '        </div>\n' +
          '    </div>\n';
      }).join('') + '</div>\n';
    }).join('');
  }

  function yearOptions(list) {
    var years = [];
    list.forEach(function (x) { if (years.indexOf(x.year) < 0) years.push(x.year); });
    years.sort(function (a, b) { return b - a; });
    return years.map(function (y) {
      return '\t\t\t\t\t\t\t\t   <option value="' + esc(y) + '">' + esc(y) + '</option>\n';
    }).join('');
  }

  // ---------- Patents (icl_patent.xlsx / patent_html.py 와 같은 규칙) ----------
  // 항목: no(No.), name(발명자), title, nation, applicationNo, applicationDate, registrationNo, registrationDate
  // 등록번호가 있으면 '등록 …', 없으면 '출원 …'; 대한민국이 아니면 국가명을 앞에 붙임.
  // 연도는 등록일, 없으면 출원일의 앞 4자리. 연도별로 묶고 그 안에서는 No. 큰 순서.
  function patentNumberText(p) {
    var t = p.registrationNo ? '등록 ' + p.registrationNo : '출원 ' + p.applicationNo;
    var n = String(p.nation || '대한민국').trim();
    return n === '대한민국' ? t : n + ' ' + t;
  }
  function patentYear(p) {
    return Number(String(p.registrationDate || p.applicationDate || '').trim().slice(0, 4)) || 0;
  }
  function sortPatents(list) {
    return list.map(function (p) { return Object.assign({}, p, { year: patentYear(p) }); })
      .sort(function (a, b) { return b.year - a.year || b.no - a.no; });
  }
  function patents(list) {
    return groupByYear(sortPatents(list)).map(function (g) {
      return '<div class="journal-item" data-year="' + esc(g.year) + '">\n' + g.items.map(function (p) {
        return '  <div class="animate-box" data-animate-effect="fadeInLeft">\n' +
          '    <div class="journals_box">\n' +
          '      <div class="number-box">' + esc(p.no) + '</div>\n' +
          '      <div class="tbox">\n' +
          '        <h4>' + richText(p.title) + ' <i>' + esc(patentNumberText(p)) + '</i>, <b>' + esc(p.year) + '</b></h4>\n' +
          '        <div class="smt">' + esc(p.name) + '</div>\n' +
          '      </div>\n' +
          '    </div>\n' +
          '  </div>\n';
      }).join('') + '</div>\n';
    }).join('');
  }

  // ---------- Members / Alumni (members info.xlsx, Alumni info.xlsx 와 같은 항목) ----------
  // 멤버: name, from, degree, email, photo  → 기간은 'from–present'
  // 졸업생: name, from, to, current, email, photo → 'Current - current' (비어 있으면 Unknown)
  // 구분(title) = 엑셀의 시트 이름. 졸업생은 최근 졸업자가 위에 오도록 저장(엑셀은 반대 순서).
  function sectionId(title) {
    return 'position-' + String(title).toLowerCase().trim().replace(/\s+/g, '-');
  }

  function people(sections, opts) {
    var folder = opts.alumni ? 'Alumni' : 'members';
    var col = opts.alumni ? 'col-sm-6' : 'col-md-2 col-sm-5';
    return sections.filter(function (s) { return s.people && s.people.length; }).map(function (s) {
      return '    <div class="fh5co-narrow-content" id="' + esc(sectionId(s.title)) + '">\n' +
        '        <h2 class="fh5co-heading animate-box" data-animate-effect="fadeInLeft">' + esc(s.title) + '</h2>\n' +
        '        <div class="row row-bottom-padded-md">\n' +
        s.people.map(function (m) {
          var photo = m.photo || 'blank_profile.png';
          var dir = m.photo ? folder : 'members';
          var b = baseName(photo);
          var note = opts.alumni ? 'Current - ' + (m.current || 'Unknown') : (m.degree || '');
          var period = opts.alumni ? (m.from || '') + '–' + (m.to || '') : (m.from || '') + '–present';
          return '            <div class="' + col + ' col-padding text-center animate-box p10 member-container">\n' +
            '                <div class="work g2 member-img" id="member-' + esc(b) + '" data-base-name="' + esc(b) + '" style="background-image: url(images/' + dir + '/' + esc(photo) + ');"></div>\n' +
            '                <div class="caption">\n' +
            '                    <div class="caption-top">\n' +
            '                        <h3>' + esc(m.name) + '</h3>\n' +
            '                        <span class="p4"> ' + esc(m.email) + ' <br> </span>\n' +
            '                        <span class="p6">' + esc(period) + '<br><br></span>\n' +
            '                    </div>\n' +
            '                    <div class="caption-bottom">\n' +
            '                        <span class="p11"> ' + esc(note) + ' <br></span>\n' +
            '                    </div>\n' +
            '                </div>\n' +
            '            </div>\n';
        }).join('') +
        '        </div>\n' +
        '    </div>\n';
    }).join('');
  }

  // ---------- Gallery (배열 순서대로, 같은 연도끼리 묶음) ----------
  function gallery(list) {
    return groupByYear(list).map(function (g) {
      return "    <h2 class='fh5co-heading animate-box' data-animate-effect='fadeInLeft'>" + esc(g.year) + '</h2>\n' +
        "    <div class='row row-bottom-padded-md'>\n" +
        g.items.map(function (x) {
          var b = baseName(x.file);
          return '        <div class="col-md-custom col-sm-6 col-padding text-center animate-box">\n' +
            '            <a href="images/gallery/' + esc(x.file) + '" data-toggle="lightbox" data-gallery="gallery"' + (x.caption ? ' data-title="' + esc(x.caption) + '"' : '') + '>\n' +
            '                <div class="work g1" id="Journal-' + esc(b) + '" data-base-name="' + esc(b) + '" style="background-image: url(images/gallery/' + esc(x.file) + ');"></div>\n' +
            '            </a>\n' +
            '            <div class="caption">\n' +
            '                <span class="p8"> ' + esc(x.caption) + '<br></span>\n' +
            '            </div>\n' +
            '        </div>\n';
        }).join('') +
        '    </div>\n';
    }).join('');
  }

  // ---------- 페이지에 끼워 넣기 ----------
  function replaceRegion(html, name, content) {
    var start = '<!-- ADMIN:' + name + ' -->';
    var end = '<!-- /ADMIN:' + name + ' -->';
    var i = html.indexOf(start), j = html.indexOf(end);
    if (i < 0 || j < i) throw new Error('페이지에서 표시(' + start + ')를 찾을 수 없습니다.');
    var nl = html.indexOf('\r\n') >= 0 ? '\r\n' : '\n';   // 파일의 줄바꿈 방식(Windows CRLF)을 그대로 따름
    return html.slice(0, i + start.length) + nl + content.replace(/\r?\n/g, nl) + html.slice(j);
  }

  // 데이터 종류 → 바꿔야 할 페이지와 영역
  var PAGES = {
    publications: { page: 'Publications.html', regions: { 'pub-years': yearOptions, 'publications': publications } },
    patents: { page: 'Patent.html', regions: { 'patent-years': function (d) { return yearOptions(sortPatents(d)); }, 'patents': patents } },
    members: { page: 'Members.html', regions: { 'members': function (d) { return people(d, { alumni: false }); } } },
    alumni: { page: 'Alumni.html', regions: { 'alumni': function (d) { return people(d, { alumni: true }); } } },
    gallery: { page: 'Gallery.html', regions: { 'gallery': gallery } }
  };

  function renderPage(kind, html, data) {
    var def = PAGES[kind];
    Object.keys(def.regions).forEach(function (r) {
      html = replaceRegion(html, r, def.regions[r](data));
    });
    return html;
  }

  var api = {
    PAGES: PAGES, renderPage: renderPage, replaceRegion: replaceRegion,
    publications: publications, patents: patents, people: people, gallery: gallery,
    yearOptions: yearOptions, citation: citation, sortPubs: sortPubs, esc: esc, plain: plain, richText: richText,
    doiUrl: doiUrl, patentNumberText: patentNumberText, patentYear: patentYear, sortPatents: sortPatents
  };
  if (typeof module !== 'undefined' && module.exports) module.exports = api;
  else root.ICLRender = api;
})(this);
