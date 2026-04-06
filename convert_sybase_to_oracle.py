"""
Sybase SQL -> Oracle 19c ANSI SQL 변환 스크립트
migration_guide.md 규칙 기반
"""

import re
import os
import sys
from pathlib import Path
from dataclasses import dataclass, field
from typing import Callable


# ─────────────────────────────────────────────
#  변환 규칙 정의
# ─────────────────────────────────────────────

@dataclass
class Rule:
    name: str
    pattern: str
    replacement: str | Callable
    flags: int = re.IGNORECASE


# 단순 regex 치환 규칙 목록
SIMPLE_RULES: list[Rule] = [

    # ── Functions ──────────────────────────────
    Rule("ISNULL -> NVL",
         r'\bISNULL\s*\(',
         'NVL('),

    Rule("GETDATE() -> SYSDATE",
         r'\bGETDATE\s*\(\s*\)',
         'SYSDATE'),

    Rule("SUBSTRING -> SUBSTR",
         r'\bSUBSTRING\s*\(',
         'SUBSTR('),

    Rule("CHARINDEX -> INSTR",
         r'\bCHARINDEX\s*\(',
         'INSTR('),

    # Sybase NOW(*) -> SYSDATE
    Rule("NOW(*) -> SYSDATE",
         r'\bNOW\s*\(\s*\*\s*\)',
         'SYSDATE'),

    # Sybase YEARS(date1, date2) 연 차이 -> TRUNC(MONTHS_BETWEEN()/12)
    Rule("YEARS() -> MONTHS_BETWEEN",
         r'\bYEARS\s*\(\s*DATE\s*\(([^,]+)\)\s*,\s*DATE\s*\(([^)]+)\)\s*\)',
         lambda m: f'TRUNC(MONTHS_BETWEEN(TO_DATE({m.group(2)}, \'YYYYMMDD\'), TO_DATE({m.group(1)}, \'YYYYMMDD\')) / 12)'),

    # Sybase MONTHS(date, n) -> ADD_MONTHS
    Rule("MONTHS(date, n) -> ADD_MONTHS",
         r'\bMONTHS\s*\(\s*(DATE\s*\([^,]+\))\s*,\s*(-?\d+)\s*\)',
         lambda m: f'ADD_MONTHS({m.group(1)}, {m.group(2)})'),

    # Sybase DATE('YYYYMMDD') -> TO_DATE(...)
    Rule("DATE('str') -> TO_DATE",
         r"\bDATE\s*\(\s*'([^']+)'\s*\)",
         lambda m: f"TO_DATE('{m.group(1)}', 'YYYYMMDD')"),

    # Sybase DATEFORMAT(date, fmt) -> TO_CHAR(date, fmt)
    Rule("DATEFORMAT -> TO_CHAR",
         r"\bDATEFORMAT\s*\(\s*(.*?)\s*,\s*'([^']+)'\s*\)",
         lambda m: f"TO_CHAR({m.group(1)}, '{m.group(2)}')"),

    # ── Data Types ─────────────────────────────
    Rule("DATETIME -> DATE",
         r'\bDATETIME\b',
         'DATE'),

    Rule("BIT -> NUMBER(1)",
         r'\bBIT\b',
         'NUMBER(1)'),

    Rule("IMAGE -> BLOB",
         r'\bIMAGE\b',
         'BLOB'),

    Rule("TEXT -> CLOB",
         r'\bTEXT\b(?!\s+\w+\s*=)',   # TEXT 타입만 (주석 내 TEXT 제외 어려우므로 단어 경계 사용)
         'CLOB'),

    Rule("NUMERIC -> NUMBER",
         r'\bNUMERIC\s*\(([^)]+)\)',
         lambda m: f'NUMBER({m.group(1)})'),

    # ── Sybase-specific Syntax ─────────────────
    # @@ROWCOUNT -> SQL%ROWCOUNT  (DML 직후 별도 선언 필요 → 주석 추가)
    Rule("@@ROWCOUNT -> SQL%ROWCOUNT",
         r'@@ROWCOUNT',
         'SQL%ROWCOUNT'),

    Rule("@@rowcount -> SQL%ROWCOUNT",
         r'@@rowcount',
         'SQL%ROWCOUNT'),

    # TRUNCATE TABLE t -> TRUNCATE TABLE t  (Oracle 동일, 단 세미콜론 필요)
    # 이미 호환 가능 – 별도 변환 불필요

    # SET var = ... (Sybase 변수 할당) -> 주석으로 표시
    # Oracle 에서는 PL/SQL 블록 내에서 := 을 사용해야 함
    Rule("SET var= -> := (PL/SQL)",
         r'^\s*SET\s+(\w+)\s*=\s*',
         lambda m: f'    {m.group(1)} := ',
         re.IGNORECASE | re.MULTILINE),

    # LOAD TABLE ... FROM ... -> Oracle SQL*Loader 또는 외부 테이블로 대체 (주석)
    Rule("LOAD TABLE -> /* LOAD TABLE: use SQL*Loader */",
         r'(LOAD\s+TABLE\b[^\n]*(?:\n(?!\n)[^\n]*)*)',
         lambda m: f'/* [TODO] Oracle에서는 SQL*Loader 또는 외부 테이블로 대체하세요:\n{m.group(1)}\n*/',
         re.IGNORECASE | re.DOTALL),

    # Sybase FROM 절 없는 SELECT ... -> SELECT ... FROM DUAL
    # (아래 별도 함수로 처리)

    # ── UPDATE FROM 구문 ────────────────────────
    # Sybase: UPDATE t SET ... FROM t1, t2 WHERE ...
    # Oracle: UPDATE (subquery) SET ... 또는 MERGE
    # 복잡하므로 TODO 주석 삽입
    Rule("UPDATE ... FROM -> TODO MERGE",
         r'(UPDATE\s+\w[\w.]*\s*\n?\s*SET\s+.*?FROM\s+\w[\w.]*)',
         lambda m: f'/* [TODO] Oracle은 UPDATE-FROM 미지원. MERGE 또는 서브쿼리로 변환 필요:\n   {m.group(1)}\n*/',
         re.IGNORECASE | re.DOTALL),

    # ── String concatenation ────────────────────
    # '...' + '...' -> '...' || '...'   (문자열 리터럴 +)
    Rule("string + -> ||",
         r"(?<=')\s*\+\s*(?=')",
         ' || '),
]


# ─────────────────────────────────────────────
#  복잡한 변환: Outer Join  *=  =*  → ANSI JOIN
# ─────────────────────────────────────────────

def _split_by_top_level_and(text: str) -> list[str]:
    """WHERE 본문을 최상위 AND로 분리 (괄호 안은 무시)."""
    parts: list[str] = []
    depth = 0
    buf: list[str] = []
    i = 0
    up = text.upper()
    while i < len(text):
        ch = text[i]
        if ch == '(':
            depth += 1
            buf.append(ch); i += 1
        elif ch == ')':
            depth -= 1
            buf.append(ch); i += 1
        elif depth == 0 and up[i:i+3] == 'AND' and \
                (i == 0 or text[i-1] in ' \t\n\r') and \
                (i+3 >= len(text) or text[i+3] in ' \t\n\r'):
            parts.append(''.join(buf).strip())
            buf = []
            i += 3
            while i < len(text) and text[i] in ' \t\n\r':
                i += 1
        else:
            buf.append(ch); i += 1
    tail = ''.join(buf).strip()
    if tail:
        parts.append(tail)
    return [p for p in parts if p]


def _parse_table_refs(from_text: str) -> list[tuple[str, str]]:
    """
    FROM 절 텍스트에서 (full_name, alias) 리스트를 파싱한다.
    예: "DM.월개인본인 A ,DM.카드이용 B" -> [("DM.월개인본인","A"), ("DM.카드이용","B")]
    """
    refs: list[tuple[str, str]] = []
    # -- 주석 행 제거 후 파싱
    from_text = re.sub(r'--[^\n]*', '', from_text)
    # 최상위 콤마로 분리 (서브쿼리 안 콤마 제외)
    parts: list[str] = []
    depth = 0
    buf: list[str] = []
    for ch in from_text:
        if ch == '(':
            depth += 1; buf.append(ch)
        elif ch == ')':
            depth -= 1; buf.append(ch)
        elif ch == ',' and depth == 0:
            parts.append(''.join(buf).strip()); buf = []
        else:
            buf.append(ch)
    if buf:
        parts.append(''.join(buf).strip())

    for part in parts:
        part = re.sub(r'\s+', ' ', part).strip()
        tokens = part.split()
        if not tokens:
            continue
        full_name = tokens[0]
        # 마지막 토큰이 AS가 아니고 키워드가 아닌 경우 alias
        if len(tokens) >= 2 and tokens[-1].upper() not in ('ON', 'SET', 'WHERE'):
            alias = tokens[-1] if tokens[-2].upper() != 'AS' else tokens[-1]
        else:
            alias = full_name.split('.')[-1]
        refs.append((full_name, alias))
    return refs


def _alias_of(col_ref: str) -> str:
    """'T1.column_name' → 'T1'  /  'column_name' → ''"""
    if '.' in col_ref:
        return col_ref.split('.')[0]
    return ''


def _build_ansi_from(
    table_refs: list[tuple[str, str]],
    oj_groups: dict[tuple[str, str], dict],
) -> str:
    """
    table_refs : [(full_name, alias), ...]
    oj_groups  : {(outer_alias_upper, inner_alias_upper): {type, on_parts}}
    → ANSI JOIN 텍스트 반환
    """
    alias_map = {alias.upper(): (full, alias) for full, alias in table_refs}

    def table_str(alias_upper: str) -> str:
        if alias_upper in alias_map:
            full, al = alias_map[alias_upper]
            return f"{full} {al}" if full.upper() != al.upper() else full
        return alias_upper

    joined: list[str] = []
    used: set[str] = set()

    # 시작 테이블: 첫 번째 outer join의 outer(보존) 테이블
    if oj_groups:
        first_key = next(iter(oj_groups))
        start = first_key[0]  # outer alias
    else:
        start = table_refs[0][1].upper() if table_refs else ''

    joined.append(table_str(start))
    used.add(start)

    # outer join 순서대로 JOIN 절 생성
    for (outer_al, inner_al), info in oj_groups.items():
        join_type = info['type']
        on_parts  = info['on_parts']
        on_expr   = '\n           AND '.join(on_parts)

        # 아직 추가 안 된 테이블 결정
        if outer_al not in used and inner_al in used:
            # outer 쪽이 아직 없음 → 방향 반전
            join_type = 'RIGHT OUTER JOIN' if join_type == 'LEFT OUTER JOIN' else 'LEFT OUTER JOIN'
            new_table = outer_al
        else:
            new_table = inner_al

        joined.append(f"{join_type} {table_str(new_table)}\n           ON {on_expr}")
        used.add(outer_al)
        used.add(inner_al)

    # outer join에 포함되지 않은 나머지 테이블 → INNER JOIN으로 추가
    for full, alias in table_refs:
        if alias.upper() not in used:
            joined.append(f"INNER JOIN {table_str(alias.upper())}\n           ON /* [TODO] 조인 조건을 입력하세요 */")
            used.add(alias.upper())

    indent = '\n        '
    return indent.join(joined)


def _convert_outer_joins(sql: str) -> tuple[str, int]:
    """
    Sybase WHERE 절의 *=, =* 을 ANSI LEFT/RIGHT OUTER JOIN 으로 변환한다.

    변환 전:
        FROM DM.월개인본인 A
            ,DM.카드이용   B
        WHERE A.고객번호 *= B.고객번호
          AND A.기준년월 *= B.기준년월
          AND A.유효여부 = 1

    변환 후:
        FROM DM.월개인본인 A
        LEFT OUTER JOIN DM.카드이용 B
           ON A.고객번호 = B.고객번호
           AND A.기준년월 = B.기준년월
        WHERE A.유효여부 = 1
    """
    total = 0

    # FROM이 줄 맨 앞(공백 허용)에서만 시작하도록 MULTILINE + ^ 사용
    # → "--  FROM ..." 같은 주석 행은 매칭되지 않음
    block_re = re.compile(
        r'^([ \t]*FROM[ \t]*\n?)'          # group 1: 줄 첫 FROM (MULTILINE)
        r'((?:(?!\bWHERE\b|\bSELECT\b)'
        r'(?!\bGROUP\b)(?!\bORDER\b).)+?)' # group 2: 테이블 목록
        r'(\s*\bWHERE\b\s+)'               # group 3: WHERE 키워드
        r'(.*?)'                            # group 4: 조건절
        r'(?=\s*(?:;|\bGROUP\b|\bORDER\b|\bHAVING\b|\bUNION\b'
        r'|\bCOMMIT\b|\bINSERT\b|\bUPDATE\b|\bDELETE\b|\Z))',
        re.IGNORECASE | re.DOTALL | re.MULTILINE,
    )

    def _do_transform(from_kw: str, from_text: str,
                      where_kw: str, where_body: str) -> tuple[str, int]:
        """FROM/WHERE 블록 하나를 ANSI JOIN 으로 변환. (변환문, 변환수) 반환."""
        if not re.search(r'\*=|=\*', where_body):
            return from_kw + from_text + where_kw + where_body, 0

        table_refs = _parse_table_refs(from_text)
        conditions = _split_by_top_level_and(where_body)

        oj_groups: dict[tuple[str, str], dict] = {}
        regular: list[str] = []

        for cond in conditions:
            c = cond.strip()
            m_left  = re.match(r'([\w.]+)\s*\*=\s*([\w.]+)\s*$', c)
            m_right = re.match(r'([\w.]+)\s*=\*\s*([\w.]+)\s*$', c)

            if m_left:
                lhs, rhs = m_left.group(1), m_left.group(2)
                outer_al = _alias_of(lhs).upper() or lhs.upper()
                inner_al = _alias_of(rhs).upper() or rhs.upper()
                key = (outer_al, inner_al)
                if key not in oj_groups:
                    oj_groups[key] = {'type': 'LEFT OUTER JOIN', 'on_parts': []}
                oj_groups[key]['on_parts'].append(f"{lhs} = {rhs}")

            elif m_right:
                lhs, rhs = m_right.group(1), m_right.group(2)
                outer_al = _alias_of(rhs).upper() or rhs.upper()
                inner_al = _alias_of(lhs).upper() or lhs.upper()
                key = (outer_al, inner_al)
                if key not in oj_groups:
                    oj_groups[key] = {'type': 'LEFT OUTER JOIN', 'on_parts': []}
                oj_groups[key]['on_parts'].append(f"{rhs} = {lhs}")

            else:
                regular.append(c)

        if not oj_groups:
            return from_kw + from_text + where_kw + where_body, 0

        n = sum(len(v['on_parts']) for v in oj_groups.values())
        new_from  = _build_ansi_from(table_refs, oj_groups)
        new_where = ('\n  AND '.join(regular)) if regular else '/* [TODO] WHERE 조건 없음 */'
        return from_kw + new_from + where_kw + new_where, n

    # re.finditer 로 매칭 후 수동 치환 (주석 행 FROM 은 MULTILINE ^ 로 차단)
    result: list[str] = []
    last_end = 0
    for m in block_re.finditer(sql):
        transformed, n = _do_transform(
            m.group(1), m.group(2), m.group(3), m.group(4)
        )
        result.append(sql[last_end: m.start()])
        result.append(transformed)
        last_end = m.end()
        total += n

    result.append(sql[last_end:])
    sql = ''.join(result)
    return sql, total


# ─────────────────────────────────────────────
#  복잡한 변환: FROM 절 없는 SELECT -> FROM DUAL
# ─────────────────────────────────────────────

def _add_from_dual(sql: str) -> tuple[str, int]:
    """
    FROM 절이 없는 SELECT 문 뒤에 FROM DUAL 을 추가한다.
    예: SELECT 1+1, SYSDATE  ->  SELECT 1+1, SYSDATE FROM DUAL
    """
    count = 0
    lines = sql.splitlines()
    result = []
    i = 0
    while i < len(lines):
        line = lines[i]
        stripped = line.strip().upper()
        # 단독 SELECT로 시작하고 FROM이 없는 단일행 SELECT
        if re.match(r'^\s*SELECT\b', line, re.IGNORECASE):
            # 해당 SELECT 블록에 FROM이 있는지 확인 (다음 WHERE/GROUP/ORDER/; 전까지)
            block = [line]
            j = i + 1
            while j < len(lines):
                next_line = lines[j].strip().upper()
                if re.match(r'^(WHERE|GROUP|ORDER|HAVING|UNION|EXCEPT|INTERSECT|INSERT|UPDATE|DELETE|--|/\*)', next_line):
                    break
                if lines[j].strip().endswith(';'):
                    block.append(lines[j])
                    j += 1
                    break
                block.append(lines[j])
                j += 1

            block_text = '\n'.join(block)
            has_from = bool(re.search(r'\bFROM\b', block_text, re.IGNORECASE))
            if not has_from and len(block) == 1 and re.search(r'\bSELECT\b.+', line, re.IGNORECASE):
                # 단일 행 SELECT에 FROM 없음
                line = line.rstrip().rstrip(';') + ' FROM DUAL;'
                count += 1
            result.append(line)
            i += 1
            continue

        result.append(line)
        i += 1

    return '\n'.join(result), count


# ─────────────────────────────────────────────
#  메인 변환 함수
# ─────────────────────────────────────────────

@dataclass
class ConversionResult:
    filename: str
    applied_rules: list[str] = field(default_factory=list)
    warnings: list[str] = field(default_factory=list)


def convert_sql(sql: str, filename: str = "") -> tuple[str, ConversionResult]:
    result = ConversionResult(filename=filename)

    # 1. Outer Join 변환 (가장 먼저)
    sql, oj_count = _convert_outer_joins(sql)
    if oj_count:
        result.applied_rules.append(f"Outer Join (*=, =*): {oj_count}건 → ANSI LEFT/RIGHT OUTER JOIN 변환")

    # 2. Simple regex 규칙 적용
    for rule in SIMPLE_RULES:
        flags = rule.flags
        try:
            new_sql, n = re.subn(rule.pattern, rule.replacement, sql, flags=flags)
        except Exception as e:
            result.warnings.append(f"규칙 '{rule.name}' 오류: {e}")
            continue
        if n:
            result.applied_rules.append(f"{rule.name}: {n}건")
            sql = new_sql

    # 3. FROM DUAL 추가
    sql, dual_count = _add_from_dual(sql)
    if dual_count:
        result.applied_rules.append(f"FROM DUAL 추가: {dual_count}건")

    return sql, result


# ─────────────────────────────────────────────
#  파일 처리
# ─────────────────────────────────────────────

SOURCE_ENCODINGS = ['utf-8', 'ms949', 'cp949', 'euc-kr']


def read_sql_file(path: Path) -> tuple[str, str]:
    """파일을 읽고 (내용, 사용된_인코딩)을 반환."""
    for enc in SOURCE_ENCODINGS:
        try:
            return path.read_text(encoding=enc, errors='strict'), enc
        except (UnicodeDecodeError, LookupError):
            continue
    # 최후 수단: 오류 문자 대체
    content = path.read_text(encoding='ms949', errors='replace')
    return content, 'ms949(errors=replace)'


def process_file(input_path: Path, output_dir: Path) -> ConversionResult:
    sql, enc = read_sql_file(input_path)
    converted, result = convert_sql(sql, filename=input_path.name)

    output_path = output_dir / (input_path.stem + '_oracle.sql')
    output_path.write_text(converted, encoding='utf-8')

    result.applied_rules.insert(0, f"인코딩: {enc} → UTF-8 저장")
    return result


def process_directory(input_dir: Path, output_dir: Path) -> list[ConversionResult]:
    sql_files = sorted(input_dir.glob('*.sql'))
    if not sql_files:
        print(f"[경고] {input_dir} 에 .sql 파일이 없습니다.")
        return []

    output_dir.mkdir(parents=True, exist_ok=True)
    results = []
    for f in sql_files:
        print(f"\n{'='*60}")
        print(f"[>>] 처리 중: {f.name}")
        r = process_file(f, output_dir)
        results.append(r)
        _print_result(r)
    return results


def _print_result(r: ConversionResult) -> None:
    if r.applied_rules:
        print("  [변환 내역]")
        for rule in r.applied_rules:
            print(f"    [OK] {rule}")
    else:
        print("  [변환 내역] 없음")
    if r.warnings:
        print("  [경고]")
        for w in r.warnings:
            print(f"    {w}")


# ─────────────────────────────────────────────
#  CLI 진입점
# ─────────────────────────────────────────────

def main() -> None:
    args = sys.argv[1:]

    # 기본 경로
    script_dir = Path(__file__).parent
    default_input  = script_dir / 'input_sql'
    default_output = script_dir / 'output_sql'

    if not args:
        # 인자 없음 → 기본 디렉토리 일괄 변환
        print(f"입력 디렉토리: {default_input}")
        print(f"출력 디렉토리: {default_output}")
        results = process_directory(default_input, default_output)

    elif len(args) == 1:
        p = Path(args[0])
        if p.is_dir():
            results = process_directory(p, default_output)
        elif p.is_file() and p.suffix.lower() == '.sql':
            default_output.mkdir(parents=True, exist_ok=True)
            r = process_file(p, default_output)
            results = [r]
            _print_result(r)
        else:
            print(f"[오류] 유효한 .sql 파일 또는 디렉토리를 지정하세요: {p}")
            sys.exit(1)

    elif len(args) == 2:
        input_path  = Path(args[0])
        output_path = Path(args[1])
        if input_path.is_dir():
            results = process_directory(input_path, output_path)
        else:
            output_path.mkdir(parents=True, exist_ok=True)
            r = process_file(input_path, output_path)
            results = [r]
            _print_result(r)

    else:
        print("사용법:")
        print("  python convert_sybase_to_oracle.py                          # input_sql/ 전체 변환")
        print("  python convert_sybase_to_oracle.py <file.sql>               # 단일 파일 변환")
        print("  python convert_sybase_to_oracle.py <input_dir> <output_dir> # 디렉토리 지정")
        sys.exit(1)

    # 최종 요약
    print(f"\n{'='*60}")
    print(f"[완료] {len(results)}개 파일 처리")
    total_rules = sum(len(r.applied_rules) for r in results)
    total_warns = sum(len(r.warnings) for r in results)
    print(f"   총 변환 항목: {total_rules}건 / 수동 검토 필요: {total_warns}건")
    print(f"   출력 위치: {default_output if len(args) < 2 else Path(args[-1])}")


if __name__ == '__main__':
    main()
