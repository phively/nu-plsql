Create or Replace View v_industry_groups as 
select tms_fld_of_work.fld_of_work_code,
       tms_fld_of_work.short_desc,
Case  When  tms_fld_of_work.short_desc  IN  ('Accounting') then  'corp, fin'
  When  tms_fld_of_work.short_desc  IN  ('Airlines/Aviation') then  'man, tech, tran'
  When  tms_fld_of_work.short_desc  IN  ('Alternative Dispute Resolution') then  'leg, org'
  When  tms_fld_of_work.short_desc  IN  ('Alternative Medicine') then  'hlth'
  When  tms_fld_of_work.short_desc  IN  ('Animation') then  'art, med'
  When  tms_fld_of_work.short_desc  IN  ('Apparel & Fashion') then  'good'
  When  tms_fld_of_work.short_desc  IN  ('Architecture & Planning') then  'cons'
  When  tms_fld_of_work.short_desc  IN  ('Arts and Crafts') then  'art, med, rec'
  When  tms_fld_of_work.short_desc  IN  ('Automotive') then  'man'
  When  tms_fld_of_work.short_desc  IN  ('Aviation & Aerospace') then  'gov, man'
  When  tms_fld_of_work.short_desc  IN  ('Banking') then  'fin'
  When  tms_fld_of_work.short_desc  IN  ('Biotechnology') then  'gov, hlth, tech'
  When  tms_fld_of_work.short_desc  IN  ('Broadcast Media') then  'med, rec'
  When  tms_fld_of_work.short_desc  IN  ('Building Materials') then  'cons'
  When  tms_fld_of_work.short_desc  IN  ('Business Supplies and Equipment') then  'corp, man'
  When  tms_fld_of_work.short_desc  IN  ('Capital Markets') then  'fin'
  When  tms_fld_of_work.short_desc  IN  ('Chemicals') then  'man'
  When  tms_fld_of_work.short_desc  IN  ('Civic & Social Organization') then  'org, serv'
  When  tms_fld_of_work.short_desc  IN  ('Civil Engineering') then  'cons, gov'
  When  tms_fld_of_work.short_desc  IN  ('Commercial Real Estate') then  'cons, corp, fin'
  When  tms_fld_of_work.short_desc  IN  ('Computer & Network Security' ) then  'tech'
  When  tms_fld_of_work.short_desc  IN  ('Computer Games') then  'med, rec'
  When  tms_fld_of_work.short_desc  IN  ('Computer Hardware') then  'tech'
  When  tms_fld_of_work.short_desc  IN  ('Computer Networking') then  'tech'
  When  tms_fld_of_work.short_desc  IN  ('Computer Software') then  'tech'
  When  tms_fld_of_work.short_desc  IN  ('Construction') then  'cons'
  When  tms_fld_of_work.short_desc  IN  ('Consumer Electronics') then  'good, man'
  When  tms_fld_of_work.short_desc  IN  ('Consumer Goods') then  'good, man'
  When  tms_fld_of_work.short_desc  IN  ('Consumer Services') then  'org, serv'
  When  tms_fld_of_work.short_desc  IN  ('Cosmetics') then  'good'
  When  tms_fld_of_work.short_desc  IN  ('Dairy') then  'agr'
  When  tms_fld_of_work.short_desc  IN  ('Defense & Space') then  'gov, tech'
  When  tms_fld_of_work.short_desc  IN  ('Design') then  'art, med'
  When  tms_fld_of_work.short_desc  IN  ('Education Management') then  'edu'
  When  tms_fld_of_work.short_desc  IN  ('E-Learning') then  'edu, org'
  When  tms_fld_of_work.short_desc  IN  ('Electrical/Electronic Manufacturing') then  'good, man'
  When  tms_fld_of_work.short_desc  IN  ('Entertainment') then  'med, rec'
  When  tms_fld_of_work.short_desc  IN  ('Environmental Services') then  'org, serv'
  When  tms_fld_of_work.short_desc  IN  ('Events Services') then  'corp, rec, serv'
  When  tms_fld_of_work.short_desc  IN  ('Executive Office') then  'gov'
  When  tms_fld_of_work.short_desc  IN  ('Facilities Services') then  'corp, serv'
  When  tms_fld_of_work.short_desc  IN  ('Farming') then  'agr'
  When  tms_fld_of_work.short_desc  IN  ('Financial Services') then  'fin'
  When  tms_fld_of_work.short_desc  IN  ('Fine Art') then  'art, med, rec'
  When  tms_fld_of_work.short_desc  IN  ('Fishery') then  'agr'
  When  tms_fld_of_work.short_desc  IN  ('Food & Beverages') then  'rec, serv'
  When  tms_fld_of_work.short_desc  IN  ('Food Production') then  'good, man, serv'
  When  tms_fld_of_work.short_desc  IN  ('Fund-Raising') then  'org'
  When  tms_fld_of_work.short_desc  IN  ('Furniture') then  'good, man'
  When  tms_fld_of_work.short_desc  IN  ('Gambling & Casinos') then  'rec'
  When  tms_fld_of_work.short_desc  IN  ('Glass, Ceramics & Concrete') then  'cons, man'
  When  tms_fld_of_work.short_desc  IN  ('Government Administration') then  'gov'
  When  tms_fld_of_work.short_desc  IN  ('Government Relations') then  'gov'
  When  tms_fld_of_work.short_desc  IN  ('Graphic Design') then  'art, med'
  When  tms_fld_of_work.short_desc  IN  ('Health, Wellness and Fitness') then  'hlth, rec'
  When  tms_fld_of_work.short_desc  IN  ('Higher Education') then  'edu'
  When  tms_fld_of_work.short_desc  IN  ('Hospital & Health Care') then  'hlth'
  When  tms_fld_of_work.short_desc  IN  ('Hospitality') then  'rec, serv, tran'
  When  tms_fld_of_work.short_desc  IN  ('Human Resources') then  'corp'
  When  tms_fld_of_work.short_desc  IN  ('Import and Export') then  'corp, good, tran'
  When  tms_fld_of_work.short_desc  IN  ('Individual & Family Services') then  'org, serv'
  When  tms_fld_of_work.short_desc  IN  ('Industrial Automation') then  'cons, man'
  When  tms_fld_of_work.short_desc  IN  ('Information Services') then  'med, serv'
  When  tms_fld_of_work.short_desc  IN  ('Information Technology and Services') then  'tech'
  When  tms_fld_of_work.short_desc  IN  ('Insurance') then  'fin'
  When  tms_fld_of_work.short_desc  IN  ('International Affairs') then  'gov'
  When  tms_fld_of_work.short_desc  IN  ('International Trade and Development') then  'gov, org, tran'
  When  tms_fld_of_work.short_desc  IN  ('Internet') then  'tech'
  When  tms_fld_of_work.short_desc  IN  ('Investment Banking') then  'fin'
  When  tms_fld_of_work.short_desc  IN  ('Investment Management') then  'fin'
  When  tms_fld_of_work.short_desc  IN  ('Judiciary') then  'gov, leg'
  When  tms_fld_of_work.short_desc  IN  ('Law Enforcement') then  'gov, leg'
  When  tms_fld_of_work.short_desc  IN  ('Law Practice') then  'leg'
  When  tms_fld_of_work.short_desc  IN  ('Legal Services') then  'leg'
  When  tms_fld_of_work.short_desc  IN  ('Legislative Office') then  'gov, leg'
  When  tms_fld_of_work.short_desc  IN  ('Leisure, Travel & Tourism') then  'rec, serv, tran'
  When  tms_fld_of_work.short_desc  IN  ('Libraries') then  'med, rec, serv'
  When  tms_fld_of_work.short_desc  IN  ('Logistics and Supply Chain') then  'corp, tran'
  When  tms_fld_of_work.short_desc  IN  ('Luxury Goods & Jewelry') then  'good'
  When  tms_fld_of_work.short_desc  IN  ('Machinery') then  'man'
  When  tms_fld_of_work.short_desc  IN  ('Management Consulting') then  'corp'
  When  tms_fld_of_work.short_desc  IN  ('Maritime') then  'tran'
  When  tms_fld_of_work.short_desc  IN  ('Market Research') then  'corp'
  When  tms_fld_of_work.short_desc  IN  ('Marketing and Advertising') then  'corp, med'
  When  tms_fld_of_work.short_desc  IN  ('Mechanical or Industrial Engineering') then  'cons, gov, man'
  When  tms_fld_of_work.short_desc  IN  ('Media Production') then  'med, rec'
  When  tms_fld_of_work.short_desc  IN  ('Medical Devices') then  'hlth'
  When  tms_fld_of_work.short_desc  IN  ('Medical Practice') then  'hlth'
  When  tms_fld_of_work.short_desc  IN  ('Mental Health Care') then  'hlth'
  When  tms_fld_of_work.short_desc  IN  ('Military') then  'gov'
  When  tms_fld_of_work.short_desc  IN  ('Mining & Metals') then  'man'
  When  tms_fld_of_work.short_desc  IN  ('Motion Pictures and Film') then  'art, med, rec'
  When  tms_fld_of_work.short_desc  IN  ('Museums and Institutions') then  'art, med, rec'
  When  tms_fld_of_work.short_desc  IN  ('Music') then  'art, rec'
  When  tms_fld_of_work.short_desc  IN  ('Nanotechnology') then  'gov, man, tech'
  When  tms_fld_of_work.short_desc  IN  ('Newspapers') then  'med, rec'
  When  tms_fld_of_work.short_desc  IN  ('Non-Profit Organization Management') then  'org'
  When  tms_fld_of_work.short_desc  IN  ('Oil & Energy') then  'man'
  When  tms_fld_of_work.short_desc  IN  ('Online Media') then  'med'
  When  tms_fld_of_work.short_desc  IN  ('Outsourcing/Offshoring') then  'corp'
  When  tms_fld_of_work.short_desc  IN  ('Package/Freight Delivery') then  'serv, tran'
  When  tms_fld_of_work.short_desc  IN  ('Packaging and Containers') then  'good, man'
  When  tms_fld_of_work.short_desc  IN  ('Paper & Forest Products') then  'man'
  When  tms_fld_of_work.short_desc  IN  ('Performing Arts') then  'art, med, rec'
  When  tms_fld_of_work.short_desc  IN  ('Pharmaceuticals') then  'hlth, tech'
  When  tms_fld_of_work.short_desc  IN  ('Philanthropy') then  'org'
  When  tms_fld_of_work.short_desc  IN  ('Photography') then  'art, med, rec'
  When  tms_fld_of_work.short_desc  IN  ('Plastics') then  'man'
  When  tms_fld_of_work.short_desc  IN  ('Political Organization') then  'gov, org'
  When  tms_fld_of_work.short_desc  IN  ('Primary/Secondary Education') then  'edu'
  When  tms_fld_of_work.short_desc  IN  ('Printing') then  'med, rec'
  When  tms_fld_of_work.short_desc  IN  ('Professional Training & Coaching') then  'corp'
  When  tms_fld_of_work.short_desc  IN  ('Program Development') then  'corp, org'
  When  tms_fld_of_work.short_desc  IN  ('Public Policy') then  'gov'
  When  tms_fld_of_work.short_desc  IN  ('Public Relations and Communications') then  'corp'
  When  tms_fld_of_work.short_desc  IN  ('Public Safety') then  'gov'
  When  tms_fld_of_work.short_desc  IN  ('Publishing') then  'med, rec'
  When  tms_fld_of_work.short_desc  IN  ('Railroad Manufacture') then  'man'
  When  tms_fld_of_work.short_desc  IN  ('Ranching') then  'agr'
  When  tms_fld_of_work.short_desc  IN  ('Real Estate') then  'cons, fin, good'
  When  tms_fld_of_work.short_desc  IN  ('Recreational Facilities and Services') then  'rec, serv'
  When  tms_fld_of_work.short_desc  IN  ('Religious Institutions') then  'org, serv'
  When  tms_fld_of_work.short_desc  IN  ('Renewables & Environment') then  'gov, man, org'
  When  tms_fld_of_work.short_desc  IN  ('Research') then  'edu, gov'
  When  tms_fld_of_work.short_desc  IN  ('Restaurants') then  'rec, serv'
  When  tms_fld_of_work.short_desc  IN  ('Retail') then  'good, man'
  When  tms_fld_of_work.short_desc  IN  ('Security and Investigations') then  'corp, org, serv'
  When  tms_fld_of_work.short_desc  IN  ('Semiconductors') then  'tech'
  When  tms_fld_of_work.short_desc  IN  ('Shipbuilding') then  'man'
  When  tms_fld_of_work.short_desc  IN  ('Sporting Goods') then  'good, rec'
  When  tms_fld_of_work.short_desc  IN  ('Sports') then  'rec'
  When  tms_fld_of_work.short_desc  IN  ('Staffing and Recruiting') then  'corp'
  When  tms_fld_of_work.short_desc  IN  ('Supermarkets') then  'good'
  When  tms_fld_of_work.short_desc  IN  ('Telecommunications') then  'gov, tech'
  When  tms_fld_of_work.short_desc  IN  ('Textiles') then  'man'
  When  tms_fld_of_work.short_desc  IN  ('Think Tanks') then  'gov, org'
  When  tms_fld_of_work.short_desc  IN  ('Tobacco') then  'good'
  When  tms_fld_of_work.short_desc  IN  ('Translation and Localization') then  'corp, gov, serv'
  When  tms_fld_of_work.short_desc  IN  ('Transportation/Trucking/Railroad') then  'tran'
  When  tms_fld_of_work.short_desc  IN  ('Utilities') then  'man'
  When  tms_fld_of_work.short_desc  IN  ('Venture Capital & Private Equity') then  'fin, tech'
  When  tms_fld_of_work.short_desc  IN  ('Veterinary') then  'hlth'
  When  tms_fld_of_work.short_desc  IN  ('Warehousing') then  'tran'
  When  tms_fld_of_work.short_desc  IN  ('Wholesale') then  'good'
  When  tms_fld_of_work.short_desc  IN  ('Wine and Spirits') then  'good, man, rec'
  When  tms_fld_of_work.short_desc  IN  ('Wireless') then  'tech'
  When  tms_fld_of_work.short_desc  IN  ('Writing and Editing') then  'art, med, rec'
Else '' End as industry_group,
  ---- Agriculture Indicator
case when tms_fld_of_work.short_desc IN ('Dairy', 'Farming', 'Fishery', 'Ranching') then 'X' else '' END as AGR,
  ---- Art Indicator
case when tms_fld_of_work.short_desc IN ('Animation', 'Design', 'Graphic Design', 'Arts and Crafts','Fine Art','Motion Pictures and Film',
  'Museums and Institutions','Performing Arts','Photography','Writing and Editing','Music' ) 
  then 'X' else '' END as ART,
    --- Construction Indicator
 case when tms_fld_of_work.short_desc IN ('Architecture & Planning', 'Building Materials', 'Construction', 'Commercial Real Estate','Real Estate',
   'Civil Engineering','Mechanical or Industrial Engineering','Glass, Ceramics & Concrete','Industrial Automation') 
  then 'X' else '' END as CONS,   
    --- Corporate Indicator
 case when tms_fld_of_work.short_desc IN ('Human Resources', 'Management Consulting', 'Market Research', 
   'Outsourcing/Offshoring','Professional Training & Coaching',
   'Public Relations and Communications','Staffing and Recruiting',
   'Accounting','Import and Export','Translation and Localization',
   'Business Supplies and Equipment','Marketing and Advertising','Program Development',
   'Security and Investigations','Events Services','Facilities Services','Logistics and Supply Chain') 
  then 'X' else '' END as CORP,
    --- Education Indicator
case when tms_fld_of_work.short_desc IN ('Education Management','Higher Education',
  'Primary/Secondary Education','Research','E-Learning') 
  then 'X' else '' END as EDU,
    --- Finance Indicator
case when tms_fld_of_work.short_desc IN ('Banking','Capital Markets', 'Financial Services','Insurance',
  'Investment Banking','Investment Management','Venture Capital & Private Equity','Accounting') 
  then 'X' else '' END as FIN,
    --- Goods Indicator 
case when tms_fld_of_work.short_desc IN ('Apparel & Fashion','Cosmetics', 'Luxury Goods & Jewelry','Supermarkets',
  'Tobacco','Wholesale','Consumer Electronics','Consumer Goods','Electrical/Electronic Manufacturing',
  'Furniture','Packaging and Containers','Retail','Wine and Spirits',
  'Food Production','Sporting Goods','Import and Export','Real Estate') 
  then 'X' else '' END as GOODS,   
   --- Govt Indicator
case when tms_fld_of_work.short_desc IN ('Executive Office','Government Administration', 'Government Relations','International Affairs',
  'Military','Public Policy','Public Safety','Biotechnology','Judiciary',
  'Law Enforcement','Legislative Office','Aviation & Aerospace','Renewables & Environment',
  'Nanotechnology','Political Organization','Think Tanks','International Trade and Development',
  'Defense & Space','Telecommunications','Research','Translation and Localization',
  'Mechanical or Industrial Engineering','Civil Engineering') 
  then 'X' else '' END as GOVT,   
 --- Health Indicator
 case when tms_fld_of_work.short_desc IN ('Alternative Medicine','Hospital & Health Care', 'Medical Devices','Medical Practice',
  'Mental Health Care','Veterinary','Health, Wellness and Fitness','Pharmaceuticals','Biotechnology') 
  then 'X' else '' END as HLTH,
 --- Legal Indicator
case when tms_fld_of_work.short_desc IN ('Law Practice','Legal Services', 'Alternative Dispute Resolution') 
  then 'X' else '' END as LEG,
 --- Manufacturing Indicator
 case when tms_fld_of_work.short_desc IN ('Automotive','Chemicals', 'Machinery',
   'Mining & Metals','Oil & Energy', 'Paper & Forest Products','Plastics',
  'Railroad Manufacture','Shipbuilding','Textiles','Utilities','Airlines/Aviation'
  ,'Nanotechnology','Renewables & Environment','Aviation & Aerospace',
  'Consumer Electronics','Consumer Goods','Electrical/Electronic Manufacturing',
  'Furniture','Packaging and Containers','Retail','Wine and Spirits','Food Production',
  'Business Supplies and Equipment','Mechanical or Industrial Engineering','Glass, Ceramics & Concrete',
'Industrial Automation'
   ) 
  then 'X' else '' END as MAN,  
    --- Medical Indicator
     case when tms_fld_of_work.short_desc IN ('Online Media','Broadcast Media', 'Computer Games',
   'Entertainment','Media Production', 'Newspapers','Printing',
  'Publishing','Libraries','Information Services'
   ) 
  then 'X' else '' END as MED,
    --- Organization Indicator
    case when tms_fld_of_work.short_desc IN ('Fund-Raising','Non-Profit Organization Management', 'Philanthropy',
   'Civic & Social Organization','Consumer Services', 'Environmental Services','Individual & Family Services',
  'Religious Institutions','Alternative Dispute Resolution','Renewables & Environment','Nanotechnology',
  'Political Organization','Think Tanks','International Trade and Development','E-Learning',
  'Security and Investigations','Program Development'
   ) 
  then 'X' else '' END as ORG,
    --- Recreation Indicator
    case when tms_fld_of_work.short_desc IN ('Gambling & Casinos','Sports', 'Food & Beverages',
   'Recreational Facilities and Services','Restaurants', 'Hospitality','Leisure, Travel & Tourism',
   'Broadcast Media','Computer Games', 'Entertainment','Media Production', 'Newspapers',
   'Printing','Publishing', 'Entertainment','Libraries','Health, Wellness and Fitness','Sporting Goods',
   'Wine and Spirits','Events Services'
   ) 
    ---- Service Indicator
  then 'X' else '' END as REC, 
   case when tms_fld_of_work.short_desc IN ('Package/Freight Delivery','Civic & Social Organization','Consumer Services', 
     'Environmental Services','Individual & Family Services','Religious Institutions','Libraries','Food Production'
     ,'Facilities Services','Events Services','Security and Investigations','Translation and Localization',
     'Arts and Crafts','Fine Art','Motion Pictures and Film','Museums and Institutions','Performing Arts',
     'Photography','Writing and Editing') 
  then 'X' else '' END as SERV,
    --- Technology Indicator
    case when tms_fld_of_work.short_desc IN ('Computer & Network Security','Computer Hardware','Computer Networking', 
     'Computer Software','Information Technology and Services',
     'Internet','Semiconductors','Wireless','Airlines/Aviation','Pharmaceuticals','Defense & Space',
'Telecommunications','Biotechnology','Venture Capital & Private Equity','Nanotechnology')
  then 'X' else '' END as TECH,
    ---- Transporation Indicator
    case when tms_fld_of_work.short_desc IN ('Maritime','Transportation/Trucking/Railroad','Warehousing', 
     'Hospitality','Leisure, Travel & Tourism',
     'Package/Freight Delivery','Airlines/Aviation','Logistics and Supply Chain',
     'Import and Export','Pharmaceuticals','Defense & Space',
'Telecommunications','Biotechnology','Venture Capital & Private Equity') 
  then 'X' else '' END as TRAN
       from  tms_fld_of_work 
       where tms_fld_of_work.fld_of_work_code Like 'L%'
       and tms_fld_of_work.fld_of_work_code Not Like 'LENF'
           order by tms_fld_of_work.short_desc asc
   
