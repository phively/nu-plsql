-- Main email table
Create Or Replace View v_nu_emails As

Select
  ems.im_msg_id
  , ems.msg_id
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
  , emr.msg_fk As msg_id
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
Create Or Replace View v_nu_emails_clicks As

Select
  emc.im_msg_id
  , emc.msg_fk As msg_id
  , emc.im_msg_recipient_id
  , er.id_number
  , Case
      When er.id_number Is Not Null
        Then er.id_number
      Else to_char(emc.im_msg_recipient_id)
      End
    As constituent_or_member_id
  , er.report_name
  , vne.email_msg_name
  , vne.kellogg_sender
  , eml.email_link_url
  , eml.email_link_name
  , Case
      When lower(email_link_name) Like '%unsubscribe%'
        Then 'Y'
      End
    As unsubscribe_link
  , trunc(emc.im_date_timestamp)
    As click_date
  , to_char(emc.im_date_timestamp, 'HH:MI:SS AM')
    As click_time
From nu_bio_t_emmx_msgs_clicks emc
Inner Join v_nu_emails vne
  On vne.im_msg_id = emc.im_msg_id
Left Join nu_bio_t_emmx_msgs_links eml
  On emc.im_msg_id = eml.im_msg_id
  And emc.msg_click_link_id = eml.im_msg_links_id
Left Join v_nu_emails_recipients er
  On er.im_msg_id = emc.im_msg_id
  And er.im_msg_rcpt_id = emc.im_msg_recipient_id
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
    , count(constituent_or_member_id)
      As email_clicks
    , count(Distinct constituent_or_member_id)
      As email_unique_clicks
    , count(Distinct Case When unsubscribe_link = 'Y' Then constituent_or_member_id End)
      As email_unsubscribe_clicks
  From v_nu_emails_clicks
  Group By im_msg_id
)

-- Main query
Select
  vne.im_msg_id
  , vne.msg_id
  , vne.email_msg_name
  , vne.email_from_name
  , vne.email_from_address
  , vne.kellogg_sender
  , vne.email_subject
  , vne.email_pre_header
  , vne.email_category_name
  , vne.email_actual_send_date
  , vne.email_send_date
  , vne.email_send_time
  , vne.email_send_month
  , vne.email_send_weekday
  , vne.email_sent_count
  , bounces.email_bounces
  , opens.email_opens
  , opens.email_unique_opens
  , opens.email_unique_opens / email_sent_count
    As unique_open_rate
  , clicks.email_clicks
  , clicks.email_unique_clicks
  , clicks.email_unique_clicks / email_sent_count
    As clickthrough_rate_all_links
  , clicks.email_unsubscribe_clicks
From v_nu_emails vne
Left Join opens
  On opens.im_msg_id = vne.im_msg_id
Left Join bounces
  On bounces.im_msg_id = vne.im_msg_id
Left Join clicks
  On clicks.im_msg_id = vne.im_msg_id
;
