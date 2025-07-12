alter table "public"."logs" drop constraint "logs_level_check";

alter table "public"."logs" drop constraint "logs_user_id_fkey";

drop view if exists "public"."log_summary";

drop index if exists "public"."logs_created_at_idx";

drop index if exists "public"."logs_user_id_idx";

alter table "public"."logs" drop column "context_data";

alter table "public"."logs" drop column "stack_trace";

alter table "public"."logs" add column "context" jsonb default '{}'::jsonb;

alter table "public"."logs" add column "device_info" jsonb default '{}'::jsonb;

alter table "public"."logs" add column "error_details" jsonb default '{}'::jsonb;

alter table "public"."logs" add column "performance_ms" integer;

alter table "public"."logs" add column "session_id" text;

alter table "public"."logs" alter column "operation" set not null;

CREATE INDEX logs_created_at_idx ON public.logs USING btree (created_at DESC);

CREATE INDEX logs_user_id_idx ON public.logs USING btree (user_id) WHERE (user_id IS NOT NULL);

alter table "public"."logs" add constraint "logs_level_check" CHECK ((level = ANY (ARRAY['ERROR'::text, 'WARN'::text, 'INFO'::text, 'DEBUG'::text]))) not valid;

alter table "public"."logs" validate constraint "logs_level_check";

alter table "public"."logs" add constraint "logs_user_id_fkey" FOREIGN KEY (user_id) REFERENCES auth.users(id) not valid;

alter table "public"."logs" validate constraint "logs_user_id_fkey";

create or replace view "public"."log_summary" as  SELECT level,
    category,
    count(*) AS count,
    max(created_at) AS latest_occurrence
   FROM logs
  WHERE (created_at > (now() - '24:00:00'::interval))
  GROUP BY level, category
  ORDER BY (count(*)) DESC;



