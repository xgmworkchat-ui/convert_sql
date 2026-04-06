/*----------------------------------------------------------------------------------------------------------*/
/*  프로그램ID    : ACSAC월개인CA이용SCORE01.sql                                                              */
/*  프로그램명    : 월개인CA이용SCORE 적재(변경적재)                                                        */
/*  최초  작성    : 2005-02-21   이소영                                                                     */
/*  최종  변경    : 2004-04-15   강진호                                                                     */
/*  Declare       :                                                                                        */
/*                                                                                                          */
/*  SOURCE table  : DM.월개인본인회원실적 ,DM.월개인회원정보, DM.월개인본인회원실적,DM.월복수카드이용실적,  */
/*                  DM.월회원가맹점실적,DM.월회원채널이용실적,DW.현금서비스확정,DM.일개인회원모집결과정보,  */
/*                  DW.개별입금,CRM.월개인당사이용패턴,CRM.월개인타사이용패턴,DM.월은행연합회대출채무보증정보 */                  
/*  TARGET table  :                                                                                         */
/*  LOCAL TEMP    : WRK.TM_월개인CA이용SCORE                                                                */
/*  Physical TEMP :                                                                                         */
/*  참조TABLE     : set temporary option Divide_by_zero_error = 'Off'                                      */
/*                                                                                                          */
/*  변경이력                                                                                                */
/*   1) 0000-00-00                                                                                          */
/*----------------------------------------------------------------------------------------------------------*/
-- 일정기간동안 모두 값이 없어야만 NOT 4+이다
------------------------------------------------------------------------------------------------------
--   STEP 1.
--     1) 월개인회원실적 테이블전체를 모수로 함
--        적재대상년월 & 정상회원여부 = 1 & 입회경과차월 > 2 & 리스크등급  IN ( 1~7급) & 연속무실적개월수_CA_12개월 > 1   
--        월복수카드이용실적 테이블의 기준년월 = 적재대상년월 -1 & 이용카드사수_CA < 3   


--   1차 수정 : 2005/04/15 : 고객번호에서 주민번호로 join
------------------------------------------------------------------------------------------------------
--CALL SP_DMJOB ('월개인CA','S');  --1 
  
        TRUNCATE TABLE WRK.TM_월개인CA이용SCORE ;
      
        SET delete_cnt=@@rowcount;
      
        COMMIT;
        
        
-- 4+ 회원 먼저 200404/ 1034523명

  INSERT INTO WRK.TM_월개인CA이용SCORE
  (       
           기준년월                          
          ,고객번호                                               
    ,주민번호                                  
    ,정상회원여부                                             
    ,입회경과차월                          
    ,Score_CASC                          
    ,target여부_CASC                           
    ,Rank_CASC                           
    ,이용건수_CA2_CASC                   
    ,이용건수_CA3_CASC                   
    ,이용건수_CA4_CASC                                             
    ,성별연령대_CASC                                              
    ,ECI개인근로소득_CASC                                        
    ,청구서발송방법_CASC                                       
    ,RP이용회원여부                                             
    ,리스크등급                                                  
    ,사용기준VIP                                                   
    ,최종카드발급후경과월_당사_CASC                             
    ,최초카드발급후경과월_당타사                                   
    ,최종매출후경과월_CA_CASC          
    ,가입후대출여부                                            
    ,대출여부_당타사_6개월                                         
    ,대출잔여개월여부                                          
    ,카드한도소진율_최대값_6개월_CASC                          
    ,카드한도금액증감패턴_CA_6개월_CASC                     
    ,무보증한도증감패턴_3개월_CASC                              
    ,매출평균_할부_6개월_CASC                             
    ,유흥매출비율_6개월_CASC                                           
    ,은행계이용비율_CA_5개월                   
                ,SOW_CA_5개월_CASC                   
    ,이용개월수_CA_당타사_5개월_CASC                                  
    ,이용개월수_CA_6개월_CASC                             
    ,연속이용개월수_CA_당타사_5개월_CASC                           
    ,연속유실적개월수_기본_CASC                             
    ,연속무실적개월수_CA_12개월                             
    ,연속무실적개월수_신판_CASC                             
    ,최대연속증가개월수_할부_6개월_CASC                     
    ,이용카드사수_CA                                              
    ,이용카드사수_신판_CASC                                     
    ,최대이용카드사수_CA_5개월_CASC                             
    ,주사용카드_당사_신판_5개월_CASC                              
    ,최종CA강제연체대체월                                     
    ,최종CA정상대체월                                           
    ,최종CA한도조회일                  
    ,ARS인터넷_30만원이하CA이용여부_6개월                         
    ,상담경험여부_3개월                  
    ,한도ARS_최종상담일                    
    ,CA한도외_최종상담일                                 
    ,CRM적재일시                           
  )                                        
  SELECT  
           A.기준년월                                           AS  기준년월                                                                                   
          ,A.주민번호                                           AS  주민번호
    ,A.주민번호                                           AS  주민번호                                                                                   
    ,A.정상회원여부                                       AS  정상회원여부                                                                                        
    ,A.입회경과차월                                       AS  입회경과차월                                                                                   
    ,0                                                    AS  Score_CASC                                                                                   
    ,0                                                    AS  target여부_CASC                                                                          
    ,0                                                    AS  Rank_CASC                                                                                  
    ,0                                                    AS  이용건수_CA2_CASC                                                                                
    ,0                                                    AS  이용건수_CA3_CASC                                                                                
    ,0                                                    AS  이용건수_CA4_CASC                                                                          
    ,CASE WHEN A.연령코드 = 'ZZ' THEN 'ZZ'
                WHEN A.성별코드 = '2' THEN 'FZ'
                WHEN CAST(A.성별코드 AS INT)=1  AND CAST(SUBSTR(A.주민번호,1,1) AS INT) >= 1  AND YEARS(DATE('19'||SUBSTR(A.주민번호,1,6) ),DATE(EDW_기준년월||'01')) + 1    <= 30 THEN 'M1'
                WHEN CAST(A.성별코드 AS INT)=1  AND CAST(SUBSTR(A.주민번호,1,1) AS INT) >= 1  AND YEARS(DATE('19'||SUBSTR(A.주민번호,1,6) ),DATE(EDW_기준년월||'01')) + 1    <= 40 THEN 'M2'    
                WHEN CAST(A.성별코드 AS INT)=1  AND CAST(SUBSTR(A.주민번호,1,1) AS INT) >= 1  AND YEARS(DATE('19'||SUBSTR(A.주민번호,1,6) ),DATE(EDW_기준년월||'01')) + 1     > 40 THEN 'M3'                    
          ELSE 'ZZ'
    END                                                   AS  성별연령대_CASC                                                                               
    ,'Z'                                                  AS  ECI개인근로소득_CASC                                                                                   
    ,'Z'                                                  AS  청구서발송방법_CASC                                                                                
    ,'0'                                                  AS  RP이용회원여부                                                                                
    ,SUBSTR(A.리스크등급, 1,2)                            AS  리스크등급                                                                                             
    ,'Z'                                                  AS  사용기준VIP                                                                                            
    ,'Z'                                                  AS  최종카드발급후경과월_당사_CASC                                                           
    ,0                                                    AS  최초카드발급후경과월_당타사                                                                  
    ,'Z'                                                  AS  최종매출후경과월_CA_CASC                                                                             
    ,CASE WHEN A.이용여부_정상론_일반론 = 1                                                                   
      OR A.이용여부_정상론_소액론 = 1 THEN 1                                                           
          ELSE 0 END                                  AS  가입후대출여부                                     
    ,0                                                    AS  대출여부_당타사_6개월                                                                            
    ,0                                                    AS  대출잔여개월여부                                                                                     
    ,'Z'                                                  AS  카드한도소진율_최대값_6개월_CASC                                                                
    ,'N'                                                  AS  카드한도금액증감패턴_CA_6개월_CASC                                                                
    ,'N'                                                  AS  무보증한도증감패턴_3개월_CASC                                                                       
    ,'Z'                                                  AS  매출평균_할부_6개월_CASC                                                                             
    ,'0'                                                  AS  유흥매출비율_6개월_CASC                                                                   
    ,9.9999                                               AS  은행계이용비율_CA_5개월                                                                         
    ,'N'                                                  AS  SOW_CA_5개월_CASC                                                                               
    ,'0'                                                  AS  이용개월수_CA_당타사_5개월_CASC                                                               
    ,'Z'                                                  AS  이용개월수_CA_6개월_CASC                                                                             
    ,'N'                                                  AS  연속이용개월수_CA_당타사_5개월_CASC                                                               
    ,CASE WHEN A.연속유실적개월수_기본_12개월 = 0                                                                    
          THEN '0'  ELSE '1' END                          AS  연속유실적개월수_기본_CASC                                        
    ,ISNULL(A.연속무실적개월수_CA_12개월 ,0)              AS  연속무실적개월수_CA_12개월                                           
    ,'0'                                                  AS  연속무실적개월수_신판_CASC                                                                   
    ,0                                                    AS  최대연속증가개월수_할부_6개월_CASC                                                                
    ,ISNULL(B.이용카드사수_CA ,0)                         AS  이용카드사수_CA                                                               
    ,CASE WHEN B.이용카드사수_신판 <= 0 THEN '0'
          WHEN B.이용카드사수_신판 <= 1 THEN '1'
          WHEN B.이용카드사수_신판 <= 2 THEN '2'
          WHEN B.이용카드사수_신판 <= 3 THEN '3'
          WHEN B.이용카드사수_신판 <= 4 THEN '4'
          WHEN B.이용카드사수_신판 <= 5 THEN '5' 
          WHEN B.이용카드사수_신판  > 5 THEN '6'    
          ELSE 'E' END                                    AS  이용카드사수_신판_CASC                                                                        
    ,'N'                                                  AS  최대이용카드사수_CA_5개월_CASC                                                                
    ,'N'                                                  AS  주사용카드_당사_신판_5개월_CASC                                                               
    ,'999999'                                             AS  최종CA강제연체대체월                                                                                
    ,'999999'                                             AS  최종CA정상대체월                                                                                      
    ,DATE('06060606')                                     AS  최종CA한도조회일                                                                           
    ,0                                                    AS  ARS인터넷_30만원이하CA이용여부_6개월                                                                    
    ,0                                                    AS  상담경험여부_3개월                                                                             
    ,DATE('06060606')                                     AS  한도ARS_최종상담일                                                                           
    ,DATE('06060606')                                     AS  CA한도외_최종상담일                                                                          
    ,NOW(*)                                               AS  CR적재일시                                                                           
    FROM  DM.월개인본인회원실적 A           
         ,DM.월복수카드이용실적 B          
   WHERE A.기준년월 = EDW_기준년월
     AND A.기준년월 = B.기준년월            
           AND A.주민번호 = B.주민번호
           AND A.정상회원여부 = 1 
           AND A.입회경과차월 > 2
           AND A.리스크등급  IN ('01','02','03','04','05','06','07')             
           AND A.연속무실적개월수_CA_12개월 > 1    
          -- AND B.당사회원여부_제공년월 = 1
           AND B.주민번호 <> ' ' 
           AND B.이용카드사수_CA < 3 
           AND A.성별코드  IN ('1','2') ;
   
   
--INSERT건수
  SET insert_cnt = @@ROWCOUNT ;
  
  COMMIT ;
  

 
 -- 4- 회원   : 200404/ 243804 명

  INSERT INTO WRK.TM_월개인CA이용SCORE
  (       
           기준년월                          
          ,고객번호                                               
    ,주민번호                                  
    ,정상회원여부                                             
    ,입회경과차월                          
    ,Score_CASC                          
    ,target여부_CASC                           
    ,Rank_CASC                           
    ,이용건수_CA2_CASC                   
    ,이용건수_CA3_CASC                   
    ,이용건수_CA4_CASC                                             
    ,성별연령대_CASC                                              
    ,ECI개인근로소득_CASC                                        
    ,청구서발송방법_CASC                                       
    ,RP이용회원여부                                             
    ,리스크등급                                                  
    ,사용기준VIP                                                   
    ,최종카드발급후경과월_당사_CASC                             
    ,최초카드발급후경과월_당타사                                   
    ,최종매출후경과월_CA_CASC          
    ,가입후대출여부                                            
    ,대출여부_당타사_6개월                                         
    ,대출잔여개월여부                                          
    ,카드한도소진율_최대값_6개월_CASC                          
    ,카드한도금액증감패턴_CA_6개월_CASC                     
    ,무보증한도증감패턴_3개월_CASC                              
    ,매출평균_할부_6개월_CASC                             
    ,유흥매출비율_6개월_CASC                                           
    ,은행계이용비율_CA_5개월                   
                ,SOW_CA_5개월_CASC                   
    ,이용개월수_CA_당타사_5개월_CASC                                  
    ,이용개월수_CA_6개월_CASC                             
    ,연속이용개월수_CA_당타사_5개월_CASC                           
    ,연속유실적개월수_기본_CASC                             
    ,연속무실적개월수_CA_12개월                             
    ,연속무실적개월수_신판_CASC                             
    ,최대연속증가개월수_할부_6개월_CASC                     
    ,이용카드사수_CA                                              
    ,이용카드사수_신판_CASC                                     
    ,최대이용카드사수_CA_5개월_CASC                             
    ,주사용카드_당사_신판_5개월_CASC                              
    ,최종CA강제연체대체월                                     
    ,최종CA정상대체월                                           
    ,최종CA한도조회일                  
    ,ARS인터넷_30만원이하CA이용여부_6개월                         
    ,상담경험여부_3개월                  
    ,한도ARS_최종상담일                    
    ,CA한도외_최종상담일                                 
    ,CRM적재일시            
  )    
                                            
  SELECT  
           C.기준년월                                  AS  기준년월                         
          ,C.고객번호                                  AS  고객번호                             
    ,C.주민번호                                  AS  주민번호                         
    ,C.정상회원여부                                  AS  정상회원여부                         
    ,C.입회경과차월                                  AS  입회경과차월                         
    ,C.Score_CASC                                  AS  Score_CASC                         
    ,C.target여부_CASC                           AS  target여부_CASC                               
    ,C.Rank_CASC                                   AS  Rank_CASC                          
    ,C.이용건수_CA2_CASC                           AS  이용건수_CA2_CASC                  
    ,C.이용건수_CA3_CASC                           AS  이용건수_CA3_CASC                  
    ,C.이용건수_CA4_CASC                           AS  이용건수_CA4_CASC                  
    ,C.성별연령대_CASC                           AS  성별연령대_CASC                                    
    ,C.ECI개인근로소득_CASC                          AS  ECI개인근로소득_CASC                             
    ,C.청구서발송방법_CASC                           AS  청구서발송방법_CASC                             
    ,C.RP이용회원여부                          AS  RP이용회원여부                         
    ,C.리스크등급                                  AS  리스크등급                         
    ,C.사용기준VIP                                   AS  사용기준VIP                          
    ,C.최종카드발급후경과월_당사_CASC          AS  최종카드발급후경과월_당사_CASC         
    ,C.최초카드발급후경과월_당타사                   AS  최초카드발급후경과월_당타사          
    ,C.최종매출후경과월_CA_CASC                  AS  최종매출후경과월_CA_CASC         
    ,C.가입후대출여부                          AS  가입후대출여부                         
    ,C.대출여부_당타사_6개월                   AS  대출여부_당타사_6개월                      
    ,C.대출잔여개월여부                          AS  대출잔여개월여부                 
    ,C.카드한도소진율_최대값_6개월_CASC          AS  카드한도소진율_최대값_6개월_CASC 
    ,C.카드한도금액증감패턴_CA_6개월_CASC          AS  카드한도금액증감패턴_CA_6개월_CASC 
    ,C.무보증한도증감패턴_3개월_CASC           AS  무보증한도증감패턴_3개월_CASC          
    ,C.매출평균_할부_6개월_CASC                  AS  매출평균_할부_6개월_CASC         
    ,C.유흥매출비율_6개월_CASC                   AS  유흥매출비율_6개월_CASC                      
    ,C.은행계이용비율_CA_5개월                   AS  은행계이용비율_CA_5개월                  
    ,C.SOW_CA_5개월_CASC                           AS  SOW_CA_5개월_CASC                  
    ,C.이용개월수_CA_당타사_5개월_CASC           AS  이용개월수_CA_당타사_5개월_CASC          
    ,C.이용개월수_CA_6개월_CASC                  AS  이용개월수_CA_6개월_CASC         
    ,C.연속이용개월수_CA_당타사_5개월_CASC           AS  연속이용개월수_CA_당타사_5개월_CASC  
    ,C.연속유실적개월수_기본_CASC                  AS  연속유실적개월수_기본_CASC         
    ,C.연속무실적개월수_CA_12개월                  AS  연속무실적개월수_CA_12개월         
    ,C.연속무실적개월수_신판_CASC                  AS  연속무실적개월수_신판_CASC         
    ,C.최대연속증가개월수_할부_6개월_CASC          AS  최대연속증가개월수_할부_6개월_CASC 
    ,C.이용카드사수_CA                           AS  이용카드사수_CA                          
    ,C.이용카드사수_신판_CASC                  AS  이용카드사수_신판_CASC                 
    ,C.최대이용카드사수_CA_5개월_CASC          AS  최대이용카드사수_CA_5개월_CASC         
    ,C.주사용카드_당사_신판_5개월_CASC           AS  주사용카드_당사_신판_5개월_CASC          
    ,C.최종CA강제연체대체월                          AS  최종CA강제연체대체월                 
    ,C.최종CA정상대체월                          AS  최종CA정상대체월                 
    ,C.최종CA한도조회일                          AS  최종CA한도조회일                 
    ,C.ARS인터넷_30만원이하CA이용여부_6개월          AS  ARS인터넷_30만원이하CA이용여부_6개월 
    ,C.상담경험여부_3개월                          AS  상담경험여부_3개월                 
    ,C.한도ARS_최종상담일                          AS  한도ARS_최종상담일                 
    ,C.CA한도외_최종상담일                           AS  CA한도외_최종상담일                  
    ,C.CRM적재일시                                   AS  CRM적재일시                          
    FROM (
         SELECT    B.고객번호                                           AS  B_고객번호
                  ,A.기준년월                                           AS  기준년월                                                                                   
            ,A.고객번호                                           AS  고객번호                                                                                               
      ,A.주민번호                                           AS  주민번호                                                                                   
      ,A.정상회원여부                                       AS  정상회원여부                                                                                        
      ,A.입회경과차월                                       AS  입회경과차월                                                                                   
      ,0                                                    AS  Score_CASC                                                                                   
      ,0                                                    AS  target여부_CASC                                                                          
      ,0                                                    AS  Rank_CASC                                                                                  
      ,0                                                    AS  이용건수_CA2_CASC                                                                                
      ,0                                                    AS  이용건수_CA3_CASC                                                                                
      ,0                                                    AS  이용건수_CA4_CASC                                                                          
            ,CASE WHEN A.연령코드 = 'ZZ' THEN 'ZZ'
                        WHEN A.성별코드 = '2' THEN 'FZ'
                        WHEN CAST(A.성별코드 AS INT)=1  AND CAST(SUBSTR(A.주민번호,1,1) AS INT) >= 1  AND YEARS(DATE('19'||SUBSTR(A.주민번호,1,6) ), DATE(EDW_기준년월||'01')) + 1    <= 30 THEN 'M1'
                        WHEN CAST(A.성별코드 AS INT)=1  AND CAST(SUBSTR(A.주민번호,1,1) AS INT) >= 1  AND YEARS(DATE('19'||SUBSTR(A.주민번호,1,6) ), DATE(EDW_기준년월||'01')) + 1    <= 40 THEN 'M2'    
                        WHEN CAST(A.성별코드 AS INT)=1  AND CAST(SUBSTR(A.주민번호,1,1) AS INT) >= 1  AND YEARS(DATE('19'||SUBSTR(A.주민번호,1,6) ), DATE(EDW_기준년월||'01')) + 1     > 40 THEN 'M3'                    
                  ELSE 'ZZ'
            END                                                   AS  성별연령대_CASC                                                                                          
      ,'Z'                                                  AS  ECI개인근로소득_CASC                                                                                   
      ,'Z'                                                  AS  청구서발송방법_CASC                                                                                
      ,'0'                                                  AS  RP이용회원여부                                                                                
      ,SUBSTR(A.리스크등급,1,2)                             AS  리스크등급                                                                                             
      ,'Z'                                                  AS  사용기준VIP                                                                                            
      ,'Z'                                                  AS  최종카드발급후경과월_당사_CASC                                                           
      ,0                                                    AS  최초카드발급후경과월_당타사                                                                  
      ,'Z'                                                  AS  최종매출후경과월_CA_CASC                                                                             
      ,CASE WHEN A.이용여부_정상론_일반론 = 1                                                                   
        OR A.이용여부_정상론_소액론 = 1 THEN 1                                                           
            ELSE 0 END                                  AS  가입후대출여부                                     
      ,0                                                    AS  대출여부_당타사_6개월                                                                            
      ,0                                                    AS  대출잔여개월여부                                                                                     
      ,'N'                                                  AS  카드한도소진율_최대값_6개월_CASC                                                                
      ,'N'                                                  AS  카드한도금액증감패턴_CA_6개월_CASC                                                                
      ,'N'                                                  AS  무보증한도증감패턴_3개월_CASC                                                                       
      ,'Z'                                                  AS  매출평균_할부_6개월_CASC                                                                             
      ,'0'                                                  AS  유흥매출비율_6개월_CASC                                                                   
      ,9.9999                                               AS  은행계이용비율_CA_5개월                                                                         
      ,'N'                                                  AS  SOW_CA_5개월_CASC                                                                               
      ,'N'                                                  AS  이용개월수_CA_당타사_5개월_CASC                                                               
      ,'N'                                                  AS  이용개월수_CA_6개월_CASC                                                                             
      ,'N'                                                  AS  연속이용개월수_CA_당타사_5개월_CASC                                                               
      ,CASE WHEN A.연속유실적개월수_기본_12개월 = 0                                                                    
            THEN '0'  ELSE '1' END                          AS  연속유실적개월수_기본_CASC                                        
      ,ISNULL(A.연속무실적개월수_CA_12개월, 0)              AS  연속무실적개월수_CA_12개월                                           
      ,'0'                                                  AS  연속무실적개월수_신판_CASC                                                                   
      ,0                                                    AS  최대연속증가개월수_할부_6개월_CASC                                                                
      ,ISNULL(B.이용카드사수_CA ,0)                         AS  이용카드사수_CA                                                               
      ,'N'                                                  AS  이용카드사수_신판_CASC                                                                        
      ,'N'                                                  AS  최대이용카드사수_CA_5개월_CASC                                                                
      ,'Z'                                                  AS  주사용카드_당사_신판_5개월_CASC                                                               
      ,'999999'                                             AS  최종CA강제연체대체월                                                                                
      ,'999999'                                             AS  최종CA정상대체월                                                                                      
      ,DATE('06060606')                                     AS  최종CA한도조회일                                                                           
      ,0                                                    AS  ARS인터넷_30만원이하CA이용여부_6개월                                                                    
      ,0                                                    AS  상담경험여부_3개월                                                                             
      ,DATE('06060606')                                     AS  한도ARS_최종상담일                                                                           
      ,DATE('06060606')                                     AS  CA한도외_최종상담일                                                                          
      ,NOW(*)                                               AS  CRM적재일시 
 
         --    FROM DM.월개인본인회원실적 A LEFT OUTER JOIN  DM.월복수카드이용실적  B
         --         ON A.고객번호 = B.고객번호    
             FROM DM.월개인본인회원실적 A 
                  ,DM.월복수카드이용실적 B                         
            WHERE A.고객번호 *= B.고객번호
              AND A.기준년월 *= B.기준년월 
              AND A.기준년월 = EDW_기준년월   
              AND A.정상회원여부 = 1 
              AND A.입회경과차월 > 2
              AND A.리스크등급 IN ('01','02','03','04','05','06','07')             
              AND A.연속무실적개월수_CA_12개월 > 1 
              AND B.당사회원여부_제공년월 = 1
              AND B.고객번호 <> ' '
              AND A.성별코드 IN ('1','2')     
                ) C
         WHERE C.B_고객번호 IS NULL  ;     
  COMMIT;
  
  

--2

------------------------------------------------------------------------------------------------------
--   STEP 1.
--     1) 월개인본인회원실적 TABLE에서  카드한도금액증감패턴_CA_6개월_CASC,매출평균_할부_6개월_CASC
--                                     ,카드한도소진율_최대값_6개월_CASC,무보증한도증감패턴_3개월_CASC  column을 update한다.  
------------------------------------------------------------------------------------------------------

  UPDATE WRK.TM_월개인CA이용SCORE 
     SET A.매출평균_할부_6개월_CASC = CASE WHEN  B.매출평균_할부_6개월_CASC = 0       THEN '0'
             WHEN  B.매출평균_할부_6개월_CASC <= 20000  THEN '1' 
             WHEN  B.매출평균_할부_6개월_CASC <= 100000 THEN '2' 
             WHEN  B.매출평균_할부_6개월_CASC <= 200000 THEN '3'
             WHEN  B.매출평균_할부_6개월_CASC <= 500000 THEN '4'
             WHEN  B.매출평균_할부_6개월_CASC >  500000 THEN '5'
             ELSE  '9'
                                            END
               ,A.카드한도소진율_최대값_6개월_CASC = B.카드한도소진율_최대값_6개월_CASC                            
    FROM WRK.TM_월개인CA이용SCORE A,  
         (          
          SELECT 고객번호                
                 ,AVG(이용금액_개인본인_할부)                                 AS 매출평균_할부_6개월_CASC
                 ,CASE WHEN SUM(카드한도금액) = 0  THEN 'N'
                       WHEN SUM(이용금액_개인본인_기본) = 0  THEN '0'
                       WHEN SUM(이용금액_개인본인_기본) <> 0 AND SUM(카드한도금액) <> 0 AND 
                            MAX(이용금액_개인본인_기본*100 / CASE WHEN 카드한도금액= 0 THEN 1 ELSE 카드한도금액  END  )  = 0  THEN '0'
                       WHEN MAX(이용금액_개인본인_기본*100 / CASE WHEN 카드한도금액= 0 THEN 1 ELSE 카드한도금액  END  ) <= 3  THEN '1'
                       WHEN MAX(이용금액_개인본인_기본*100 / CASE WHEN 카드한도금액= 0 THEN 1 ELSE 카드한도금액  END  ) <= 5  THEN '2'
                       WHEN MAX(이용금액_개인본인_기본*100 / CASE WHEN 카드한도금액= 0 THEN 1 ELSE 카드한도금액  END  ) <= 10 THEN '3'
                       WHEN MAX(이용금액_개인본인_기본*100 / CASE WHEN 카드한도금액= 0 THEN 1 ELSE 카드한도금액  END  ) <= 15 THEN '4'
                       WHEN MAX(이용금액_개인본인_기본*100 / CASE WHEN 카드한도금액= 0 THEN 1 ELSE 카드한도금액  END  ) <= 30 THEN '5'
                       WHEN MAX(이용금액_개인본인_기본*100 / CASE WHEN 카드한도금액= 0 THEN 1 ELSE 카드한도금액  END  )  > 30 THEN '6'
                       ELSE   '9'        
                  END                                                   AS 카드한도소진율_최대값_6개월_CASC                
            FROM DM.월개인본인회원실적 
           WHERE 기준년월  BETWEEN  EDW_5개월전월  AND  EDW_기준년월   
           GROUP BY 고객번호
         ) B  
  WHERE A.고객번호 = B.고객번호 ;  
    
  COMMIT;
  
---------카드한도금액증감패턴_CA_6개월_CASC ----------------- 
  
  UPDATE WRK.TM_월개인CA이용SCORE 
     SET  A.카드한도금액증감패턴_CA_6개월_CASC = CASE WHEN CAST(B.변경전한도 AS INT) = CAST(B.변경후한도 AS INT) THEN '1'
                  WHEN CAST(B.변경전한도 AS INT) > CAST(B.변경후한도 AS INT) THEN '0'
                  WHEN CAST(B.변경전한도 AS INT) < CAST(B.변경후한도 AS INT) THEN '2'
                  ELSE 'Z'
                   END 
         FROM  WRK.TM_월개인CA이용SCORE A,
              (
     SELECT 본인고객번호
            ,SUBSTR(MIN(DATEFORMAT(한도시작일자,'YYYYMMDD')||변경전한도금액),9)     AS 변경전한도
        ,SUBSTR(MAX(DATEFORMAT(한도시작일자,'YYYYMMDD')||변경후한도금액),9)     AS 변경후한도
       FROM  DW.회원한도변경이력                      
      WHERE  DATEFORMAT(변경일시,'YYYYMMDD') BETWEEN EDW_5개월전월||'01'  AND  EDW_말일
        AND 한도구분코드 = '13'          
           GROUP BY  본인고객번호
    ) B
    WHERE A.고객번호 = B.본인고객번호 ;                    
    
    COMMIT;                    
  
      
--------------------  
  
  UPDATE WRK.TM_월개인CA이용SCORE 
     SET  A.무보증한도증감패턴_3개월_CASC = CASE WHEN CAST(B.변경전한도 AS INT) = CAST(B.변경후한도 AS INT) THEN '1'
                   WHEN CAST(B.변경전한도 AS INT) > CAST(B.변경후한도 AS INT) THEN '0'
                   WHEN CAST(B.변경전한도 AS INT) < CAST(B.변경후한도 AS INT) THEN '2'
                   ELSE 'Z'
              END 
         FROM  WRK.TM_월개인CA이용SCORE A,
              (
     SELECT 본인고객번호
            ,SUBSTR(MIN(DATEFORMAT(한도시작일자,'YYYYMMDD')||변경전한도금액),9)     AS 변경전한도
        ,SUBSTR(MAX(DATEFORMAT(한도시작일자,'YYYYMMDD')||변경후한도금액),9)     AS 변경후한도
       FROM  DW.회원한도변경이력                      
      WHERE  DATEFORMAT(변경일시,'YYYYMMDD')  BETWEEN EDW_2개월전월||'01'  AND  EDW_말일
        AND 한도구분코드 = '21'          
           GROUP BY  본인고객번호
    ) B
    WHERE A.고객번호 = B.본인고객번호 ;                    
    
    COMMIT; 

------------     

--  UPDATE WRK.TM_월개인CA이용SCORE 
--     SET A.무보증한도증감패턴_3개월_CASC = CASE WHEN B.최대값 = B.최소값                THEN 'N'
--                  WHEN B.한도금액_3월전 = B.당월한도금액  THEN '1'
--                  WHEN B.한도금액_3월전 > B.당월한도금액  THEN '0'
--                  WHEN B.한도금액_3월전 < B.당월한도금액  THEN '2'
--                  ELSE '9'
--             END 
--    FROM WRK.TM_월개인CA이용SCORE A,  
--         (          
--          SELECT 고객번호
--                 ,MAX(여신한도금액_무보증한도_소액론)                      AS 최대값
--                 ,MIN(여신한도금액_무보증한도_소액론)                      AS 최소값
--                 ,SUBSTR(MIN(기준년월||여신한도금액_무보증한도_소액론),7)  AS 한도금액_3월전
--                 ,SUBSTR(MAX(기준년월||여신한도금액_무보증한도_소액론),7)  AS 당월한도금액
--            FROM DM.월개인본인회원실적 
--           WHERE 기준년월  BETWEEN  EDW_2개월전월  AND  EDW_기준년월   
--        GROUP BY 고객번호
--         ) B  
--  WHERE A.고객번호 = B.고객번호 ;
--    
--  COMMIT;    
--
--


------------------------------------------------------------------------------------------------------
--   STEP 2.
--     1) 월복수카드이용실적  TABLE에서 SOW_CA_5개월_CASC,최대이용카드사수_CA_5개월_CASC,column을 update한다
--                                      은행계이용비율_CA_5개월            



--   1차 수정 : 2005/04/15 : 고객번호에서 주민번호로 join
------------------------------------------------------------------------------------------------------


        UPDATE WRK.TM_월개인CA이용SCORE 
     SET A.SOW_CA_5개월_CASC              = B.SOW_CA_5개월_CASC 
        ,A.최대이용카드사수_CA_5개월_CASC = B.최대이용카드사수_CA_5개월_CASC 
        ,A.은행계이용비율_CA_5개월        = B.은행계이용비율_CA_5개월    
          FROM WRK.TM_월개인CA이용SCORE  A, 
          (SELECT 주민번호, max(고객번호) as 고객번호
                        ,CASE WHEN SUM(이용금액_CA_당사) <> 0 AND SUM(이용금액_CA)  = 0  THEN 'E' 
                  WHEN SUM(이용금액_CA_당사)  = 0 AND SUM(이용금액_CA)  = 0  THEN '0'
                  WHEN SUM(이용금액_CA_당사)  = 0 AND SUM(이용금액_CA) <> 0  THEN '1'
                  WHEN SUM(이용금액_CA_당사)*100 / SUM(이용금액_CA) <= 25    THEN '2'
                  WHEN SUM(이용금액_CA_당사)*100 / SUM(이용금액_CA) <= 50    THEN '3'
                  WHEN SUM(이용금액_CA_당사)*100 / SUM(이용금액_CA) <= 75    THEN '4'
                  WHEN SUM(이용금액_CA_당사)*100 / SUM(이용금액_CA) <= 100   THEN '5'
                  ELSE '9'
                  
             END                                                       AS   SOW_CA_5개월_CASC 
            ,CASE WHEN MAX(이용카드사수_CA)  = 0 THEN '0'
                  WHEN MAX(이용카드사수_CA) <= 1 THEN '1'
                  WHEN MAX(이용카드사수_CA) <= 2 THEN '2'
                  WHEN MAX(이용카드사수_CA) <= 3 THEN '3'
                  WHEN MAX(이용카드사수_CA) <= 4 THEN '4'
                  WHEN MAX(이용카드사수_CA) <= 5 THEN '5'
                  WHEN MAX(이용카드사수_CA)  > 5 THEN '6'
                  ELSE '9'
             END                                                       AS   최대이용카드사수_CA_5개월_CASC 
                  ,CASE WHEN SUM(이용금액_CA) = 0 THEN 0 
                 ELSE  SUM(이용금액_CA_국민+이용금액_CA_외환+
                           이용금액_CA_신한+이용금액_CA_비씨+
                           이용금액_CA_기타)*100/SUM(이용금액_CA)           
             END                                                       AS   은행계이용비율_CA_5개월                                                               
                   FROM DM.월복수카드이용실적
                  WHERE 기준년월  BETWEEN  EDW_4개월전월  AND  EDW_기준년월
                 --   AND 당사회원여부_제공년월 = 1
                    AND 주민번호 <> ' '
               GROUP BY 주민번호
          ) B
         WHERE A.고객번호 = B.고객번호 ;
     
         COMMIT;
      

------------------------------------------------------------------------------------------------------
--   STEP 3.
--     1) 월개인당사패턴   TABLE에서 이용개월수_CA_6개월_CASC  column을 update한다
--
------------------------------------------------------------------------------------------------------


  
  UPDATE WRK.TM_월개인CA이용SCORE 
     SET A.이용개월수_CA_6개월_CASC =   CASE WHEN B.이용개월수_CA_6개월 = 0 THEN '0'
                                             WHEN B.이용개월수_CA_6개월 = 1 THEN '1'
                                             WHEN B.이용개월수_CA_6개월 = 2 THEN '2'
                                             WHEN B.이용개월수_CA_6개월 = 3 THEN '3'
                                             WHEN B.이용개월수_CA_6개월 > 4 THEN '4'  
                                             ELSE '9'    
                                        END         
    FROM WRK.TM_월개인CA이용SCORE A
         ,ACRM.월개인당사이용패턴 B
   WHERE A.고객번호 = B.고객번호
     AND B.기준년월 = EDW_기준년월 ;      
    
  COMMIT;     



------------------------------------------------------------------------------------------------------
--   STEP 4.
--     1) 월복수카드이용실적   TABLE에서 이용개월수_CA_당타사_5개월_CASC ,
--                                       연속이용개월수_CA_당타사_5개월_CASC  column을 update한다
--
--   1차 수정 : 2005/04/15 : 고객번호에서 주민번호로 join
------------------------------------------------------------------------------------------------------
  
        
        UPDATE WRK.TM_월개인CA이용SCORE 
     SET A.이용개월수_CA_당타사_5개월_CASC   = B.이용개월수_CA_당타사_5개월_CASC       
          FROM WRK.TM_월개인CA이용SCORE  A, 
          (  SELECT 주민번호, max(고객번호) as 고객번호                                 
                    ,CASE WHEN COUNT(이용금액_CA) = 1 THEN '1'
                          WHEN COUNT(이용금액_CA) = 2 THEN '2'
                          WHEN COUNT(이용금액_CA) = 3 THEN '3'
                          WHEN COUNT(이용금액_CA) = 4 THEN '4'
                          WHEN COUNT(이용금액_CA) = 5 THEN '5'             
                          ELSE '9'
                     END                                             AS 이용개월수_CA_당타사_5개월_CASC                      
         FROM DM.월복수카드이용실적            
              WHERE 기준년월  BETWEEN  EDW_4개월전월  AND  EDW_기준년월
              --  AND 당사회원여부_제공년월 = 1
                AND 주민번호 <> ' '
                AND 이용금액_CA > 0
                 GROUP BY 주민번호
          ) B
         WHERE A.고객번호 = B.고객번호 ;
     
         COMMIT;
      

  
--------- 연속이용개월수_CA_당타사_5개월_CASC -----------
        
--   1차 수정 : 2005/04/15 : 고객번호에서 주민번호로 join
               
                    
        TRUNCATE TABLE TEMPACRM_연속이용개월수_5개월_CA;  
  COMMIT; 

  INSERT INTO TEMPACRM_연속이용개월수_5개월_CA
       SELECT 주민번호, max(고객번호) as 고객번호           
        ,SUM(CASE WHEN 기준년월 = EDW_4개월전월   AND  이용금액_CA > 0 THEN 1 ELSE 0 END)||
         SUM(CASE WHEN 기준년월 = EDW_3개월전월   AND  이용금액_CA > 0 THEN 1 ELSE 0 END)||
         SUM(CASE WHEN 기준년월 = EDW_2개월전월   AND  이용금액_CA > 0 THEN 1 ELSE 0 END)||
         SUM(CASE WHEN 기준년월 = EDW_전월        AND  이용금액_CA > 0 THEN 1 ELSE 0 END)||
         SUM(CASE WHEN 기준년월 = EDW_기준년월    AND  이용금액_CA > 0 THEN 1 ELSE 0 END) AS  연속이용개월수_CA_당타사          
           FROM  DM.월복수카드이용실적
          WHERE  기준년월  BETWEEN  EDW_4개월전월  AND  EDW_기준년월
         --   AND 당사회원여부_제공년월 = 1
          AND 주민번호 <> ' '
           GROUP BY 주민번호 ;         
  
  COMMIT;
    
    
  UPDATE WRK.TM_월개인CA이용SCORE
     SET A.연속이용개월수_CA_당타사_5개월_CASC  = CASE WHEN SUBSTR(B.연속이용개월수_CA_당타사,0) = '11111' THEN '5'
                                                   WHEN SUBSTR(B.연속이용개월수_CA_당타사,0) = '01111' THEN '4'
                                                   WHEN SUBSTR(B.연속이용개월수_CA_당타사,2) = '0111' THEN '3'
                                                   WHEN SUBSTR(B.연속이용개월수_CA_당타사,3) = '011' THEN '2'
                                                   WHEN SUBSTR(B.연속이용개월수_CA_당타사,4) = '01' THEN '1'
                                                   ELSE '0'
                                                  END                                                                                 
    FROM  WRK.TM_월개인CA이용SCORE          A
         ,TEMPACRM_연속이용개월수_5개월_CA  B
   WHERE A.고객번호 = B.고객번호 ;
  
   COMMIT;            

--3 
------------------------------------------------------------------------------------------------------
--   STEP 6.
--     1) 월개인회원정보 TABLE에서  최종카드발급후경과월_CASC ,최종매출후경과월_CA_CASC,사용기준VIP  
--                                 ,ECI게인근로소득_CASC,RP이용회원여부,최초카드발급후경과월_당타사, column을 update한다
------------------------------------------------------------------------------------------------------
  
  UPDATE WRK.TM_월개인CA이용SCORE 
     SET  A.최종카드발급후경과월_당사_CASC =  CASE WHEN 최종카드발급년월 IN ('060606','050505') THEN  'E'   
                                                   WHEN MONTHS(DATE(B.최종카드발급년월||'01') , DATE(EDW_기준년월||'01'))  = 0   THEN '0'
                                                   WHEN MONTHS(DATE(B.최종카드발급년월||'01') , DATE(EDW_기준년월||'01')) <= 5   THEN '1'
                                                   WHEN MONTHS(DATE(B.최종카드발급년월||'01') , DATE(EDW_기준년월||'01')) <= 11  THEN '2'
                                                   WHEN MONTHS(DATE(B.최종카드발급년월||'01') , DATE(EDW_기준년월||'01')) <= 17  THEN '3'
                                                   WHEN MONTHS(DATE(B.최종카드발급년월||'01') , DATE(EDW_기준년월||'01'))  > 17  THEN '4'
                                                   ELSE '9'
                                               END      
         ,A.최종매출후경과월_CA_CASC  =  CASE WHEN 최종이용일자_CA IN ('0606-06-06','0505-05-05') THEN  '0'   
                      WHEN MONTHS(B.최종이용일자_CA , DATE(EDW_기준년월||'01') )  = 0   THEN '1'                                              
                                              WHEN MONTHS(B.최종이용일자_CA , DATE(EDW_기준년월||'01') ) <= 3   THEN '2'
                                              WHEN MONTHS(B.최종이용일자_CA , DATE(EDW_기준년월||'01') ) <= 6   THEN '3'
                                              WHEN MONTHS(B.최종이용일자_CA , DATE(EDW_기준년월||'01') ) <= 12  THEN '4'
                                              WHEN MONTHS(B.최종이용일자_CA , DATE(EDW_기준년월||'01') ) <= 18  THEN '5'
                                              WHEN MONTHS(B.최종이용일자_CA , DATE(EDW_기준년월||'01') )  > 18  THEN '6'
                                              ELSE '9'
                                         END      
         ,A.사용기준VIP               =  CASE WHEN B.VIP고객구분코드 IN ('1','2') THEN '1' ELSE '0' END   
         ,A.ECI개인근로소득_CASC      =  CASE WHEN B.ECI_추정개인근로소득  = 0    THEN 'N'
                                              WHEN B.ECI_추정개인근로소득 <= 1500 THEN '1'
                                              WHEN B.ECI_추정개인근로소득 <= 4000 THEN '2'
                                              WHEN B.ECI_추정개인근로소득  > 4000 THEN '3'
                                              ELSE '9'
                                         END  
         ,A.RP이용회원여부              =  CASE WHEN B. RP이용회원여부 = 1 THEN '1' ELSE '0' END 
         ,A.최초카드발급후경과월_당타사 =  CASE WHEN B.전카드사최초발급일자 IN ('0606-06-06','0505-05-05') THEN  99999                                                
                                                      ELSE  MONTHS(B.전카드사최초발급일자 , DATE(EDW_기준년월||'01'))
                                                 END 
    FROM WRK.TM_월개인CA이용SCORE A,  
         DM.월개인회원정보 B
   WHERE A.고객번호 = B.고객번호
     AND B.기준년월 = EDW_기준년월 ;   
  
  COMMIT; 
  
  

------------------------------------------------------------------------------------------------------
--   STEP 9.
--     1)  DM.월회원가맹점실적 TABLE에서 유흥매출비율_6개월_CASC column을 update한다
--                                
------------------------------------------------------------------------------------------------------

  UPDATE WRK.TM_월개인CA이용SCORE 
     SET  A.유흥매출비율_6개월_CASC = CASE WHEN B.신판유흥건수 = 0 THEN '1' 
                                           WHEN B.신판유흥건수 *100 / B.유흥전체건수  <= 1  THEN '2' 
                                           WHEN B.신판유흥건수 *100 / B.유흥전체건수  <= 5  THEN '3' 
                                           WHEN B.신판유흥건수 *100 / B.유흥전체건수  <= 10 THEN '4' 
                                           WHEN B.신판유흥건수 *100 / B.유흥전체건수  <= 30 THEN '5' 
                                           WHEN B.신판유흥건수 *100 / B.유흥전체건수  > 30  THEN '6' 
                                           ELSE 'E'
                                      END       
    FROM WRK.TM_월개인CA이용SCORE A,
               (
    SELECT  T1.본인회원고객번호         AS 고객번호
           ,T1.전체건수                 AS 유흥전체건수
           ,T2.유흥건수                 AS 신판유흥건수
      FROM( 
      SELECT 본인회원고객번호 
             ,COUNT(*)            AS 전체건수
        FROM DM.월회원가맹점실적
       WHERE 기준년월  BETWEEN  EDW_5개월전월  AND  EDW_기준년월
         AND 이용건수_신판_국내 > 0 
          GROUP BY 본인회원고객번호
            ) T1    
           ,( 
      SELECT 본인회원고객번호 
             ,COUNT(*)            AS 유흥건수
        FROM DM.월회원가맹점실적
       WHERE 기준년월  BETWEEN  EDW_5개월전월  AND  EDW_기준년월
         AND 가맹점업종코드  IN ('3106','3201','3202','3203','2217','2218','4207')
         AND 이용건수_신판_국내 > 0 
          GROUP BY 본인회원고객번호
            ) T2            
     WHERE T1.본인회원고객번호 = T2.본인회원고객번호       
    
                ) B
       WHERE A.고객번호 = B.고객번호
   AND A.기준년월 = EDW_기준년월 ;         
 
 
------------------------------------------------------------------------------------------------------
--   STEP 9.
--     1) 월개인본인회원실적 TABLE에서 이용건수_CA_M2후,이용건수_CA_M3후,이용건수_CA_M4후  column을 update한다
--(변경 2005/04/14)  WRK.TM_월개인CA이용SCORE 이아닌 ACRM.월개인CA이용SCOR를 UPDATE해야할듯
------------------------------------------------------------------------------------------------------
    
  
  UPDATE ACRM.월개인CA이용SCORE
     SET A.이용건수_CA2_CASC = ISNULL(B.이용건수_개인본인_CA,0),
         A.target여부_CASC = 
         CASE WHEN ISNULL(B.이용건수_개인본인_CA,0) + A.이용건수_CA3_CASC + A.이용건수_CA4_CASC > 0
         THEN 1 ELSE 0 END
    FROM ACRM.월개인CA이용SCORE A LEFT OUTER JOIN 
         DM.월개인본인회원실적 B
      ON A.고객번호 = B.고객번호
     AND B.기준년월 = EDW_기준년월
   WHERE A.기준년월 = DATEFORMAT(MONTHS(DATE(EDW_기준년월||'01'),-2),'YYYYMM')
   ;
  
  COMMIT;
  
  UPDATE ACRM.월개인CA이용SCORE
     SET A.이용건수_CA3_CASC = ISNULL(B.이용건수_개인본인_CA,0),
         A.target여부_CASC = 
         CASE WHEN ISNULL(B.이용건수_개인본인_CA,0) + A.이용건수_CA2_CASC + A.이용건수_CA4_CASC > 0
         THEN 1 ELSE 0 END
    FROM ACRM.월개인CA이용SCORE A LEFT OUTER JOIN 
         DM.월개인본인회원실적 B
      ON A.고객번호 = B.고객번호
     AND B.기준년월 = EDW_기준년월
   WHERE A.기준년월 = DATEFORMAT(MONTHS(DATE(EDW_기준년월||'01'),-3),'YYYYMM')
   ;
  
  COMMIT;
  
  UPDATE ACRM.월개인CA이용SCORE
     SET A.이용건수_CA4_CASC = B.이용건수_개인본인_CA,
         A.target여부_CASC = 
         CASE WHEN ISNULL(B.이용건수_개인본인_CA,0) + A.이용건수_CA2_CASC + A.이용건수_CA3_CASC > 0
         THEN 1 ELSE 0 END
    FROM ACRM.월개인CA이용SCORE A LEFT OUTER JOIN 
         DM.월개인본인회원실적 B
      ON A.고객번호 = B.고객번호
     AND B.기준년월 = EDW_기준년월
   WHERE A.기준년월 = DATEFORMAT(MONTHS(DATE(EDW_기준년월||'01'),-4),'YYYYMM')
   ;
  
  COMMIT;
       

------------------------------------------------------------------------------------------------------
--   STEP 9.
--     1) 주사용카드_당사_신판_5개월_CASC  column을 update한다
--     
--
--   1차 수정 : 2005/04/15 : 고객번호에서 주민번호로 join                  
------------------------------------------------------------------------------------------------------

--마지막달 당사신판SOW가 최대이고
--이전 4개월 중 연속 3개월 이상 동일한 타사 신판SOW가 최대인 경우 
--주카드가 당사로 변경된 회원으로 정의함
--당사변경회원=1,당사미변경회원=0

/* 로직변경(2005/04/07) 4개월중 연속3개월-> 4개월중 3개월 */


  TRUNCATE TABLE TEMPACRM_결측_5개월_02_CA; 
  COMMIT;   

/* 마지막달 당사신판SOW가 최대 */
        INSERT INTO TEMPACRM_결측_5개월_02_CA
        (  
           주민번호, 고객번호,
           TMP
         )   
      SELECT 주민번호, 고객번호,
             '0'
        FROM DM.월복수카드이용실적 
       WHERE 기준년월 = EDW_기준년월
  /*       AND 당사회원여부_제공년월 = 1  */
         AND 주민번호 <> ' '
         AND 신판1순위카드사_당월 = '1200';
         
        COMMIT; 

/* 이전 4개월중 3개월 타사 신판SOW가 최대 */

        UPDATE TEMPACRM_결측_5개월_02_CA
           SET A.TMP = '1'
          FROM TEMPACRM_결측_5개월_02_CA A,
               (
                SELECT 주민번호, MAX(고객번호) AS 고객번호
                       ,신판1순위카드사_당월
                       ,COUNT(*) 건수
                  FROM DM.월복수카드이용실적 
                 WHERE 기준년월  BETWEEN EDW_4개월전월  AND EDW_전월
                /*  AND 당사회원여부_제공년월 = 1  */
                    AND 주민번호 <> ' '
                   AND 신판1순위카드사_당월 NOT IN ('1200','ZZZZ')
                 GROUP BY 주민번호, 신판1순위카드사_당월
                 HAVING 건수 >= 3
               ) B
         WHERE A.고객번호 = B.고객번호;

        COMMIT;        


        UPDATE WRK.TM_월개인CA이용SCORE
           SET A.주사용카드_당사_신판_5개월_CASC = B.TMP
          FROM WRK.TM_월개인CA이용SCORE A,
               TEMPACRM_결측_5개월_02_CA B
         WHERE A.고객번호 = B.고객번호; 
         
         COMMIT;       
         
/*2005/04/07 추가*/
--   1차 수정 : 2005/04/15 : 고객번호에서 주민번호로 join

/* 4+ 이고 변경이 아니면 0 */
        UPDATE WRK.TM_월개인CA이용SCORE
           SET A.주사용카드_당사_신판_5개월_CASC = '0'
          FROM WRK.TM_월개인CA이용SCORE A,
               DM.월복수카드이용실적 B
         WHERE A.주민번호 = B.주민번호
          AND  B.기준년월  BETWEEN EDW_4개월전월  AND EDW_전월
          AND  A.주사용카드_당사_신판_5개월_CASC <> '1' ;
          
         COMMIT;       

------------------------------------------------------------------------------------------------------
--   STEP 9.
--     1) 청구서발송방법코드_CASC column을 update한다
--                        
------------------------------------------------------------------------------------------------------
/* 2005/04/08 수정 DM.일개인회원모집결과정보 기초자료가 '20050301'*/

    UPDATE WRK.TM_월개인CA이용SCORE
       SET A.청구서발송방법_CASC = CASE WHEN B.청구서발송방법코드  IN ('02','03','04') THEN '1'
                                        WHEN B.청구서발송방법코드  IN ('01','05')      THEN '2'
                                        ELSE '3'
                                  END     
      FROM WRK.TM_월개인CA이용SCORE   A,
           DM.일개인회원모집결과정보  B
     WHERE A.고객번호 = B.본인회원고객번호
             AND B.기준일자 = (CASE WHEN EDW_당월말일 > '20050301' THEN DATE(EDW_당월말일) 
                               ELSE DATE('2005-03-01') END) ;


  COMMIT;
------------------------------------------------------------------------------------------------------
--   STEP 9.
--     1) 최대연속증가개월수_할부_6개월_CASC  : 금액기준     column을 update한다         
------------------------------------------------------------------------------------------------------
  
    TRUNCATE TABLE TEMPACRM_최대연속증감개월수_6개월_CA;
    COMMIT;
    
    
    INSERT INTO TEMPACRM_최대연속증감개월수_6개월_CA
          SELECT  고객번호
                  ,CASE WHEN A.M4 > A.M5 THEN 1 ELSE 0 END AS M4
            ,CASE WHEN A.M3 > A.M4 THEN 1 ELSE 0 END AS M3
            ,CASE WHEN A.M2 > A.M3 THEN 1 ELSE 0 END AS M2
            ,CASE WHEN A.M1 > A.M2 THEN 1 ELSE 0 END AS M1
            ,CASE WHEN A.M0 > A.M1 THEN 1 ELSE 0 END AS M0
             FROM 
                  (SELECT 고객번호 
                          ,SUM(CASE WHEN 기준년월 = EDW_5개월전월  THEN 이용금액_개인본인_할부  ELSE 0 END) AS M5 
                          ,SUM(CASE WHEN 기준년월 = EDW_4개월전월  THEN 이용금액_개인본인_할부  ELSE 0 END) AS M4 
                          ,SUM(CASE WHEN 기준년월 = EDW_3개월전월  THEN 이용금액_개인본인_할부  ELSE 0 END) AS M3 
                          ,SUM(CASE WHEN 기준년월 = EDW_2개월전월  THEN 이용금액_개인본인_할부  ELSE 0 END) AS M2 
                          ,SUM(CASE WHEN 기준년월 = EDW_전월       THEN 이용금액_개인본인_할부  ELSE 0 END) AS M1 
                          ,SUM(CASE WHEN 기준년월 = EDW_기준년월   THEN 이용금액_개인본인_할부  ELSE 0 END) AS M0
                     FROM DM.월개인본인회원실적
                    WHERE 기준년월  BETWEEN  EDW_5개월전월  AND  EDW_기준년월                 
                  GROUP BY 고객번호
                  ) A ;
               
             
    COMMIT;
    
    UPDATE WRK.TM_월개인CA이용SCORE 
       SET A.최대연속증가개월수_할부_6개월_CASC = B.개월수
      FROM WRK.TM_월개인CA이용SCORE A,
           ( SELECT T1.고객번호, 
                    T2.개월수
         FROM TEMPACRM_최대연속증감개월수_6개월_CA   T1,
              WRK.TM_최대연속증감개월수_당사        T2
        WHERE T1.M4 = T2.M4
          AND T1.M3 = T2.M3
          AND T1.M2 = T2.M2
          AND T1.M1 = T2.M1
          AND T1.M0 = T2.M0
      ) B
     WHERE A.고객번호 = B.고객번호 ;   
    
    COMMIT;
--4 

------------------------------------------------------------------------------------------------------
--   STEP 9.
--     1) 연속무실적개월수_신판_CASC        column을 update한다         
------------------------------------------------------------------------------------------------------
  
  TRUNCATE TABLE TEMPACRM_연속무실적개월수_신판_12개월;
  COMMIT; 

  INSERT INTO TEMPACRM_연속무실적개월수_신판_12개월
    SELECT 고객번호,
           SUM(CASE WHEN 기준년월 = EDW_12개월전월  AND 이용여부_신판 = 0 THEN 1 ELSE 0 END)||
           SUM(CASE WHEN 기준년월 = EDW_11개월전월  AND 이용여부_신판 = 0 THEN 1 ELSE 0 END)||
           SUM(CASE WHEN 기준년월 = EDW_10개월전월  AND 이용여부_신판 = 0 THEN 1 ELSE 0 END)||
           SUM(CASE WHEN 기준년월 = EDW_9개월전월   AND 이용여부_신판 = 0 THEN 1 ELSE 0 END)||
           SUM(CASE WHEN 기준년월 = EDW_8개월전월   AND 이용여부_신판 = 0 THEN 1 ELSE 0 END)||
           SUM(CASE WHEN 기준년월 = EDW_7개월전월   AND 이용여부_신판 = 0 THEN 1 ELSE 0 END)||
           SUM(CASE WHEN 기준년월 = EDW_6개월전월   AND 이용여부_신판 = 0 THEN 1 ELSE 0 END)||
           SUM(CASE WHEN 기준년월 = EDW_5개월전월   AND 이용여부_신판 = 0 THEN 1 ELSE 0 END)||
           SUM(CASE WHEN 기준년월 = EDW_4개월전월   AND 이용여부_신판 = 0 THEN 1 ELSE 0 END)||
           SUM(CASE WHEN 기준년월 = EDW_3개월전월   AND 이용여부_신판 = 0 THEN 1 ELSE 0 END)||
           SUM(CASE WHEN 기준년월 = EDW_2개월전월   AND 이용여부_신판 = 0 THEN 1 ELSE 0 END)||
           SUM(CASE WHEN 기준년월 = EDW_전월        AND 이용여부_신판 = 0 THEN 1 ELSE 0 END)||
           SUM(CASE WHEN 기준년월 = EDW_기준년월    AND 이용여부_신판 = 0 THEN 1 ELSE 0 END) AS  연속무실적개월수_신판_12개월           
      FROM DM.월개인본인회원실적
     WHERE 기준년월  BETWEEN  EDW_12개월전월  AND  EDW_기준년월 
        GROUP BY 고객번호  ;      
  
  COMMIT;
  
  
  UPDATE WRK.TM_월개인CA이용SCORE   A 
     SET A.연속무실적개월수_신판_CASC =  CASE   WHEN B.개월수 <= 3  THEN '1'
                                                WHEN B.개월수 <= 9  THEN '2'
                                                WHEN B.개월수 <= 12 THEN '3' 
                                                WHEN B.개월수  > 12 THEN '4'  
                                                ELSE '9'
                                         END                                                                    
    FROM WRK.TM_월개인CA이용SCORE         A,
         ( SELECT 고객번호,
                  CASE WHEN SUBSTR(연속무실적개월수_신판_12개월 ,0) = '1111111111111' THEN 13
           WHEN SUBSTR(연속무실적개월수_신판_12개월 ,1) = '0111111111111' THEN 12
           WHEN SUBSTR(연속무실적개월수_신판_12개월 ,2) = '011111111111' THEN 11
           WHEN SUBSTR(연속무실적개월수_신판_12개월 ,3) = '01111111111' THEN 10
                       WHEN SUBSTR(연속무실적개월수_신판_12개월 ,4) = '0111111111' THEN 9
                       WHEN SUBSTR(연속무실적개월수_신판_12개월 ,5) = '011111111' THEN 8
                       WHEN SUBSTR(연속무실적개월수_신판_12개월 ,6) = '01111111' THEN 7
           WHEN SUBSTR(연속무실적개월수_신판_12개월 ,7) = '0111111' THEN 6
                             WHEN SUBSTR(연속무실적개월수_신판_12개월 ,8) = '011111' THEN 5
                       WHEN SUBSTR(연속무실적개월수_신판_12개월 ,9) = '01111' THEN 4
                       WHEN SUBSTR(연속무실적개월수_신판_12개월 ,10)= '0111' THEN 3
                       WHEN SUBSTR(연속무실적개월수_신판_12개월 ,11)= '011' THEN 2
                             WHEN SUBSTR(연속무실적개월수_신판_12개월 ,12)= '01' THEN 1
                       ELSE 0
                  END                                      AS 개월수 
             FROM TEMPACRM_연속무실적개월수_신판_12개월  
         ) B
   WHERE A.고객번호 = B.고객번호 ;  
  
  
   COMMIT;

 
------------------------------------------------------------------------------------------------------
--   STEP 9.
--     1) ARS인터넷_30만원이하CA이용여부_6개월,CA한도조회일,최종CA정상대체월   column을 update한다
--                              
------------------------------------------------------------------------------------------------------  
-- 거래구분코드
--1 지급                                                      
--2 정상대체                                                  
--3 연체대체                                                  
--4 강제대체                                                  
--5 이체                                                      
--6 조회                                                     

-- ARS인터넷_30만원이하CA이용여부_6개월 
/* 거래구분코드,발생경로코드 변경(2004-04-07)    */

  UPDATE WRK.TM_월개인CA이용SCORE 
     SET  A.ARS인터넷_30만원이하CA이용여부_6개월 = CASE WHEN B.ARS인터넷_30만원이하CA이용여부_6개월 > 0 
                                                        THEN 1 ELSE 0 END             
    FROM WRK.TM_월개인CA이용SCORE A
         ,(
    SELECT 고객번호
           ,COUNT(*)                              AS  ARS인터넷_30만원이하CA이용여부_6개월
      FROM DW.현금서비스확정 
     WHERE 거래구분코드 IN ('1','2','5','9')
       AND 발생경로코드 IN ('03','04','08','09') 
       AND 취소전표여부 <> 1             
       AND 매출금액 <= 300000  
       AND 매출일자  BETWEEN  DATE(EDW_5개월전월||'01')  AND  DATE(EDW_당월말일)
     GROUP BY 고객번호
                ) B
        WHERE A.고객번호 = B.고객번호 ;
    
  COMMIT; 
          

-- CA한도조회일 

  UPDATE WRK.TM_월개인CA이용SCORE 
     SET  A.최종CA한도조회일 = B.최종CA한도조회일               
    FROM WRK.TM_월개인CA이용SCORE A
         ,(
    SELECT 고객번호
           ,MAX(매출일자)          AS     최종CA한도조회일
      FROM DW.현금서비스확정 
     WHERE 거래구분코드 = '6' 
       AND 취소전표여부 <> 1 
       AND 매출일자  <=  DATE(EDW_당월말일)  
        GROUP BY 고객번호
     ) B
        WHERE A.고객번호 = B.고객번호 ; 
  
  COMMIT; 
          

-- 최종CA정상대체월 

  UPDATE WRK.TM_월개인CA이용SCORE 
     SET  A.최종CA정상대체월 = B.최종CA정상대체월           
    FROM WRK.TM_월개인CA이용SCORE A
         ,(
    SELECT 고객번호
           ,DATEFORMAT(MAX(매출일자),'YYYYMM')          AS 최종CA정상대체월
      FROM DW.현금서비스확정 
     WHERE 거래구분코드 = '2' 
       AND 취소전표여부 <> 1     
       AND 매출일자  <=  DATE(EDW_당월말일)  
     GROUP BY 고객번호
    ) B
        WHERE A.고객번호 = B.고객번호 ;
      
  COMMIT; 


-- 최종CA강제연체대체월   

  UPDATE WRK.TM_월개인CA이용SCORE 
     SET  A.최종CA강제연체대체월 = B.최종CA강제연체대체월           
    FROM WRK.TM_월개인CA이용SCORE A
         ,(
    SELECT 고객번호
           ,DATEFORMAT(MAX(매출일자),'YYYYMM') AS 최종CA강제연체대체월
      FROM DW.현금서비스확정 
     WHERE 거래구분코드 IN ('3','4') 
       AND 취소전표여부 <> 1     
       AND 매출일자  <=  DATE(EDW_당월말일)         
     GROUP BY 고객번호
    ) B
         WHERE A.고객번호 = B.고객번호 ;
   
  COMMIT; 
   

------------------------------------------------------------------------------------------------------
--   STEP 9.
--     1) 상담 TABLE에서  한도ASR_최종상담일, CA한도외_최종상담일   column을 update한다
--                              
------------------------------------------------------------------------------------------------------  
-- 한도ASR_최종상담일 
         
         
         UPDATE WRK.TM_월개인CA이용SCORE  
      SET A.한도ARS_최종상담일  = B.한도ARS_최종상담일
     FROM WRK.TM_월개인CA이용SCORE  A,
          (
    SELECT 고객번호
           ,MAX(접촉일자)  AS 한도ARS_최종상담일
      FROM DW.상담 
     WHERE 고객상담접촉구분코드 = '01'   
       AND (고객상담결과코드  IN ('04','22') OR 
            고객상담상세결과코드  IN ('025','026','027','028','032','051','057','067',
                                                 '086','123','422','428','429','430','521','928','931'))    
        AND 접촉일자  <=  DATE(EDW_당월말일)                                                          
    GROUP BY  고객번호
                ) B
          WHERE A.고객번호 = B.고객번호 ;
  
  COMMIT;
  
-- CA한도외_최종상담일 

  UPDATE WRK.TM_월개인CA이용SCORE  
      SET A.CA한도외_최종상담일  = B.CA한도외_최종상담일
     FROM WRK.TM_월개인CA이용SCORE  A,
          (
    SELECT 고객번호
           ,MAX(접촉일자)  AS CA한도외_최종상담일
      FROM DW.상담 
     WHERE 고객상담접촉구분코드 = '01'   
       AND (고객상담결과코드  IN ('07','25') OR 
            고객상담상세결과코드  IN ('055','059','088','560','594','613','873','885','886'))  
        AND 접촉일자  <=  DATE(EDW_당월말일)                
    GROUP BY  고객번호
                ) B
          WHERE A.고객번호 = B.고객번호;     
  
  COMMIT;


-----------------------------------------------------------------------------------------------------
--   STEP 9.
--     1) 상담경험여부_3개월 column을 update한다                              
------------------------------------------------------------------------------------------------------  
-- 01 : I/B CALL 

  UPDATE WRK.TM_월개인CA이용SCORE 
     SET  A.상담경험여부_3개월 =  CASE WHEN B.상담경험여부_3개월 = 0 THEN 0 ELSE 1 END        
    FROM WRK.TM_월개인CA이용SCORE A
        ,(
          SELECT 고객번호
                 ,COUNT(고객번호)   AS 상담경험여부_3개월
            FROM DW.상담
           WHERE DATEFORMAT(접촉일자,'YYYYMM') BETWEEN EDW_2개월전월  AND EDW_기준년월
            AND 고객상담접촉구분코드 = '01'
        GROUP BY 고객번호 
         )B 
   WHERE A.고객번호 = B.고객번호 ;   
  
  COMMIT;        
         
         
-----------------------------------------------------------------------------------------------------
--   STEP 9.
--     1) 대출여부_당타사_6개월, 대출잔여개월여부 column을 update한다                              
------------------------------------------------------------------------------------------------------

  UPDATE WRK.TM_월개인CA이용SCORE 
     SET  A.대출잔여개월여부 =   CASE WHEN B.대출완납일자 IN ('0606-06-06','0505-05-05') THEN 1
                                      WHEN B.대출완납일자 > EDW_말일  THEN 1 
                                      ELSE 0 
                                 END              
    FROM WRK.TM_월개인CA이용SCORE A
         ,DM.월대출실적 B 
   WHERE A.고객번호 = B.고객번호  
     AND B.기준년월 = EDW_기준년월 ;
    
  COMMIT;   
    
/* DM.월은행연합회대출채무보증정보 의 적재기간 확인 */  
/*2005/04/07 DM.대출원장 -> DM.월은행연합회대출채무보증정보 */  

  UPDATE WRK.TM_월개인CA이용SCORE 
     SET  A.대출여부_당타사_6개월 =  1          
    FROM WRK.TM_월개인CA이용SCORE A,
         (SELECT DISTINCT 주민사업자번호 AS 주민번호 
            FROM DM.월은행연합회대출채무보증정보
           WHERE 기준년월 BETWEEN  EDW_5개월전월  AND  EDW_기준년월
         ) B  
   WHERE A.주민번호 = B.주민번호  ;
    
  COMMIT;   

-- 3

------------------------------------------------------------------------------------------------------
--   STEP 1.
--     1) ACRM.월개인CA이용SCORE에 최종적재
------------------------------------------------------------------------------------------------------   
   
   DELETE
           FROM  ACRM.월개인CA이용SCORE
          WHERE  기준년월 = '$1';
                    
        
    --   SET delete_cnt=@@rowcount;
      
        COMMIT;
        

  INSERT INTO ACRM.월개인CA이용SCORE
  (       
           기준년월                                    
          ,고객번호                                                 
    ,주민번호                                    
    ,정상회원여부                                               
    ,입회경과차월                                    
    ,Score_CASC                                    
    ,target여부_CASC                                     
    ,Rank_CASC                                     
    ,이용건수_CA2_CASC                             
    ,이용건수_CA3_CASC                             
    ,이용건수_CA4_CASC                                               
    ,성별연령대_CASC                                                        
    ,ECI개인근로소득_CASC                                          
    ,청구서발송방법_CASC                                         
    ,RP이용회원여부                                               
    ,리스크등급                                                    
    ,사용기준VIP                                                     
    ,최종카드발급후경과월_당사_CASC                               
    ,최초카드발급후경과월_당타사                                     
    ,최종매출후경과월_CA_CASC                    
    ,가입후대출여부                                              
    ,대출여부_당타사_6개월                                           
    ,대출잔여개월여부                                            
    ,카드한도소진율_최대값_6개월_CASC                            
    ,카드한도금액증감패턴_CA_6개월_CASC                       
    ,무보증한도증감패턴_3개월_CASC                                
    ,매출평균_할부_6개월_CASC                               
    ,유흥매출비율_6개월_CASC                                                     
    ,은행계이용비율_CA_5개월                             
                ,SOW_CA_5개월_CASC                             
    ,이용개월수_CA_당타사_5개월_CASC                                            
    ,이용개월수_CA_6개월_CASC                               
    ,연속이용개월수_CA_당타사_5개월_CASC                             
    ,연속유실적개월수_기본_CASC                               
    ,연속무실적개월수_CA_12개월                               
    ,연속무실적개월수_신판_CASC                               
    ,최대연속증가개월수_할부_6개월_CASC                       
    ,이용카드사수_CA                                                        
    ,이용카드사수_신판_CASC                                       
    ,최대이용카드사수_CA_5개월_CASC                               
    ,주사용카드_당사_신판_5개월_CASC                                        
    ,최종CA강제연체대체월                                       
    ,최종CA정상대체월                                             
    ,최종CA한도조회일                            
    ,ARS인터넷_30만원이하CA이용여부_6개월                           
    ,상담경험여부_3개월                            
    ,한도ARS_최종상담일                            
    ,CA한도외_최종상담일                                   
    ,CRM적재일시                                     
  )                                        
  SELECT    
     기준년월                                    
          ,고객번호                                          
    ,주민번호                                    
    ,정상회원여부                                        
    ,입회경과차월                                    
    ,Score_CASC                                    
    ,target여부_CASC                                     
    ,Rank_CASC                                     
    ,이용건수_CA2_CASC                             
    ,이용건수_CA3_CASC                             
    ,이용건수_CA4_CASC                                        
    ,성별연령대_CASC                                                 
    ,ECI개인근로소득_CASC                                   
    ,청구서발송방법_CASC                                  
    ,CAST(RP이용회원여부 AS TINYINT)                                         
    ,리스크등급                                             
    ,사용기준VIP                                              
    ,최종카드발급후경과월_당사_CASC                        
    ,최초카드발급후경과월_당타사                              
    ,최종매출후경과월_CA_CASC                    
    ,가입후대출여부                                       
    ,대출여부_당타사_6개월                                    
    ,대출잔여개월여부                                     
    ,카드한도소진율_최대값_6개월_CASC                     
    ,카드한도금액증감패턴_CA_6개월_CASC                
    ,무보증한도증감패턴_3개월_CASC                         
    ,매출평균_할부_6개월_CASC                        
    ,유흥매출비율_6개월_CASC                                              
    ,은행계이용비율_CA_5개월                             
                ,SOW_CA_5개월_CASC                             
    ,이용개월수_CA_당타사_5개월_CASC                                     
    ,이용개월수_CA_6개월_CASC                        
    ,연속이용개월수_CA_당타사_5개월_CASC                      
    ,연속유실적개월수_기본_CASC                        
    ,연속무실적개월수_CA_12개월                        
    ,연속무실적개월수_신판_CASC                        
    ,최대연속증가개월수_할부_6개월_CASC                
    ,이용카드사수_CA                                                 
    ,이용카드사수_신판_CASC                                
    ,최대이용카드사수_CA_5개월_CASC                        
    ,주사용카드_당사_신판_5개월_CASC                                 
    ,최종CA강제연체대체월                                
    ,최종CA정상대체월                                      
    ,최종CA한도조회일                            
    ,ARS인터넷_30만원이하CA이용여부_6개월                    
    ,상담경험여부_3개월                            
    ,한도ARS_최종상담일                            
    ,CA한도외_최종상담일                             
    ,CRM적재일시                                     
                
    FROM  WRK.TM_월개인CA이용SCORE ;
    


        COMMIT; 
        
------------------------------------------------------------------------------------------------------
--   STEP 1.
--     1) 월개인CA이용SCORE 모델변수 sam 파일 내리기
------------------------------------------------------------------------------------------------------         

        SET  EXTRACT_DAT = '/ACRM_HOME/DAT/CDC/ACSAC월개인CA이용SCORE'||'$1'||'.dat';      
        SET  EXTRACT_SQL = '
        
        SELECT  
           고객번호                             
    ,기준년월                             
    ,주민번호                             
    ,카드한도금액증감패턴_CA_6개월_CASC   
    ,SOW_CA_5개월_CASC                    
    ,이용개월수_CA_6개월_CASC             
    ,리스크등급                           
    ,연속유실적개월수_기본_CASC           
    ,최종카드발급후경과월_당사_CASC       
    ,매출평균_할부_6개월_CASC             
    ,최대연속증가개월수_할부_6개월_CASC   
    ,최대이용카드사수_CA_5개월_CASC       
    ,유흥매출비율_6개월_CASC              
    ,연속무실적개월수_신판_CASC           
    ,최종매출후경과월_CA_CASC             
    ,성별연령대_CASC                      
    ,이용개월수_CA_당타사_5개월_CASC      
    ,연속이용개월수_CA_당타사_5개월_CASC  
    ,무보증한도증감패턴_3개월_CASC        
    ,카드한도소진율_최대값_6개월_CASC       
                ,이용카드사수_신판_CASC    
                
     FROM ACRM.월개인CA이용SCORE 
    WHERE 기준년월 = ''$1'' ' ;
            
            CALL  SP_EXTRACT(EXTRACT_DAT, EXTRACT_SQL);

            COMMIT; 

CALL SP_DMJOB ('월개인CA03','E');  --6



------------------------------------------------------------------------------------------------------
--   STEP 1.
--     1) 월개인CA이용SCORE 모델변수 sam 파일 내리기
------------------------------------------------------------------------------------------------------         

        SET  EXTRACT_DAT = '/ACRM_HOME/DAT/CDC/ACSAC월개인CA이용SCORE02.dat';      
        SET  EXTRACT_SQL = '
        
        SELECT  
           기준년월                                    
          ,고객번호                                          
    ,주민번호                                    
    ,정상회원여부                                        
    ,입회경과차월                                    
    ,Score_CASC                                    
    ,target여부_CASC                                     
    ,Rank_CASC                                     
    ,이용건수_CA2_CASC                             
    ,이용건수_CA3_CASC                             
    ,이용건수_CA4_CASC                                        
    ,성별연령대_CASC                                                 
    ,ECI개인근로소득_CASC                                   
    ,청구서발송방법_CASC                                  
    ,CAST(RP이용회원여부 AS TINYINT)                                         
    ,리스크등급                                             
    ,사용기준VIP                                              
    ,최종카드발급후경과월_당사_CASC                        
    ,최초카드발급후경과월_당타사                              
    ,최종매출후경과월_CA_CASC                    
    ,가입후대출여부                                       
    ,대출여부_당타사_6개월                                    
    ,대출잔여개월여부                                     
    ,카드한도소진율_최대값_6개월_CASC                     
    ,카드한도금액증감패턴_CA_6개월_CASC                
    ,무보증한도증감패턴_3개월_CASC                         
    ,매출평균_할부_6개월_CASC                        
    ,유흥매출비율_6개월_CASC                                              
    ,은행계이용비율_CA_5개월                             
                ,SOW_CA_5개월_CASC                             
    ,이용개월수_CA_당타사_5개월_CASC                                     
    ,이용개월수_CA_6개월_CASC                        
    ,연속이용개월수_CA_당타사_5개월_CASC                      
    ,연속유실적개월수_기본_CASC                        
    ,연속무실적개월수_CA_12개월                        
    ,연속무실적개월수_신판_CASC                        
    ,최대연속증가개월수_할부_6개월_CASC                
    ,이용카드사수_CA                                                 
    ,이용카드사수_신판_CASC                                
    ,최대이용카드사수_CA_5개월_CASC                        
    ,주사용카드_당사_신판_5개월_CASC                                 
    ,최종CA강제연체대체월                                
    ,최종CA정상대체월                                      
    ,최종CA한도조회일                            
    ,ARS인터넷_30만원이하CA이용여부_6개월                    
    ,상담경험여부_3개월                            
    ,한도ARS_최종상담일                            
    ,CA한도외_최종상담일                             
    ,CRM적재일시                 
                
     FROM ACRM.월개인CA이용SCORE 
    WHERE 기준년월 = ''$1'' ' ;
            
            CALL  SP_EXTRACT(EXTRACT_DAT, EXTRACT_SQL);

            COMMIT; 

/*--------------------------------------------------------------------------------------*/
/*     End of  PROGRAM                                                                  */
/*--------------------------------------------------------------------------------------*/  
