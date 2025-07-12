create type "public"."payment_status" as enum ('pending', 'paid', 'failed', 'processing');

create type "public"."transaction_status" as enum ('success', 'failure', 'initiated');

set check_function_bodies = off;

CREATE OR REPLACE FUNCTION public.create_profile_for_new_user()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
BEGIN
    INSERT INTO public.profiles (user_id)
    VALUES (NEW.id);
    RETURN NEW;
END;
$function$
;


