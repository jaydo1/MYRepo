SET SERVEROUTPUT ON
DECLARE
  v_dsql varchar2(400);
  webconfigcount varchar2(100);
  verifierscount varchar2(100);
  v_rec_count number(5) := 0;
  v_domain varchar2(255);
  v_url varchar2(255);
BEGIN 
  dbms_output.put_line('INFO | START');
  
  SELECT Sys_Context('UserEnv','TERMINAL'), 
    'http://'||Sys_Context('UserEnv','TERMINAL')||'/reportserver_vc/'
  INTO v_domain, v_url
  FROM dual;
  
  IF v_domain IS NOT NULL AND v_url IS NOT NULL
  THEN
    dbms_output.put_line('INFO | Domain: ' || v_domain || ', Url: ' || v_url);
  
    FOR rec IN (
    select owner from SYS.all_objects
    where 
       owner not in (
    'SYSTEM', 'XDB', 'SYS', 'TSMSYS',  'MDSYS', 'EXFSYS',  'WMSYS', 'ORDSYS',  'OUTLN', 'DBSNMP','PUBLIC','APPQOSSYS')
    and object_name='WEB_CONFIG' and object_type='TABLE'
    )
    LOOP 
                  
    v_dsql := 'update ' || rec.owner || '.web_config SET parameter_value = ''' || v_domain || ''' where parameter=''RCWebServiceDomain''';              
    EXECUTE IMMEDIATE v_dsql;
    
    v_dsql := 'update ' || rec.owner || '.web_config SET parameter_value = ''' || v_url || ''' where parameter=''RCWebServiceBaseUrl''';              
    EXECUTE IMMEDIATE v_dsql;
                   
    v_rec_count := v_rec_count + 1;
    END LOOP;
  END IF;
  
  dbms_output.put_line('INFO | Number of environments updated: ' || v_rec_count);
  
  dbms_output.put_line('INFO | END');
END;
/


commit;