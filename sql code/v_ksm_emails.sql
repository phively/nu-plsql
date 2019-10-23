-- Main email table
Create Or Replace View v_nu_emails As

Select
  ems.im_msg_id
  , email_msg_name
  , email_from_name
  , email_from_address
  , Case
      -- Any email with Kellogg (not case sensitive) in the from address, though NOT necessarily the domain
      When lower(email_from_address) Like '%kellogg%'
        Then 'Y'
      End
    As kellogg_sender
  , email_subject
  , email_pre_header
  , email_category_name
  , email_actual_send_date
  , trunc(email_actual_send_date)
    As email_send_date
  , to_char(email_actual_send_date, 'HH:MI:SS AM')
    As email_send_time
  , to_char(email_actual_send_date, 'Month')
    As email_send_month
  , to_char(email_actual_send_date, 'Dy')
    As email_send_weekday
  , email_sent_count -- probably not de-duped
From nu_bio_t_emmx_msgs ems
;

-- Email recipients
Create Or Replace View v_nu_emails_recipients As

Select
  entity.id_number
  , entity.report_name
  , emr.im_msg_id
  , emr.im_member_id
    As imodules_id
  , im_msg_rcpt_id
  , emr.msg_first_name
  , emr.msg_last_name
  , emr.msg_rcpt_class_year
  , emr.msg_email_address
From entity
Inner Join nu_bio_t_emmx_msgs_rcpts emr
  On emr.constituent_id = entity.id_number
;

-- Email bounces
Select *
/* er.id_number
  , er.report_name
  , emb.im_msg_id
  , msg_bounce_type
  , msg_bounce_reason */
From nu_bio_t_emmx_msgs_bounces emb
;

-- Email opens
Select *
From nu_bio_t_emmx_msgs_opens
;

-- Email clicks
Select *
From nu_bio_t_emmx_msgs_clicks
;

-- Aggregated email stats
Create Or Replace View v_nu_emails_summary As

With

-- Aggregated email opens
opens As (
  Select
    im_msg_id
    , count(im_msg_recipient_id)
      As email_opens
    , count(Distinct im_msg_recipient_id)
      As email_unique_opens
  From nu_bio_t_emmx_msgs_opens
  Group By im_msg_id
)

-- Aggregated email bounces
, bounces As (
  Select
    im_msg_id
    , count(im_msg_recipient_id)
      As email_bounces
  From nu_bio_t_emmx_msgs_bounces
  Group By im_msg_id
)

-- Aggregated email clicks
, clicks As (
  Select
    im_msg_id
    , count(im_msg_recipient_id)
      As email_clicks
    , count(Distinct im_msg_recipient_id)
      As email_unique_clicks
  From nu_bio_t_emmx_msgs_clicks
  Group By im_msg_id
)

-- Main query
Select
  vne.*
  , bounces.email_bounces
  , opens.email_opens
  , opens.email_unique_opens
  , opens.email_unique_opens / email_sent_count
    As unique_open_rate
  , clicks.email_clicks
  , clicks.email_unique_clicks
  , clicks.email_unique_clicks / email_sent_count
    As clickthrough_rate_all_links
From v_nu_emails vne
Left Join opens
  On opens.im_msg_id = vne.im_msg_id
Left Join bounces
  On bounces.im_msg_id = vne.im_msg_id
Left Join clicks
  On clicks.im_msg_id = vne.im_msg_id
;
