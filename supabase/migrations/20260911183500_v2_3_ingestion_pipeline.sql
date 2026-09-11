create or replace function public.ingest_department_schedule(payload jsonb)
returns jsonb language plpgsql security definer set search_path=public as $$
declare
 target jsonb:=coalesce(payload->'target','{}'::jsonb); department_name text:=nullif(trim(payload->>'department'),''); department_code text:=nullif(trim(payload->>'department_code'),''); source_file text:=nullif(trim(payload->>'source_file'),''); file_count int:=greatest(1,coalesce((payload->>'files_count')::int,1)); source_type text:=case when lower(coalesce(source_file,'')) like '%.pdf%' then 'pdf' when lower(coalesce(source_file,''))~'\.(png|jpg|jpeg|webp)' then 'image' else 'document' end;
 schedule_id uuid; department_id uuid; run_id uuid; classes jsonb:=coalesce(payload->'classes','[]'::jsonb); item jsonb; dc_id uuid; v record; candidate_count int; best_score numeric; best_v1 uuid; best_method text; status text; review boolean; evidence jsonb; inserted_count int:=0; matched_count int:=0; mismatch_count int:=0; ambiguous_count int:=0; no_match_count int:=0; cls_date date; cls_day text; st time; et time; subj text; sess text; bat text; norm_dept text; norm_v1 text; score numeric;
begin
 if jsonb_typeof(classes)<>'array' then raise exception 'classes must be an array'; end if;
 if department_name is null then raise exception 'department is required'; end if;
 select id into department_id from departments where lower(name)=lower(department_name) limit 1;
 if department_id is null then insert into departments(name,code) values(department_name,department_code) returning id into department_id; elsif department_code is not null then update departments set code=coalesce(code,department_code),updated_at=now() where id=department_id; end if;
 insert into department_schedules(department_id,academic_program,academic_term,batch,week_start,week_end,source_file,source_type,status,metadata) values(department_id,target->>'programme',target->>'term',target->>'batch',nullif(target->>'from','')::date,nullif(target->>'to','')::date,source_file,source_type,'EXTRACTED',jsonb_build_object('document_retained',false,'department',department_name,'files_count',file_count)) returning id into schedule_id;
 insert into schedule_ingestion_runs(schedule_id,status,extractor_version,files_count,classes_extracted,started_at) values(schedule_id,'RUNNING','v2.3',file_count,0,now()) returning id into run_id;
 for item in select value from jsonb_array_elements(classes) loop
  cls_date:=nullif(item->>'class_date','')::date; cls_day:=upper(coalesce(item->>'day','')); st:=nullif(item->>'start_time','')::time; et:=nullif(item->>'end_time','')::time; subj:=nullif(trim(item->>'subject'),''); sess:=nullif(trim(item->>'session_type'),''); bat:=nullif(trim(item->>'batch'),'');
  if cls_date is null or st is null or et is null then continue; end if;
  insert into department_classes(schedule_id,department_id,class_date,day,start_time,end_time,session_type,subject,topic,faculty,venue,batch,raw_text,confidence,extraction_status,extraction_metadata) values(schedule_id,department_id,cls_date,coalesce(cls_day,upper(to_char(cls_date,'DY'))),st,et,sess,subj,nullif(item->>'topic',''),nullif(item->>'faculty',''),nullif(item->>'venue',''),bat,nullif(item->>'raw_text',''),nullif(item->>'confidence','')::numeric,'EXTRACTED',jsonb_build_object('source_file',source_file)) returning id into dc_id;
  inserted_count:=inserted_count+1; norm_dept:=lower(regexp_replace(coalesce(subj,''),'[^a-z0-9]+','','g')); candidate_count:=0; best_score:=-1; best_v1:=null; best_method:=null;
  for v in select * from v1_classes where academic_program=target->>'programme' and academic_term=target->>'term' and start_time=st and end_time=et and (class_date=cls_date or (class_date is null and upper(day)=cls_day)) and (batch is null or bat is null or upper(batch)=upper(bat)) loop
   if v.class_date is null and v.occurrence_rule is not null then if floor((extract(day from cls_date)::int-1)/7)+1 not in (select case when position('-' in trim(x))>0 then generate_series(split_part(trim(x),'-',1)::int,split_part(trim(x),'-',2)::int) else trim(x)::int end from regexp_split_to_table(replace(v.occurrence_rule,' ',''),';') x) then continue; end if; end if;
   candidate_count:=candidate_count+1; norm_v1:=lower(regexp_replace(coalesce(v.subject,''),'[^a-z0-9]+','','g')); score:=0;
   if norm_dept<>'' and norm_dept=norm_v1 then score:=score+0.65; elsif norm_dept<>'' and (norm_dept like '%'||norm_v1||'%' or norm_v1 like '%'||norm_dept||'%') then score:=score+0.45; end if;
   if upper(coalesce(v.session_type,''))=upper(coalesce(sess,'')) then score:=score+0.15; end if;
   if upper(coalesce(v.batch,''))=upper(coalesce(bat,'')) and bat is not null then score:=score+0.15; end if;
   if v.class_date=cls_date then score:=score+0.05; elsif v.class_date is null then score:=score+0.05; end if;
   if score>best_score then best_score:=score; best_v1:=v.id; best_method:='DETERMINISTIC'; end if;
  end loop;
  if candidate_count=0 then status:='NO_MATCH'; review:=true; best_score:=0; no_match_count:=no_match_count+1; elsif candidate_count=1 and best_score>=0.75 then status:='MATCHED'; review:=false; matched_count:=matched_count+1; elsif candidate_count>1 and best_score>=0.75 then status:='AMBIGUOUS'; review:=true; ambiguous_count:=ambiguous_count+1; else status:='MISMATCH'; review:=true; mismatch_count:=mismatch_count+1; end if;
  evidence:=jsonb_build_object('department_class',jsonb_build_object('date',cls_date,'time',to_char(st,'HH24:MI')||'-'||to_char(et,'HH24:MI'),'batch',bat,'subject',subj,'session_type',sess,'source_file',source_file),'candidate_count',candidate_count,'best_score',best_score);
  insert into schedule_matches(v1_class_id,department_class_id,match_status,match_score,match_method,review_required,evidence) values(best_v1,dc_id,status,best_score,best_method,review,evidence);
 end loop;
 update schedule_ingestion_runs set status='COMPLETED',classes_extracted=inserted_count,completed_at=now() where id=run_id;
 return jsonb_build_object('schedule_id',schedule_id,'run_id',run_id,'classes_extracted',inserted_count,'matched',matched_count,'mismatch',mismatch_count,'ambiguous',ambiguous_count,'no_match',no_match_count);
exception when others then if run_id is not null then update schedule_ingestion_runs set status='FAILED',error_message=sqlerrm,completed_at=now() where id=run_id; end if; raise;
end; $$;
revoke all on function public.ingest_department_schedule(jsonb) from public;
grant execute on function public.ingest_department_schedule(jsonb) to anon,authenticated;

create or replace function public.get_schedule_results(p_schedule_id uuid)
returns jsonb language sql security definer set search_path=public as $$
 select coalesce(jsonb_agg(jsonb_build_object('department_class_id',dc.id,'class_date',dc.class_date,'day',dc.day,'start_time',to_char(dc.start_time,'HH24:MI'),'end_time',to_char(dc.end_time,'HH24:MI'),'subject',dc.subject,'session_type',dc.session_type,'topic',dc.topic,'faculty',dc.faculty,'venue',dc.venue,'batch',dc.batch,'confidence',dc.confidence,'match_status',sm.match_status,'match_score',sm.match_score,'match_method',sm.match_method,'review_required',sm.review_required,'v1_class_id',sm.v1_class_id,'v1_subject',vc.subject,'v1_session_type',vc.session_type,'evidence_summary',case when sm.match_status='MATCHED' then 'Deterministic V1 match' when sm.match_status='MISMATCH' then 'V1 candidate differs from department schedule' when sm.match_status='AMBIGUOUS' then 'Multiple plausible V1 candidates' else 'No V1 candidate at same date/time/batch' end) order by dc.class_date,dc.start_time),'[]'::jsonb) from department_classes dc left join schedule_matches sm on sm.department_class_id=dc.id left join v1_classes vc on vc.id=sm.v1_class_id where dc.schedule_id=p_schedule_id;
$$;
revoke all on function public.get_schedule_results(uuid) from public;
grant execute on function public.get_schedule_results(uuid) to anon,authenticated;