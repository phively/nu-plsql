With

predata As (
  Select
    pgc.*
    , Case
        When ("Double-Alum" + "3 Year Season-Ticket Holder" + "Past or Current Parent") > 0
          Then 1
        Else 0
      End As "Deep Engagement"
    , "Active Prop Indicator" + "AGE" + "PM Visit Last 2Yrs" + "5 + Visits C Rpts" + "25K To Annual" + 
      "10+ Dist Yrs 1 Gft in Last 3" + "MG $250000 or more" + "Morty Visit" + "Trustee or Advisory BD" + 
      "Alumnus" + "CHIACGO_HOME"
      As other_indicators
  From rpt_sjs971.pg_cultivation pgc
)

Select
  "Primary Entity ID"
  , "Prospect ID"
  , "Prospect Name"
  , "Qualification Level"
  , "Pref State US/ Country (Int)"
  , "All NU Degrees"
  , "All NU Degrees Spouse"
  , "Prospect Manager"
  , "Affinity Score"
  , "CAMPAIGN_NEWGIFT_CMIT_CREDIT"
  , "ACTIVE_PLEDGE_BALANCE"
  , "MULTI_OR_SINGLE_INTEREST"
  , "POTENTIAL_INTEREST_AREAS"
  , ("Deep Engagement" + other_indicators) As "Cultivation Score"
  , "Active Prop Indicator"
  , "AGE"
  , "PM Visit Last 2Yrs"
  , "5 + Visits C Rpts"
  , "25K To Annual"
  , "10+ Dist Yrs 1 Gft in Last 3"
  , "MG $250000 or more"
  , "Morty Visit"
  , "Trustee or Advisory BD"
  , "Alumnus"
  , "Deep Engagement"
  , "CHIACGO_HOME"
  , "Double-Alum"
  , "3 Year Season-Ticket Holder"
  , "Past or Current Parent"
  , "PREF_NAME_SORT"
From predata
Order By
  ("Deep Engagement" + other_indicators) Desc
  , "Qualification Level" Asc
  , "PREF_NAME_SORT" Asc
