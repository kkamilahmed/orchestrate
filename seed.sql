-- Orchestrate keynote demo: seed data
-- Loaded automatically by docker-compose after schema.sql.
--
-- Dates are written relative to CURRENT_DATE ("CURRENT_DATE - 2" = two days ago), so the
-- signals read true on the day the database is created. refresh_demo_dates() (called by
-- server.js on startup) slides them forward if the keynote happens later.
--
-- ID scheme (explicit so industries can cross-reference): industry N uses
--   records N01..N99, products/flows/signals N1..N9, chats N01..N09.
--
-- Template placeholders ({{name}}, {{discount_pct}}, ...) are rendered by server.js.
-- See README.md > "Data model" for the full list of variables and the flow steps format.

INSERT INTO industries (id, slug, name, company_name, logo_text, record_noun, sort_order) VALUES
  (1, 'insurance',     'Insurance',         'Harborline Mutual Insurance',     'Harborline',    'clients',   1),
  (2, 'banking',       'Banking & Wealth',  'Crestview Private Bank',          'Crestview',     'clients',   2),
  (3, 'healthcare',    'Healthcare clinic', 'Maplewood Family Health',         'Maplewood',     'patients',  3),
  (4, 'retail',        'Retail',            'Kestrel & Pine Outfitters',       'Kestrel & Pine','customers', 4),
  (5, 'hr',            'Human resources',   'Brightline Technologies',         'Brightline',    'employees', 5),
  (6, 'real-estate',   'Real estate',       'Cedar & Stone Realty',            'Cedar & Stone', 'contacts',  6),
  (7, 'manufacturing', 'Manufacturing',     'Ironbridge Precision Manufacturing', 'Ironbridge', 'items',     7);

INSERT INTO app_state (key, value) VALUES ('active_industry', 'insurance'), ('offline_mode', 'false');
-- ===========================================================================
-- 1. Insurance - Harborline Mutual Insurance
-- ===========================================================================

INSERT INTO app_users (industry_id, name, role, email) VALUES
  (1, 'Paul Zikopoulos', 'Senior Account Manager', 'paul.zikopoulos@harborline.example');

INSERT INTO records (id, industry_id, name, email, phone, record_type, attributes) VALUES
  (101, 1, 'John Collins', 'john.collins@example.com', '(555) 010-2231', 'client',
   '{"first_name":"John","policy_number":"HL-448210","plan":"Family Gold PPO","tenure_years":9,
     "dependent_name":"Ethan","dependent_age":25,"recommended_for":"Ethan",
     "situation":"Ethan turned 25 this week, which means he ages out of your family plan at the end of the month.",
     "coverage_need":"Ethan needs his own health coverage before the family plan ends at month end."}'),
  (102, 1, 'Maria Delgado', 'maria.delgado@example.com', '(555) 010-4410', 'client',
   '{"first_name":"Maria","policy_number":"HL-390114","plan":"Family Silver HMO","tenure_years":6,
     "dependent_name":"Sofia","dependent_age":25,"recommended_for":"Sofia",
     "situation":"Sofia turned 25 last week, so she will age out of your family plan at the end of the month.",
     "coverage_need":"Sofia needs an individual plan to avoid a gap when the family coverage ends."}'),
  (103, 1, 'Priya Raman', 'priya.raman@example.com', '(555) 010-7782', 'client',
   '{"first_name":"Priya","policy_number":"HL-512877","plan":"Individual Silver HMO","tenure_years":4,
     "spouse_name":"Arjun","recommended_for":"Arjun",
     "situation":"Congratulations on your marriage to Arjun! We also noted that his job-based coverage is ending.",
     "coverage_need":"Arjun needs new coverage, and marriage opens a 60-day special enrollment window."}'),
  (104, 1, 'David Okafor', 'david.okafor@example.com', '(555) 010-3356', 'client',
   '{"first_name":"David","policy_number":"HL-601245","plan":"Family Gold PPO","tenure_years":3,
     "dependent_name":"Samuel","dependent_age":23,"recommended_for":"Samuel",
     "situation":"Samuel just graduated, and his student health plan has ended.",
     "coverage_need":"Samuel lost his student coverage, which qualifies him for a 60-day special enrollment window.",
     "claim_number":"CLM-21177","claim_type":"Auto collision","claim_amount":6850,"adjuster":"Kim Osei",
     "next_step":"The body shop is revising its repair estimate. Once it arrives, the adjuster approves repairs within 3 business days."}'),
  (105, 1, 'Linda Park', 'linda.park@example.com', '(555) 010-9021', 'client',
   '{"first_name":"Linda","policy_number":"HL-733902","plan":"Family Silver HMO","tenure_years":1,
     "dependent_name":"Marcus","dependent_age":25,"recommended_for":"Marcus",
     "situation":"Marcus turned 25 yesterday, so he will age out of your family plan at the end of the month.",
     "coverage_need":"Marcus needs his own health coverage before the family plan ends at month end."}'),
  (106, 1, 'Robert Chen', 'robert.chen@example.com', '(555) 010-6647', 'client',
   '{"first_name":"Robert","policy_number":"HL-284519","plan":"Auto + Home Bundle","tenure_years":7,
     "premium_monthly":214,"renewal_premium":240}'),
  (107, 1, 'Angela Brooks', 'angela.brooks@example.com', '(555) 010-1198', 'client',
   '{"first_name":"Angela","policy_number":"HL-455630","plan":"HomeShield Standard","tenure_years":5,
     "premium_monthly":148,"renewal_premium":161}'),
  (108, 1, 'Tom Walsh', 'tom.walsh@example.com', '(555) 010-5573', 'client',
   '{"first_name":"Tom","policy_number":"HL-118364","plan":"HomeShield Premier","tenure_years":12,
     "claim_number":"CLM-20931","claim_type":"Water damage (kitchen)","claim_amount":18400,"adjuster":"Dana Ruiz",
     "next_step":"The adjuster inspection is scheduled. Payment review follows within 5 business days of the inspection."}');

INSERT INTO life_events (record_id, event_type, description, event_date) VALUES
  (101, 'dependent_age_out', 'Son Ethan turned 25 and ages out of the family plan', CURRENT_DATE - 2),
  (102, 'dependent_age_out', 'Daughter Sofia turned 25 and ages out of the family plan', CURRENT_DATE - 5),
  (103, 'marriage',          'Married Arjun Mehta; his job-based coverage is ending', CURRENT_DATE - 4),
  (104, 'graduation',        'Son Samuel graduated; his student health plan ended', CURRENT_DATE - 6),
  (105, 'dependent_age_out', 'Son Marcus turned 25 and ages out of the family plan', CURRENT_DATE - 1),
  (106, 'renewal_due',       'Auto + Home Bundle renews with a premium increase of about 12%; requested 2 competitor quotes', CURRENT_DATE + 9),
  (107, 'renewal_due',       'HomeShield Standard renews; premium rising to $161/month after a regional rate filing', CURRENT_DATE + 12),
  (108, 'claim_stalled',     'Water damage claim CLM-20931 open 34 days, waiting on adjuster inspection', CURRENT_DATE - 34),
  (104, 'claim_stalled',     'Auto claim CLM-21177 open 22 days, waiting on a revised repair estimate', CURRENT_DATE - 22);

INSERT INTO products (id, industry_id, name, description, price, price_unit, discount_pct, eligibility_rules) VALUES
  (11, 1, 'Silver Marketplace Plan',
   'Individual Silver-level plan with $0 preventive care, a $3,500 deductible and a nationwide PPO network.',
   412.00, '/month', 15,
   '{"all":[{"attr":"tenure_years","op":">=","value":3,"label":"3+ years as a Harborline client"}]}'),
  (12, 1, 'Gold Marketplace Plan',
   'Individual Gold-level plan with $0 preventive care, a $1,500 deductible and lower copays.',
   538.00, '/month', 10,
   '{"all":[{"attr":"tenure_years","op":">=","value":3,"label":"3+ years as a Harborline client"}]}'),
  (13, 1, 'Bundle Protect Plus',
   'Home and auto coverage in one policy with accident forgiveness and a single shared deductible.',
   229.00, '/month', 8, '{}');

INSERT INTO query_definitions (key, industry_id, description, event_types, days_from, days_to) VALUES
  ('ins_life_events',    1, 'Clients with a coverage-changing life event in the last 7 days', '{dependent_age_out,marriage,graduation}', -7, 0),
  ('ins_age_outs',       1, 'Dependents who aged out of a family plan in the last 14 days', '{dependent_age_out}', -14, 0),
  ('ins_renewals',       1, 'Policies renewing in the next 14 days with churn signals', '{renewal_due}', 0, 14),
  ('ins_stalled_claims', 1, 'Claims open 21 or more days without progress', '{claim_stalled}', -120, -21);

INSERT INTO flows (id, industry_id, slug, title, description, flow_type, keywords, icon, product_id, sort_order, steps) VALUES
  (11, 1, 'life-event-outreach', 'Life-event coverage outreach',
   'Spot clients whose family situation changed and offer the right plan, with loyalty pricing applied.',
   'outreach', '{life event,life events,turned 25,turning 25,aged out,age out,ages out,upsell,dependent,dependents,own coverage}',
   'user--multiple', 11, 1,
   '{"query":"ins_life_events",
     "agent_steps":["Querying CRM for life events in the last 7 days",
                    "Found {{count}} {{record_noun}} with recent life events",
                    "Checking eligibility rules for the {{product}}",
                    "{{eligible_count}} of {{count}} qualify for the {{discount_pct}}% loyalty discount"],
     "table_title":"Clients with recent life events",
     "select_hint":"Select the clients you want to reach out to.",
     "change_label":"Recent change",
     "contact_field":"email",
     "draft_mode":"per_record",
     "content_type":"Email",
     "to":"{{email}}",
     "cc":"{{sender_email}}",
     "subject":"Coverage for {{recommended_for}}: an option worth a quick look",
     "facts":[{"key":"discount_pct","label":"Loyalty discount","kind":"percent"},
              {"key":"price","label":"Plan price","kind":"money"},
              {"key":"discounted_price","label":"Price after discount","kind":"money"},
              {"key":"dependent_age","label":"Dependent age","kind":"age"}],
     "approve":{"label":"Send email","action_type":"email_sent","log_label":"Logged to CRM",
                "task_title":"Follow up with {{name}} about the {{product}}",
                "follow_up":{"weekday":5},
                "confirmation":"Email sent to {{name}}. Logged to CRM. Follow-up task created for {{follow_up_day}}."}}'),
  (12, 1, 'renewal-risk', 'Renewal risk outreach',
   'Reach clients with upcoming renewals and churn signals before a competitor does.',
   'outreach', '{renewal,renewals,renew,renewing,retention,at risk,churn,lapse}',
   'renew', 13, 2,
   '{"query":"ins_renewals",
     "agent_steps":["Scanning policies that renew in the next 14 days",
                    "Found {{count}} renewals with churn signals",
                    "Comparing renewal premiums with the {{product}}",
                    "Locking pricing from the rate table"],
     "table_title":"Policies renewing soon",
     "select_hint":"Select the policyholders to contact before renewal.",
     "change_label":"Renewal signal",
     "contact_field":"email",
     "draft_mode":"per_record",
     "content_type":"Email",
     "to":"{{email}}",
     "cc":"{{sender_email}}",
     "subject":"Your {{plan}} renewal on {{event_date}}",
     "facts":[{"key":"event_date","label":"Renewal date","kind":"date"},
              {"key":"premium_monthly","label":"Current premium","kind":"money"},
              {"key":"renewal_premium","label":"Renewal premium","kind":"money"},
              {"key":"discount_pct","label":"Multi-policy discount","kind":"percent"},
              {"key":"discounted_price","label":"Offer price","kind":"money"}],
     "approve":{"label":"Send email","action_type":"email_sent","log_label":"Logged to CRM",
                "task_title":"Renewal review call with {{name}}",
                "follow_up":{"business_days":2},
                "confirmation":"Email sent to {{name}}. Logged to CRM. Renewal review task created for {{follow_up_day}}."}}'),
  (13, 1, 'claim-status', 'Stalled claim status update',
   'Send honest, specific updates on claims that have gone quiet.',
   'outreach', '{claim,claims,stalled,claim status,status update,adjuster}',
   'document', NULL, 3,
   '{"query":"ins_stalled_claims",
     "agent_steps":["Checking claims open longer than 21 days",
                    "Found {{count}} stalled claims",
                    "Pulling adjuster notes and next steps",
                    "Setting a committed update date"],
     "table_title":"Claims without an update in 21+ days",
     "select_hint":"Select the claimants who should get a status update.",
     "change_label":"Claim status",
     "contact_field":"email",
     "draft_mode":"per_record",
     "content_type":"Email",
     "to":"{{email}}",
     "cc":"claims@harborline.example",
     "subject":"Update on your claim {{claim_number}}",
     "facts":[{"key":"claim_amount","label":"Claim estimate","kind":"money"},
              {"key":"event_date","label":"Filed on","kind":"date"},
              {"key":"follow_up_date","label":"Next update by","kind":"date"}],
     "approve":{"label":"Send update","action_type":"email_sent","log_label":"Logged to claim file",
                "task_title":"Next update on claim {{claim_number}} for {{name}}",
                "follow_up":{"business_days":3},
                "confirmation":"Status update sent to {{name}}. Logged to claim {{claim_number}}. Follow-up task created for {{follow_up_day}}."}}'),
  (14, 1, 'handbook-qa', 'Ask the underwriting handbook',
   'Answers from the Harborline handbook, with the section it came from.',
   'qa', '{handbook,what does,how does,how do we,how long,rule,rules,guideline,guidelines,requirement,requirements,policy on,our policy,special enrollment}',
   'book', NULL, 4,
   '{"agent_steps":["Searching the Harborline handbook",
                    "Found {{count}} relevant sections",
                    "Reading \"{{top_section}}\"",
                    "Writing an answer with citations"]}');

INSERT INTO signals (id, industry_id, title, description, flow_id, severity, count_query, sort_order) VALUES
  (11, 1, '{{count}} client{{s}} had life events this week',
   'Age-outs, marriages and graduations that change the coverage they need.', 11, 'high', 'ins_life_events', 1),
  (12, 1, '{{count}} dependent{{s}} aged out of family plans',
   'Coverage ends at month end unless they get their own plan.', 11, 'high', 'ins_age_outs', 2),
  (13, 1, '{{count}} polic{{ies}} renew in the next 14 days',
   'Premium increases and competitor quote activity detected.', 12, 'medium', 'ins_renewals', 3),
  (14, 1, '{{count}} claim{{s}} stalled for 21+ days',
   'Past the 21-day service standard for a proactive update.', 13, 'medium', 'ins_stalled_claims', 4);

INSERT INTO prompt_templates (flow_id, template_text) VALUES
  (11, $t$Write a warm, concise email from {{sender}} ({{sender_role}}, {{company}}) to {{name}}.

What happened: {{event}} (recorded {{event_date}}).
Why it matters: {{coverage_need}}
Client: {{first_name}} has been with {{company_short}} for {{tenure_years}} years on the {{plan}} plan.

Recommend the {{product}} for {{recommended_for}} at {{price}}/month.
{{#eligible}}Offer: {{first_name}} qualifies for our {{discount_pct}}% loyalty discount, which brings it to {{discounted_price}}/month.{{/eligible}}{{^eligible}}Note: {{first_name}} does not yet qualify for the loyalty discount ({{eligibility_note}}), so do not mention any discount.{{/eligible}}

Close by inviting {{first_name}} to book a 15-minute call this week. Friendly, plain language, no pressure, under 170 words.$t$),
  (12, $t$Write a proactive, reassuring email from {{sender}} ({{sender_role}}, {{company}}) to {{name}} ahead of their renewal on {{event_date}}.

Context: {{event}}.
Current policy: {{plan}} at {{premium_monthly}}/month. The renewal premium will be {{renewal_premium}}/month.
Option: the {{product}} at {{discounted_price}}/month after the {{discount_pct}}% multi-policy discount (list price {{price}}/month). {{product_description}}

Acknowledge the price change honestly, explain the option in two or three sentences, and invite {{first_name}} to a 10-minute review call before {{event_date}}. Under 170 words.$t$),
  (13, $t$Write a transparent, empathetic claim status update from {{sender}} ({{sender_role}}, {{company}}) to {{name}}.

Claim: {{claim_number}} ({{claim_type}}), estimated at {{claim_amount}}, filed {{event_date}}.
Where it stands: {{event}}.
Next step: {{next_step}}
Adjuster: {{adjuster}}.

Apologize for the wait without making excuses, explain the next step in plain language, and commit to the next update by {{follow_up_date}}. Do not promise a payment amount or a payment date. Under 150 words.$t$);

INSERT INTO offline_responses (industry_id, flow_id, kind, response_text) VALUES
  (1, 11, 'draft', $t$Hi {{first_name}},

{{situation}} {{coverage_need}}

To make this easy, I'd recommend the {{product}} for {{recommended_for}}. It includes $0 preventive care and a nationwide PPO network for {{price}}/month.{{#eligible}} Because you've been with {{company_short}} for {{tenure_years}} years, you qualify for our {{discount_pct}}% loyalty discount, which brings it to {{discounted_price}}/month.{{/eligible}}

Could we find 15 minutes this week to walk through it? I can have everything ready before the current coverage ends, so there's no gap.

Warm regards,
{{sender}}
{{sender_role}}, {{company}}$t$),
  (1, 12, 'draft', $t$Hi {{first_name}},

Your {{plan}} policy renews on {{event_date}}, and I want to be upfront with you: the renewal premium will be {{renewal_premium}}/month, up from {{premium_monthly}}/month today.

Before that happens, I'd like to show you an option. With the {{product}}, you would pay {{discounted_price}}/month after our {{discount_pct}}% multi-policy discount, and you get accident forgiveness and a single shared deductible.

Could we do a 10-minute review call before {{event_date}}? I'll bring a side-by-side comparison so you can decide with every number in front of you.

Best regards,
{{sender}}
{{sender_role}}, {{company}}$t$),
  (1, 13, 'draft', $t$Hi {{first_name}},

I'm sorry your claim {{claim_number}} ({{claim_type}}) has taken longer than it should. You filed it on {{event_date}}, and you deserve a clear picture of where it stands.

Here is the next step: {{next_step}} Your adjuster, {{adjuster}}, is handling it personally.

I will send you the next update by {{follow_up_date}}, whether or not anything has changed. If you have questions before then, reply to this email or call me directly.

Thank you for your patience,
{{sender}}
{{sender_role}}, {{company}}$t$);

INSERT INTO offline_responses (industry_id, kind, match_keywords, response_text) VALUES
  (1, 'chat', '{call first,first today,prioritize,priority,priorities,who should,which client}', $t$I'd start with **John Collins**. Here's how I'd order your calls today:

1. **John Collins** - his son Ethan turned 25 this week and ages out of the Family Gold PPO at month end. John has been a client for 9 years, so he qualifies for the 15% loyalty discount on the Silver Marketplace Plan. Hard deadline, high value.
2. **Tom Walsh** - his water damage claim CLM-20931 has been open 34 days. That's past our 21-day update standard, and he's a 12-year client.
3. **Robert Chen** - his Auto + Home Bundle renews in 9 days with an increase of about 12%, and he has requested 2 competitor quotes.

Want me to draft the email to John first?$t$),
  (1, 'chat', '{summary,summarize,overview,my day,this week}', $t$Here's your book of business at a glance, {{user_first}}:

{{signals_summary}}

The most time-sensitive item is the age-outs: those dependents lose coverage at month end. I can draft outreach for any of these, or answer questions from the underwriting handbook.$t$),
  (1, 'chat', '{}', $t$Here's what I'm seeing across your clients right now:

{{signals_summary}}

I can draft outreach for any of these, check eligibility for the loyalty discount, or answer questions from the underwriting handbook. What would you like to do next?$t$);

INSERT INTO knowledge_base (industry_id, source, section_title, content) VALUES
  (1, 'Harborline Underwriting Handbook', 'Dependent eligibility on family plans',
   'Children are covered on Harborline family plans through the end of the month in which they turn 25. Coverage for that dependent ends on the last day of the month, with no grace period. Contact the policyholder as soon as an age-out is recorded so the dependent can enroll in an individual plan without a gap in coverage.'),
  (1, 'Harborline Underwriting Handbook', 'Loyalty discount program',
   'Clients with 3 or more consecutive years of active coverage qualify for a loyalty discount on a new individual plan for a family member: 15% on the Silver Marketplace Plan and 10% on the Gold Marketplace Plan. The discount applies for the first 12 months and cannot be combined with the multi-policy discount. Clients with fewer than 3 years of tenure are not eligible, and agents should not mention the discount to them.'),
  (1, 'Harborline Underwriting Handbook', 'Silver Marketplace Plan',
   'The Silver Marketplace Plan is an individual Silver-level plan priced at $412 per month. It includes $0 preventive care, a $3,500 deductible, a $30 primary care copay and access to the nationwide PPO network. It is the default recommendation for young adults leaving a family plan.'),
  (1, 'Harborline Underwriting Handbook', 'Gold Marketplace Plan',
   'The Gold Marketplace Plan is an individual Gold-level plan priced at $538 per month. It includes $0 preventive care, a $1,500 deductible and a $15 primary care copay. Recommend it when the client expects frequent care or ongoing prescriptions.'),
  (1, 'Harborline Underwriting Handbook', 'Special enrollment periods',
   'Marriage, the birth or adoption of a child, loss of other coverage (including student or employer plans) and moving to a new state each open a 60-day special enrollment period. Outside of these events, individual plans can only be purchased during open enrollment.'),
  (1, 'Harborline Service Standards', 'Renewal retention guidelines',
   'Contact clients at least 14 days before renewal when the premium rises by more than 8% or when competitor quote activity is detected. Lead with transparency about the change, offer a coverage review and present the Bundle Protect Plus option with the 8% multi-policy discount where it lowers the monthly cost.'),
  (1, 'Harborline Service Standards', 'Claims service standards',
   'Every open claim must receive a proactive status update at least every 21 days. Updates must name the adjuster, explain the next step in plain language and commit to a date for the next update. Never promise a payment amount or payment date before the adjuster review is complete.'),
  (1, 'Harborline Service Standards', 'Client communication standards',
   'Use plain language and keep emails under 200 words. Every price, discount and date in client communications must match the rate tables and policy records exactly. Always copy yourself on outreach so the email is logged to the CRM, and never pressure a client to decide on the first contact.');

INSERT INTO suggestions (industry_id, title, prompt, icon, sort_order) VALUES
  (1, 'Plan my calls', 'Which client should I call first today?', 'chat', 1),
  (1, 'Check a rule', 'What does the loyalty discount require?', 'book', 2),
  (1, 'Prevent churn', 'Draft renewal outreach for at-risk policies', 'email', 3);

INSERT INTO chats (id, industry_id, title, is_seed, created_at, updated_at) VALUES
  (101, 1, 'Renewal pipeline for this month', TRUE, now() - interval '1 day', now() - interval '1 day'),
  (102, 1, 'Claims backlog check', TRUE, now() - interval '2 days', now() - interval '2 days'),
  (103, 1, 'Special enrollment rules', TRUE, now() - interval '4 days', now() - interval '4 days');

INSERT INTO chat_messages (chat_id, role, content, created_at) VALUES
  (101, 'user', 'Which renewals should I worry about this month?', now() - interval '1 day'),
  (101, 'assistant', 'Two policies renew in the next 14 days with churn signals: **Robert Chen** (Auto + Home Bundle, increase of about 12%, 2 competitor quotes requested) and **Angela Brooks** (HomeShield Standard, rising to $161/month).', now() - interval '1 day'),
  (102, 'user', 'Any claims past the 21-day update standard?', now() - interval '2 days'),
  (102, 'assistant', 'Yes. **Tom Walsh** (CLM-20931, water damage) and **David Okafor** (CLM-21177, auto collision) have both gone more than 21 days without a proactive update.', now() - interval '2 days'),
  (103, 'user', 'Does marriage open special enrollment?', now() - interval '4 days'),
  (103, 'assistant', 'Yes. Marriage opens a 60-day special enrollment period. *Source: Harborline Underwriting Handbook, "Special enrollment periods".*', now() - interval '4 days');

INSERT INTO activity_log (industry_id, record_id, flow_id, action_type, payload, is_seed, created_at) VALUES
  (1, 107, 12, 'email_sent', '{"to":"angela.brooks@example.com","subject":"Your HomeShield Standard quote comparison","summary":"Sent a side-by-side quote comparison"}', TRUE, now() - interval '3 days'),
  (1, 108, 13, 'task_created', '{"title":"Chase adjuster inspection for CLM-20931","summary":"Internal task for the claims team"}', TRUE, now() - interval '5 days');

INSERT INTO tasks (record_id, title, due_date, status, is_seed) VALUES
  (107, 'Call Angela Brooks about the quote comparison', CURRENT_DATE + 1, 'open', TRUE),
  (108, 'Chase adjuster inspection for CLM-20931', CURRENT_DATE - 1, 'done', TRUE);
-- ===========================================================================
-- 2. Banking & Wealth - Crestview Private Bank
-- ===========================================================================

INSERT INTO app_users (industry_id, name, role, email) VALUES
  (2, 'Paul Zikopoulos', 'Relationship Manager', 'paul.zikopoulos@crestview.example');

-- Mortgage math (principal and interest, standard 30-year amortization):
--   Brian Holloway:  $460,000 at 7.5% -> $3,216/month; 26 payments in, balance $450,400;
--                    refinanced at 6.25% over 30 years -> $2,773/month (saves $443).
--   Samantha Lee:    $385,000 at 7.25% -> $2,626/month; 30 payments in, balance $375,200;
--                    refinanced at 6.25% over 30 years -> $2,310/month (saves $316).
INSERT INTO records (id, industry_id, name, email, phone, record_type, attributes) VALUES
  (201, 2, 'Elena Vasquez', 'elena.vasquez@example.com', '(555) 012-4418', 'client',
   '{"first_name":"Elena","relationship_years":6,"segment":"Private Client",
     "deposit_amount":250000,"deposit_source":"the sale of your landscaping business","account_name":"Business Checking account",
     "total_deposits":318000,
     "situation":"Congratulations on closing the sale of your business! That is a huge milestone.",
     "consideration":"With this deposit, your balances with us are now above the $250,000 FDIC coverage limit for a single ownership category, so it is worth deciding where this money should live.",
     "client_goal":"Elena mentioned wanting to fund college for her daughter and eventually retire early."}'),
  (202, 2, 'Michael Thornton', 'michael.thornton@example.com', '(555) 012-7731', 'client',
   '{"first_name":"Michael","relationship_years":11,"segment":"Private Client",
     "deposit_amount":180000,"deposit_source":"the estate of your late mother","account_name":"Personal Checking account",
     "total_deposits":291500,
     "situation":"I was so sorry to hear about the loss of your mother.",
     "consideration":"There is no rush to decide anything. Your balances are now above the $250,000 FDIC coverage limit for a single ownership category, and we can take the next steps at whatever pace feels right to you.",
     "client_goal":"Michael is recently widowed and has said he values stability over growth."}'),
  (203, 2, 'Aisha Karim', 'aisha.karim@example.com', '(555) 012-3065', 'client',
   '{"first_name":"Aisha","relationship_years":1,"segment":"Emerging Wealth",
     "deposit_amount":95000,"deposit_source":"your year-end bonus","account_name":"Personal Checking account",
     "total_deposits":131000,
     "situation":"Congratulations on the bonus. That is a well-earned reward!",
     "consideration":"Right now it is sitting in checking and earning almost nothing, so it may be worth putting it to work.",
     "client_goal":"Aisha is saving for a home down payment in the next 3 to 5 years."}'),
  (204, 2, 'Brian Holloway', 'brian.holloway@example.com', '(555) 012-5582', 'client',
   '{"first_name":"Brian","relationship_years":8,"segment":"Private Client",
     "loan_number":"CV-MTG-10482","current_rate":7.5,"new_rate":6.25,"original_loan":460000,"balance":450400,
     "current_payment":3216,"new_payment":2773,"monthly_savings":443}'),
  (205, 2, 'Samantha Lee', 'samantha.lee@example.com', '(555) 012-9147', 'client',
   '{"first_name":"Samantha","relationship_years":2,"segment":"Emerging Wealth",
     "loan_number":"CV-MTG-11906","current_rate":7.25,"new_rate":6.25,"original_loan":385000,"balance":375200,
     "current_payment":2626,"new_payment":2310,"monthly_savings":316}'),
  (206, 2, 'Kevin Brennan', 'kevin.brennan@example.com', '(555) 012-2290', 'client',
   '{"first_name":"Kevin","relationship_years":5,"segment":"Private Client",
     "card_last4":"4417","card_name":"Crestview Visa Signature","txn_amount":1289,
     "merchant":"TechHub Electronics in Miami, FL","home_city":"Denver, CO",
     "flag_reason":"In-store purchase about 1,700 miles from home, 20 minutes after a gas station purchase in Denver."}'),
  (207, 2, 'Grace Nguyen', 'grace.nguyen@example.com', '(555) 012-6604', 'client',
   '{"first_name":"Grace","relationship_years":9,"segment":"Private Client",
     "card_last4":"9032","card_name":"Crestview World Elite Mastercard","txn_amount":2460,
     "merchant":"Aurelia Fine Jewelry (online)","home_city":"Portland, OR",
     "flag_reason":"Online purchase about 3 times larger than her biggest card purchase this year, from a merchant she has never used."}');

INSERT INTO life_events (record_id, event_type, description, event_date) VALUES
  (201, 'large_deposit',          '$250,000 wire from the sale of her landscaping business', CURRENT_DATE - 2),
  (201, 'fdic_limit_exceeded',    'Deposits now total $318,000, above the $250,000 FDIC limit for one ownership category', CURRENT_DATE - 2),
  (202, 'large_deposit',          '$180,000 inheritance from his late mother''s estate', CURRENT_DATE - 4),
  (202, 'fdic_limit_exceeded',    'Deposits now total $291,500, above the $250,000 FDIC limit for one ownership category', CURRENT_DATE - 4),
  (203, 'large_deposit',          '$95,000 year-end bonus deposited to checking', CURRENT_DATE - 1),
  (204, 'rate_drop',              '30-year fixed fell to 6.25%; pays 7.5% on a $450,400 balance', CURRENT_DATE - 1),
  (205, 'rate_drop',              '30-year fixed fell to 6.25%; pays 7.25% on a $375,200 balance', CURRENT_DATE - 1),
  (206, 'unusual_card_activity',  '$1,289 at TechHub Electronics in Miami, FL on card ending 4417 (home: Denver)', CURRENT_DATE),
  (207, 'unusual_card_activity',  '$2,460 online at Aurelia Fine Jewelry on card ending 9032 (new merchant)', CURRENT_DATE - 1);

INSERT INTO products (id, industry_id, name, description, price, price_unit, discount_pct, eligibility_rules) VALUES
  (21, 2, 'Managed Portfolio',
   'A diversified stock and bond portfolio managed by the Crestview investment team and matched to your goals and risk tolerance, with a 0.85% annual advisory fee and no trading commissions.',
   50000.00, '', 25,
   '{"all":[{"attr":"relationship_years","op":">=","value":3,"label":"3+ years as a Crestview client"}]}'),
  (22, 2, '30-Year Fixed Refinance',
   'Refinance into a 30-year fixed-rate mortgage at 6.25% with no prepayment penalty and a 45-day rate lock. Standard closing costs are $5,400.',
   5400.00, '', 50,
   '{"all":[{"attr":"relationship_years","op":">=","value":3,"label":"3+ years as a Crestview client"}]}'),
  (23, 2, 'High-Yield Savings',
   'FDIC-insured savings account earning 4.10% APY on balances of $25,000 or more, with no monthly fee and same-day transfers to checking.',
   25000.00, '', 0, '{}');

INSERT INTO query_definitions (key, industry_id, description, event_types, days_from, days_to) VALUES
  ('bank_large_deposits',  2, 'Clients with a deposit of $50,000 or more in the last 7 days', '{large_deposit}', -7, 0),
  ('bank_fdic_exposure',   2, 'Clients whose deposits went above the FDIC limit in the last 7 days', '{fdic_limit_exceeded}', -7, 0),
  ('bank_refi_candidates', 2, 'Mortgages at least 0.75 points above the current 30-year rate after a rate drop in the last 7 days', '{rate_drop}', -7, 0),
  ('bank_unusual_spend',   2, 'Cards with unusual activity flagged in the last 2 days', '{unusual_card_activity}', -2, 0);

INSERT INTO flows (id, industry_id, slug, title, description, flow_type, keywords, icon, product_id, sort_order, steps) VALUES
  (21, 2, 'large-deposit-outreach', 'Large deposit conversation',
   'Reach clients who just received a large deposit and start an investment conversation, with relationship pricing applied.',
   'outreach', '{large deposit,large deposits,deposit,deposits,inflow,inflows,windfall,idle cash,investment conversation,managed portfolio}',
   'chart--line', 21, 1,
   '{"query":"bank_large_deposits",
     "agent_steps":["Scanning accounts for deposits of $50,000 or more this week",
                    "Found {{count}} {{record_noun}} with large deposits",
                    "Checking eligibility rules for the {{product}}",
                    "{{eligible_count}} of {{count}} qualify for {{discount_pct}}% off the first-year advisory fee"],
     "table_title":"Clients with large deposits this week",
     "select_hint":"Select the clients you want to start an investment conversation with.",
     "change_label":"Deposit",
     "contact_field":"email",
     "draft_mode":"per_record",
     "content_type":"Email",
     "to":"{{email}}",
     "cc":"{{sender_email}}",
     "subject":"{{first_name}}, a few ideas for your recent deposit",
     "facts":[{"key":"deposit_amount","label":"Deposit amount","kind":"money"},
              {"key":"event_date","label":"Deposit date","kind":"date"},
              {"key":"price","label":"Minimum investment","kind":"money"},
              {"key":"discount_pct","label":"First-year fee discount","kind":"percent"}],
     "approve":{"label":"Send email","action_type":"email_sent","log_label":"Logged to CRM",
                "task_title":"Investment planning call with {{name}}",
                "follow_up":{"business_days":3},
                "confirmation":"Email sent to {{name}}. Logged to CRM. Planning call task created for {{follow_up_day}}."}}'),
  (22, 2, 'refinance-outreach', 'Rate drop refinance outreach',
   'Show mortgage clients exactly how much a refinance saves them after a rate drop.',
   'outreach', '{refinance,refinancing,refi,rate drop,rates dropped,mortgage,mortgages,lower payment}',
   'renew', 22, 2,
   '{"query":"bank_refi_candidates",
     "agent_steps":["Comparing mortgage rates with the current 30-year fixed rate",
                    "Found {{count}} mortgages at least 0.75 points above market",
                    "Calculating new payments with 30-year amortization",
                    "{{eligible_count}} of {{count}} qualify for {{discount_pct}}% off closing costs"],
     "table_title":"Mortgages that benefit from refinancing",
     "select_hint":"Select the borrowers you want to show their savings to.",
     "change_label":"Rate change",
     "contact_field":"email",
     "draft_mode":"per_record",
     "content_type":"Email",
     "to":"{{email}}",
     "cc":"{{sender_email}}",
     "subject":"Rates dropped: you could save {{monthly_savings}} a month",
     "facts":[{"key":"current_rate","label":"Current rate","kind":"percent"},
              {"key":"new_rate","label":"New rate","kind":"percent"},
              {"key":"balance","label":"Loan balance","kind":"money"},
              {"key":"current_payment","label":"Current payment","kind":"money"},
              {"key":"new_payment","label":"New payment","kind":"money"},
              {"key":"monthly_savings","label":"Monthly savings","kind":"money"},
              {"key":"price","label":"Closing costs","kind":"money"},
              {"key":"discount_pct","label":"Closing cost discount","kind":"percent"},
              {"key":"discounted_price","label":"Closing costs after discount","kind":"money"}],
     "approve":{"label":"Send email","action_type":"email_sent","log_label":"Logged to CRM",
                "task_title":"Refinance review call with {{name}}",
                "follow_up":{"business_days":2},
                "confirmation":"Email sent to {{name}}. Logged to CRM. Refinance review task created for {{follow_up_day}}."}}'),
  (23, 2, 'fraud-check-in', 'Unusual spending check-in',
   'Send a friendly text to confirm unusual card activity before it becomes a fraud case.',
   'outreach', '{unusual spending,unusual activity,unusual card,card activity,fraud,suspicious,flagged card,flagged cards}',
   'warning--alt--filled', NULL, 3,
   '{"query":"bank_unusual_spend",
     "agent_steps":["Reviewing card alerts from the last 2 days",
                    "Found {{count}} cards with unusual activity",
                    "Comparing each charge with the client spending pattern",
                    "Writing check-in texts that never ask for card numbers or PINs"],
     "table_title":"Cards flagged for unusual spending",
     "select_hint":"Select the clients who should get a check-in text.",
     "change_label":"Flagged charge",
     "contact_field":"phone",
     "draft_mode":"per_record",
     "content_type":"SMS",
     "to":"{{phone}}",
     "cc":"",
     "subject":"",
     "facts":[{"key":"txn_amount","label":"Charge amount","kind":"money"},
              {"key":"event_date","label":"Charge date","kind":"date"}],
     "approve":{"label":"Send text","action_type":"sms_sent","log_label":"Logged to card security",
                "task_title":"Call {{name}} if there is no reply about card ending {{card_last4}}",
                "follow_up":{"days":1},
                "confirmation":"Text sent to {{name}}. Fraud review ticket {{ticket_id}} opened. Follow-up task created for {{follow_up_day}}.",
                "ticket":{"title":"Unusual activity on card ending {{card_last4}} for {{name}}","queue":"Card Security"}}}'),
  (24, 2, 'policy-qa', 'Ask the policy library',
   'Answers from the Crestview policy library, with the section it came from.',
   'qa', '{policy library,our policy,policy on,what does,how does,how do we,how long,rule,rules,guideline,guidelines,requirement,requirements,fdic,suitability,compliance,disclosure,disclosures}',
   'book', NULL, 4,
   '{"agent_steps":["Searching the Crestview policy library",
                    "Found {{count}} relevant sections",
                    "Reading \"{{top_section}}\"",
                    "Writing an answer with citations"]}');

INSERT INTO signals (id, industry_id, title, description, flow_id, severity, count_query, sort_order) VALUES
  (21, 2, '{{count}} card{{s}} flagged for unusual spending',
   'Charges far from home or far above the usual pattern. A quick check-in text stops fraud early.', 23, 'high', 'bank_unusual_spend', 1),
  (22, 2, '{{count}} client{{s}} received large deposits this week',
   'Business sales, inheritances and bonuses now sitting in checking.', 21, 'high', 'bank_large_deposits', 2),
  (23, 2, '{{count}} client{{s}} now above FDIC coverage limits',
   'New deposits pushed balances past $250,000 in one ownership category.', 21, 'medium', 'bank_fdic_exposure', 3),
  (24, 2, '{{count}} mortgage{{s}} could save $300+ a month by refinancing',
   'Our 30-year fixed rate dropped to 6.25%.', 22, 'medium', 'bank_refi_candidates', 4);

INSERT INTO prompt_templates (flow_id, template_text) VALUES
  (21, $t$Write a warm, personal email from {{sender}} ({{sender_role}}, {{company}}) to {{name}}.

What happened: a deposit of {{deposit_amount}} from {{deposit_source}} arrived in the client's {{account_name}} on {{event_date}}.
Opening: {{situation}}
Why it matters: {{consideration}}
What we know about the client: {{client_goal}} {{first_name}} has banked with {{company_short}} for {{relationship_years}} years.

Mention the {{product}} as one option, with a {{price}} minimum investment. {{product_description}}
{{#eligible}}Offer: {{first_name}} qualifies for {{discount_pct}}% off the advisory fee in the first year.{{/eligible}}{{^eligible}}Note: {{first_name}} does not qualify for the first-year fee discount ({{eligibility_note}}), so do not mention any discount.{{/eligible}}

Rules: do not recommend a specific investment before a suitability conversation, never promise returns, and include this sentence: "Investments are not FDIC insured, are not bank guaranteed and may lose value." Invite {{first_name}} to a 30-minute planning conversation. Match the tone to the situation, plain language, under 180 words.$t$),
  (22, $t$Write a clear, helpful email from {{sender}} ({{sender_role}}, {{company}}) to {{name}} about refinancing mortgage {{loan_number}}.

What happened: {{event}} (recorded {{event_date}}).
Current loan: {{current_rate}}% rate, balance {{balance}}, principal and interest payment {{current_payment}}/month.
Refinance: the {{product}} at {{new_rate}}%. New estimated principal and interest payment {{new_payment}}/month, saving about {{monthly_savings}}/month. {{product_description}}
Closing costs: {{price}}.{{#eligible}} {{first_name}} qualifies for {{discount_pct}}% off closing costs, bringing them to {{discounted_price}}.{{/eligible}}{{^eligible}} {{first_name}} does not qualify for the closing cost discount ({{eligibility_note}}), so do not mention any discount.{{/eligible}}

Use these exact numbers and do not calculate new ones. Say the payments are estimates until a full application confirms the rate, and invite {{first_name}} to a 15-minute call to review the numbers and lock the rate. Under 170 words.$t$),
  (23, $t$Write a short, friendly text message from {{sender_first}} at {{company_short}} to {{first_name}} to check on unusual card activity.

Charge: {{txn_amount}} at {{merchant}} on {{event_date}}, on the {{card_name}} ending in {{card_last4}}.
Why it was flagged (internal, do not include): {{flag_reason}}

Rules: ask {{first_name}} to reply YES if they made the purchase or NO if they did not. Say that {{company_short}} will never ask for a full card number, PIN or passcode. Never ask for any card number, PIN, passcode, password or account details, and do not include links. Calm, not alarming. Under 320 characters, no sign-off block.$t$);

INSERT INTO offline_responses (industry_id, flow_id, kind, response_text) VALUES
  (2, 21, 'draft', $t$Hi {{first_name}},

{{situation}} I noticed the {{deposit_amount}} deposit from {{deposit_source}} arrived in your {{account_name}} on {{event_date}}. {{consideration}}

When you are ready, one option to consider is our {{product}}: a diversified portfolio managed by our investment team and matched to your goals, with a {{price}} minimum investment.{{#eligible}} Because you have banked with {{company_short}} for {{relationship_years}} years, you would get {{discount_pct}}% off the advisory fee in your first year.{{/eligible}}

Before I recommend anything, I would like to understand your goals, your timeline and how much of this you want to keep easy to reach. Could we set up a 30-minute conversation in the next couple of weeks?

Investments are not FDIC insured, are not bank guaranteed and may lose value.

Warm regards,
{{sender}}
{{sender_role}}, {{company}}$t$),
  (2, 22, 'draft', $t$Hi {{first_name}},

Good news: mortgage rates have come down. Our 30-year fixed rate is now {{new_rate}}%, compared with the {{current_rate}}% on your current loan.

Based on your balance of {{balance}}, refinancing could lower your principal and interest payment from {{current_payment}} to about {{new_payment}} a month. That is a savings of roughly {{monthly_savings}} every month.

Standard closing costs are {{price}}.{{#eligible}} Because you have been with {{company_short}} for {{relationship_years}} years, you qualify for {{discount_pct}}% off, which brings them down to {{discounted_price}}.{{/eligible}}

These numbers are estimates until a full application confirms your rate. Could we do a quick 15-minute call this week? I can walk you through everything and lock the rate for you if it makes sense.

Best regards,
{{sender}}
{{sender_role}}, {{company}}$t$),
  (2, 23, 'draft', $t$Hi {{first_name}}, it's {{sender_first}} at {{company_short}}. Did you make a {{txn_amount}} purchase at {{merchant}} on {{event_date}} with your card ending in {{card_last4}}? Reply YES if it was you or NO if not. We will never ask for your full card number or PIN.$t$);

INSERT INTO offline_responses (industry_id, kind, match_keywords, response_text) VALUES
  (2, 'chat', '{call first,first today,prioritize,priority,priorities,who should,which client}', $t$I'd start with the two card check-ins, then the new money. Here's how I'd order your calls today:

1. **Grace Nguyen** - a $2,460 online charge at Aurelia Fine Jewelry hit her card ending 9032 yesterday. It's about 3 times her biggest card purchase this year, from a merchant she has never used.
2. **Kevin Brennan** - his card ending 4417 was used today for $1,289 at TechHub Electronics in Miami, FL, about 1,700 miles from his home in Denver.
3. **Elena Vasquez** - $250,000 from the sale of her landscaping business landed 2 days ago, and her deposits are now above the $250,000 FDIC limit. She has banked with us for 6 years, so she qualifies for 25% off the first-year advisory fee on the Managed Portfolio.
4. **Brian Holloway** - refinancing from 7.5% to 6.25% would lower his payment from $3,216 to $2,773 a month, and he qualifies for 50% off closing costs.

Want me to draft the check-in texts to Grace and Kevin first?$t$),
  (2, 'chat', '{summary,summarize,overview,my day,this week}', $t$Here's your client book at a glance, {{user_first}}:

{{signals_summary}}

The most time-sensitive items are the flagged cards: a quick check-in text now can stop fraud before more charges go through. After that, the large deposits are the biggest opportunity. I can draft outreach for any of these, or answer questions from the policy library.$t$),
  (2, 'chat', '{}', $t$Here's what I'm seeing across your clients right now:

{{signals_summary}}

I can draft a card check-in text, start an investment conversation about a large deposit, show a client their refinance savings, or answer questions from the Crestview policy library. What would you like to do next?$t$);

INSERT INTO knowledge_base (industry_id, source, section_title, content) VALUES
  (2, 'Crestview Relationship Playbook', 'Large deposit review guidelines',
   'Any deposit of $50,000 or more into a client account creates a large deposit alert. The relationship manager should reach out within 5 business days. Lead with the client, not the product: congratulate them on a sale or bonus, and acknowledge a loss with care when the money comes from an inheritance. Point out when the deposit pushes balances above FDIC coverage limits. The first message invites a planning conversation; it never recommends a specific investment.'),
  (2, 'Crestview Relationship Playbook', 'Investment suitability requirements',
   'Before recommending any investment, complete a suitability profile with the client: goals, time horizon, risk tolerance, liquidity needs, income, and existing investments. Encourage clients to keep at least 6 months of expenses in cash before investing. For inheritances and other emotional events, suggest waiting until the client is ready and never set a deadline. Money needed within 3 years, such as a home down payment, belongs in savings, not in a stock portfolio.'),
  (2, 'Crestview Product Guide', 'Managed Portfolio',
   'The Managed Portfolio is a diversified stock and bond portfolio managed by the Crestview investment team. The minimum investment is $50,000 and the annual advisory fee is 0.85%, with no trading commissions. Clients with 3 or more years at Crestview receive 25% off the advisory fee in their first year. Investments are not FDIC insured, are not bank guaranteed and may lose value.'),
  (2, 'Crestview Product Guide', '30-Year Fixed Refinance program',
   'Contact mortgage clients when their rate is at least 0.75 points above the current 30-year fixed rate of 6.25% and the estimated savings are at least $200 per month. Standard closing costs are $5,400, and clients with 3 or more years at Crestview receive 50% off closing costs. Every refinance includes a 45-day rate lock and no prepayment penalty. Payment estimates cover principal and interest only, use standard 30-year amortization on the current balance, and must be labeled as estimates until a full application, appraisal and credit review confirm the rate.'),
  (2, 'Crestview Card Security Procedures', 'Fraud check-in text rules',
   'When a card alert fires, send a check-in text within 1 hour. The text identifies Crestview, the last 4 digits of the card, the amount, the merchant and the date, and asks the client to reply YES or NO. Never ask for a full card number, PIN, CVV, online banking password or one-time passcode, and never include links. A NO reply blocks the card and ships a replacement overnight. If there is no reply within 2 hours, call the client at the phone number on file.'),
  (2, 'Crestview Policy Library', 'FDIC coverage basics',
   'The FDIC insures deposits up to $250,000 per depositor, per insured bank, for each ownership category. Single accounts, joint accounts, certain retirement accounts and trust accounts are separate categories. A joint account is insured up to $250,000 per co-owner, so a two-person joint account is covered up to $500,000. Accounts of a corporation or LLC are insured separately from the owners, but a sole proprietorship counts as the owner''s single account. Investment products are not deposits and are not FDIC insured.'),
  (2, 'Crestview Product Guide', 'High-Yield Savings',
   'High-Yield Savings earns 4.10% APY on balances of $25,000 or more, with no monthly fee and same-day transfers to checking. It is FDIC insured and is the recommended place for money a client wants to keep safe and easy to reach while they decide on a longer-term plan.'),
  (2, 'Crestview Policy Library', 'Client communication compliance',
   'Use plain language and keep emails under 200 words. Every rate, payment and fee must match the loan system and product guide exactly, and payment figures must be labeled as estimates. Any message that mentions an investment product must include the disclosure that investments are not FDIC insured, are not bank guaranteed and may lose value. Never guarantee returns. Emails and texts may show only the last 4 digits of an account or card number. Always copy yourself on client email so it is retained in the CRM.');

INSERT INTO suggestions (industry_id, title, prompt, icon, sort_order) VALUES
  (2, 'Plan my calls', 'Which client should I call first today?', 'chat', 1),
  (2, 'Check a rule', 'How does FDIC coverage work for joint accounts?', 'book', 2),
  (2, 'Show refinance savings', 'Draft refinance outreach for mortgages that benefit from the rate drop', 'email', 3);

INSERT INTO chats (id, industry_id, title, is_seed, created_at, updated_at) VALUES
  (201, 2, 'Large deposits this week', TRUE, now() - interval '1 day', now() - interval '1 day'),
  (202, 2, 'Refinance candidates', TRUE, now() - interval '1 day', now() - interval '1 day'),
  (203, 2, 'Card check-in rules', TRUE, now() - interval '3 days', now() - interval '3 days');

INSERT INTO chat_messages (chat_id, role, content, created_at) VALUES
  (201, 'user', 'Which clients received large deposits this week?', now() - interval '1 day'),
  (201, 'assistant', 'Three clients: **Elena Vasquez** ($250,000 from the sale of her business), **Michael Thornton** ($180,000 inheritance) and **Aisha Karim** ($95,000 year-end bonus). Elena and Michael are now above the $250,000 FDIC limit for a single ownership category.', now() - interval '1 day'),
  (202, 'user', 'Which mortgages benefit from the rate drop?', now() - interval '1 day'),
  (202, 'assistant', 'Two: **Brian Holloway** (7.5% today, about $443/month in savings at 6.25%) and **Samantha Lee** (7.25% today, about $316/month in savings). Brian qualifies for 50% off closing costs; Samantha has been a client for 2 years, so she does not.', now() - interval '1 day'),
  (203, 'user', 'Can I ask a client to confirm their card number by text?', now() - interval '3 days'),
  (203, 'assistant', 'No. Check-in texts may only show the last 4 digits of the card, and you must never ask for a full card number, PIN, CVV, password or one-time passcode. Ask the client to reply YES or NO instead. *Source: Crestview Card Security Procedures, "Fraud check-in text rules".*', now() - interval '3 days');

INSERT INTO activity_log (industry_id, record_id, flow_id, action_type, payload, is_seed, created_at) VALUES
  (2, 202, 21, 'email_sent', '{"to":"michael.thornton@example.com","subject":"Thinking of you","summary":"Sent condolences and offered help with estate paperwork"}', TRUE, now() - interval '3 days'),
  (2, 204, 22, 'task_created', '{"title":"Pull payoff statement for loan CV-MTG-10482","summary":"Internal task for the mortgage team"}', TRUE, now() - interval '2 days');

INSERT INTO tasks (record_id, title, due_date, status, is_seed) VALUES
  (202, 'Schedule estate planning meeting with Michael Thornton', CURRENT_DATE + 2, 'open', TRUE),
  (204, 'Pull payoff statement for loan CV-MTG-10482', CURRENT_DATE - 1, 'done', TRUE);
-- ===========================================================================
-- 3. Healthcare clinic - Maplewood Family Health
-- All patients are fictional.
-- ===========================================================================

INSERT INTO app_users (industry_id, name, role, email) VALUES
  (3, 'Paul Zikopoulos', 'Care Coordinator', 'paul.zikopoulos@maplewood.example');

INSERT INTO records (id, industry_id, name, email, phone, record_type, attributes) VALUES
  (301, 3, 'Rosa Martinez', 'rosa.martinez@example.com', '(555) 013-2284', 'patient',
   '{"first_name":"Rosa","age":52,"pcp":"Dr. Hannah Brooks",
     "screening":"colorectal cancer screening (FIT kit)","last_screening":"16 months ago",
     "interval_note":"we recommend a FIT kit every year for adults 45 to 75",
     "next_step":"We can mail a FIT kit to your home, or you can pick one up at the front desk. It takes about 5 minutes to do at home."}'),
  (302, 3, 'Karen Liu', 'karen.liu@example.com', '(555) 013-6620', 'patient',
   '{"first_name":"Karen","age":46,"pcp":"Dr. Hannah Brooks",
     "screening":"screening mammogram","last_screening":"26 months ago",
     "interval_note":"we recommend a mammogram every 2 years for women 40 to 74",
     "next_step":"We can send the order to Lakeside Imaging today so you can book a time that suits you."}'),
  (303, 3, 'Marcus Johnson', 'marcus.johnson@example.com', '(555) 013-4471', 'patient',
   '{"first_name":"Marcus","age":61,"pcp":"Dr. Samuel Ortiz",
     "screening":"yearly eye exam","last_screening":"13 months ago",
     "interval_note":"we recommend this eye exam every year as part of your ongoing care",
     "next_step":"We can do the exam right here with our retinal camera. It takes about 10 minutes and no eye drops are needed."}'),
  (304, 3, 'Tyrone Ellis', 'tyrone.ellis@example.com', '(555) 013-8812', 'patient',
   '{"first_name":"Tyrone","age":49,"pcp":"Dr. Samuel Ortiz",
     "provider":"Dr. Samuel Ortiz","appointment_time":"9:30 AM","visit_type":"Diabetes follow-up",
     "prior_no_shows":2,"recent_visits":4}'),
  (305, 3, 'Olivia Grant', 'olivia.grant@example.com', '(555) 013-3057', 'patient',
   '{"first_name":"Olivia","age":38,"pcp":"Jordan Hale, NP",
     "provider":"Jordan Hale, NP","appointment_time":"3:15 PM","visit_type":"Blood pressure check",
     "prior_no_shows":2,"recent_visits":3}'),
  (306, 3, 'Walter Simmons', 'walter.simmons@example.com', '(555) 013-7719', 'patient',
   '{"first_name":"Walter","age":72,"pcp":"Dr. Hannah Brooks","lives_alone":true,
     "discharge_hospital":"St. Anne Regional Hospital","diagnosis":"Community-acquired pneumonia",
     "diagnosis_plain":"You had pneumonia. This is an infection in your lungs.",
     "medication":"amoxicillin","dose_mg":875,"dose_schedule":"twice a day for 7 days",
     "medication_tip":"Take every dose until it is gone, even if you feel better.",
     "home_care":"Rest, drink plenty of water, and walk a little more each day.",
     "follow_up_provider":"Dr. Hannah Brooks","follow_up_time":"10:00 AM",
     "warning_signs":"you have trouble breathing, chest pain, a fever above 101 F, or you feel confused or very sleepy."}'),
  (307, 3, 'Denise Carter', 'denise.carter@example.com', '(555) 013-5146', 'patient',
   '{"first_name":"Denise","age":64,"pcp":"Dr. Samuel Ortiz","lives_alone":false,
     "discharge_hospital":"Riverside General Hospital","diagnosis":"COPD exacerbation",
     "diagnosis_plain":"Your COPD flared up. COPD is a long-term lung disease that makes it hard to breathe.",
     "medication":"prednisone","dose_mg":40,"dose_schedule":"once a day in the morning for 5 days",
     "medication_tip":"Take it with food. Keep using your albuterol rescue inhaler when you need it.",
     "home_care":"Use your daily inhaler every day, and stay away from smoke.",
     "follow_up_provider":"Dr. Samuel Ortiz","follow_up_time":"2:30 PM",
     "warning_signs":"your rescue inhaler does not help, your lips or fingertips turn blue, or you cannot finish a sentence without stopping to breathe."}');

INSERT INTO life_events (record_id, event_type, description, event_date) VALUES
  (301, 'screening_overdue',        'Annual FIT colorectal screening overdue (last FIT 16 months ago)', CURRENT_DATE - 120),
  (302, 'screening_overdue',        'Screening mammogram overdue (last one 26 months ago)', CURRENT_DATE - 60),
  (303, 'screening_overdue',        'Annual diabetic eye exam overdue (last one 13 months ago)', CURRENT_DATE - 30),
  (304, 'missed_appointment',       'No-show: diabetes follow-up', CURRENT_DATE - 38),
  (304, 'appointment_noshow_risk',  'Diabetes follow-up with Dr. Ortiz at 9:30 AM; missed 2 of the last 4 visits', CURRENT_DATE + 1),
  (305, 'missed_appointment',       'No-show: blood pressure check', CURRENT_DATE - 21),
  (305, 'appointment_noshow_risk',  'Blood pressure check with Jordan Hale, NP at 3:15 PM; missed 2 of the last 3 visits', CURRENT_DATE + 2),
  (306, 'hospital_discharge',       'Discharged from St. Anne Regional after 4 days with pneumonia', CURRENT_DATE - 1),
  (306, 'follow_up_visit',          'Post-discharge visit with Dr. Brooks', CURRENT_DATE + 4),
  (307, 'hospital_discharge',       'Discharged from Riverside General after 3 days with a COPD flare-up', CURRENT_DATE - 2),
  (307, 'follow_up_visit',          'Post-discharge visit with Dr. Ortiz', CURRENT_DATE + 3);

INSERT INTO products (id, industry_id, name, description, price, price_unit, discount_pct, eligibility_rules) VALUES
  (31, 3, 'Preventive Screening Visit',
   'Recommended screenings are covered at 100% as preventive care by most insurance plans, including Medicare, with no copay and no deductible.',
   0.00, '', 0, '{}'),
  (32, 3, 'Telehealth Follow-Up',
   'A 20-minute video visit with your care team, usually within 2 business days, for a $25 copay with most plans.',
   25.00, '/visit', 0, '{}'),
  (33, 3, 'Evening and Saturday Appointments',
   'Extended hours at our Oak Street clinic on weekday evenings until 8 PM and on Saturdays from 9 AM to 1 PM, for visits, screenings and lab work.',
   0.00, '', 0, '{}');

INSERT INTO query_definitions (key, industry_id, description, event_types, days_from, days_to) VALUES
  ('hc_overdue_screenings', 3, 'Patients whose preventive screening came due in the last 12 months and is still open', '{screening_overdue}', -365, -1),
  ('hc_noshow_risk',        3, 'Appointments in the next 2 days for patients with a no-show history', '{appointment_noshow_risk}', 0, 2),
  ('hc_recent_discharges',  3, 'Patients discharged from a hospital in the last 7 days', '{hospital_discharge}', -7, 0);

INSERT INTO flows (id, industry_id, slug, title, description, flow_type, keywords, icon, product_id, sort_order, steps) VALUES
  (31, 3, 'screening-reminders', 'Overdue screening reminders',
   'Remind patients about preventive screenings they are overdue for, and make booking easy.',
   'outreach', '{screening,screenings,overdue,mammogram,mammograms,colonoscopy,colorectal,fit kit,eye exam,preventive care}',
   'list--checked', 31, 1,
   '{"query":"hc_overdue_screenings",
     "agent_steps":["Checking care gaps against screening intervals",
                    "Found {{count}} {{record_noun}} overdue for a screening",
                    "Confirming preventive coverage for the {{product}}",
                    "Writing reminders without clinical details"],
     "table_title":"Patients overdue for preventive screenings",
     "select_hint":"Select the patients you want to remind.",
     "change_label":"Care gap",
     "contact_field":"email",
     "draft_mode":"per_record",
     "content_type":"Email",
     "to":"{{email}}",
     "cc":"",
     "subject":"{{first_name}}, time to book your {{screening}}",
     "facts":[{"key":"event_date","label":"Due since","kind":"date"},
              {"key":"age","label":"Patient age","kind":"age"}],
     "approve":{"label":"Send email","action_type":"email_sent","log_label":"Logged to chart",
                "task_title":"Check whether {{name}} booked the {{screening}}",
                "follow_up":{"business_days":5},
                "confirmation":"Email sent to {{name}}. Logged to chart. Booking check task created for {{follow_up_day}}."}}'),
  (32, 3, 'no-show-confirmations', 'No-show confirmation texts',
   'Text patients with a no-show history to confirm upcoming appointments.',
   'outreach', '{no show,no shows,confirmation text,confirmation texts,confirm appointments,appointment,appointments,missed appointment,missed appointments}',
   'phone', NULL, 2,
   '{"query":"hc_noshow_risk",
     "agent_steps":["Scanning appointments in the next 2 days",
                    "Found {{count}} {{record_noun}} with a no-show history",
                    "Checking contact preferences and quiet hours",
                    "Writing HIPAA-safe confirmation texts"],
     "table_title":"Upcoming appointments with a no-show history",
     "select_hint":"Select the patients who should get a confirmation text.",
     "change_label":"Appointment",
     "contact_field":"phone",
     "draft_mode":"per_record",
     "content_type":"SMS",
     "to":"{{phone}}",
     "cc":"",
     "subject":"",
     "facts":[{"key":"event_date","label":"Appointment date","kind":"date"}],
     "approve":{"label":"Send text","action_type":"sms_sent","log_label":"Logged to scheduling",
                "task_title":"Check confirmation reply from {{name}}",
                "follow_up":{"days":1},
                "confirmation":"Text sent to {{name}}. Logged to scheduling. Reply check task created for {{follow_up_day}}."}}'),
  (33, 3, 'discharge-summary', 'Plain-language discharge summary',
   'Turn hospital discharge records into clear, 6th-grade portal messages patients can act on.',
   'insight', '{discharge,discharges,discharged,discharge summary,discharge summaries,hospital stay,plain language}',
   'document', NULL, 3,
   '{"query":"hc_recent_discharges",
     "agent_steps":["Pulling hospital discharges from the last 7 days",
                    "Found {{count}} recently discharged {{record_noun}}",
                    "Reading diagnoses, medications and follow-up plans",
                    "Rewriting at a 6th-grade reading level"],
     "table_title":"Patients discharged this week",
     "select_hint":"Select the patients who should get a plain-language summary.",
     "change_label":"Discharge",
     "contact_field":"email",
     "draft_mode":"per_record",
     "content_type":"Portal message",
     "to":"{{name}} (patient portal)",
     "cc":"",
     "subject":"Your hospital stay and next steps",
     "facts":[{"key":"event_date","label":"Discharge date","kind":"date"},
              {"key":"dose_mg","label":"Medication dose","kind":"quantity","unit":"mg"},
              {"key":"date_follow_up_visit","label":"Follow-up visit","kind":"date"}],
     "approve":{"label":"Send to portal","action_type":"portal_message_sent","log_label":"Logged to chart",
                "task_title":"Post-discharge check-in call with {{name}}",
                "follow_up":{"business_days":1},
                "confirmation":"Summary sent to the patient portal for {{name}}. Logged to chart. Check-in call task created for {{follow_up_day}}."}}'),
  (34, 3, 'protocols-qa', 'Ask clinic protocols',
   'Answers from Maplewood clinical protocols and clinic policies, with the section it came from.',
   'qa', '{protocol,protocols,clinic policy,clinic policies,our policy,policy on,what does,how does,how do we,how long,how often,guideline,guidelines,rule,rules,hipaa}',
   'book', NULL, 4,
   '{"agent_steps":["Searching Maplewood protocols and policies",
                    "Found {{count}} relevant sections",
                    "Reading \"{{top_section}}\"",
                    "Writing an answer with citations"]}');

INSERT INTO signals (id, industry_id, title, description, flow_id, severity, count_query, sort_order) VALUES
  (31, 3, '{{count}} patient{{s}} discharged from the hospital this week',
   'Each needs a plain-language summary and a check-in call within 48 hours.', 33, 'high', 'hc_recent_discharges', 1),
  (32, 3, '{{count}} appointment{{s}} in the next 2 days with a no-show history',
   'Repeat no-shows get a confirmation text 1 to 2 days before the visit.', 32, 'high', 'hc_noshow_risk', 2),
  (33, 3, '{{count}} patient{{s}} overdue for preventive screenings',
   'Colorectal, breast and diabetic eye screenings past their due date.', 31, 'medium', 'hc_overdue_screenings', 3);

INSERT INTO prompt_templates (flow_id, template_text) VALUES
  (31, $t$Write a warm, encouraging email from {{sender}} ({{sender_role}}, {{company}}) to {{name}}, age {{age}}.

Care gap: {{first_name}} is due for a {{screening}}. It has been due since {{event_date}}; the last one was {{last_screening}}. Guideline: {{interval_note}}.
Coverage: {{product}}. {{product_description}}
How to get it done: {{next_step}}
Also available: evening and Saturday appointments.

Rules: do not mention any diagnosis, test result or risk factor, and do not give medical advice. Keep it friendly and short, make booking feel easy, and invite {{first_name}} to reply or call (555) 013-0100. Under 150 words.$t$),
  (32, $t$Write a short appointment confirmation text from {{company}} to {{first_name}}.

Appointment: {{event_date}} at {{appointment_time}} with {{provider}}.
Internal context (do not include): {{visit_type}}; missed {{prior_no_shows}} of the last {{recent_visits}} visits.

Rules: HIPAA-safe. Do not mention the reason for the visit, any diagnosis, medication or past missed visits. Ask {{first_name}} to reply C to confirm or R to reschedule, and give the clinic number (555) 013-0100. Friendly, not scolding. Under 320 characters, no sign-off block.$t$),
  (33, $t$Rewrite this hospital discharge record as a patient portal message from {{sender}} ({{sender_role}}, {{company}}) to {{name}}.

Hospital: {{discharge_hospital}}, discharged {{event_date}}.
Diagnosis: {{diagnosis}}. Plain version: {{diagnosis_plain}}
Medication: {{medication}} {{dose_mg}} mg {{dose_schedule}}. {{medication_tip}}
At home: {{home_care}}
Follow-up visit: {{follow_up_provider}} on {{date_follow_up_visit}} at {{follow_up_time}}.
Call the clinic at (555) 013-0100 right away if {{warning_signs}} In an emergency, call 911.

Rules: write at a 6th-grade reading level with short sentences and everyday words. Use short labeled sections. Include only what is in this record: do not add new medical advice, new medications, dose changes or new instructions, and copy the medication name, dose and schedule exactly. Under 200 words.$t$);

INSERT INTO offline_responses (industry_id, flow_id, kind, response_text) VALUES
  (3, 31, 'draft', $t$Hi {{first_name}},

This is {{sender_first}}, a care coordinator at {{company}}. Our records show you are due for your {{screening}}. It has been due since {{event_date}}, and your last one was {{last_screening}}. As a reminder, {{interval_note}}.

Good news: recommended screenings like this one are covered at 100% as preventive care by most insurance plans, so there is usually no cost to you. {{next_step}}

If weekdays are hard, we also have evening and Saturday appointments. Just reply to this email or call us at (555) 013-0100, and we will find a time that works for you.

Take care,
{{sender}}
{{sender_role}}, {{company}}$t$),
  (3, 32, 'draft', $t$Hi {{first_name}}, this is {{company}}. You have an appointment with {{provider}} on {{event_date}} at {{appointment_time}}. Reply C to confirm or R to reschedule. Questions? Call (555) 013-0100.$t$),
  (3, 33, 'draft', $t$Hi {{first_name}},

You went home from {{discharge_hospital}} on {{event_date}}. Here is a short summary of your stay and what to do next.

Why you were in the hospital
{{diagnosis_plain}}

Your medicine
Take {{medication}} {{dose_mg}} mg {{dose_schedule}}. {{medication_tip}}

Taking care of yourself at home
{{home_care}}

Your next visit
You will see {{follow_up_provider}} on {{date_follow_up_visit}} at {{follow_up_time}}.

When to call us
Call us right away at (555) 013-0100 if {{warning_signs}} If it is an emergency, call 911.

We are here to help. You can reply to this message with any questions.

{{sender}}
{{sender_role}}, {{company}}$t$);

INSERT INTO offline_responses (industry_id, kind, match_keywords, response_text) VALUES
  (3, 'chat', '{call first,first today,prioritize,priority,priorities,who should,which patient}', $t$I'd start with **Denise Carter**. Here's how I'd order your calls today:

1. **Denise Carter** - discharged from Riverside General 2 days ago after a COPD flare-up. Our standard is a check-in call within 48 hours of discharge, so her window closes today. She is taking prednisone 40 mg once a day for 5 days.
2. **Walter Simmons** - discharged from St. Anne Regional yesterday after pneumonia. He is 72 and lives alone, and his follow-up visit with Dr. Brooks is in 4 days.
3. **Tyrone Ellis** - has an appointment tomorrow at 9:30 AM with Dr. Ortiz and missed 2 of his last 4 visits. A confirmation text today makes a real difference.

Want me to draft Denise's plain-language discharge summary first?$t$),
  (3, 'chat', '{summary,summarize,overview,my day,this week}', $t$Here's your patient panel at a glance, {{user_first}}:

{{signals_summary}}

The most time-sensitive items are the recent discharges: each patient needs a plain-language summary and a check-in call within 48 hours. I can draft any of these, or answer questions from our clinical protocols and clinic policies.$t$),
  (3, 'chat', '{}', $t$Here's what I'm seeing across your patients right now:

{{signals_summary}}

I can write a plain-language discharge summary, send appointment confirmation texts, remind patients about overdue screenings, or answer questions from Maplewood protocols and policies. What would you like to do next?$t$);

INSERT INTO knowledge_base (industry_id, source, section_title, content) VALUES
  (3, 'Maplewood Clinical Protocols', 'Preventive screening intervals',
   'Colorectal cancer screening: adults 45 to 75, with a FIT kit every year or a colonoscopy every 10 years. Breast cancer screening: a mammogram every 2 years for women 40 to 74. Cervical cancer screening: a Pap test every 3 years from 21 to 29, and a Pap test every 3 years or an HPV test every 5 years from 30 to 65. Diabetic eye exam: every year for adults with diabetes. A screening counts as overdue the day after its due date.'),
  (3, 'Maplewood Clinical Protocols', 'Overdue screening outreach',
   'Send a reminder email when a preventive screening is overdue, a second reminder 30 days later, and a phone call from the care coordinator if the screening is still open after 60 days. Reminders name the screening and how to book it, and mention that most plans cover preventive screenings at 100%. They never include past results, diagnoses or risk factors.'),
  (3, 'Maplewood Clinic Policies', 'No-show and late cancellation policy',
   'A no-show is a missed appointment without at least 24 hours notice. Patients with 2 or more no-shows in the last 12 months receive a confirmation text 1 to 2 days before each visit, and a call if they do not reply. We do not charge no-show fees and we never dismiss a patient for no-shows without a review by their primary care provider. Offer evening and Saturday appointments when timing is the barrier.'),
  (3, 'Maplewood Clinic Policies', 'Appointment confirmation texts',
   'Confirmation texts go out between 8 AM and 8 PM, 1 to 2 days before the appointment. They include the clinic name, the date, the time and the provider name, and ask the patient to reply C to confirm or R to reschedule. They never include the reason for the visit. Keep texts under 320 characters and always include the clinic number, (555) 013-0100.'),
  (3, 'Maplewood Clinical Protocols', 'Discharge communication standards',
   'Every patient discharged from a hospital receives a plain-language summary in the patient portal within 48 hours. Write at a 6th-grade reading level with short sentences and everyday words. Include why they were in the hospital, each medication exactly as prescribed (name, dose and schedule), home care, the follow-up visit, and warning signs that mean they should call us or 911. Only restate what is in the discharge record: never add new medical advice, medications or dose changes. Questions about treatment go to the provider.'),
  (3, 'Maplewood Clinical Protocols', 'Transitional care follow-up',
   'After a hospital discharge, the care coordinator calls the patient within 48 hours to review medications, check that prescriptions were filled and confirm the follow-up visit. The follow-up visit should happen within 7 days of discharge. Patients who are 65 or older, live alone or were treated for COPD, heart failure or pneumonia are high risk and should be seen in person for that first visit.'),
  (3, 'Maplewood Clinic Policies', 'Telehealth visits',
   'Telehealth follow-ups are 20-minute video visits, usually available within 2 business days, with a $25 copay for most plans. They work well for medication checks, blood pressure reviews with a home cuff and lab result discussions. They are not a replacement for the first in-person visit after a hospital stay for high-risk patients.'),
  (3, 'Maplewood Clinic Policies', 'HIPAA-safe messaging',
   'Share the minimum necessary information in every message. Text messages and email may include appointment dates, times, provider names and general reminders, but never a diagnosis, test result, medication or the reason for a visit. Clinical details such as discharge summaries go only through the secure patient portal. Confirm the phone number and email on file before sending, and honor STOP replies right away.');

INSERT INTO suggestions (industry_id, title, prompt, icon, sort_order) VALUES
  (3, 'Plan my calls', 'Which patient should I call first today?', 'chat', 1),
  (3, 'Check a rule', 'What are the HIPAA rules for patient text messages?', 'book', 2),
  (3, 'Reduce no-shows', 'Send confirmation texts for upcoming appointments with a no-show history', 'phone', 3);

INSERT INTO chats (id, industry_id, title, is_seed, created_at, updated_at) VALUES
  (301, 3, 'Discharges this week', TRUE, now() - interval '1 day', now() - interval '1 day'),
  (302, 3, 'No-show risks', TRUE, now() - interval '2 days', now() - interval '2 days'),
  (303, 3, 'FIT test interval', TRUE, now() - interval '4 days', now() - interval '4 days');

INSERT INTO chat_messages (chat_id, role, content, created_at) VALUES
  (301, 'user', 'Who was discharged from the hospital this week?', now() - interval '1 day'),
  (301, 'assistant', 'Two patients: **Walter Simmons** (pneumonia, St. Anne Regional Hospital) and **Denise Carter** (COPD flare-up, Riverside General Hospital). Both need a plain-language summary in the portal and a check-in call within 48 hours of discharge.', now() - interval '1 day'),
  (302, 'user', 'Which upcoming appointments have a no-show history?', now() - interval '2 days'),
  (302, 'assistant', 'Two: **Tyrone Ellis** with Dr. Ortiz (missed 2 of his last 4 visits) and **Olivia Grant** with Jordan Hale, NP (missed 2 of her last 3). Both qualify for a confirmation text 1 to 2 days before the visit.', now() - interval '2 days'),
  (303, 'user', 'How often should patients do a FIT test?', now() - interval '4 days'),
  (303, 'assistant', 'Every year for adults 45 to 75. A colonoscopy every 10 years is the alternative. *Source: Maplewood Clinical Protocols, "Preventive screening intervals".*', now() - interval '4 days');

INSERT INTO activity_log (industry_id, record_id, flow_id, action_type, payload, is_seed, created_at) VALUES
  (3, 305, 32, 'sms_sent', '{"to":"(555) 013-3057","summary":"Sent a reschedule text after a missed blood pressure check"}', TRUE, now() - interval '5 days'),
  (3, 303, 31, 'task_created', '{"title":"Request last eye exam report for Marcus Johnson","summary":"Internal task for the care team"}', TRUE, now() - interval '2 days');

INSERT INTO tasks (record_id, title, due_date, status, is_seed) VALUES
  (303, 'Request last eye exam report for Marcus Johnson', CURRENT_DATE + 1, 'open', TRUE),
  (305, 'Offer Olivia Grant a Saturday appointment slot', CURRENT_DATE - 2, 'done', TRUE);
-- ===========================================================================
-- 4. Retail - Kestrel & Pine Outfitters
-- ===========================================================================

INSERT INTO app_users (industry_id, name, role, email) VALUES
  (4, 'Paul Zikopoulos', 'Customer Experience Lead', 'paul.zikopoulos@kestrelpine.example');

INSERT INTO records (id, industry_id, name, email, phone, record_type, attributes) VALUES
  (401, 4, 'Olivia Grant', 'olivia.grant@example.com', '(555) 014-2207', 'customer',
   $j${"first_name":"Olivia","customer_id":"KP-C-58213","tier":"Summit","lifetime_value":4860,
     "last_purchase_item":"Cascade Down Parka","days_since_purchase":96,
     "favorite_category":"Outerwear","home_store":"Portland Pearl District"}$j$),
  (402, 4, 'Marcus Bell', 'marcus.bell@example.com', '(555) 014-3391', 'customer',
   $j${"first_name":"Marcus","customer_id":"KP-C-44870","tier":"Summit","lifetime_value":3920,
     "last_purchase_item":"Talus Trail Runner","days_since_purchase":118,
     "favorite_category":"Footwear","home_store":"Seattle Capitol Hill"}$j$),
  (403, 4, 'Hannah Reyes', 'hannah.reyes@example.com', '(555) 014-5126', 'customer',
   $j${"first_name":"Hannah","customer_id":"KP-C-61502","tier":"Trailhead","lifetime_value":1640,
     "last_purchase_item":"Merino 200 Base Layer Crew","days_since_purchase":134,
     "favorite_category":"Base layers","home_store":"Denver LoDo"}$j$),
  (404, 4, 'Northfield Textiles', 'dana.kowalski@example.com', '(555) 014-6630', 'supplier',
   $j${"first_name":"Dana","contact_name":"Dana Kowalski","supplier_id":"SUP-1142",
     "sku":"KP-RS3L-M-BLK","item":"Ridgeline 3L Rain Shell (men, size M, black)",
     "on_hand":14,"reorder_point":60,"reorder_qty":240,"unit_cost":118,"order_total":28320,
     "lead_time_days":21}$j$),
  (405, 4, 'Alpine Loop Footwear', 'sam.ortiz@example.com', '(555) 014-7784', 'supplier',
   $j${"first_name":"Sam","contact_name":"Sam Ortiz","supplier_id":"SUP-1178",
     "sku":"KP-TTR-W8-SLT","item":"Talus Trail Runner (women, size 8, slate)",
     "on_hand":9,"reorder_point":40,"reorder_qty":180,"unit_cost":62,"order_total":11160,
     "lead_time_days":14}$j$),
  (406, 4, 'Ben Castillo', 'ben.castillo@example.com', '(555) 014-8812', 'customer',
   $j${"first_name":"Ben","order_number":"KP-100482","item":"Talus Trail Runner","rating":1,
     "store":"Portland Pearl District",
     "review_excerpt":"The sole started peeling away from the upper after two weeks of easy trail miles. For this price I expected a lot more.",
     "remedy":"Your Talus Trail Runners are covered by our Trail Promise warranty, so we will ship you a new pair right away with a prepaid label for the worn pair. There is no need to wait for the return to arrive."}$j$),
  (407, 4, 'Grace Whitfield', 'grace.whitfield@example.com', '(555) 014-9043', 'customer',
   $j${"first_name":"Grace","order_number":"KP-100517","item":"Ridgeline 3L Rain Shell","rating":2,
     "store":"Denver LoDo",
     "review_excerpt":"The main zipper split on my third hike, and the store told me I would have to mail the jacket in for repair myself.",
     "remedy":"Your jacket is covered by our Trail Promise warranty, and any Kestrel & Pine store can take it in for a free zipper repair. If you would rather not wait, bring it to Denver LoDo and the team will swap it for a new one on the spot."}$j$);

INSERT INTO life_events (record_id, event_type, description, event_date) VALUES
  (401, 'vip_lapsed',         'Summit member, last purchase was a Cascade Down Parka; no orders in 96 days', CURRENT_DATE - 96),
  (402, 'vip_lapsed',         'Summit member, last purchase was a Talus Trail Runner; no orders in 118 days', CURRENT_DATE - 118),
  (403, 'vip_lapsed',         'Trailhead member, last purchase was a Merino 200 Base Layer Crew; no orders in 134 days', CURRENT_DATE - 134),
  (404, 'low_stock',          'Ridgeline 3L Rain Shell (M, black) fell to 14 units, below the reorder point of 60', CURRENT_DATE - 1),
  (404, 'stockout_projected', 'Projected stockout of the Ridgeline 3L Rain Shell (M, black) at current sell-through', CURRENT_DATE + 9),
  (405, 'low_stock',          'Talus Trail Runner (W8, slate) fell to 9 units, below the reorder point of 40', CURRENT_DATE),
  (405, 'stockout_projected', 'Projected stockout of the Talus Trail Runner (W8, slate) at current sell-through', CURRENT_DATE + 6),
  (406, 'negative_review',    '1-star review of the Talus Trail Runner (order KP-100482): sole separated after two weeks', CURRENT_DATE - 1),
  (407, 'negative_review',    '2-star review of the Ridgeline 3L Rain Shell (order KP-100517): zipper failed, store would not repair', CURRENT_DATE);

INSERT INTO products (id, industry_id, name, description, price, price_unit, discount_pct, eligibility_rules) VALUES
  (41, 4, 'Ridgeline 3L Rain Shell',
   'Fully seam-taped three-layer waterproof shell with pit zips, a helmet-compatible hood and a stow pocket it packs into.',
   289.00, '', 20,
   '{"all":[{"attr":"lifetime_value","op":">=","value":2000,"label":"$2,000+ lifetime spend with Kestrel & Pine"}]}'),
  (42, 4, 'Talus Trail Runner',
   'Lightweight trail running shoe with a grippy lugged outsole, a rock plate and a roomy toe box for long days on rough ground.',
   149.00, '', 15,
   '{"all":[{"attr":"lifetime_value","op":">=","value":2000,"label":"$2,000+ lifetime spend with Kestrel & Pine"}]}'),
  (43, 4, 'Merino 200 Base Layer Crew',
   'Midweight merino wool crew that stays warm when damp, resists odor on multi-day trips and layers cleanly under a shell.',
   98.00, '', 25,
   '{"all":[{"attr":"lifetime_value","op":">=","value":2000,"label":"$2,000+ lifetime spend with Kestrel & Pine"}]}');

INSERT INTO query_definitions (key, industry_id, description, event_types, days_from, days_to) VALUES
  ('ret_lapsed_vips',  4, 'Trailhead and Summit members with no purchase in 90 or more days', '{vip_lapsed}', -365, -90),
  ('ret_low_stock',    4, 'SKUs that fell below their reorder point in the last 3 days', '{low_stock}', -3, 0),
  ('ret_neg_reviews',  4, 'Reviews rated 2 stars or lower in the last 48 hours', '{negative_review}', -2, 0);

INSERT INTO flows (id, industry_id, slug, title, description, flow_type, keywords, icon, product_id, sort_order, steps) VALUES
  (41, 4, 'vip-win-back', 'VIP win-back offer',
   'Bring lapsed VIP customers back with a personal note and a win-back offer on a product they will love.',
   'outreach', '{win back,winback,lapsed,lapsed customers,vip,vips,dormant,re engage,reengage,come back offer}',
   'user--multiple', 41, 1,
   '{"query":"ret_lapsed_vips",
     "agent_steps":["Querying the loyalty program for VIPs with no purchase in 90+ days",
                    "Found {{count}} lapsed {{record_noun}}",
                    "Checking win-back eligibility for the {{product}}",
                    "{{eligible_count}} of {{count}} qualify for the {{discount_pct}}% win-back offer"],
     "table_title":"Lapsed VIP customers",
     "select_hint":"Select the customers you want to win back.",
     "change_label":"Last purchase",
     "contact_field":"email",
     "draft_mode":"per_record",
     "content_type":"Email",
     "to":"{{email}}",
     "cc":"{{sender_email}}",
     "subject":"We saved something for you, {{first_name}}",
     "facts":[{"key":"discount_pct","label":"Win-back discount","kind":"percent"},
              {"key":"price","label":"Regular price","kind":"money"},
              {"key":"discounted_price","label":"Price after discount","kind":"money"},
              {"key":"savings","label":"Customer saves","kind":"money"},
              {"key":"event_date","label":"Last purchase","kind":"date"}],
     "approve":{"label":"Send email","action_type":"email_sent","log_label":"Logged to customer profile",
                "task_title":"Check whether {{name}} redeemed the {{product}} offer",
                "follow_up":{"days":7},
                "confirmation":"Email sent to {{name}}. Logged to customer profile. Redemption check created for {{follow_up_day}}."}}'),
  (42, 4, 'supplier-reorder', 'Low-stock supplier reorder',
   'Catch SKUs that dropped below their reorder point and send the supplier a precise reorder request.',
   'outreach', '{reorder,reorders,reorder point,restock,low stock,stock levels,inventory,supplier,suppliers,purchase order,out of stock,stockout}',
   'tool-kit', NULL, 2,
   '{"query":"ret_low_stock",
     "agent_steps":["Checking on-hand inventory against reorder points",
                    "Found {{count}} SKUs below their reorder point",
                    "Pulling supplier contacts, unit costs and lead times",
                    "Calculating reorder quantities and order totals"],
     "table_title":"SKUs below reorder point",
     "select_hint":"Select the suppliers to send a reorder request to.",
     "change_label":"Stock alert",
     "contact_field":"email",
     "draft_mode":"per_record",
     "content_type":"Email",
     "to":"{{email}}",
     "cc":"purchasing@kestrelpine.example",
     "subject":"Reorder request: {{item}} ({{sku}})",
     "facts":[{"key":"on_hand","label":"On hand","kind":"quantity","unit":"units"},
              {"key":"reorder_qty","label":"Reorder quantity","kind":"quantity","unit":"units"},
              {"key":"unit_cost","label":"Unit cost","kind":"money"},
              {"key":"order_total","label":"Order total","kind":"money"},
              {"key":"lead_time_days","label":"Standard lead time","kind":"quantity","unit":"days"},
              {"key":"date_stockout_projected","label":"Projected stockout","kind":"date"}],
     "approve":{"label":"Send reorder request","action_type":"email_sent","log_label":"Logged to purchasing",
                "task_title":"Confirm the {{sku}} reorder with {{contact_name}} at {{name}}",
                "follow_up":{"business_days":2},
                "confirmation":"Reorder request sent to {{contact_name}} at {{name}}. Logged to purchasing. Confirmation check created for {{follow_up_day}}."}}'),
  (43, 4, 'review-response', 'Negative review reply and ticket',
   'Reply personally to low-rated reviews and open a Store Operations ticket so the root cause gets fixed.',
   'outreach', '{review,reviews,negative review,negative reviews,bad review,bad reviews,one star,1 star,two star,complaint,complaints,unhappy customer,unhappy customers}',
   'chat', NULL, 3,
   '{"query":"ret_neg_reviews",
     "agent_steps":["Scanning reviews posted in the last 48 hours",
                    "Found {{count}} reviews rated 2 stars or lower",
                    "Matching each review to its order and store",
                    "Preparing replies and Store Operations tickets"],
     "table_title":"Low-rated reviews in the last 48 hours",
     "select_hint":"Select the reviews you want to respond to.",
     "change_label":"Review",
     "contact_field":"email",
     "draft_mode":"per_record",
     "content_type":"Email",
     "to":"{{email}}",
     "cc":"{{sender_email}}",
     "subject":"About your {{item}} from Kestrel & Pine",
     "facts":[{"key":"rating","label":"Rating","kind":"quantity","unit":"stars"},
              {"key":"event_date","label":"Review posted","kind":"date"}],
     "approve":{"label":"Send reply and open ticket","action_type":"email_sent","log_label":"Logged to customer profile",
                "task_title":"Confirm {{name}} received the fix for order {{order_number}}",
                "follow_up":{"business_days":3},
                "ticket":{"title":"Review follow-up: {{item}}, order {{order_number}} ({{store}})","queue":"Store Operations"},
                "confirmation":"Reply sent to {{name}}. Ticket #{{ticket_id}} opened in Store Operations for the {{store}} store. Follow-up task created for {{follow_up_day}}."}}'),
  (44, 4, 'policy-qa', 'Ask the store policy guide',
   'Answers from the Kestrel & Pine policy guide and customer experience playbook, with the section it came from.',
   'qa', '{policy,policies,return policy,returns,return window,refund,refunds,exchange,exchanges,warranty,trail promise,price match,price matching,loyalty tier,loyalty tiers,tier benefits,what is our,how does,how do we,what does}',
   'book', NULL, 4,
   '{"agent_steps":["Searching the Kestrel & Pine policy guide",
                    "Found {{count}} relevant sections",
                    "Reading \"{{top_section}}\"",
                    "Writing an answer with citations"]}');

INSERT INTO signals (id, industry_id, title, description, flow_id, severity, count_query, sort_order) VALUES
  (41, 4, '{{count}} negative review{{s}} in the last 48 hours',
   'Our standard is a personal reply within 24 hours.', 43, 'high', 'ret_neg_reviews', 1),
  (42, 4, '{{count}} SKU{{s}} below reorder point',
   'Projected to sell out before a standard-lead-time order would arrive.', 42, 'high', 'ret_low_stock', 2),
  (43, 4, '{{count}} VIP{{s}} lapsed 90+ days without a purchase',
   'High lifetime value customers who have gone quiet since their last order.', 41, 'medium', 'ret_lapsed_vips', 3);

INSERT INTO prompt_templates (flow_id, template_text) VALUES
  (41, $t$Write a warm, personal win-back email from {{sender}} ({{sender_role}}, {{company}}) to {{name}}.

Customer: {{first_name}} is a {{tier}} member. Their last purchase was the {{last_purchase_item}} on {{event_date}}, {{days_since}} days ago, and they mostly shop {{favorite_category}} at our {{home_store}} store.
Do not mention their exact spend or how many days it has been.

Recommend the {{product}} at {{price}}: {{product_description}}
{{#eligible}}Offer: {{first_name}} qualifies for our {{discount_pct}}% win-back offer, which brings it to {{discounted_price}} (a saving of {{savings}}). The offer is valid for two weeks.{{/eligible}}{{^eligible}}Note: {{first_name}} does not qualify for the win-back discount ({{eligibility_note}}), so do not mention any discount. Mention free shipping and free returns as a {{tier}} member instead.{{/eligible}}

Friendly and outdoorsy, no guilt, no pressure. Invite them to reply or visit the {{home_store}} store. Under 150 words.$t$),
  (42, $t$Write a clear, professional reorder request from {{sender}} ({{sender_role}}, {{company}}) to {{contact_name}} at {{name}}.

Item: {{item}}, SKU {{sku}}.
Situation: {{event}}. We have {{on_hand}} units on hand and project a stockout on {{date_stockout_projected}}.
Order: {{reorder_qty}} units at {{unit_cost}} per unit, for an order total of {{order_total}}.
Their standard lead time is {{lead_time_days}} days, which lands after the projected stockout, so ask whether an earlier ship date or a partial shipment is possible.

Ask {{first_name}} to confirm quantity, price and ship date by reply. Say a formal purchase order follows once confirmed. Every number must match exactly. Under 150 words.$t$),
  (43, $t$Write a sincere, personal reply from {{sender}} ({{sender_role}}, {{company}}) to {{name}}, who left a {{rating}}-star review on {{event_date}}.

Order: {{order_number}}, {{item}}, bought at our {{store}} store.
What they wrote: "{{review_excerpt}}"
What we will do: {{remedy}}

Thank them for the honest feedback, apologize without excuses, quote or paraphrase the specific problem so they know a person read it, explain the fix in plain language, and say the {{store}} store team has been asked to follow up so it does not happen again. Do not offer cash or store credit. Under 160 words.$t$);

INSERT INTO offline_responses (industry_id, flow_id, kind, response_text) VALUES
  (4, 41, 'draft', $t$Hi {{first_name}},

We have missed you at Kestrel & Pine! I hope your {{last_purchase_item}} has seen plenty of trail time since you picked it up on {{event_date}}.

With the wet season on its way, I thought of you when the {{product}} came back in stock. {{product_description}} It is {{price}}.{{#eligible}} As a thank-you to one of our {{tier}} members, I have saved you {{discount_pct}}% off, which brings it to {{discounted_price}} (you save {{savings}}). The offer is yours for the next two weeks.{{/eligible}}{{^eligible}} As a {{tier}} member, shipping and returns are always free for you.{{/eligible}}

Just reply to this email if you would like me to set one aside at our {{home_store}} store, or grab it online whenever you are ready.

See you out there,
{{sender}}
{{sender_role}}, {{company}}$t$),
  (4, 42, 'draft', $t$Hi {{first_name}},

We need to reorder the {{item}} (SKU {{sku}}). We are down to {{on_hand}} units on hand across our stores, and at the current sell-through we project a stockout on {{date_stockout_projected}}.

Could you please confirm the following order?
- Quantity: {{reorder_qty}} units
- Unit cost: {{unit_cost}}
- Order total: {{order_total}}

Your standard lead time is {{lead_time_days}} days, which lands after our projected stockout. If an earlier ship date or a partial shipment is possible, that would help us a lot.

Please reply with the confirmed quantity, price and ship date, and I will send the formal purchase order right away.

Thank you,
{{sender}}
{{sender_role}}, {{company}}$t$),
  (4, 43, 'draft', $t$Hi {{first_name}},

Thank you for taking the time to review your {{item}} (order {{order_number}}). I read your note, "{{review_excerpt}}", and I am truly sorry. That is not the experience we want anyone to have with our gear or our stores.

Here is what we will do: {{remedy}}

I have also asked the {{store}} store team to follow up on what happened, so the next customer gets this right the first time.

If anything else comes up, reply to this email and it will come straight to me.

With apologies and thanks,
{{sender}}
{{sender_role}}, {{company}}$t$);

INSERT INTO offline_responses (industry_id, kind, match_keywords, response_text) VALUES
  (4, 'chat', '{first today,contact first,prioritize,priority,priorities,which customer,who should}', $t$I'd start with **Ben Castillo**. Here's how I'd order today:

1. **Ben Castillo** - he left a 1-star review of the Talus Trail Runner yesterday (order KP-100482, Portland Pearl District store) after the sole separated within two weeks. Our standard is a personal reply within 24 hours, and it's covered by the Trail Promise warranty.
2. **Grace Whitfield** - a 2-star review of the Ridgeline 3L Rain Shell today (order KP-100517). The Denver LoDo store told her to mail the jacket in for a zipper repair, which goes against our warranty policy, so it also needs a Store Operations ticket.
3. **Olivia Grant** - a Summit member with $4,860 in lifetime spend who hasn't ordered in 96 days. She qualifies for the 20% win-back offer on the Ridgeline 3L Rain Shell.

One supplier item to fit in too: **Northfield Textiles** is down to 14 units of the rain shell with a 21-day lead time, and the $28,320 order needs merchandising director approval.

Want me to draft the reply to Ben first?$t$),
  (4, 'chat', '{summary,summarize,overview,my day,this week}', $t$Here's where things stand across the stores, {{user_first}}:

{{signals_summary}}

The most time-sensitive items are the two low-rated reviews: our standard is a personal reply within 24 hours. I can draft review replies, supplier reorders or win-back offers, or answer questions from the store policy guide.$t$),
  (4, 'chat', '{}', $t$Here's what I'm seeing across Kestrel & Pine right now:

{{signals_summary}}

I can draft replies to low-rated reviews, send reorder requests to suppliers, prepare win-back offers for lapsed VIPs, or answer questions about returns, warranty, price matching and loyalty tiers. What would you like to do next?$t$);

INSERT INTO knowledge_base (industry_id, source, section_title, content) VALUES
  (4, 'Kestrel & Pine Store Policy Guide', 'Returns and exchanges',
   'Unused items with tags can be returned or exchanged for a full refund within 60 days of purchase, in any store or by mail with the prepaid label in the order email. Summit members get 365 days. Used gear that has not failed can be returned within 30 days for store credit. Refunds go back to the original payment method within 5 business days. There is no restocking fee, and returns from online orders are always accepted in stores.'),
  (4, 'Kestrel & Pine Store Policy Guide', 'Trail Promise warranty',
   'All Kestrel & Pine brand apparel is covered for life against defects in materials and workmanship, and Kestrel & Pine footwear is covered for 1 year. Zipper, seam and sole failures are defects. We repair first when a repair can be done well, otherwise we replace the item or issue a refund. Every store accepts warranty items at the service desk and ships them to our repair center at our cost. A customer should never be told to mail a warranty item in themselves.'),
  (4, 'Kestrel & Pine Store Policy Guide', 'Price match',
   'We match a lower advertised price on an identical item (same brand, model, size and color) from an authorized US retailer, at the time of purchase or within 14 days after. Show the associate the live listing. Clearance, marketplace sellers, bundle deals and member-only prices from other retailers are excluded. Price matches cannot be combined with the win-back offer.'),
  (4, 'Kestrel & Pine Store Policy Guide', 'Loyalty tiers',
   'Basecamp is free for everyone and earns 1 point per dollar. Trailhead starts at $750 spent in 12 months and adds free shipping and a birthday reward. Summit starts at $2,000 spent in 12 months and adds 2 points per dollar, free returns for 365 days, early access to new gear and a dedicated service line. Once earned, a tier is held for the following 12 months. Trailhead and Summit members together are treated as VIPs.'),
  (4, 'Kestrel & Pine Customer Experience Playbook', 'VIP win-back program',
   'A VIP is lapsed after 90 days without a purchase. Send a personal email from a named person, not a campaign blast, recommending one product that fits what they bought before. Customers with $2,000 or more in lifetime spend receive the product''s win-back discount, valid for 14 days and limited to one win-back offer per customer every 12 months. Customers below that threshold get the personal note without a discount; never mention their spend or how long it has been.'),
  (4, 'Kestrel & Pine Customer Experience Playbook', 'Responding to negative reviews',
   'Every review rated 2 stars or lower gets a personal email reply within 24 hours of posting. Name the specific problem, apologize without excuses, and explain exactly how we will fix it under the Trail Promise warranty or the returns policy. Do not offer cash or store credit to settle a review. When the review mentions a store experience, open a ticket in the Store Operations queue so the store manager can follow up with the team.'),
  (4, 'Kestrel & Pine Merchandising Handbook', 'Supplier reorders',
   'Each SKU has a reorder point set to cover the supplier lead time plus two weeks of safety stock. When on-hand inventory falls below it, email the supplier contact with the SKU, quantity, unit cost and order total, and ask for an earlier or partial shipment when the lead time is longer than the time to a projected stockout. Purchase orders over $25,000 need merchandising director approval before they are issued.'),
  (4, 'Kestrel & Pine Customer Experience Playbook', 'Customer communication standards',
   'Write like a person who spends weekends outside: warm, plain and specific. Every price, discount and date must match the product catalog and order records exactly. Copy yourself on customer emails so they log to the customer profile, keep emails under 200 words, and never pressure a customer to buy.');

INSERT INTO suggestions (industry_id, title, prompt, icon, sort_order) VALUES
  (4, 'Plan my day', 'Which customer should I contact first today?', 'chat', 1),
  (4, 'Check a policy', 'What is our price match policy?', 'book', 2),
  (4, 'Win back VIPs', 'Draft win-back offers for lapsed VIPs', 'email', 3);

INSERT INTO chats (id, industry_id, title, is_seed, created_at, updated_at) VALUES
  (401, 4, 'Rain shell stock check', TRUE, now() - interval '1 day', now() - interval '1 day'),
  (402, 4, 'Warranty repairs in stores', TRUE, now() - interval '3 days', now() - interval '3 days'),
  (403, 4, 'Summit tier return window', TRUE, now() - interval '5 days', now() - interval '5 days');

INSERT INTO chat_messages (chat_id, role, content, created_at) VALUES
  (401, 'user', 'How are we doing on Ridgeline rain shells?', now() - interval '1 day'),
  (401, 'assistant', 'Men''s size M in black is the problem: **Northfield Textiles** SKU KP-RS3L-M-BLK is at 14 units against a reorder point of 60. A 240-unit reorder at $118 per unit comes to $28,320, which is over the $25,000 approval threshold.', now() - interval '1 day'),
  (402, 'user', 'Can a store send a warranty item out for repair, or does the customer have to mail it?', now() - interval '3 days'),
  (402, 'assistant', 'Every store accepts warranty items at the service desk and ships them to the repair center at our cost. A customer should never be told to mail a warranty item in themselves. *Source: Kestrel & Pine Store Policy Guide, "Trail Promise warranty".*', now() - interval '3 days'),
  (403, 'user', 'How long do Summit members have to return something?', now() - interval '5 days'),
  (403, 'assistant', 'Summit members get 365 days to return unused items with tags, compared with 60 days for everyone else. *Source: Kestrel & Pine Store Policy Guide, "Returns and exchanges".*', now() - interval '5 days');

INSERT INTO activity_log (industry_id, record_id, flow_id, action_type, payload, is_seed, created_at) VALUES
  (4, 405, 42, 'email_sent', '{"to":"sam.ortiz@example.com","subject":"Ship date for the Talus Trail Runner men size 10 reorder","summary":"Confirmed the ship date on an earlier reorder"}', TRUE, now() - interval '4 days'),
  (4, 407, 43, 'task_created', '{"title":"Pull Denver LoDo service desk notes for order KP-100517","summary":"Internal task for Store Operations"}', TRUE, now() - interval '2 hours');

INSERT INTO tasks (record_id, title, due_date, status, is_seed) VALUES
  (407, 'Pull Denver LoDo service desk notes for order KP-100517', CURRENT_DATE + 1, 'open', TRUE),
  (405, 'Confirm ship date with Alpine Loop Footwear', CURRENT_DATE - 2, 'done', TRUE);
-- ===========================================================================
-- 5. Human resources - Brightline Technologies
-- ===========================================================================

INSERT INTO app_users (industry_id, name, role, email) VALUES
  (5, 'Paul Zikopoulos', 'HR Business Partner', 'paul.zikopoulos@brightline.example');

INSERT INTO records (id, industry_id, name, email, phone, record_type, attributes) VALUES
  (501, 5, 'Nadia Petrov', 'nadia.petrov@brightline.example', '(555) 015-3318', 'employee',
   $j${"first_name":"Nadia","employee_id":"BL-1042","title":"Senior Product Designer","department":"Design",
     "manager":"Chris Alvarez","manager_first":"Chris","manager_email":"chris.alvarez@brightline.example",
     "years":5,"is_milestone":1,
     "milestone_note":"Five years also adds a fifth week of PTO for Nadia, starting this year.",
     "recent_highlight":"She led the redesign of the customer onboarding app, which cut setup time in half"}$j$),
  (502, 5, 'Daniel Hughes', 'daniel.hughes@brightline.example', '(555) 015-4427', 'employee',
   $j${"first_name":"Daniel","employee_id":"BL-0318","title":"Staff Software Engineer","department":"Platform Engineering",
     "manager":"Priya Nair","manager_first":"Priya","manager_email":"priya.nair@brightline.example",
     "years":10,"is_milestone":1,
     "milestone_note":"Ten years also unlocks a 4-week paid sabbatical, to be taken within the next 12 months.",
     "recent_highlight":"He mentored four engineers through promotion and led the move to the new deployment pipeline"}$j$),
  (503, 5, 'Sam Rivera', 'sam.rivera@brightline.example', '(555) 015-5186', 'employee',
   $j${"first_name":"Sam","employee_id":"BL-1587","title":"Customer Success Manager","department":"Customer Success",
     "manager":"Tanya Holt","manager_first":"Tanya","manager_email":"tanya.holt@brightline.example",
     "years":3,"is_milestone":0,
     "recent_highlight":"Sam kept every one of their 40 enterprise accounts through renewal this year"}$j$),
  (504, 5, 'Leah Kim', 'leah.kim@example.com', '(555) 015-6204', 'employee',
   $j${"first_name":"Leah","employee_id":"BL-2211","title":"Data Analyst","department":"Finance",
     "manager":"Omar Haddad","manager_first":"Omar","manager_email":"omar.haddad@brightline.example",
     "buddy":"Wes Turner, Senior Data Analyst",
     "laptop":"MacBook Pro 14-inch, delivered to your home before your first day",
     "work_location":"Austin office, 5th floor (hybrid, Tuesday to Thursday in the office). Check in at the front desk.",
     "first_day_schedule":"9:00 IT setup and badge photo, 10:30 welcome session with the People team, 12:00 team lunch with Omar and Wes, 2:00 benefits walkthrough, 3:30 first 1:1 with Omar"}$j$),
  (505, 5, 'Marco Silva', 'marco.silva@example.com', '(555) 015-7390', 'employee',
   $j${"first_name":"Marco","employee_id":"BL-2214","title":"Account Executive","department":"Sales",
     "manager":"Rachel Stein","manager_first":"Rachel","manager_email":"rachel.stein@brightline.example",
     "buddy":"Jenna Park, Senior Account Executive",
     "laptop":"MacBook Air 13-inch, arriving by courier two days before your start",
     "work_location":"Remote from Denver. The video links are in your calendar invites.",
     "first_day_schedule":"9:00 IT setup call, 10:00 virtual welcome session, 11:30 sales team stand-up, 1:00 first 1:1 with Rachel, 3:00 CRM training"}$j$),
  (506, 5, 'Aisha Bello', 'aisha.bello@example.com', '(555) 015-8155', 'employee',
   $j${"first_name":"Aisha","employee_id":"BL-2219","title":"Site Reliability Engineer","department":"Platform Engineering",
     "manager":"Priya Nair","manager_first":"Priya","manager_email":"priya.nair@brightline.example",
     "buddy":"Daniel Hughes, Staff Software Engineer",
     "laptop":"MacBook Pro 16-inch, ready for pickup at the IT bar on your first morning",
     "work_location":"Austin office, 3rd floor (hybrid, Tuesday to Thursday in the office). Check in at the front desk.",
     "first_day_schedule":"9:00 laptop pickup and IT setup, 10:30 welcome session with the People team, 12:00 lunch with Daniel, 1:30 platform architecture overview, 3:30 first 1:1 with Priya"}$j$),
  (507, 5, 'Kevin Liu', 'kevin.liu@brightline.example', '(555) 015-9062', 'employee',
   $j${"first_name":"Kevin","employee_id":"BL-1893","title":"Marketing Manager","department":"Marketing",
     "manager":"Rachel Stein","manager_first":"Rachel","manager_email":"rachel.stein@brightline.example",
     "years":2,"is_milestone":0,
     "recent_highlight":"He ran the product launch campaign that doubled trial sign-ups"}$j$);

INSERT INTO life_events (record_id, event_type, description, event_date) VALUES
  (501, 'milestone_anniversary', '5-year work anniversary (milestone)', CURRENT_DATE + 1),
  (502, 'milestone_anniversary', '10-year work anniversary (milestone)', CURRENT_DATE + 3),
  (503, 'anniversary',           '3-year work anniversary', CURRENT_DATE),
  (507, 'anniversary',           '2-year work anniversary', CURRENT_DATE + 12),
  (504, 'start_date',            'Starts as Data Analyst in Finance (hybrid, Austin)', CURRENT_DATE + 2),
  (505, 'start_date',            'Starts as Account Executive in Sales (remote, Denver)', CURRENT_DATE + 4),
  (506, 'start_date',            'Starts as Site Reliability Engineer in Platform Engineering (hybrid, Austin)', CURRENT_DATE + 6);

INSERT INTO products (id, industry_id, name, description, price, price_unit, discount_pct, eligibility_rules) VALUES
  (51, 5, 'Milestone Recognition Gift',
   'For 5, 10, 15 and 20-year work anniversaries: a gift the employee picks from the Brightline recognition catalog, a handwritten card from the CEO and a shout-out at the next all-hands.',
   500.00, '', 0,
   '{"all":[{"attr":"is_milestone","op":">=","value":1,"label":"5, 10, 15 or 20-year milestone"}]}'),
  (52, 5, 'Home Office Setup Allowance',
   'One-time allowance for a desk, chair, monitor or other workspace gear, claimed through the expense tool within the first 90 days.',
   600.00, '', 0, '{}'),
  (53, 5, 'Learning and Growth Stipend',
   'Annual budget for courses, certifications, conferences and books. Available from day one; unused funds do not roll over.',
   1500.00, '/year', 0, '{}');

INSERT INTO query_definitions (key, industry_id, description, event_types, days_from, days_to) VALUES
  ('hr_anniversaries', 5, 'Work anniversaries from 2 days ago through the next 5 days', '{anniversary,milestone_anniversary}', -2, 5),
  ('hr_milestones',    5, 'Milestone (5, 10, 15, 20-year) anniversaries from 2 days ago through the next 5 days', '{milestone_anniversary}', -2, 5),
  ('hr_new_hires',     5, 'New hires starting in the next 7 days', '{start_date}', 0, 7);

INSERT INTO flows (id, industry_id, slug, title, description, flow_type, keywords, icon, product_id, sort_order, steps) VALUES
  (51, 5, 'anniversary-nudge', 'Work anniversary manager nudge',
   'Remind managers about upcoming work anniversaries, with milestone perks and a highlight worth celebrating.',
   'outreach', '{work anniversary,work anniversaries,anniversaries,anniversary nudge,milestone anniversary,milestone anniversaries,years of service,service award}',
   'user--avatar', 51, 1,
   '{"query":"hr_anniversaries",
     "agent_steps":["Checking the HRIS for work anniversaries this week",
                    "Found {{count}} {{record_noun}} with an anniversary",
                    "Checking milestone eligibility for the {{product}}",
                    "{{eligible_count}} of {{count}} are milestone anniversaries"],
     "table_title":"Work anniversaries this week",
     "select_hint":"Select the employees whose managers should get a nudge.",
     "change_label":"Anniversary",
     "contact_field":"email",
     "draft_mode":"per_record",
     "content_type":"Email",
     "to":"{{manager_email}}",
     "cc":"{{sender_email}}",
     "subject":"Heads-up: {{name}} celebrates {{years}} years on {{event_date}}",
     "facts":[{"key":"years","label":"Years of service","kind":"quantity","unit":"year"},
              {"key":"event_date","label":"Anniversary date","kind":"date"},
              {"key":"price","label":"Gift budget","kind":"money"}],
     "approve":{"label":"Send to manager","action_type":"email_sent","log_label":"Logged to HRIS",
                "task_title":"Check that {{manager}} recognized {{name}}",
                "follow_up":{"business_days":1},
                "confirmation":"Nudge sent to {{manager}} about {{name}}. Logged to HRIS. Check-in task created for {{follow_up_day}}."}}'),
  (52, 5, 'new-hire-onboarding', 'New hire onboarding and welcome',
   'Confirm the laptop, buddy and first-day schedule for each new hire and send a welcome email with their manager copied.',
   'outreach', '{new hire,new hires,onboarding,onboard,new starter,new starters,welcome email,starting soon,first day}',
   'list--checked', 52, 2,
   '{"query":"hr_new_hires",
     "agent_steps":["Checking the HRIS for start dates in the next 7 days",
                    "Found {{count}} new hires",
                    "Confirming laptop, onboarding buddy and first-day schedule",
                    "Preparing welcome emails with managers copied"],
     "table_title":"New hires starting in the next 7 days",
     "select_hint":"Select the new hires who should get a welcome email.",
     "change_label":"Start",
     "contact_field":"email",
     "draft_mode":"per_record",
     "content_type":"Email",
     "to":"{{email}}",
     "cc":"{{manager_email}}",
     "subject":"Welcome to Brightline, {{first_name}}! Your first day on {{event_date}}",
     "facts":[{"key":"event_date","label":"Start date","kind":"date"},
              {"key":"price","label":"Allowance","kind":"money"}],
     "approve":{"label":"Send welcome email","action_type":"email_sent","log_label":"Logged to onboarding tracker",
                "task_title":"Confirm laptop and buddy are ready for {{name}}",
                "follow_up":{"business_days":1},
                "confirmation":"Welcome email sent to {{name}} with {{manager}} copied. Logged to onboarding tracker. Readiness check created for {{follow_up_day}}."}}'),
  (53, 5, 'handbook-qa', 'Ask the employee handbook',
   'Answers from the Brightline Employee Handbook, with the section it came from.',
   'qa', '{handbook,pto,paid time off,vacation,time off,sick leave,sick day,sick days,holiday,holidays,parental leave,maternity,paternity,remote work,work from home,hybrid,expense,expenses,reimbursement,learning stipend,stipend,benefits,benefits enrollment,open enrollment,sabbatical,policy,policies,how many,how much,how does,how do i,what is our}',
   'book', NULL, 3,
   '{"agent_steps":["Searching the Brightline Employee Handbook",
                    "Found {{count}} relevant sections",
                    "Reading \"{{top_section}}\"",
                    "Writing an answer with citations"]}');

INSERT INTO signals (id, industry_id, title, description, flow_id, severity, count_query, sort_order) VALUES
  (51, 5, '{{count}} new hire{{s}} start in the next 7 days',
   'Laptops, buddies and first-day schedules to confirm before day one.', 52, 'high', 'hr_new_hires', 1),
  (52, 5, '{{count}} milestone anniversar{{ies}} this week',
   '5 and 10-year milestones come with a recognition gift and extra perks.', 51, 'high', 'hr_milestones', 2),
  (53, 5, '{{count}} work anniversar{{ies}} this week',
   'Managers who recognize anniversaries on the day see higher retention.', 51, 'medium', 'hr_anniversaries', 3);

INSERT INTO prompt_templates (flow_id, template_text) VALUES
  (51, $t$Write a short, friendly nudge from {{sender}} ({{sender_role}}, {{company}}) to {{manager}}, the manager of {{name}}.

Anniversary: {{name}} ({{title}}, {{department}}) celebrates {{years}} years at {{company_short}} on {{event_date}}.
Highlight worth mentioning: {{recent_highlight}}.
{{#eligible}}Milestone: this is a milestone year, so {{first_name}} gets the {{product}} with a budget of {{price}}. {{product_description}} {{milestone_note}}{{/eligible}}{{^eligible}}Not a milestone year: do not mention a gift budget or extra perks.{{/eligible}}

Address {{manager_first}} directly. Suggest two or three easy ways to recognize {{first_name}} on the day (a personal note, a team shout-out, a conversation about what is next). Warm, practical, under 150 words.$t$),
  (52, $t$Write a warm welcome email from {{sender}} ({{sender_role}}, {{company}}) to {{name}}, who starts as {{title}} on the {{department}} team on {{event_date}}. Their manager {{manager}} is copied.

Include a short first-day checklist with exactly these details:
- Laptop: {{laptop}}
- Onboarding buddy: {{buddy}}
- Where: {{work_location}}
- First-day schedule: {{first_day_schedule}}

Also mention the {{product}} ({{price}}{{price_unit}}): {{product_description}}

Say {{manager_first}} is looking forward to working with {{first_name}}, invite questions by reply, and keep it upbeat and clear. Under 200 words.$t$);

INSERT INTO offline_responses (industry_id, flow_id, kind, response_text) VALUES
  (5, 51, 'draft', $t$Hi {{manager_first}},

A quick heads-up: {{name}} ({{title}}, {{department}}) celebrates {{years}} years at Brightline on {{event_date}}.

{{#eligible}}This is a milestone year, so {{first_name}} gets the {{product}} with a budget of {{price}}: a gift from the recognition catalog, a handwritten card from the CEO and a shout-out at the next all-hands. {{milestone_note}} I will send {{first_name}} the catalog link on the day.{{/eligible}}{{^eligible}}It is not a milestone year, but a little recognition on the day goes a long way.{{/eligible}}

A few easy ways to mark it:
- Send {{first_name}} a personal note. One thing worth calling out: {{recent_highlight}}.
- Give a shout-out in your next team meeting or the team channel.
- Set up a short 1:1 to talk about what {{first_name}} wants to take on next.

Thanks for making it count,
{{sender}}
{{sender_role}}, {{company}}$t$),
  (5, 52, 'draft', $t$Hi {{first_name}},

Welcome to Brightline! We are so glad you are joining the {{department}} team as {{title}}, and we can't wait to see you on {{event_date}}.

Here is your first-day checklist:
- Laptop: {{laptop}}
- Onboarding buddy: {{buddy}}, who will be your go-to person for any question during your first weeks
- Where: {{work_location}}
- First-day schedule: {{first_day_schedule}}

You will also get the {{product}} ({{price}}{{price_unit}}). {{product_description}}

{{manager_first}}, copied here, is looking forward to working with you. If anything comes up before your first day, just reply to this email.

See you soon,
{{sender}}
{{sender_role}}, {{company}}$t$);

INSERT INTO offline_responses (industry_id, kind, match_keywords, response_text) VALUES
  (5, 'chat', '{first today,reach out to first,contact first,prioritize,priority,priorities,who should,which employee,which manager}', $t$I'd start with **Chris Alvarez**, Nadia Petrov's manager. Here's the order I'd take today:

1. **Nadia Petrov** (nudge Chris Alvarez) - Nadia hits her 5-year milestone tomorrow. She qualifies for the $500 Milestone Recognition Gift and a fifth week of PTO, and Chris hasn't been reminded yet.
2. **Leah Kim** - starts as a Data Analyst in Finance in 2 days and hasn't had her welcome email. Her laptop, her buddy Wes Turner and her first-day schedule are all confirmed.
3. **Daniel Hughes** (nudge Priya Nair) - his 10-year milestone is in 3 days, which also unlocks a 4-week paid sabbatical. He is also Aisha Bello's onboarding buddy, so Priya may want to plan around both.

Want me to draft the note to Chris first?$t$),
  (5, 'chat', '{summary,summarize,overview,my day,this week}', $t$Here's your week at a glance, {{user_first}}:

{{signals_summary}}

The most time-sensitive items are the new hires: welcome emails should go out before day one. I can draft anniversary nudges for managers, send welcome emails, or answer questions from the employee handbook.$t$),
  (5, 'chat', '{}', $t$Here's what I'm seeing across Brightline right now:

{{signals_summary}}

I can nudge managers about work anniversaries, send new hires their welcome email and first-day checklist, or answer handbook questions about PTO, parental leave, remote work, expenses, benefits and more. What would you like to do next?$t$);

INSERT INTO knowledge_base (industry_id, source, section_title, content) VALUES
  (5, 'Brightline Employee Handbook', 'Paid time off (PTO)',
   'Full-time employees accrue 20 days of PTO per year from their first day, rising to 25 days after 5 years of service. Up to 5 unused days carry over into the next year; anything above that expires. Request time off in the HR portal at least 2 weeks ahead for absences of 3 or more days, and at least 2 days ahead for shorter ones. Managers approve or discuss requests within 3 business days. PTO does not need a reason, and you are encouraged to take at least one full week off each year.'),
  (5, 'Brightline Employee Handbook', 'Sick leave and company holidays',
   'Sick leave is separate from PTO: every employee gets 10 paid sick days per year, usable for their own illness, medical appointments or caring for a family member. No doctor''s note is needed for absences under 3 consecutive days. Brightline observes 11 paid company holidays plus a company-wide winter break between the holiday period and the new year. Employees can swap up to 2 company holidays for days of personal or cultural significance.'),
  (5, 'Brightline Employee Handbook', 'Parental leave',
   'All parents (birthing, non-birthing, adoptive and foster) get 16 weeks of fully paid parental leave after 90 days of employment. Birthing parents also receive up to 6 additional weeks of paid medical recovery leave. Leave can be taken all at once or in up to 3 blocks within 12 months of the birth or placement. After leave, parents can use a 4-week phased return at 60% of their normal schedule on full pay. Tell your manager and HR Business Partner at least 30 days before leave starts when you can, and HR will arrange coverage and benefits changes.'),
  (5, 'Brightline Employee Handbook', 'Remote and hybrid work',
   'Employees near the Austin and Denver hubs work hybrid: Tuesday through Thursday in the office, Monday and Friday wherever works best. Remote employees can live in any US state where Brightline is registered to employ; check with HR before moving. Everyone can work from anywhere in the US for up to 4 weeks per year with manager approval. Core collaboration hours are 10:00 to 3:00 in your team''s primary time zone.'),
  (5, 'Brightline Employee Handbook', 'Home office setup allowance',
   'Every new hire, hybrid or remote, gets a one-time $600 home office setup allowance for a desk, chair, monitor or other workspace gear, claimed through the expense tool within the first 90 days. Remote employees also receive a $50 monthly internet stipend, paid automatically through payroll. Equipment bought with the allowance belongs to the employee.'),
  (5, 'Brightline Employee Handbook', 'Expenses and reimbursement',
   'Submit business expenses in the expense tool within 30 days, with an itemized receipt for anything over $25. Travel meals are covered up to $75 per day, economy airfare is booked through the travel portal, and hotels should stay under the city rate shown in the portal. Expenses over $500 need manager approval before you spend. Approved expenses are reimbursed in the next payroll run, usually within 10 business days.'),
  (5, 'Brightline Employee Handbook', 'Learning and growth stipend',
   'Every employee has a $1,500 learning and growth stipend per calendar year, available from day one. It covers courses, certifications, conference tickets, workshops and books related to your current role or a role you are working toward. Unused funds do not roll over. Pre-approval from your manager is needed for single items over $500. Conference travel is paid from your team travel budget, not the stipend.'),
  (5, 'Brightline Employee Handbook', 'Benefits enrollment',
   'Medical, dental and vision coverage starts on your first day. New hires have 30 days from their start date to enroll in benefits and add dependents; if you miss the window, the next chance is annual open enrollment in the fall or a qualifying life event such as marriage, birth or adoption. Brightline pays 90% of employee premiums and 75% of dependent premiums, and matches 401(k) contributions dollar for dollar up to 4% of salary, vesting immediately.'),
  (5, 'Brightline Employee Handbook', 'Work anniversary recognition',
   'Managers receive a reminder from HR a few days before each work anniversary and are expected to recognize it on the day, with a personal note, a team shout-out or a career conversation. Milestone anniversaries at 5, 10, 15 and 20 years add the Milestone Recognition Gift: a $500 gift chosen from the recognition catalog, a handwritten card from the CEO and a shout-out at the next all-hands. The 5-year milestone also raises PTO to 25 days per year, and the 10-year milestone unlocks a 4-week paid sabbatical, to be taken within 12 months and scheduled with your manager.'),
  (5, 'Brightline Employee Handbook', 'Onboarding and the buddy program',
   'Before day one, IT ships or prepares the new hire''s laptop, the manager sends a first-week plan, and HR sends a welcome email with a first-day checklist. Every new hire is paired with an onboarding buddy from a nearby team for their first 90 days: someone to ask the questions they would not ask their manager. Buddies meet the new hire on day one and at least weekly for the first month. Managers hold 30, 60 and 90-day check-ins, and HR runs a new hire welcome session on the first morning.');

INSERT INTO suggestions (industry_id, title, prompt, icon, sort_order) VALUES
  (5, 'Plan my day', 'Who should I reach out to first today?', 'chat', 1),
  (5, 'Ask the handbook', 'How much parental leave do we offer?', 'book', 2),
  (5, 'Welcome new hires', 'Prepare onboarding for new hires starting soon', 'list--checked', 3);

INSERT INTO chats (id, industry_id, title, is_seed, created_at, updated_at) VALUES
  (501, 5, 'Sabbatical rules for 10 years', TRUE, now() - interval '1 day', now() - interval '1 day'),
  (502, 5, 'Onboarding cohort readiness', TRUE, now() - interval '2 days', now() - interval '2 days'),
  (503, 5, 'Remote work from another state', TRUE, now() - interval '6 days', now() - interval '6 days');

INSERT INTO chat_messages (chat_id, role, content, created_at) VALUES
  (501, 'user', 'What do employees get at 10 years?', now() - interval '1 day'),
  (501, 'assistant', 'The 10-year milestone adds the $500 Milestone Recognition Gift and unlocks a 4-week paid sabbatical, to be taken within 12 months and scheduled with the manager. *Source: Brightline Employee Handbook, "Work anniversary recognition".*', now() - interval '1 day'),
  (502, 'user', 'Are we ready for the new hires starting next week?', now() - interval '2 days'),
  (502, 'assistant', 'Mostly. **Leah Kim** (Finance) and **Aisha Bello** (Platform Engineering) have laptops and buddies assigned. **Marco Silva** (Sales) is still waiting on a laptop courier date, so I created a task to confirm it with IT.', now() - interval '2 days'),
  (503, 'user', 'Can someone work from another state for a month?', now() - interval '6 days'),
  (503, 'assistant', 'Yes. Everyone can work from anywhere in the US for up to 4 weeks per year with manager approval. A permanent move needs HR review first. *Source: Brightline Employee Handbook, "Remote and hybrid work".*', now() - interval '6 days');

INSERT INTO activity_log (industry_id, record_id, flow_id, action_type, payload, is_seed, created_at) VALUES
  (5, 505, 52, 'task_created', '{"title":"Confirm laptop courier date for Marco Silva with IT","summary":"Internal task for IT"}', TRUE, now() - interval '2 days'),
  (5, 503, 51, 'email_sent', '{"to":"tanya.holt@brightline.example","subject":"Heads-up: Sam Rivera celebrates 3 years","summary":"Anniversary nudge sent to the manager"}', TRUE, now() - interval '3 days');

INSERT INTO tasks (record_id, title, due_date, status, is_seed) VALUES
  (505, 'Confirm laptop courier date for Marco Silva with IT', CURRENT_DATE - 1, 'done', TRUE),
  (503, 'Check that Tanya Holt recognized Sam Rivera', CURRENT_DATE, 'open', TRUE);
-- ===========================================================================
-- 6. Real estate - Cedar & Stone Realty
-- ===========================================================================

INSERT INTO app_users (industry_id, name, role, email) VALUES
  (6, 'Paul Zikopoulos', 'Listing Agent', 'paul.zikopoulos@cedarstone.example');

INSERT INTO records (id, industry_id, name, email, phone, record_type, attributes) VALUES
  (601, 6, 'Kevin and Laura Bennett', 'kevin.bennett@example.com', '(555) 016-2204', 'buyer',
   '{"first_name":"Kevin and Laura","budget":725000,"beds_wanted":4,"search_area":"Willow Creek",
     "preapproval_status":"Pre-approved with Summit Home Lending",
     "what_matched":"four bedrooms, a fenced backyard and a 6-minute walk to Willow Creek Elementary"}'),
  (602, 6, 'Marcus Hale', 'marcus.hale@example.com', '(555) 016-3817', 'buyer',
   '{"first_name":"Marcus","budget":700000,"beds_wanted":3,"search_area":"Willow Creek and Oak Hollow",
     "preapproval_status":"Pre-approved with Harbor Credit Union",
     "what_matched":"a dedicated home office, a two-car garage and more than the three bedrooms on your list"}'),
  (603, 6, 'Denise Carter', 'denise.carter@example.com', '(555) 016-5530', 'buyer',
   '{"first_name":"Denise","budget":750000,"beds_wanted":3,"search_area":"Willow Creek",
     "preapproval_status":"Pre-approval in progress",
     "what_matched":"a main-floor primary suite and an open kitchen with a large island"}'),
  (604, 6, 'Omar Haddad', 'omar.haddad@example.com', '(555) 016-7142', 'tenant',
   '{"first_name":"Omar","unit":"Unit 3B at 118 Birch Street","current_rent":2150,"renewal_rent":2240,
     "term_months":12,"on_time_months":24}'),
  (605, 6, 'Grace Liu', 'grace.liu@example.com', '(555) 016-8865', 'tenant',
   '{"first_name":"Grace","unit":"Unit 1A at 22 Harbor Court","current_rent":1875,"renewal_rent":1950,
     "term_months":12,"on_time_months":9}'),
  (606, 6, 'Priya Shah', 'priya.shah@example.com', '(555) 016-4091', 'visitor',
   '{"first_name":"Priya","preapproved":true,"preapproval_status":"Pre-approved with Summit Home Lending",
     "asked_about":"the HOA fee and whether the basement could be finished",
     "answer":"The HOA fee is $85/month and covers the walking trails and common-area landscaping. The basement has 8-foot ceilings and a bathroom rough-in, so finishing it is straightforward, and I can share a contractor estimate if that helps."}'),
  (607, 6, 'Daniel Ortiz', 'daniel.ortiz@example.com', '(555) 016-6378', 'visitor',
   '{"first_name":"Daniel","preapproved":false,"preapproval_status":"Not yet pre-approved",
     "asked_about":"the school boundaries and the age of the roof",
     "answer":"The home is zoned for Ridgeview Elementary and Ridgeview Middle School, and the roof was replaced 4 years ago with a transferable 25-year warranty."}');

INSERT INTO life_events (record_id, event_type, description, event_date) VALUES
  (601, 'listing_match',    'Saved search (Willow Creek, 4+ bedrooms) matched new listing 42 Willow Lane', CURRENT_DATE - 1),
  (602, 'listing_match',    'Saved search (Willow Creek and Oak Hollow, home office) matched new listing 42 Willow Lane', CURRENT_DATE - 1),
  (603, 'listing_match',    'Saved search (Willow Creek, main-floor primary suite) matched new listing 42 Willow Lane', CURRENT_DATE),
  (604, 'lease_end',        'Lease for Unit 3B at 118 Birch Street ends; renewal offer not yet sent', CURRENT_DATE + 38),
  (605, 'lease_end',        'Lease for Unit 1A at 22 Harbor Court ends; renewal offer not yet sent', CURRENT_DATE + 52),
  (606, 'open_house_visit', 'Visited the 18 Aspen Court open house and asked about the HOA fee and the basement', CURRENT_DATE - 2),
  (607, 'open_house_visit', 'Visited the 18 Aspen Court open house and asked about schools and the roof', CURRENT_DATE - 1);

INSERT INTO products (id, industry_id, name, description, price, price_unit, discount_pct, eligibility_rules) VALUES
  (61, 6, '42 Willow Lane',
   'A 4-bedroom, 2.5-bath craftsman on a quarter-acre lot in Willow Creek with a main-floor primary suite, a dedicated home office, an open kitchen with a large island, a fenced backyard and a two-car garage. It is a 6-minute walk to Willow Creek Elementary.',
   689000.00, '', 0, '{}'),
  (62, 6, 'Early renewal credit',
   'A one-time $150 credit on the first month of the new lease for tenants who sign a 12-month renewal at least 30 days before their current lease ends.',
   150.00, '', 0,
   '{"all":[{"attr":"on_time_months","op":">=","value":12,"label":"12+ months of on-time rent"}]}'),
  (63, 6, 'Free home valuation',
   'A no-obligation market valuation of your current home with recent comparable sales, prepared by a Cedar & Stone agent within 3 business days.',
   0.00, '', 0, '{}'),
  (64, 6, '18 Aspen Court',
   'A 3-bedroom, 2-bath townhome in Oak Hollow with an unfinished basement (8-foot ceilings and a bathroom rough-in), a roof replaced 4 years ago with a transferable 25-year warranty, and an HOA fee of $85/month that covers the walking trails and common-area landscaping.',
   615000.00, '', 0, '{}');

INSERT INTO query_definitions (key, industry_id, description, event_types, days_from, days_to) VALUES
  ('re_listing_matches', 6, 'Buyers whose saved search matched a new listing in the last 3 days', '{listing_match}', -3, 0),
  ('re_lease_renewals',  6, 'Tenants whose lease ends in the next 60 days', '{lease_end}', 0, 60),
  ('re_open_house',      6, 'Open house visitors from the last 7 days', '{open_house_visit}', -7, 0);

INSERT INTO flows (id, industry_id, slug, title, description, flow_type, keywords, icon, product_id, sort_order, steps) VALUES
  (61, 6, 'listing-match', 'New listing buyer matches',
   'Email buyers whose saved search matches a new listing, with the details they care about.',
   'outreach', '{new listing,new listings,listing match,listing matches,saved search,saved searches,matched buyers,buyer match,buyer matches,buyers,willow lane}',
   'user--multiple', 61, 1,
   '{"query":"re_listing_matches",
     "agent_steps":["Checking saved searches against new listings",
                    "Found {{count}} {{record_noun}} whose search matches {{product}}",
                    "Comparing budgets and must-haves with the listing",
                    "Pulling listing details from the MLS"],
     "table_title":"Buyers matched to the new listing",
     "select_hint":"Select the buyers you want to tell about the listing.",
     "change_label":"Search match",
     "contact_field":"email",
     "draft_mode":"per_record",
     "content_type":"Email",
     "to":"{{email}}",
     "cc":"{{sender_email}}",
     "subject":"New listing that fits your search: {{product}}",
     "facts":[{"key":"price","label":"List price","kind":"money"},
              {"key":"budget","label":"Buyer budget","kind":"money"},
              {"key":"beds_wanted","label":"Bedrooms wanted","kind":"quantity","unit":"bedrooms"}],
     "approve":{"label":"Send email","action_type":"email_sent","log_label":"Logged to CRM",
                "task_title":"Book a showing of {{product}} with {{name}}",
                "follow_up":{"business_days":1},
                "confirmation":"Email sent to {{name}}. Logged to CRM. Showing follow-up task created for {{follow_up_day}}."}}'),
  (62, 6, 'lease-renewal', 'Lease renewal offers',
   'Send tenants a clear renewal offer well before their lease ends, with the early renewal credit where they qualify.',
   'outreach', '{lease,leases,lease renewal,lease renewals,renewal,renewals,renew,tenant,tenants,rent increase}',
   'renew', 62, 2,
   '{"query":"re_lease_renewals",
     "agent_steps":["Scanning leases that end in the next 60 days",
                    "Found {{count}} {{record_noun}} with leases ending soon",
                    "Checking payment history for the {{product}}",
                    "{{eligible_count}} of {{count}} qualify for the {{product}}"],
     "table_title":"Leases ending in the next 60 days",
     "select_hint":"Select the tenants who should get a renewal offer.",
     "change_label":"Lease status",
     "contact_field":"email",
     "draft_mode":"per_record",
     "content_type":"Email",
     "to":"{{email}}",
     "cc":"{{sender_email}}",
     "subject":"Your renewal offer for {{unit}}",
     "facts":[{"key":"event_date","label":"Lease ends","kind":"date"},
              {"key":"current_rent","label":"Current rent","kind":"money"},
              {"key":"renewal_rent","label":"Renewal rent","kind":"money"},
              {"key":"term_months","label":"Renewal term","kind":"quantity","unit":"months"},
              {"key":"price","label":"Early renewal credit","kind":"money"}],
     "approve":{"label":"Send offer","action_type":"email_sent","log_label":"Logged to the tenant file",
                "task_title":"Confirm renewal decision with {{name}}",
                "follow_up":{"weekday":5},
                "confirmation":"Renewal offer sent to {{name}}. Logged to the tenant file. Follow-up task created for {{follow_up_day}}."}}'),
  (63, 6, 'open-house-follow-up', 'Open house follow-up',
   'Thank open house visitors and answer the question they asked, while the visit is still fresh.',
   'outreach', '{open house,open houses,open house visitors,visitor,visitors,sign in sheet,sign in list}',
   'email', 64, 3,
   '{"query":"re_open_house",
     "agent_steps":["Reading the open house sign-in list",
                    "Found {{count}} {{record_noun}} who visited {{product}}",
                    "Matching each visitor to the question they asked",
                    "Checking pre-approval status"],
     "table_title":"Open house visitors",
     "select_hint":"Select the visitors you want to follow up with.",
     "change_label":"Visit",
     "contact_field":"email",
     "draft_mode":"per_record",
     "content_type":"Email",
     "to":"{{email}}",
     "cc":"{{sender_email}}",
     "subject":"Thanks for visiting {{product}}",
     "facts":[{"key":"price","label":"List price","kind":"money"}],
     "approve":{"label":"Send email","action_type":"email_sent","log_label":"Logged to CRM",
                "task_title":"Check in with {{name}} about a second showing",
                "follow_up":{"days":2},
                "confirmation":"Email sent to {{name}}. Logged to CRM. Follow-up task created for {{follow_up_day}}."}}'),
  (64, 6, 'handbook-qa', 'Ask the brokerage handbook',
   'Answers from the Cedar & Stone brokerage handbook, with the section it came from.',
   'qa', '{handbook,brokerage handbook,fair housing,disclosure,disclosures,earnest money,deposit,deposits,showing policy,showing policies,lockbox,what does,how does,how do we,how long,rule,rules,guideline,guidelines,requirement,requirements,policy on,our policy,allowed to}',
   'book', NULL, 4,
   '{"agent_steps":["Searching the Cedar & Stone brokerage handbook",
                    "Found {{count}} relevant sections",
                    "Reading \"{{top_section}}\"",
                    "Writing an answer with citations"]}');

INSERT INTO signals (id, industry_id, title, description, flow_id, severity, count_query, sort_order) VALUES
  (61, 6, '{{count}} buyer{{s}} matched to 42 Willow Lane',
   'Saved searches matched the new listing. First to hear, first to book a showing.', 61, 'high', 're_listing_matches', 1),
  (62, 6, '{{count}} lease{{s}} ending in the next 60 days',
   'Renewal offers are due at least 30 days before the lease ends.', 62, 'medium', 're_lease_renewals', 2),
  (63, 6, '{{count}} open house visitor{{s}} to follow up',
   'Handbook standard: follow up within 48 hours of the open house.', 63, 'medium', 're_open_house', 3);

INSERT INTO prompt_templates (flow_id, template_text) VALUES
  (61, $t$Write a warm, concise email from {{sender}} ({{sender_role}}, {{company}}) to {{name}} (address them as {{first_name}}).

What happened: {{event}} (recorded {{event_date}}).
Their saved search: {{search_area}}, {{beds_wanted}}+ bedrooms, budget up to {{budget}}. Financing: {{preapproval_status}}.
Why this listing fits: {{what_matched}}.

The listing: {{product}}, listed at {{price}}. {{product_description}}

Invite {{first_name}} to a private showing in the next couple of days. Describe the property, never the neighborhood's residents or who the home is "perfect for" (fair housing). Friendly, plain language, under 160 words.$t$),
  (62, $t$Write a friendly, clear lease renewal offer from {{sender}} ({{sender_role}}, {{company}}) to {{name}}.

Unit: {{unit}}. The current lease ends on {{event_date}} ({{days_until}} days from now).
Current rent: {{current_rent}}/month. Renewal rent: {{renewal_rent}}/month for a {{term_months}}-month term.
{{#eligible}}Offer: {{first_name}} qualifies for the {{product}} ({{price}}). {{product_description}}{{/eligible}}{{^eligible}}Note: {{first_name}} does not qualify for the {{product}} ({{eligibility_note}}), so do not mention any credit.{{/eligible}}

State the new rent plainly, thank {{first_name}} for being a tenant, and ask them to reply with their decision so the renewal can be sent for e-signature. Under 150 words.$t$),
  (63, $t$Write a warm follow-up email from {{sender}} ({{sender_role}}, {{company}}) to {{name}}, who visited the open house at {{product}}.

Visit: {{event}} ({{event_date}}).
They asked about: {{asked_about}}.
Answer to share: {{answer}}
Financing: {{preapproval_status}}.
Listing: {{product}}, listed at {{price}}. {{product_description}}

Thank them for coming, answer their question directly, then {{#preapproved}}offer a second, private showing{{/preapproved}}{{^preapproved}}offer to introduce a couple of local lenders for a pre-approval, with no obligation{{/preapproved}}. No pressure, under 150 words.$t$);

INSERT INTO offline_responses (industry_id, flow_id, kind, response_text) VALUES
  (6, 61, 'draft', $t$Hi {{first_name}},

Good news: a new listing just matched your saved search in {{search_area}}. {{product}} is listed at {{price}}, comfortably inside your {{budget}} budget, and it has {{what_matched}}.

Here are the highlights: {{product_description}}

Homes like this tend to move quickly, so I'd love to get you in for a private showing before it gets busy. Would sometime in the next couple of days work for you?

Warm regards,
{{sender}}
{{sender_role}}, {{company}}$t$),
  (6, 62, 'draft', $t$Hi {{first_name}},

Your lease for {{unit}} ends on {{event_date}}, and we'd love to have you stay. I wanted to send your renewal offer early so you have plenty of time to decide.

- Current rent: {{current_rent}}/month
- Renewal rent: {{renewal_rent}}/month for a {{term_months}}-month term
{{#eligible}}
Thank you for paying on time every month. That also means you qualify for our {{product}}: {{price}} off your first month's rent when you sign at least 30 days before your lease ends.
{{/eligible}}
Just reply to let me know whether you'd like to renew, and I'll send the lease over for e-signature. If you have any questions about the new terms, I'm happy to talk them through.

Best regards,
{{sender}}
{{sender_role}}, {{company}}$t$),
  (6, 63, 'draft', $t$Hi {{first_name}},

Thank you for stopping by the open house at {{product}}. It was great to meet you.

You asked about {{asked_about}}, so here's what I found: {{answer}}

{{#preapproved}}Since you're already pre-approved, you're in a strong position if you'd like to move forward. I'm happy to set up a second, private showing so you can take your time with the home.{{/preapproved}}{{^preapproved}}If you're thinking about making an offer, the first step is a mortgage pre-approval. I'm happy to introduce you to a couple of local lenders, with no obligation.{{/preapproved}}

The home is listed at {{price}}. Just reply here with any other questions.

Best,
{{sender}}
{{sender_role}}, {{company}}$t$);

INSERT INTO offline_responses (industry_id, kind, match_keywords, response_text) VALUES
  (6, 'chat', '{call first,first today,prioritize,priority,priorities,who should,which contact,which lead}', $t$I'd start with **Kevin and Laura Bennett**. Here's how I'd order your calls today:

1. **Kevin and Laura Bennett** - their saved search matched 42 Willow Lane yesterday. It's listed at $689,000, under their $725,000 budget, and it has the four bedrooms, fenced backyard and walk to Willow Creek Elementary they asked for. They're pre-approved, so they can move fast.
2. **Priya Shah** - she visited the 18 Aspen Court open house 2 days ago, is already pre-approved and asked about the HOA fee and finishing the basement. Our 48-hour follow-up window closes today.
3. **Omar Haddad** - his lease at Unit 3B, 118 Birch Street ends in 38 days. He has 24 months of on-time rent, so he qualifies for the $150 early renewal credit if he signs in the next week.

Want me to draft the email to Kevin and Laura first?$t$),
  (6, 'chat', '{summary,summarize,overview,my day,this week}', $t$Here's your pipeline at a glance, {{user_first}}:

{{signals_summary}}

The most time-sensitive item is 42 Willow Lane: three buyers' saved searches matched it, and the first to see it usually makes the first offer. I can draft outreach for any of these, or answer questions from the brokerage handbook.$t$),
  (6, 'chat', '{}', $t$Here's what I'm seeing across your contacts right now:

{{signals_summary}}

I can email matched buyers about a new listing, send lease renewal offers, follow up with open house visitors, or answer questions from the brokerage handbook. What would you like to do next?$t$);

INSERT INTO knowledge_base (industry_id, source, section_title, content) VALUES
  (6, 'Cedar & Stone Brokerage Handbook', 'Fair housing in marketing language',
   'Listing descriptions, emails and social posts must describe the property, never the people who might live there. Do not use phrases that signal a preference based on race, color, religion, sex, disability, familial status or national origin, such as "perfect for young families", "ideal for singles" or "walking distance to church". Describe features instead: "4 bedrooms", "fenced backyard", "6-minute walk to Willow Creek Elementary". When in doubt, ask the managing broker before publishing.'),
  (6, 'Cedar & Stone Brokerage Handbook', 'Seller disclosure requirements',
   'The seller disclosure statement must be signed by every seller and uploaded to the transaction file before the listing goes live. Agents share it with any buyer who requests it and with every buyer before an offer is written. Known material defects (roof, foundation, water intrusion, past insurance claims) must be disclosed even if they were repaired. Agents never fill in the disclosure on the seller''s behalf.'),
  (6, 'Cedar & Stone Brokerage Handbook', 'Earnest money deposits',
   'Earnest money is typically 1% to 3% of the purchase price and must be delivered to the Cedar & Stone trust account or the named escrow company within 2 business days of mutual acceptance. Agents never hold deposit checks overnight. Refunds and releases require written instructions signed by both buyer and seller, and the managing broker reviews every disputed deposit.'),
  (6, 'Cedar & Stone Brokerage Handbook', 'Showing policies and lockbox access',
   'All showings are booked through the showing service so sellers get notice at least 2 hours in advance. The showing agent must accompany buyers for the entire visit, lock every door and return the key to the lockbox. Lockbox codes are never shared by text or email with buyers. Private showings of a new listing may begin once the seller disclosure is on file.'),
  (6, 'Cedar & Stone Brokerage Handbook', 'Open house sign-in and follow-up',
   'Every open house visitor is invited to sign in, but signing in is optional. Follow up with each visitor who left an email within 48 hours, answer the question they asked, and ask about pre-approval only once. Visitors who ask not to be contacted are marked do-not-contact in the CRM the same day.'),
  (6, 'Cedar & Stone Brokerage Handbook', 'Lease renewal offers',
   'Send renewal offers at least 30 days and ideally 45 to 60 days before the lease ends. Renewal rent increases are capped at 5% for tenants in good standing. Tenants with 12 or more months of on-time rent qualify for the Early renewal credit: a one-time $150 credit on the first month of a 12-month renewal signed at least 30 days before the current lease ends.'),
  (6, 'Cedar & Stone Brokerage Handbook', 'New listing alerts for buyers',
   'When a new listing matches a buyer''s saved search, contact the buyer within 24 hours with the list price, the features that matched their search and an offer of a private showing. Never share the seller''s motivation, timeline or lowest acceptable price. Confirm the buyer''s pre-approval before writing an offer.'),
  (6, 'Cedar & Stone Brokerage Handbook', 'Client communication standards',
   'Use plain language and keep emails under 200 words. Every price, rent, credit and date must match the MLS listing or lease record exactly. Always copy yourself so the email is logged to the CRM, and never pressure a buyer, seller or tenant to decide on the first contact.');

INSERT INTO suggestions (industry_id, title, prompt, icon, sort_order) VALUES
  (6, 'Plan my calls', 'Which contact should I call first today?', 'chat', 1),
  (6, 'Check a rule', 'What are the earnest money rules?', 'book', 2),
  (6, 'Match the new listing', 'Email buyers whose saved search matches 42 Willow Lane', 'email', 3);

INSERT INTO chats (id, industry_id, title, is_seed, created_at, updated_at) VALUES
  (601, 6, 'Buyers for 42 Willow Lane', TRUE, now() - interval '1 day', now() - interval '1 day'),
  (602, 6, 'Upcoming lease renewals', TRUE, now() - interval '3 days', now() - interval '3 days'),
  (603, 6, 'Fair housing wording check', TRUE, now() - interval '5 days', now() - interval '5 days');

INSERT INTO chat_messages (chat_id, role, content, created_at) VALUES
  (601, 'user', 'Who is a good fit for 42 Willow Lane?', now() - interval '1 day'),
  (601, 'assistant', 'Three saved searches match it: **Kevin and Laura Bennett** (Willow Creek, budget $725,000), **Marcus Hale** (Willow Creek and Oak Hollow, budget $700,000) and **Denise Carter** (Willow Creek, budget $750,000). The list price of $689,000 is inside all three budgets.', now() - interval '1 day'),
  (602, 'user', 'Which leases are coming up for renewal?', now() - interval '3 days'),
  (602, 'assistant', 'Two leases end in the next 60 days: **Omar Haddad** (Unit 3B at 118 Birch Street, renewal rent $2,240/month) and **Grace Liu** (Unit 1A at 22 Harbor Court, renewal rent $1,950/month). Omar qualifies for the $150 early renewal credit; Grace has 9 months of on-time rent, so she does not yet.', now() - interval '3 days'),
  (603, 'user', 'Can I describe a listing as perfect for young families?', now() - interval '5 days'),
  (603, 'assistant', 'No. Familial status is protected, so describe the property instead, for example "4 bedrooms, fenced backyard, 6-minute walk to Willow Creek Elementary". *Source: Cedar & Stone Brokerage Handbook, "Fair housing in marketing language".*', now() - interval '5 days');

INSERT INTO activity_log (industry_id, record_id, flow_id, action_type, payload, is_seed, created_at) VALUES
  (6, 606, 63, 'task_created', '{"title":"Send HOA budget and rules to Priya Shah","summary":"Priya asked for the HOA documents at the open house"}', TRUE, now() - interval '1 day'),
  (6, 601, 61, 'email_sent', '{"to":"kevin.bennett@example.com","subject":"Your updated Willow Creek saved search","summary":"Confirmed their saved search criteria and budget"}', TRUE, now() - interval '6 days');

INSERT INTO tasks (record_id, title, due_date, status, is_seed) VALUES
  (606, 'Send HOA budget and rules to Priya Shah', CURRENT_DATE + 1, 'open', TRUE),
  (601, 'Confirm saved search criteria with Kevin and Laura Bennett', CURRENT_DATE - 6, 'done', TRUE);
-- ===========================================================================
-- 7. Manufacturing - Ironbridge Precision Manufacturing
-- ===========================================================================

INSERT INTO app_users (industry_id, name, role, email) VALUES
  (7, 'Paul Zikopoulos', 'Plant Operations Manager', 'paul.zikopoulos@ironbridge.example');

INSERT INTO records (id, industry_id, name, email, phone, record_type, attributes) VALUES
  (701, 7, 'CNC Mill 4', 'line2-lead@ironbridge.example', '(555) 017-2204', 'asset',
   '{"asset_tag":"IB-CNC-04","line":"Line 2 - Machining",
     "vibration_mm_s":7.8,"baseline_mm_s":2.1,"temp_c":68,"baseline_temp_c":45,
     "priority":"P1 (repair within 24 hours)",
     "likely_cause":"Front spindle bearing wear (vibration peak at the bearing defect frequency)",
     "recommended_action":"Replace the front spindle bearing set at the next planned stop, then run a spindle warm-up cycle and re-check vibration against baseline"}'),
  (702, 7, 'Conveyor Drive Motor 3', 'line3-lead@ironbridge.example', '(555) 017-2305', 'asset',
   '{"asset_tag":"IB-CNV-03","line":"Line 3 - Assembly",
     "vibration_mm_s":6.4,"baseline_mm_s":1.9,"temp_c":63,"baseline_temp_c":44,
     "priority":"P2 (repair within 72 hours)",
     "likely_cause":"Drive-end motor bearing wear with possible belt misalignment",
     "recommended_action":"Replace the drive-end bearing, check belt alignment and tension, then re-baseline the sensor"}'),
  (703, 7, 'Northfield Hydraulics', 'dana.whitfield@example.com', '(555) 017-4418', 'customer',
   '{"first_name":"Dana","contact_name":"Dana Whitfield","po_number":"PO-58817","quantity":1200,
     "part":"machined valve bodies (IB-VB-220)","delay_days":6,
     "reason":"Our bar-stock supplier had a furnace outage at their mill, and their shipment to us slipped"}'),
  (704, 7, 'Apex Agricultural Equipment', 'luis.romero@example.com', '(555) 017-5127', 'customer',
   '{"first_name":"Luis","contact_name":"Luis Romero","po_number":"PO-60342","quantity":450,
     "part":"gearbox housings (IB-GH-310)","delay_days":9,
     "reason":"Our casting supplier had to take its heat-treatment line down for repairs"}'),
  (705, 7, 'Line 1 - Stamping', 'line1-lead@ironbridge.example', '(555) 017-1101', 'line',
   '{"shift":"Day shift","units_produced":1840,"target_units":2000,"downtime_minutes":35,
     "open_issues":"Die change on Press 1 overran; coil stock for IB-BR-115 runs low mid-shift"}'),
  (706, 7, 'Line 2 - Machining', 'line2-lead@ironbridge.example', '(555) 017-2204', 'line',
   '{"shift":"Day shift","units_produced":610,"target_units":700,"downtime_minutes":85,
     "open_issues":"CNC Mill 4 limited to light passes until the P1 spindle bearing work order is done"}'),
  (707, 7, 'Line 3 - Assembly', 'line3-lead@ironbridge.example', '(555) 017-2305', 'line',
   '{"shift":"Day shift","units_produced":1120,"target_units":1100,"downtime_minutes":10,
     "open_issues":"Conveyor Drive Motor 3 vibration elevated (P2 work order); watch motor temperature"}');

INSERT INTO life_events (record_id, event_type, description, event_date) VALUES
  (701, 'sensor_anomaly', 'Spindle vibration at 7.8 mm/s, above the 7.1 mm/s alarm limit (baseline 2.1 mm/s)', CURRENT_DATE),
  (702, 'sensor_anomaly', 'Drive motor vibration at 6.4 mm/s, above the 4.5 mm/s alert limit (baseline 1.9 mm/s)', CURRENT_DATE - 1),
  (703, 'supplier_delay', 'Bar-stock supplier confirmed a late shipment; PO-58817 slips 6 days', CURRENT_DATE - 1),
  (703, 'eta_original',   'Original promised delivery for PO-58817', CURRENT_DATE + 4),
  (703, 'eta_revised',    'Revised delivery for PO-58817 after the supplier delay', CURRENT_DATE + 10),
  (704, 'supplier_delay', 'Casting supplier heat-treatment outage; PO-60342 slips 9 days', CURRENT_DATE - 2),
  (704, 'eta_original',   'Original promised delivery for PO-60342', CURRENT_DATE + 7),
  (704, 'eta_revised',    'Revised delivery for PO-60342 after the supplier delay', CURRENT_DATE + 16),
  (705, 'shift_end',      'Open issue: die change on Press 1 overran; coil stock for IB-BR-115 runs low mid-shift', CURRENT_DATE),
  (706, 'shift_end',      'Open issue: CNC Mill 4 limited to light passes until the P1 spindle bearing work order is done', CURRENT_DATE),
  (707, 'shift_end',      'Open issue: Conveyor Drive Motor 3 vibration elevated (P2 work order); watch motor temperature', CURRENT_DATE);

INSERT INTO products (id, industry_id, name, description, price, price_unit, discount_pct, eligibility_rules) VALUES
  (71, 7, 'Bearing replacement kit',
   'Matched bearing set with seals, high-speed grease and a torque spec card for spindle and drive-motor bearings. Stocked in the MRO crib, with 2 hours of vendor technician phone support included.',
   1240.00, '', 0, '{}'),
  (72, 7, 'Expedited freight at no charge',
   'We upgrade the shipment to expedited 2-day freight at no charge to the customer (normally $780 per shipment), so parts ship the day they clear final inspection.',
   0.00, '', 0,
   '{"all":[{"attr":"delay_days","op":">=","value":5,"label":"Delay of 5+ days"}]}');

INSERT INTO query_definitions (key, industry_id, description, event_types, days_from, days_to) VALUES
  ('mfg_sensor_anomalies', 7, 'Assets with a sensor anomaly in the last 3 days', '{sensor_anomaly}', -3, 0),
  ('mfg_supplier_delays',  7, 'Customer orders hit by a supplier delay in the last 7 days', '{supplier_delay}', -7, 0),
  ('mfg_shift_end',        7, 'Production lines closing their shift today', '{shift_end}', 0, 0);

INSERT INTO flows (id, industry_id, slug, title, description, flow_type, keywords, icon, product_id, sort_order, steps) VALUES
  (71, 7, 'sensor-work-order', 'Sensor anomaly work orders',
   'Turn abnormal sensor readings into technician-ready maintenance work orders.',
   'outreach', '{sensor,sensors,sensor anomaly,sensor anomalies,sensor alert,sensor alerts,anomaly,anomalies,work order,work orders,maintenance,bearing,bearings,overheating}',
   'tool-kit', 71, 1,
   '{"query":"mfg_sensor_anomalies",
     "agent_steps":["Scanning sensor data from the last 3 days",
                    "Found {{count}} assets running outside baseline",
                    "Matching vibration signatures to likely causes",
                    "Checking MRO stock for the {{product}}"],
     "table_title":"Assets with sensor anomalies",
     "select_hint":"Select the assets that need a work order.",
     "change_label":"Anomaly",
     "contact_field":"email",
     "draft_mode":"per_record",
     "content_type":"Work order",
     "to":"maintenance@ironbridge.example",
     "cc":"{{email}}",
     "subject":"Work order: {{name}} ({{asset_tag}}), {{priority}}",
     "facts":[{"key":"vibration_mm_s","label":"Vibration","kind":"quantity","unit":"mm/s"},
              {"key":"baseline_mm_s","label":"Vibration baseline","kind":"quantity","unit":"mm/s"},
              {"key":"temp_c","label":"Bearing temperature","kind":"quantity","unit":"°C"},
              {"key":"baseline_temp_c","label":"Temperature baseline","kind":"quantity","unit":"°C"},
              {"key":"event_date","label":"Detected on","kind":"date"},
              {"key":"price","label":"Kit cost","kind":"money"}],
     "approve":{"label":"Create work order","action_type":"work_order_created","log_label":"Logged to CMMS",
                "task_title":"Verify repair and re-baseline {{name}}",
                "follow_up":{"business_days":1},
                "confirmation":"Work order created for {{name}} and sent to Maintenance. Logged to CMMS. Parts request {{ticket_id}} opened. Verification task created for {{follow_up_day}}.",
                "ticket":{"title":"Issue {{product}} for {{name}} ({{asset_tag}})","queue":"MRO Stores"}}}'),
  (72, 7, 'supplier-delay-eta', 'Customer ETA updates',
   'Tell customers early and honestly when a supplier delay moves their delivery date.',
   'outreach', '{supplier delay,supplier delays,delayed order,delayed orders,late order,late orders,late shipment,eta,etas,revised eta,new eta,delivery date,customer update}',
   'time', 72, 2,
   '{"query":"mfg_supplier_delays",
     "agent_steps":["Checking open POs against supplier delay notices",
                    "Found {{count}} customer orders affected",
                    "Recalculating delivery dates from the new supplier ship dates",
                    "{{eligible_count}} of {{count}} qualify for {{product}}"],
     "table_title":"Customer orders hit by supplier delays",
     "select_hint":"Select the customers who should get an updated ETA.",
     "change_label":"Delay notice",
     "contact_field":"email",
     "draft_mode":"per_record",
     "content_type":"Email",
     "to":"{{email}}",
     "cc":"{{sender_email}}",
     "subject":"Updated delivery date for {{po_number}}",
     "facts":[{"key":"date_eta_original","label":"Original ETA","kind":"date"},
              {"key":"date_eta_revised","label":"Revised ETA","kind":"date"},
              {"key":"delay_days","label":"Delay","kind":"quantity","unit":"days"},
              {"key":"quantity","label":"Order quantity","kind":"quantity","unit":"units"}],
     "approve":{"label":"Send update","action_type":"email_sent","log_label":"Logged to ERP order notes",
                "task_title":"Confirm {{po_number}} ships on time for {{name}}",
                "follow_up":{"business_days":2},
                "confirmation":"ETA update sent to {{contact_name}} at {{name}}. Logged to ERP order notes. Follow-up task created for {{follow_up_day}}."}}'),
  (73, 7, 'shift-handover', 'Shift handover summary',
   'One handover summary for the next shift: output vs target, downtime and open issues per line.',
   'insight', '{handover,hand over,shift handover,shift summary,shift report,end of shift,next shift,night shift}',
   'list--checked', NULL, 3,
   '{"query":"mfg_shift_end",
     "agent_steps":["Pulling the shift data from the MES",
                    "Found {{count}} lines closing the shift",
                    "Comparing output with targets and logging downtime",
                    "Collecting open issues for the next shift"],
     "table_title":"Lines closing the shift",
     "select_hint":"Select the lines to include in the handover.",
     "change_label":"Open issue",
     "contact_field":"email",
     "draft_mode":"combined",
     "list_template":"- {{name}}: {{units_produced}} units vs target {{target_units}}, {{downtime_minutes}} min downtime. {{event}}",
     "content_type":"Handover summary",
     "to":"nightshift-leads@ironbridge.example",
     "cc":"{{sender_email}}",
     "subject":"Shift handover: {{count}} lines, {{today}}",
     "facts":[{"key":"units_produced","label":"Units produced","kind":"quantity","unit":"units"},
              {"key":"target_units","label":"Target","kind":"quantity","unit":"units"},
              {"key":"downtime_minutes","label":"Downtime","kind":"quantity","unit":"minutes"}],
     "approve":{"label":"Share summary","action_type":"summary_shared","log_label":"Posted to the shift log",
                "task_title":"Review handover follow-ups with the night shift leads",
                "follow_up":{"days":1},
                "confirmation":"Handover summary for {{names}} shared with the night shift leads. Posted to the shift log. Follow-up task created for {{follow_up_day}}."}}'),
  (74, 7, 'sop-qa', 'Ask the SOP library',
   'Answers from the Ironbridge SOP library, with the procedure it came from.',
   'qa', '{sop,sops,sop library,lockout,tagout,loto,threshold,thresholds,alarm limit,alarm limits,escalation,escalate,quality hold,quality holds,procedure,procedures,what does,how does,how do we,how long,rule,rules,requirement,requirements,policy on,our policy}',
   'book', NULL, 4,
   '{"agent_steps":["Searching the Ironbridge SOP library",
                    "Found {{count}} relevant sections",
                    "Reading \"{{top_section}}\"",
                    "Writing an answer with citations"]}');

INSERT INTO signals (id, industry_id, title, description, flow_id, severity, count_query, sort_order) VALUES
  (71, 7, '{{count}} asset{{s}} with abnormal vibration',
   'Readings well above baseline point to bearing wear. Unplanned downtime risk.', 71, 'high', 'mfg_sensor_anomalies', 1),
  (72, 7, '{{count}} customer order{{s}} hit by supplier delays',
   'Delivery dates moved. Customers have not been told yet.', 72, 'medium', 'mfg_supplier_delays', 2),
  (73, 7, '{{count}} line{{s}} ready for shift handover',
   'Output, downtime and open issues to pass to the night shift.', 73, 'low', 'mfg_shift_end', 3);

INSERT INTO prompt_templates (flow_id, template_text) VALUES
  (71, $t$Write a clear, technician-ready maintenance work order from {{sender}} ({{sender_role}}, {{company}}) to the maintenance team.

Asset: {{name}} ({{asset_tag}}) on {{line}}.
Detected: {{event}} on {{event_date}}.
Readings vs baseline: vibration {{vibration_mm_s}} mm/s (baseline {{baseline_mm_s}} mm/s), bearing temperature {{temp_c}} °C (baseline {{baseline_temp_c}} °C).
Priority: {{priority}}.
Likely cause: {{likely_cause}}.
Recommended action: {{recommended_action}}.
Parts: {{product}} ({{price}}). {{product_description}}

Format it as a work order with short labeled sections (Asset, Readings, Likely cause, Action, Parts, Safety). Include a reminder to apply lockout/tagout before work begins. Under 170 words.$t$),
  (72, $t$Write an honest, proactive email from {{sender}} ({{sender_role}}, {{company}}) to {{contact_name}} at {{name}} (address them as {{first_name}}).

Order: {{po_number}}, {{quantity}} {{part}}.
What happened: {{reason}}. ({{event}}, recorded {{event_date}}.)
Original ETA: {{date_eta_original}}. Revised ETA: {{date_eta_revised}} ({{delay_days}} days later).
{{#eligible}}Make-good: {{product}}. {{product_description}}{{/eligible}}{{^eligible}}Note: this order does not qualify for {{product}} ({{eligibility_note}}), so do not offer it.{{/eligible}}

Apologize without excuses, give both dates plainly, explain the make-good, and offer a partial shipment if part of the quantity would help. Under 160 words.$t$),
  (73, $t$Write a shift handover summary from {{sender}} ({{sender_role}}) for the night shift leads, dated {{today}}.

Lines ({{count}}):
{{records_list}}

For each line, give output vs target, downtime and the open issue to carry over. Then list the top 3 actions for the next shift, most urgent first, with safety and P1 maintenance items at the top. Use short headings and bullets. Do not invent numbers. Under 200 words.$t$);

INSERT INTO offline_responses (industry_id, flow_id, kind, response_text) VALUES
  (7, 71, 'draft', $t$WORK ORDER: {{name}} ({{asset_tag}})
Line: {{line}}
Priority: {{priority}}
Detected: {{event_date}}

Readings vs baseline
- Vibration: {{vibration_mm_s}} mm/s (baseline {{baseline_mm_s}} mm/s)
- Bearing temperature: {{temp_c}} °C (baseline {{baseline_temp_c}} °C)

Likely cause
{{likely_cause}}

Action
{{recommended_action}}.

Parts
{{product}} ({{price}}), in stock in the MRO crib.

Safety
Apply lockout/tagout per the SOP before any work begins, and verify zero energy at the spindle or drive.

Requested by {{sender}}, {{sender_role}}$t$),
  (7, 72, 'draft', $t$Hi {{first_name}},

I want to give you an honest heads-up on {{po_number}} for {{quantity}} {{part}}. {{reason}}, so your order will arrive {{delay_days}} days later than we promised.

- Original delivery date: {{date_eta_original}}
- Revised delivery date: {{date_eta_revised}}

I'm sorry for the disruption.{{#eligible}} To win back some of that time, we're upgrading the shipment to expedited 2-day freight at no charge (normally $780 per shipment), so the parts leave our dock the day they clear final inspection.{{/eligible}}

If a partial shipment would help keep your line running, tell me the quantity you need first and I'll see what we can send ahead.

Best regards,
{{sender}}
{{sender_role}}, {{company}}$t$),
  (7, 73, 'draft', $t$Shift handover - {{today}}
From: {{sender}}, {{sender_role}}

Day shift results ({{count}} lines)
{{records_list}}

Priorities for the night shift
1. Review the open issues above at the start-of-shift huddle and confirm an owner for each, starting with any P1 maintenance item.
2. Keep lockout/tagout in place on any asset with an open work order until Maintenance signs it off.
3. Log downtime reasons in the MES as they happen so tomorrow's report is complete.

Call me if anything above changes the plan. Thanks, team.
{{sender}}$t$);

INSERT INTO offline_responses (industry_id, kind, match_keywords, response_text) VALUES
  (7, 'chat', '{first today,prioritize,priority,priorities,tackle first,which issue,which problem,biggest risk}', $t$I'd start with **CNC Mill 4**. Here's how I'd order today:

1. **CNC Mill 4 (Line 2 - Machining)** - spindle vibration hit 7.8 mm/s today against a 2.1 mm/s baseline. That's above the 7.1 mm/s alarm limit, so it's a P1: repair within 24 hours. The likely cause is front spindle bearing wear, and the bearing replacement kit is in stock.
2. **Apex Agricultural Equipment** - PO-60342 (450 gearbox housings) slipped 9 days after a casting supplier outage. It's the longer delay, and Luis Romero hasn't heard from us yet.
3. **Conveyor Drive Motor 3 (Line 3 - Assembly)** - 6.4 mm/s against a 1.9 mm/s baseline since yesterday. That's a P2 (within 72 hours), but plan it before it becomes a P1.

Want me to create the work order for CNC Mill 4 first?$t$),
  (7, 'chat', '{summary,summarize,overview,my day,this week}', $t$Here's the plant at a glance, {{user_first}}:

{{signals_summary}}

The most urgent item is CNC Mill 4: its spindle vibration is past the alarm limit, and Line 2 is already running below target. I can create work orders, draft customer ETA updates, prepare the shift handover, or answer questions from the SOP library.$t$),
  (7, 'chat', '{}', $t$Here's what I'm seeing across the plant right now:

{{signals_summary}}

I can turn sensor anomalies into work orders, send customers updated delivery dates, prepare the shift handover summary, or answer questions from the SOP library. What would you like to do next?$t$);

INSERT INTO knowledge_base (industry_id, source, section_title, content) VALUES
  (7, 'Ironbridge SOP Library', 'Lockout/tagout (SOP-S-014)',
   'Before any maintenance on a machine, the technician notifies affected operators, shuts the machine down with its normal stop, isolates every energy source (electrical, hydraulic, pneumatic and stored spring or gravity energy), applies a personal lock and tag to each isolation point, and verifies zero energy by attempting a start. Every person working on the machine applies their own lock. Locks are removed only by the person who applied them, after tools are cleared and guards are back in place.'),
  (7, 'Ironbridge SOP Library', 'Vibration alarm thresholds (SOP-M-022)',
   'Overall vibration velocity is measured in mm/s RMS. Below 2.8 mm/s is normal. From 4.5 mm/s the asset is in alert: open a P2 work order. Above 7.1 mm/s the asset is in alarm: open a P1 work order and limit the machine to light duty until the repair. A reading more than 3 times its own baseline is treated as an alert even below 4.5 mm/s.'),
  (7, 'Ironbridge SOP Library', 'Bearing temperature limits (SOP-M-023)',
   'Bearing and motor temperatures are compared with each asset''s own baseline. A rise of 15 °C over baseline is an alert, and a rise of 20 °C or more is an alarm. Combined with elevated vibration, a temperature alarm upgrades the work order to P1. Never touch a bearing housing to check temperature; use the handheld infrared gun or the online sensor.'),
  (7, 'Ironbridge SOP Library', 'Maintenance escalation matrix (SOP-M-010)',
   'P1 work orders must be repaired within 24 hours and the maintenance supervisor is paged immediately. P2 work orders are repaired within 72 hours, at a planned stop where possible. P3 items are added to the next preventive maintenance window. If a P1 cannot be staffed within 4 hours, escalate to the plant operations manager.'),
  (7, 'Ironbridge SOP Library', 'Quality holds (SOP-Q-007)',
   'Any operator can place a quality hold. Red-tag the affected parts, move them to the hold cage, and record the part number, lot and quantity in the MES. Quality must disposition held parts within 4 hours: release, rework or scrap. Held parts are never shipped, and a hold on a customer order triggers a same-day note to the account owner.'),
  (7, 'Ironbridge SOP Library', 'Customer delay communication (SOP-C-003)',
   'When a supplier delay moves a customer delivery by more than 3 days, notify the customer within 1 business day of confirming the new date. Give the original and revised dates, the reason in plain language, and a named contact. For delays of 5 days or more, offer expedited freight at no charge, and offer a partial shipment if finished parts are available.'),
  (7, 'Ironbridge SOP Library', 'Shift handover standard (SOP-O-011)',
   'Each line lead records units produced vs target, downtime minutes with reasons, and open issues before the end of shift. The outgoing shift lead shares one handover summary with the next shift leads and holds a 10-minute huddle at the line. Safety issues and P1 work orders are always listed first.'),
  (7, 'Ironbridge SOP Library', 'Work order content standard (SOP-M-004)',
   'Every work order names the asset and asset tag, the line, the readings compared with baseline, the likely cause, the recommended action, the parts needed and a lockout/tagout reminder. The requester is copied on completion, and the technician re-baselines any sensor after the repair.');

INSERT INTO suggestions (industry_id, title, prompt, icon, sort_order) VALUES
  (7, 'Plan my day', 'Which issue should I tackle first today?', 'chat', 1),
  (7, 'Check a procedure', 'What does our lockout procedure require?', 'book', 2),
  (7, 'Hand over the shift', 'Draft the shift handover for the night shift', 'list--checked', 3);

INSERT INTO chats (id, industry_id, title, is_seed, created_at, updated_at) VALUES
  (701, 7, 'Line 2 spindle vibration', TRUE, now() - interval '1 day', now() - interval '1 day'),
  (702, 7, 'Supplier delays this week', TRUE, now() - interval '2 days', now() - interval '2 days'),
  (703, 7, 'Vibration alarm limits', TRUE, now() - interval '4 days', now() - interval '4 days');

INSERT INTO chat_messages (chat_id, role, content, created_at) VALUES
  (701, 'user', 'Is CNC Mill 4 trending the wrong way?', now() - interval '1 day'),
  (701, 'assistant', 'Yes. **CNC Mill 4** spindle vibration has been climbing from its 2.1 mm/s baseline and bearing temperature is running above its 45 °C baseline. The pattern points to front spindle bearing wear. I will flag it the moment it crosses an alarm limit.', now() - interval '1 day'),
  (702, 'user', 'Which customer orders are affected by supplier delays?', now() - interval '2 days'),
  (702, 'assistant', 'Two so far: **Apex Agricultural Equipment** (PO-60342, 450 gearbox housings, 9 days late after a casting supplier outage) and **Northfield Hydraulics** (PO-58817, 1,200 machined valve bodies, 6 days late after a bar-stock delay). Both qualify for expedited freight at no charge.', now() - interval '2 days'),
  (703, 'user', 'At what vibration level do we open a P1 work order?', now() - interval '4 days'),
  (703, 'assistant', 'Above 7.1 mm/s the asset is in alarm: open a P1 work order and limit the machine to light duty until the repair. From 4.5 mm/s it is an alert and gets a P2. *Source: Ironbridge SOP Library, "Vibration alarm thresholds (SOP-M-022)".*', now() - interval '4 days');

INSERT INTO activity_log (industry_id, record_id, flow_id, action_type, payload, is_seed, created_at) VALUES
  (7, 706, 73, 'summary_shared', '{"to":"nightshift-leads@ironbridge.example","subject":"Shift handover: 3 lines","summary":"Shared the previous day shift handover"}', TRUE, now() - interval '1 day'),
  (7, 703, 72, 'task_created', '{"title":"Chase bar-stock supplier for a confirmed ship date on PO-58817","summary":"Internal task for Purchasing"}', TRUE, now() - interval '1 day');

INSERT INTO tasks (record_id, title, due_date, status, is_seed) VALUES
  (703, 'Chase bar-stock supplier for a confirmed ship date on PO-58817', CURRENT_DATE + 1, 'open', TRUE),
  (706, 'Review Line 2 scrap rate with Quality', CURRENT_DATE - 1, 'done', TRUE);
SELECT setval(pg_get_serial_sequence('industries','id'), (SELECT max(id) FROM industries));
SELECT setval(pg_get_serial_sequence('records','id'), (SELECT max(id) FROM records));
SELECT setval(pg_get_serial_sequence('products','id'), (SELECT max(id) FROM products));
SELECT setval(pg_get_serial_sequence('flows','id'), (SELECT max(id) FROM flows));
SELECT setval(pg_get_serial_sequence('signals','id'), (SELECT max(id) FROM signals));
SELECT setval(pg_get_serial_sequence('chats','id'), (SELECT max(id) FROM chats));
