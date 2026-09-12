create or replace function public.persist_department_schedule_extraction(payload jsonb)
returns jsonb language plpgsql security definer set search_path=public as $$
declare
 target jsonb:=coalesce(payload->'target','{}'::jsonb);
 department_name text:=nullif(trim(payload->>'department'),'');
 department_code text:=nullif(trim(payload->>'department_code'),'');
 source_file text:=nullif(trim(payload->>'source_file'),'');
 file_count int:=greatest(1,coalesce((payload->>'files_count')::int,1));
 source_type text:=coalesce(nullif(payload->>'source_type',''), 'document');
 schedule_id uuid; department_id uuid; run_id uuid; classes jsonb:=coalesce(payload->'classes','[]'::jsonb); item jsonb;
 inserted_count int:=0; rejected_count int:=0; cls_date date; cls_day text; st time; et time; conf numeric;
begin
 if department_name is null then raise exception 'department is required'; end if;
 if jsonb_typeof(classes)<>'array' then raise exception 'classes must be an array'; end if;
 select id into department_id from departments where lower(name)=lower(department_name) limit 1;
 if department_id is null then insert into departments(name,code) values(department_name,department_code) returning id into department_id;
 elsif department_code is not null then update departments set code=coalesce(code,department_code),updated_at=now() where id=department_id; end if;
 insert into department_schedules(department_id,academic_program,academic_term,batch,week_start,week_end,source_file,source_type,status,metadata)
 values(department_id,target->>'programme',target->>'term',target->>'batch',nullif(target->>'from','')::date,nullif(target->>'to','')::date,source_file,source_type,'PROCESSING',jsonb_build_object('document_retained',false,'pipeline','structured_ingest','files_count',file_count)) returning id into schedule_id;
 insert into schedule_ingestion_runs(schedule_id,status,extractor_version,files_count,classes_extracted,started_at) values(schedule_id,'RUNNING',coalesce(payload->>'extractor_version','v2.4-structured'),file_count,0,now()) returning id into run_id;
 for item in select value from jsonb_array_elements(classes) loop
  begin
   cls_date:=nullif(item->>'class_date','')::date;
   cls_day:=upper(nullif(trim(item->>'day'),'',''));
   st:=nullif(item->>'start_time','')::time;
   et:=nullif(item->>'end_time','')::time;
   conf:=nullif(item->>'confidence','')::numeric;
   if st is null or et is null or et<=st then rejected_count:=rejected_count+1; continue; end if;
   if cls_day is null and cls_date is not null then cls_day:=upper(to_char(cls_date,'DY')); end if;
   if conf is not null then conf:=least(1,greatest(0,conf)); end if;
   insert into department_classes(schedule_id,department_id,class_date,day,start_time,end_time,session_type,subject,topic,faculty,venue,batch,raw_text,confidence,extraction_status,extraction_metadata)
   values(schedule_id,department_id,cls_date,cls_day,st,et,nullif(trim(item->>'session_type'),''),nullif(trim(item->>'subject'),''),nullif(trim(item->>'topic'),''),nullif(trim(item->>'faculty'),''),nullif(trim(item->>'venue'),''),nullif(trim(item->>'batch'),''),nullif(item->>'raw_text',''),conf,case when coalesce(conf,0)>=0.8 and nullif(trim(item->>'subject'),'') is not null then 'EXTRACTED' else 'NEEDS_REVIEW' end,jsonb_build_object('source_file',source_file,'structured',true,'source_page',item->>'source_page'));
   inserted_count:=inserted_count+1;
  exception when others then rejected_count:=rejected_count+1; end;
 end loop;
 update schedule_ingestion_runs set status='COMPLETED',classes_extracted=inserted_count,completed_at=now(),error_message=case when rejected_count>0 then rejected_count||' rows rejected during validation' else null end where id=run_id;
 update department_schedules set status='EXTRACTED',metadata=metadata||jsonb_build_object('classes_extracted',inserted_count,'rows_rejected',rejected_count) where id=schedule_id;
 return jsonb_build_object('schedule_id',schedule_id,'run_id',run_id,'classes_extracted',inserted_count,'rows_rejected',rejected_count,'status','EXTRACTED');
exception when others then
 if run_id is not null then update schedule_ingestion_runs set status='FAILED',error_message=sqlerrm,completed_at=now() where id=run_id; end if;
 if schedule_id is not null then update department_schedules set status='FAILED' where id=schedule_id; end if;
 raise;
end; $$;
revoke all on function public.persist_department_schedule_extraction(jsonb) from public;
grant execute on function public.persist_department_schedule_extraction(jsonb) to anon,authenticated;
