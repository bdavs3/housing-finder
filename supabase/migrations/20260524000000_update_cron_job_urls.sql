select cron.unschedule('daily-groups');
select cron.unschedule('daily-marketplace');
select cron.unschedule('score-listings');

-- Update cron job URLs from sf-housing-finder.vercel.app to bens-housing-finder.vercel.app
select cron.schedule(
  'daily-groups',
  '0 6 * * *',
  $$
    select net.http_post(
      url := 'https://bens-housing-finder.vercel.app/api/trigger-groups',
      headers := json_build_object(
        'Content-Type', 'application/json',
        'Authorization', 'Basic ' || encode(convert_to(
          (select decrypted_secret from vault.decrypted_secrets where name = 'SITE_USER') || ':' ||
          (select decrypted_secret from vault.decrypted_secrets where name = 'SITE_PASS'),
          'utf8'
        ), 'base64')
      )::jsonb,
      body := '{}'::jsonb
    )
  $$
);

select cron.schedule(
  'daily-marketplace',
  '0 6 * * *',
  $$
    select net.http_post(
      url := 'https://bens-housing-finder.vercel.app/api/trigger-marketplace',
      headers := json_build_object(
        'Content-Type', 'application/json',
        'Authorization', 'Basic ' || encode(convert_to(
          (select decrypted_secret from vault.decrypted_secrets where name = 'SITE_USER') || ':' ||
          (select decrypted_secret from vault.decrypted_secrets where name = 'SITE_PASS'),
          'utf8'
        ), 'base64')
      )::jsonb,
      body := '{}'::jsonb
    )
  $$
);

select cron.schedule(
  'score-listings',
  '*/5 * * * *',
  $$
    select net.http_post(
      url := 'https://bens-housing-finder.vercel.app/api/score',
      headers := json_build_object(
        'Content-Type', 'application/json',
        'Authorization', 'Basic ' || encode(convert_to(
          (select decrypted_secret from vault.decrypted_secrets where name = 'SITE_USER') || ':' ||
          (select decrypted_secret from vault.decrypted_secrets where name = 'SITE_PASS'),
          'utf8'
        ), 'base64')
      )::jsonb,
      body := '{}'::jsonb
    )
  $$
);
