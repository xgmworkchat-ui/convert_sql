Markdown
# Role
너는 SQL 마이그레이션 도구 개발 전문가이자 Python 시니어 개발자야.

# Task
Sybase(T-SQL) 스크립트 파일을 읽어서 Oracle 19c ANSI 표준 SQL 파일로 변환하여 저장해주는 Python 프로그램을 작성해줘.

# Requirements
1. **File I/O**: 특정 디렉토리 내의 `.sql` 파일을 모두 읽거나, 특정 파일 경로를 입력받아 변환 후 `_oracle.sql` 접미사를 붙여 저장할 것.
2. **Regex-based Transformation**: 다음 주요 변환 규칙을 포함할 것:
   - **Outer Join**: `*=`, `=*` 구문을 찾아서 ANSI `LEFT/RIGHT OUTER JOIN` 구문으로 재구성 (가장 중요)
   - **Functions**: 
     - `ISNULL(` -> `NVL(`
     - `GETDATE()` -> `SYSDATE`
     - `SUBSTRING(` -> `SUBSTR(`
     - `CHARINDEX(` -> `INSTR(`
   - **Concatenation**: 문자열 결합 `+`를 Oracle의 `||`로 변경
   - **Data Types**: `DATETIME` -> `DATE`, `BIT` -> `NUMBER(1)`, `IMAGE` -> `BLOB` 등
   - **Dummy Table**: `FROM` 절이 없는 `SELECT` 문 뒤에 `FROM DUAL` 추가
3. **Log**: 변환된 내역(어떤 파일이 변환되었는지, 어떤 패턴이 수정되었는지)을 터미널에 출력할 것.

# Output Code Style
- Python의 `re` 모듈을 활용하여 패턴 매칭을 수행할 것.
- 코드는 유지보수가 쉽도록 변환 규칙을 딕셔너리나 클래스 형태로 분리할 것.
- 대용량 파일 처리를 고려하여 효율적으로 작성할 것.

# Instruction
먼저 프로그램의 전체 구조를 설명하고, 완성된 Python 코드를 제공해줘.