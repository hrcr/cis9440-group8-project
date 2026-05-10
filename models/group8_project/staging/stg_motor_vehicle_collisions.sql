-- Clean and standardize motor vehicle collisions data
-- One row per collision

WITH source AS (
    SELECT *
    FROM {{ source('raw', 'raw_motor_vehicle_collisions') }}
),

cleaned AS (
    SELECT
        -- Identifier
        CAST(collision_id AS STRING) AS collision_id,

        -- Date / time
        DATE(SAFE_CAST(crash_date AS TIMESTAMP)) AS crash_date,
        SAFE_CAST(crash_time AS TIME) AS crash_time,

        -- Location
        CASE
            WHEN UPPER(TRIM(CAST(zip_code AS STRING))) IN ('N/A', 'NA', '') THEN NULL
            WHEN REGEXP_CONTAINS(CAST(zip_code AS STRING), r'^\d{5}$') THEN CAST(zip_code AS STRING)
            WHEN REGEXP_CONTAINS(CAST(zip_code AS STRING), r'^\d{5}-\d{4}$') THEN CAST(zip_code AS STRING)
            ELSE NULL
        END AS zip_code,

        CASE
            WHEN UPPER(TRIM(CAST(borough AS STRING))) IN ('MANHATTAN', 'NEW YORK COUNTY') THEN 'Manhattan'
            WHEN UPPER(TRIM(CAST(borough AS STRING))) IN ('BRONX', 'THE BRONX') THEN 'Bronx'
            WHEN UPPER(TRIM(CAST(borough AS STRING))) IN ('BROOKLYN', 'KINGS COUNTY') THEN 'Brooklyn'
            WHEN UPPER(TRIM(CAST(borough AS STRING))) IN ('QUEENS', 'QUEEN', 'QUEENS COUNTY') THEN 'Queens'
            WHEN UPPER(TRIM(CAST(borough AS STRING))) IN ('STATEN ISLAND', 'RICHMOND COUNTY') THEN 'Staten Island'
            ELSE 'UNKNOWN'
        END AS borough,

        CAST(on_street_name AS STRING) AS on_street_name,
        CAST(off_street_name AS STRING) AS off_street_name,
        CAST(cross_street_name AS STRING) AS cross_street_name,
        SAFE_CAST(latitude AS NUMERIC) AS latitude,
        SAFE_CAST(longitude AS NUMERIC) AS longitude,

        -- Vehicle types
-- Vehicle types (standardized into clean categories)
        CASE
            WHEN UPPER(TRIM(CAST(vehicle_type_code1 AS STRING))) LIKE '%AMBULAN%'
              OR UPPER(TRIM(CAST(vehicle_type_code1 AS STRING))) LIKE '%AMBUL%'
              OR UPPER(TRIM(CAST(vehicle_type_code1 AS STRING))) IN ('AMB','AMBU','AMBUL','EAMB','E AMB','G AMB','NS AM','X AMB',
                 'EMS','EMS AMBULA','EMS AMBULE','EMT','EMT AMBULA','FDNY EMT',
                 'NYS AMBULA','REG.AMBULA','PRIV AMBUL','GEN  AMBUL','FORD AMBUL',
                 'FD AMBULAN','EMBULANCE','EMERGANCY','EMERGENCY','A bulance',
                 'abulance','almbulance','amdu','amulance','anbul','AMUBL','AMUBULANCE')
                THEN 'Ambulance'

            WHEN UPPER(TRIM(CAST(vehicle_type_code1 AS STRING))) LIKE '%FDNY%'
              OR UPPER(TRIM(CAST(vehicle_type_code1 AS STRING))) LIKE '%FIRETRUCK%'
              OR UPPER(TRIM(CAST(vehicle_type_code1 AS STRING))) LIKE '%FIRE TRUCK%'
              OR UPPER(TRIM(CAST(vehicle_type_code1 AS STRING))) LIKE '%FIRE APPAR%'
              OR UPPER(TRIM(CAST(vehicle_type_code1 AS STRING))) LIKE '%FIRE ENG%'
              OR UPPER(TRIM(CAST(vehicle_type_code1 AS STRING))) LIKE '%FIRE DEPT%'
              OR UPPER(TRIM(CAST(vehicle_type_code1 AS STRING))) LIKE '%FIRE LADD%'
              OR UPPER(TRIM(CAST(vehicle_type_code1 AS STRING))) LIKE '%FIRET%'
              OR UPPER(TRIM(CAST(vehicle_type_code1 AS STRING))) LIKE '%FD TR%'
              OR UPPER(TRIM(CAST(vehicle_type_code1 AS STRING))) LIKE '%FD EN%'
              OR UPPER(TRIM(CAST(vehicle_type_code1 AS STRING))) LIKE '%FD LA%'
              OR UPPER(TRIM(CAST(vehicle_type_code1 AS STRING))) IN ('FIRE','FIRE RUCK','FIRER','FIRTRUCK','FIRETURCK','FNDY EMS','FDNYLadder','FDNYTRUCKF')
                THEN 'Fire Apparatus'

            WHEN UPPER(TRIM(CAST(vehicle_type_code1 AS STRING))) LIKE '%SCHOOL BUS%'
              OR UPPER(TRIM(CAST(vehicle_type_code1 AS STRING))) LIKE '%SCHOOLBUS%'
              OR UPPER(TRIM(CAST(vehicle_type_code1 AS STRING))) LIKE '%SCHOOL VAN%'
              OR UPPER(TRIM(CAST(vehicle_type_code1 AS STRING))) IN ('YELLOW BUS','YELLOWBUS','YW SCHOOL','SMYELLSCHO',
                 'SHORT SCHO','MINI SCHOO','SM YW','YLL P','SHCOO','SCHOO','SCHOO LBUS',
                 'SCHOOL  BU','Yellow bus','Yellow sch','Small Bus','Small scho','Short Bus')
                THEN 'School Bus'

            WHEN UPPER(TRIM(CAST(vehicle_type_code1 AS STRING))) LIKE '%MTA BUS%'
              OR UPPER(TRIM(CAST(vehicle_type_code1 AS STRING))) LIKE '%CITY BUS%'
              OR UPPER(TRIM(CAST(vehicle_type_code1 AS STRING))) LIKE '%TRANSIT%'
              OR UPPER(TRIM(CAST(vehicle_type_code1 AS STRING))) LIKE '%OMNIBUS%'
              OR UPPER(TRIM(CAST(vehicle_type_code1 AS STRING))) IN ('BUS','BUSS','TOUR BUS','SHUTTLE BU','MINI BUS',
                 'COACH','NICE BUS','BLU BUS','BUS M','BUs','ORION','NEW FLYER','LIVERY BUS','Livery Omn','Livery Bus')
                THEN 'Bus'

            WHEN UPPER(TRIM(CAST(vehicle_type_code1 AS STRING))) LIKE '%TAXI%'
              OR UPPER(TRIM(CAST(vehicle_type_code1 AS STRING))) LIKE '%YELLOW CAB%'
              OR UPPER(TRIM(CAST(vehicle_type_code1 AS STRING))) IN ('YELLO','DOLLAR VAN','PETIT CAB','Yellow Cab','Yellow cab')
                THEN 'Taxi'

            WHEN UPPER(TRIM(CAST(vehicle_type_code1 AS STRING))) LIKE '%LIVERY%'
              OR UPPER(TRIM(CAST(vehicle_type_code1 AS STRING))) LIKE '%MEDALLION%'
              OR UPPER(TRIM(CAST(vehicle_type_code1 AS STRING))) LIKE '%TLC%'
                THEN 'Livery/TLC'

            WHEN UPPER(TRIM(CAST(vehicle_type_code1 AS STRING))) LIKE '%LIMO%'
                THEN 'Limousine'

            WHEN UPPER(TRIM(CAST(vehicle_type_code1 AS STRING))) LIKE '%USPS%'
              OR UPPER(TRIM(CAST(vehicle_type_code1 AS STRING))) LIKE '%US POSTAL%'
              OR UPPER(TRIM(CAST(vehicle_type_code1 AS STRING))) LIKE '%US MAIL%'
              OR UPPER(TRIM(CAST(vehicle_type_code1 AS STRING))) LIKE '%POSTAL%'
              OR UPPER(TRIM(CAST(vehicle_type_code1 AS STRING))) LIKE '%MAIL TRUCK%'
              OR UPPER(TRIM(CAST(vehicle_type_code1 AS STRING))) LIKE '%MAILTRUCK%'
              OR UPPER(TRIM(CAST(vehicle_type_code1 AS STRING))) IN ('LLV','LLV MAIL T','U.S. POSTA','U.S.P','US PO','US Po')
                THEN 'Postal/Mail'

            WHEN UPPER(TRIM(CAST(vehicle_type_code1 AS STRING))) LIKE '%FEDEX%'
              OR UPPER(TRIM(CAST(vehicle_type_code1 AS STRING))) LIKE '%FED EX%'
              OR UPPER(TRIM(CAST(vehicle_type_code1 AS STRING))) LIKE '%AMAZON%'
              OR UPPER(TRIM(CAST(vehicle_type_code1 AS STRING))) LIKE '%DHL%'
              OR UPPER(TRIM(CAST(vehicle_type_code1 AS STRING))) LIKE '%DELIVERY%'
              OR UPPER(TRIM(CAST(vehicle_type_code1 AS STRING))) LIKE '%DELIV%'
              OR UPPER(TRIM(CAST(vehicle_type_code1 AS STRING))) LIKE '%COURIER%'
              OR UPPER(TRIM(CAST(vehicle_type_code1 AS STRING))) IN ('UPS','UPS T','UPS VAN','UPS M','DLEV','DLVR','DELV','DELVR','DEL','DEL T')
                THEN 'Delivery Vehicle'

            WHEN UPPER(TRIM(CAST(vehicle_type_code1 AS STRING))) LIKE '%U-HAUL%'
              OR UPPER(TRIM(CAST(vehicle_type_code1 AS STRING))) LIKE '%UHAUL%'
              OR UPPER(TRIM(CAST(vehicle_type_code1 AS STRING))) LIKE '%U HAUL%'
              OR UPPER(TRIM(CAST(vehicle_type_code1 AS STRING))) LIKE '%UHUAL%'
              OR UPPER(TRIM(CAST(vehicle_type_code1 AS STRING))) IN ('RYDER','PENSKE BOX','U-TRU','UHAL','UHAL TRUCK')
                THEN 'Rental Truck'

            WHEN UPPER(TRIM(CAST(vehicle_type_code1 AS STRING))) LIKE '%PICKUP%'
              OR UPPER(TRIM(CAST(vehicle_type_code1 AS STRING))) LIKE '%PICK UP%'
              OR UPPER(TRIM(CAST(vehicle_type_code1 AS STRING))) LIKE '%PICK-UP%'
              OR UPPER(TRIM(CAST(vehicle_type_code1 AS STRING))) IN ('PU','PICKU','PK','PKUP','P/U','PICK','PICK-')
                THEN 'Pickup Truck'

            WHEN UPPER(TRIM(CAST(vehicle_type_code1 AS STRING))) LIKE '%BOX TRUCK%'
              OR UPPER(TRIM(CAST(vehicle_type_code1 AS STRING))) LIKE '%BOXTRUCK%'
              OR UPPER(TRIM(CAST(vehicle_type_code1 AS STRING))) IN ('BOX T','BOXTR','BOX VAN','BOX CAR','BOX CARGO','BOX','BOX H','EMPTYBOX T')
                THEN 'Box Truck'

            WHEN UPPER(TRIM(CAST(vehicle_type_code1 AS STRING))) LIKE '%FLATBED%'
              OR UPPER(TRIM(CAST(vehicle_type_code1 AS STRING))) LIKE '%FLAT BED%'
              OR UPPER(TRIM(CAST(vehicle_type_code1 AS STRING))) IN ('FLAT','FLAT RACK','FLAT-','FLAT/','PLATF')
                THEN 'Flatbed Truck'

            WHEN UPPER(TRIM(CAST(vehicle_type_code1 AS STRING))) LIKE '%TRACTOR TR%'
              OR UPPER(TRIM(CAST(vehicle_type_code1 AS STRING))) LIKE '%SEMI TRUCK%'
              OR UPPER(TRIM(CAST(vehicle_type_code1 AS STRING))) LIKE '%SEMI-TRUCK%'
              OR UPPER(TRIM(CAST(vehicle_type_code1 AS STRING))) LIKE '%SEMI TRAIL%'
              OR UPPER(TRIM(CAST(vehicle_type_code1 AS STRING))) LIKE '%FREIGHTLIN%'
              OR UPPER(TRIM(CAST(vehicle_type_code1 AS STRING))) LIKE '%18 WHEEL%'
              OR UPPER(TRIM(CAST(vehicle_type_code1 AS STRING))) LIKE '%18WHEEL%'
              OR UPPER(TRIM(CAST(vehicle_type_code1 AS STRING))) IN ('SEMI','SEMI-','TRACTOR','MACK','KENWORTH T',
                 'FUSO TRUCK','18 WH','18 WHEELER','18 WEELER','18 WH','18 Wh',
                 'TRACTOR TRUCK DIESEL','TRACTOR TRUCK GASOLINE','MACK TRUCK','Mack Truck','Mack truck','Macktruck',
                 'FREIG','FRHT','FRT','FLTRL','LTRL','NTTRL','LCOM','LCOMM','SCOMM')
                THEN 'Tractor/Semi-Truck'

            WHEN UPPER(TRIM(CAST(vehicle_type_code1 AS STRING))) LIKE '%DUMP TRUCK%'
              OR UPPER(TRIM(CAST(vehicle_type_code1 AS STRING))) LIKE '%DUMP TR%'
              OR UPPER(TRIM(CAST(vehicle_type_code1 AS STRING))) IN ('DUMP','DUMPT','DUMPTRUCK','DUMP TRUK','DUMPS','DUMPSTER','DUMPSTER T','DUMPTRUCK')
                THEN 'Dump Truck'

            WHEN UPPER(TRIM(CAST(vehicle_type_code1 AS STRING))) LIKE '%SANITAT%'
              OR UPPER(TRIM(CAST(vehicle_type_code1 AS STRING))) LIKE '%DSNY%'
              OR UPPER(TRIM(CAST(vehicle_type_code1 AS STRING))) LIKE '%GARBAGE%'
              OR UPPER(TRIM(CAST(vehicle_type_code1 AS STRING))) LIKE '%REFUSE%'
              OR UPPER(TRIM(CAST(vehicle_type_code1 AS STRING))) LIKE '%WASTE TR%'
              OR UPPER(TRIM(CAST(vehicle_type_code1 AS STRING))) IN ('SANAT','SANTI','SANMEN COU','SANIT','Garbage or Refuse',
                 'sanitaion','sanitaton','santiation','santa','Solid wast')
                THEN 'Sanitation/Garbage'

            WHEN UPPER(TRIM(CAST(vehicle_type_code1 AS STRING))) LIKE '%TOW TRUCK%'
              OR UPPER(TRIM(CAST(vehicle_type_code1 AS STRING))) LIKE '%TOWTRUCK%'
              OR UPPER(TRIM(CAST(vehicle_type_code1 AS STRING))) LIKE '%TOW-TRUCK%'
              OR UPPER(TRIM(CAST(vehicle_type_code1 AS STRING))) LIKE '%WRECKER%'
              OR UPPER(TRIM(CAST(vehicle_type_code1 AS STRING))) IN ('TOW T','TOWTR','TOW R','TOW TRICK','TOWE','TOWIN','TOWMA',
                 'Tow Truck / Wrecker','Tow t','Tow-t','PICKUP TOW','PICKUP-TOW','X TOW','G TOW','E TOW')
                THEN 'Tow Truck'

            WHEN UPPER(TRIM(CAST(vehicle_type_code1 AS STRING))) LIKE '%FOOD TRUCK%'
              OR UPPER(TRIM(CAST(vehicle_type_code1 AS STRING))) LIKE '%FOOD CART%'
              OR UPPER(TRIM(CAST(vehicle_type_code1 AS STRING))) LIKE '%FOOD TRAIL%'
              OR UPPER(TRIM(CAST(vehicle_type_code1 AS STRING))) IN ('FOOD','FOOD VENDE','FOOD DELIV','HOTDO','LUNCH WAGON','VENDOR CHA','VENDOR FOO','Mobile foo','Small Food')
                THEN 'Food Truck/Cart'

            WHEN UPPER(TRIM(CAST(vehicle_type_code1 AS STRING))) LIKE '%SPRINTER%'
              OR UPPER(TRIM(CAST(vehicle_type_code1 AS STRING))) LIKE '%ECONOLINE%'
              OR UPPER(TRIM(CAST(vehicle_type_code1 AS STRING))) LIKE '%MINIVAN%'
              OR UPPER(TRIM(CAST(vehicle_type_code1 AS STRING))) LIKE '%MINI VAN%'
              OR UPPER(TRIM(CAST(vehicle_type_code1 AS STRING))) LIKE '%CARGO VAN%'
              OR UPPER(TRIM(CAST(vehicle_type_code1 AS STRING))) LIKE '%TRANSIT VA%'
              OR UPPER(TRIM(CAST(vehicle_type_code1 AS STRING))) IN ('VAN','VAM','VANT','VANG','VAN`','VAV','VANET','VAN/T',
                 'VAN T','VAN C','VAN W','VAN A','VAN/B','VAN/TRUCK','VAN TRUCK',
                 'PASS VAN','COM VAN','COMM VAN','CARGO VAN','CHEVY VAN','FORD VAN','GMC VAN',
                 'PANEL VAN','SAVANA VAN','SAVANA','SPRIN','SPR','PROMASTER','ECONO',
                 'ECOLINE VA','ECONOLINE','CHEVY EXPR','MINIV','MINI VAHN',
                 'Van','Van T','Van truck','Van/Truck','Vanette','Cargo Van','Cargo van')
                THEN 'Van/Minivan'

            WHEN UPPER(TRIM(CAST(vehicle_type_code1 AS STRING))) LIKE '%SUV%'
              OR UPPER(TRIM(CAST(vehicle_type_code1 AS STRING))) LIKE '%SUBURBAN%'
              OR UPPER(TRIM(CAST(vehicle_type_code1 AS STRING))) LIKE '%SPORT UTIL%'
              OR UPPER(TRIM(CAST(vehicle_type_code1 AS STRING))) LIKE '%STATION WAG%'
              OR UPPER(TRIM(CAST(vehicle_type_code1 AS STRING))) IN ('SW','SW/SUV','SW/VAN','SPORT UTILITY / STATION WAGON',
                 'SURBURBAN','SUBN','SUBUR','SUBR','SYBN','SBN','WUBN','Station Wagon/Sport Utility Vehicle',
                 'Subn','Subur','Surburban','Suv','SUDAN','SUDN','HIGHL','SEDONA','SIERRA','SENIORCARE')
                THEN 'SUV/Station Wagon'

            WHEN UPPER(TRIM(CAST(vehicle_type_code1 AS STRING))) LIKE '%MOTORCYCLE%'
              OR UPPER(TRIM(CAST(vehicle_type_code1 AS STRING))) LIKE '%MOTORBIKE%'
              OR UPPER(TRIM(CAST(vehicle_type_code1 AS STRING))) IN ('MC','MCY','MCR','MCY B','MOT','MNI-MOTORC',
                 'MINICYCLE','MINIBIKE','MOTOR','ELE MOTORC','ELEC. UNIC','MOTOR UNIC',
                 'Motorbike','Motorcycle','Motorscooter','MOTORSCOOT','MOTO-SCOOT')
                THEN 'Motorcycle'

            WHEN UPPER(TRIM(CAST(vehicle_type_code1 AS STRING))) LIKE '%MOPED%'
              OR UPPER(TRIM(CAST(vehicle_type_code1 AS STRING))) LIKE '%MOPAD%'
              OR UPPER(TRIM(CAST(vehicle_type_code1 AS STRING))) IN ('MOPD','MOPET','MOPPED','MOPEN','MOPER','MOPOED',
                 'MO PED','MO-PED','MO PE','MOOPER','MOP','GAS MO-PED','GAS MOPED',
                 'MOped','Moped','Moped bike','Moped clas','Moped elec','Mopen','Moper','Mopoed','Mopped')
                THEN 'Moped'

            WHEN UPPER(TRIM(CAST(vehicle_type_code1 AS STRING))) LIKE '%E-BIKE%'
              OR UPPER(TRIM(CAST(vehicle_type_code1 AS STRING))) LIKE '%E BIKE%'
              OR UPPER(TRIM(CAST(vehicle_type_code1 AS STRING))) LIKE '%EBIKE%'
              OR UPPER(TRIM(CAST(vehicle_type_code1 AS STRING))) LIKE '%ELECTRIC BIKE%'
              OR UPPER(TRIM(CAST(vehicle_type_code1 AS STRING))) LIKE '%ELECTRIC B%'
              OR UPPER(TRIM(CAST(vehicle_type_code1 AS STRING))) IN ('E BIK','E-BIK','E/BIK','ECOM','E COM',
                 'UNI E-BIKE','E- BI','E- MOTOR B','E1','Ebike','ebike','e bik','e bike','e-bik','e-bike',
                 'E BIKE NO PLATE','E-BIKE NO','ELECTRIC M','ELEC','ELECT')
                THEN 'E-Bike'

            WHEN UPPER(TRIM(CAST(vehicle_type_code1 AS STRING))) LIKE '%E-SCOOTER%'
              OR UPPER(TRIM(CAST(vehicle_type_code1 AS STRING))) LIKE '%E SCOOTER%'
              OR UPPER(TRIM(CAST(vehicle_type_code1 AS STRING))) LIKE '%ESCOOTER%'
              OR UPPER(TRIM(CAST(vehicle_type_code1 AS STRING))) LIKE '%REVEL%'
              OR UPPER(TRIM(CAST(vehicle_type_code1 AS STRING))) LIKE '%LIME SCOOT%'
              OR UPPER(TRIM(CAST(vehicle_type_code1 AS STRING))) LIKE '%NINEBOT%'
              OR UPPER(TRIM(CAST(vehicle_type_code1 AS STRING))) IN ('E SCO','E-SCO','E- SCOOTER','ESCOO',
                 'MOTOR SCOO','MOTOR SKAT','MOTORIZED','MOTORIZEDS',
                 'E REVEL SCO','SPARK150 S','BEYOND SCO','RIDE ON SC',
                 'e sco','e scooter','e-scooter','eScoo','escooter','Escooter')
                THEN 'E-Scooter'

            WHEN UPPER(TRIM(CAST(vehicle_type_code1 AS STRING))) LIKE '%SCOOTER%'
              OR UPPER(TRIM(CAST(vehicle_type_code1 AS STRING))) IN ('SCL','SCOM','SCOOT','SCOO','GAS SCOOTE','GAS S',
                 'GAS PWR SC','VESPA','SCOOTOR','SCOTTER','SCOMM','GAS SCOOTER (G',
                 'SEATED SCO','STAND UP S','STANDUP SC','STANDING S','PUSH SCOOT',
                 'KICK SCOOT','RAZOR SCOO','MANUAL SCO','BLACK SCOO','RED SCOOTE',
                 'Scooter','Scoot','scoot','scooter','Kick scoot','Push scoot','Razor scoo',
                 'Seated sco','Stand Up S','Stand up s','Stand-up S','Standing S','Standing s')
                THEN 'Scooter (Gas)'

            WHEN UPPER(TRIM(CAST(vehicle_type_code1 AS STRING))) LIKE '%BICYCLE%'
              OR UPPER(TRIM(CAST(vehicle_type_code1 AS STRING))) LIKE '%BICYC%'
              OR UPPER(TRIM(CAST(vehicle_type_code1 AS STRING))) IN ('BIKE','CITIBIKE','PEDAL BIKE','GAS BICYCL',
                 'GAS BIKE','Bicycle','Bicyc','Bike','Citi bike','Gas bicycl','Gas bike','bicycle','bike')
                THEN 'Bicycle'

            WHEN UPPER(TRIM(CAST(vehicle_type_code1 AS STRING))) LIKE '%DIRT BIKE%'
              OR UPPER(TRIM(CAST(vehicle_type_code1 AS STRING))) LIKE '%DIRTBIKE%'
              OR UPPER(TRIM(CAST(vehicle_type_code1 AS STRING))) IN ('DIRT','DIRTB','DIRT-','Dart bike','Dirt Bike','Dirt bike','dirtbike','dirt bike')
                THEN 'Dirt Bike'

            WHEN UPPER(TRIM(CAST(vehicle_type_code1 AS STRING))) LIKE '%SKATEBOARD%'
              OR UPPER(TRIM(CAST(vehicle_type_code1 AS STRING))) LIKE '%HOVERBOARD%'
              OR UPPER(TRIM(CAST(vehicle_type_code1 AS STRING))) LIKE '%E-SKATEBO%'
              OR UPPER(TRIM(CAST(vehicle_type_code1 AS STRING))) LIKE '%E SKATEBOA%'
              OR UPPER(TRIM(CAST(vehicle_type_code1 AS STRING))) IN ('SKATE','ROLLERBLAD','IN LINE SK','SKATBOARD',
                 'E SKATEBOA','E-SKATEBOA','E-SKA','MOTOR SKAT','EvolveSkat',
                 'Skate','Skate boar','Skateboard','skate','skateboard','e skate bo','e-skateboa')
                THEN 'Skateboard/Hoverboard'

            WHEN UPPER(TRIM(CAST(vehicle_type_code1 AS STRING))) LIKE '%WHEELCHAIR%'
              OR UPPER(TRIM(CAST(vehicle_type_code1 AS STRING))) LIKE '%ACCESS-A-R%'
              OR UPPER(TRIM(CAST(vehicle_type_code1 AS STRING))) LIKE '%ACCESS A R%'
              OR UPPER(TRIM(CAST(vehicle_type_code1 AS STRING))) LIKE '%MOBILITY%'
              OR UPPER(TRIM(CAST(vehicle_type_code1 AS STRING))) LIKE '%ACCES%'
              OR UPPER(TRIM(CAST(vehicle_type_code1 AS STRING))) IN ('WC','WHEEL','E Wheelcha','APPOR','APPORTIONE','APORT',
                 'ACCESS-A-','ACCESS-ARI','ACCEE','ACCESS RID',
                 'Acces','Access A R','Access a R','Access-A-R','Apportione',
                 'Handicap S','Motor whee','Mobility S','MOBILTY SC','MOBILITY S')
                THEN 'Wheelchair/Mobility'

            WHEN UPPER(TRIM(CAST(vehicle_type_code1 AS STRING))) LIKE '%BACKHOE%'
              OR UPPER(TRIM(CAST(vehicle_type_code1 AS STRING))) LIKE '%EXCAVAT%'
              OR UPPER(TRIM(CAST(vehicle_type_code1 AS STRING))) LIKE '%ESCAVAT%'
              OR UPPER(TRIM(CAST(vehicle_type_code1 AS STRING))) LIKE '%BULLDOZ%'
              OR UPPER(TRIM(CAST(vehicle_type_code1 AS STRING))) LIKE '%FORKLIFT%'
              OR UPPER(TRIM(CAST(vehicle_type_code1 AS STRING))) LIKE '%FORK LIFT%'
              OR UPPER(TRIM(CAST(vehicle_type_code1 AS STRING))) LIKE '%BOBCAT%'
              OR UPPER(TRIM(CAST(vehicle_type_code1 AS STRING))) LIKE '%CRANE%'
              OR UPPER(TRIM(CAST(vehicle_type_code1 AS STRING))) LIKE '%PAYLOAD%'
              OR UPPER(TRIM(CAST(vehicle_type_code1 AS STRING))) LIKE '%SKID LOAD%'
              OR UPPER(TRIM(CAST(vehicle_type_code1 AS STRING))) LIKE '%SKID STEER%'
              OR UPPER(TRIM(CAST(vehicle_type_code1 AS STRING))) LIKE '%FRONT END%'
              OR UPPER(TRIM(CAST(vehicle_type_code1 AS STRING))) LIKE '%FRONT LOAD%'
              OR UPPER(TRIM(CAST(vehicle_type_code1 AS STRING))) LIKE '%BOOM LIFT%'
              OR UPPER(TRIM(CAST(vehicle_type_code1 AS STRING))) LIKE '%CATERPILLA%'
              OR UPPER(TRIM(CAST(vehicle_type_code1 AS STRING))) LIKE '%KOMATSU%'
              OR UPPER(TRIM(CAST(vehicle_type_code1 AS STRING))) IN ('BACK HOE','BACKH','BKHOE','HOE-L','LOADE',
                 'BUCKE','BUDGE','BULDOZER','BULL DOZER','BULLD','FORK','FORK-','FORKL',
                 'CAT','CAT 4','CATER','CATIP','CAT.','CASE','COMPACT LO','SKID','SKID-',
                 'SKIDSTEERL','LULL','FOGLIT','FOLK LIFT','HI LO','HI-LO','HILOW',
                 'Backhoe','Backh','Bobcat','Boom','Boom Lift','Bucke','Bucket Tru','Bucket tru',
                 'Bulldozer','Bull dozer','Cater','Caterpilla','Comp skid','Excav','Excavator',
                 'Escavator','Fork','Fork Lift','Fork lift','Forkl','Forklift','Front End',
                 'Front load','Front-Load','Hyster For','Liebh','Lift','Loade','Paylo','Skid','Skid steer',
                 'Swingloade','Telehandle','back ho','backh','backhoe','bobca','boom','bucke',
                 'bulld','cat','cate','forklift','front','hi-lo','hilow','lull','paylo','skid')
                THEN 'Construction Equipment'

            WHEN UPPER(TRIM(CAST(vehicle_type_code1 AS STRING))) LIKE '%SNOW PLOW%'
              OR UPPER(TRIM(CAST(vehicle_type_code1 AS STRING))) LIKE '%SNOWPLOW%'
              OR UPPER(TRIM(CAST(vehicle_type_code1 AS STRING))) LIKE '%STREET SWE%'
              OR UPPER(TRIM(CAST(vehicle_type_code1 AS STRING))) LIKE '%ROAD SWEEP%'
              OR UPPER(TRIM(CAST(vehicle_type_code1 AS STRING))) LIKE '%SWEEPER%'
              OR UPPER(TRIM(CAST(vehicle_type_code1 AS STRING))) IN ('PLOW','PLOW TRUCK','BROOM','SALT','SALTSPREAD',
                 'ROAD','ROADS','STREE','STREET CLE','STREET SWE','SWEEP','SWEPE','SWT',
                 'DSNY SWEEP','ROAD SWEEP','RD BLDNG M','Plow  truc','Plow truck','Road Sweep',
                 'Road sweep','Street Cle','Street Swe','Street swe','Sweep','Sweeper','dsny sweep',
                 'road sweep','salt','street cle','street swe','sweep','sweeper')
                THEN 'Plow/Sweeper'

            WHEN UPPER(TRIM(CAST(vehicle_type_code1 AS STRING))) LIKE '%TANKER%'
              OR UPPER(TRIM(CAST(vehicle_type_code1 AS STRING))) LIKE '%CEMENT MIX%'
              OR UPPER(TRIM(CAST(vehicle_type_code1 AS STRING))) LIKE '%CONCRETE M%'
              OR UPPER(TRIM(CAST(vehicle_type_code1 AS STRING))) IN ('TANK','TANK TRUCK','TANK WH','TANKE','OIL T',
                 'OIL TANKER','CONCR','CMIX','CMIXER','CEMENT TRU','CEMEN',
                 'Tank','Tank truck','Tanker','Oil Tanker','Cement Tru','Cement tru',
                 'Concrete Mixer','cemen','concr','tank')
                THEN 'Tank/Cement Truck'

            WHEN UPPER(TRIM(CAST(vehicle_type_code1 AS STRING))) LIKE '%GOLF CART%'
              OR UPPER(TRIM(CAST(vehicle_type_code1 AS STRING))) LIKE '%GOLF CAR%'
              OR UPPER(TRIM(CAST(vehicle_type_code1 AS STRING))) LIKE '%GOLFCART%'
              OR UPPER(TRIM(CAST(vehicle_type_code1 AS STRING))) LIKE '%GATOR%'
              OR UPPER(TRIM(CAST(vehicle_type_code1 AS STRING))) IN ('ATV','UTV','QUAD','GOLF','GO KART','GOLF KART',
                 'All-Terrain Vehicle','Gator','Gator 4x4','Golf','Golf Cart','Golf cart',
                 'Go kart','Quadricycl','atv p','gokar','golf','golf cart','gator','utv bobcat')
                THEN 'Golf Cart/ATV'

            WHEN UPPER(TRIM(CAST(vehicle_type_code1 AS STRING))) LIKE '%MOTOR HOME%'
              OR UPPER(TRIM(CAST(vehicle_type_code1 AS STRING))) LIKE '%MOTORHOME%'
              OR UPPER(TRIM(CAST(vehicle_type_code1 AS STRING))) LIKE '%WINNEBA%'
              OR UPPER(TRIM(CAST(vehicle_type_code1 AS STRING))) LIKE '%CAMPER%'
              OR UPPER(TRIM(CAST(vehicle_type_code1 AS STRING))) IN ('RV','R/V','MTR H','RV/VAN','RV/Tr','RV motorho',
                 'MOTORIZED HOME','Motorized Home','Rec Vehicl','winne','Motorhome','motorhome')
                THEN 'RV/Motorhome'

            WHEN UPPER(TRIM(CAST(vehicle_type_code1 AS STRING))) LIKE '%HORSE%'
              OR UPPER(TRIM(CAST(vehicle_type_code1 AS STRING))) IN ('HRSE','HOSRE','HOSRE DRAW','HURSE',
                 'Horse','Horse Carr','Horse Trai','Horse carr','Horse trai','Hrse','horse','hrse')
                THEN 'Horse Carriage'

            WHEN UPPER(TRIM(CAST(vehicle_type_code1 AS STRING))) LIKE '%NYPD%'
              OR UPPER(TRIM(CAST(vehicle_type_code1 AS STRING))) LIKE '%POLICE%'
              OR UPPER(TRIM(CAST(vehicle_type_code1 AS STRING))) IN ('RMP','R.M.P.','ESU','ESU T','ESU REP','ESU RESCUE',
                 'MARKED RMP','MARKED VAN','F550 ESU R','NYPD RMP','NYPD ESU T',
                 'Rmp','rmp','Nypd','nypd','police van','police veh','Polic','polic')
                THEN 'Police Vehicle'

            WHEN UPPER(TRIM(CAST(vehicle_type_code1 AS STRING))) IN (
                    'SEDAN','PASSENGER','PASSENGER VEHICLE','PASS','COUPE',
                    '2 DR','2DR','4 DOOR','4DR','4 DR SEDAN','2 DR SEDAN',
                    '4D','4DS','4SEDN','4door','4dsd','2 DOO','2 DR','2 doo',
                    'BMW','DODGE','DODGE RAM','RAM','CHEVY','CHEVROLET','CHEVR',
                    'GMC','NISSAN','NISSA','TOYOTA','TOYOT','MERCEDES',
                    'VOLVO','ACUR','ASTRO','SONATA','SIERRA','RIDGELINE',
                    'JEEP','AUDI','HYUND','IMPAL','FORD','CHEV','CHVEY',
                    'SMART','SMART CAR','FUSION','DODGE','RAM PRM','RAM COMM.',
                    'HERTZ RAM','HONDA HRV','MINI','ARIEL','ARCIMOTO',
                    'Dodge','Dodge ram','Jeep','Ram','Ram Promas','Smart',
                    'Chevr','Chevy','Ford','Gmc pick u','Gmc savann','Nissan',
                    'Supercab','Ridgeline','ford','chevy','dodge','toyota','nissan','bmw','jeep','volvo'
                )
              OR UPPER(TRIM(CAST(vehicle_type_code1 AS STRING))) LIKE '%PASSENGER%'
              OR UPPER(TRIM(CAST(vehicle_type_code1 AS STRING))) LIKE '%CHEVROLET%'
              OR UPPER(TRIM(CAST(vehicle_type_code1 AS STRING))) LIKE '%DODGE%'
              OR UPPER(TRIM(CAST(vehicle_type_code1 AS STRING))) LIKE '%TOYOTA%'
              OR UPPER(TRIM(CAST(vehicle_type_code1 AS STRING))) LIKE '%NISSAN%'
                THEN 'Passenger Vehicle'

            WHEN UPPER(TRIM(CAST(vehicle_type_code1 AS STRING))) IN (
                    'UNKNOWN','UNKNOW','UNKNO','UNKNW','UNKOWN','UNKWN','UNKWOWN',
                    'UNK','UNKN','UK','UKN','UKNOWN','UNNKO','UNNOWN','UNKNW','UNKOW',
                    'UNKOWM','UNKOWN','UNKWN','UKNOWN','UNKNO','UNKNW','UNKN',
                    'N/A','NA','N/a','NONE','NULL','0','00','000','0000','00000',
                    '00000','-','.','','?','A','B','C','D','E3','G1','H1','J1','L1',
                    'None','none','na','n/a','unk','unkn','unkno','unknown','unkow','unkown',
                    'UK','UKN','UKNOWN','UNK/L','UNL','UNNKO','UNNOWN',
                    '1','2','4','5','7','197209','2000','2003','263','787',
                    '9999','99999','0','00','000','13','17','430','985','994','997','999',
                    'NTTRL','YNK','YPS','-','.',',','omm'
                )
                THEN 'Unknown'
            WHEN vehicle_type_code1 IS NULL THEN NULL
            ELSE 'Other'
        END AS vehicle_type_1,

        CASE
            WHEN UPPER(TRIM(CAST(vehicle_type_code2 AS STRING))) LIKE '%AMBULAN%'
              OR UPPER(TRIM(CAST(vehicle_type_code2 AS STRING))) LIKE '%AMBUL%'
              OR UPPER(TRIM(CAST(vehicle_type_code2 AS STRING))) IN ('AMB','AMBU','AMBUL','EAMB','E AMB','G AMB','NS AM','X AMB',
                 'EMS','EMS AMBULA','EMS AMBULE','EMT','EMT AMBULA','FDNY EMT',
                 'NYS AMBULA','REG.AMBULA','PRIV AMBUL','GEN  AMBUL','FORD AMBUL',
                 'FD AMBULAN','EMBULANCE','EMERGANCY','EMERGENCY','A bulance',
                 'abulance','almbulance','amdu','amulance','anbul','AMUBL','AMUBULANCE')
                THEN 'Ambulance'

            WHEN UPPER(TRIM(CAST(vehicle_type_code2 AS STRING))) LIKE '%FDNY%'
              OR UPPER(TRIM(CAST(vehicle_type_code2 AS STRING))) LIKE '%FIRETRUCK%'
              OR UPPER(TRIM(CAST(vehicle_type_code2 AS STRING))) LIKE '%FIRE TRUCK%'
              OR UPPER(TRIM(CAST(vehicle_type_code2 AS STRING))) LIKE '%FIRE APPAR%'
              OR UPPER(TRIM(CAST(vehicle_type_code2 AS STRING))) LIKE '%FIRE ENG%'
              OR UPPER(TRIM(CAST(vehicle_type_code2 AS STRING))) LIKE '%FIRE DEPT%'
              OR UPPER(TRIM(CAST(vehicle_type_code2 AS STRING))) LIKE '%FIRE LADD%'
              OR UPPER(TRIM(CAST(vehicle_type_code2 AS STRING))) LIKE '%FIRET%'
              OR UPPER(TRIM(CAST(vehicle_type_code2 AS STRING))) LIKE '%FD TR%'
              OR UPPER(TRIM(CAST(vehicle_type_code2 AS STRING))) LIKE '%FD EN%'
              OR UPPER(TRIM(CAST(vehicle_type_code2 AS STRING))) LIKE '%FD LA%'
              OR UPPER(TRIM(CAST(vehicle_type_code2 AS STRING))) IN ('FIRE','FIRE RUCK','FIRER','FIRTRUCK','FIRETURCK','FNDY EMS','FDNYLadder','FDNYTRUCKF')
                THEN 'Fire Apparatus'

            WHEN UPPER(TRIM(CAST(vehicle_type_code2 AS STRING))) LIKE '%SCHOOL BUS%'
              OR UPPER(TRIM(CAST(vehicle_type_code2 AS STRING))) LIKE '%SCHOOLBUS%'
              OR UPPER(TRIM(CAST(vehicle_type_code2 AS STRING))) LIKE '%SCHOOL VAN%'
              OR UPPER(TRIM(CAST(vehicle_type_code2 AS STRING))) IN ('YELLOW BUS','YELLOWBUS','YW SCHOOL','SMYELLSCHO',
                 'SHORT SCHO','MINI SCHOO','SM YW','YLL P','SHCOO','SCHOO','SCHOO LBUS',
                 'SCHOOL  BU','Yellow bus','Yellow sch','Small Bus','Small scho','Short Bus')
                THEN 'School Bus'

            WHEN UPPER(TRIM(CAST(vehicle_type_code2 AS STRING))) LIKE '%MTA BUS%'
              OR UPPER(TRIM(CAST(vehicle_type_code2 AS STRING))) LIKE '%CITY BUS%'
              OR UPPER(TRIM(CAST(vehicle_type_code2 AS STRING))) LIKE '%TRANSIT%'
              OR UPPER(TRIM(CAST(vehicle_type_code2 AS STRING))) LIKE '%OMNIBUS%'
              OR UPPER(TRIM(CAST(vehicle_type_code2 AS STRING))) IN ('BUS','BUSS','TOUR BUS','SHUTTLE BU','MINI BUS',
                 'COACH','NICE BUS','BLU BUS','BUS M','BUs','ORION','NEW FLYER','LIVERY BUS','Livery Omn','Livery Bus')
                THEN 'Bus'

            WHEN UPPER(TRIM(CAST(vehicle_type_code2 AS STRING))) LIKE '%TAXI%'
              OR UPPER(TRIM(CAST(vehicle_type_code2 AS STRING))) LIKE '%YELLOW CAB%'
              OR UPPER(TRIM(CAST(vehicle_type_code2 AS STRING))) IN ('YELLO','DOLLAR VAN','PETIT CAB','Yellow Cab','Yellow cab')
                THEN 'Taxi'

            WHEN UPPER(TRIM(CAST(vehicle_type_code2 AS STRING))) LIKE '%LIVERY%'
              OR UPPER(TRIM(CAST(vehicle_type_code2 AS STRING))) LIKE '%MEDALLION%'
              OR UPPER(TRIM(CAST(vehicle_type_code2 AS STRING))) LIKE '%TLC%'
                THEN 'Livery/TLC'

            WHEN UPPER(TRIM(CAST(vehicle_type_code2 AS STRING))) LIKE '%LIMO%'
                THEN 'Limousine'

            WHEN UPPER(TRIM(CAST(vehicle_type_code2 AS STRING))) LIKE '%USPS%'
              OR UPPER(TRIM(CAST(vehicle_type_code2 AS STRING))) LIKE '%US POSTAL%'
              OR UPPER(TRIM(CAST(vehicle_type_code2 AS STRING))) LIKE '%US MAIL%'
              OR UPPER(TRIM(CAST(vehicle_type_code2 AS STRING))) LIKE '%POSTAL%'
              OR UPPER(TRIM(CAST(vehicle_type_code2 AS STRING))) LIKE '%MAIL TRUCK%'
              OR UPPER(TRIM(CAST(vehicle_type_code2 AS STRING))) LIKE '%MAILTRUCK%'
              OR UPPER(TRIM(CAST(vehicle_type_code2 AS STRING))) IN ('LLV','LLV MAIL T','U.S. POSTA','U.S.P','US PO','US Po')
                THEN 'Postal/Mail'

            WHEN UPPER(TRIM(CAST(vehicle_type_code2 AS STRING))) LIKE '%FEDEX%'
              OR UPPER(TRIM(CAST(vehicle_type_code2 AS STRING))) LIKE '%FED EX%'
              OR UPPER(TRIM(CAST(vehicle_type_code2 AS STRING))) LIKE '%AMAZON%'
              OR UPPER(TRIM(CAST(vehicle_type_code2 AS STRING))) LIKE '%DHL%'
              OR UPPER(TRIM(CAST(vehicle_type_code2 AS STRING))) LIKE '%DELIVERY%'
              OR UPPER(TRIM(CAST(vehicle_type_code2 AS STRING))) LIKE '%DELIV%'
              OR UPPER(TRIM(CAST(vehicle_type_code2 AS STRING))) LIKE '%COURIER%'
              OR UPPER(TRIM(CAST(vehicle_type_code2 AS STRING))) IN ('UPS','UPS T','UPS VAN','UPS M','DLEV','DLVR','DELV','DELVR','DEL','DEL T')
                THEN 'Delivery Vehicle'

            WHEN UPPER(TRIM(CAST(vehicle_type_code2 AS STRING))) LIKE '%U-HAUL%'
              OR UPPER(TRIM(CAST(vehicle_type_code2 AS STRING))) LIKE '%UHAUL%'
              OR UPPER(TRIM(CAST(vehicle_type_code2 AS STRING))) LIKE '%U HAUL%'
              OR UPPER(TRIM(CAST(vehicle_type_code2 AS STRING))) LIKE '%UHUAL%'
              OR UPPER(TRIM(CAST(vehicle_type_code2 AS STRING))) IN ('RYDER','PENSKE BOX','U-TRU','UHAL','UHAL TRUCK')
                THEN 'Rental Truck'

            WHEN UPPER(TRIM(CAST(vehicle_type_code2 AS STRING))) LIKE '%PICKUP%'
              OR UPPER(TRIM(CAST(vehicle_type_code2 AS STRING))) LIKE '%PICK UP%'
              OR UPPER(TRIM(CAST(vehicle_type_code2 AS STRING))) LIKE '%PICK-UP%'
              OR UPPER(TRIM(CAST(vehicle_type_code2 AS STRING))) IN ('PU','PICKU','PK','PKUP','P/U','PICK','PICK-')
                THEN 'Pickup Truck'

            WHEN UPPER(TRIM(CAST(vehicle_type_code2 AS STRING))) LIKE '%BOX TRUCK%'
              OR UPPER(TRIM(CAST(vehicle_type_code2 AS STRING))) LIKE '%BOXTRUCK%'
              OR UPPER(TRIM(CAST(vehicle_type_code2 AS STRING))) IN ('BOX T','BOXTR','BOX VAN','BOX CAR','BOX CARGO','BOX','BOX H','EMPTYBOX T')
                THEN 'Box Truck'

            WHEN UPPER(TRIM(CAST(vehicle_type_code2 AS STRING))) LIKE '%FLATBED%'
              OR UPPER(TRIM(CAST(vehicle_type_code2 AS STRING))) LIKE '%FLAT BED%'
              OR UPPER(TRIM(CAST(vehicle_type_code2 AS STRING))) IN ('FLAT','FLAT RACK','FLAT-','FLAT/','PLATF')
                THEN 'Flatbed Truck'

            WHEN UPPER(TRIM(CAST(vehicle_type_code2 AS STRING))) LIKE '%TRACTOR TR%'
              OR UPPER(TRIM(CAST(vehicle_type_code2 AS STRING))) LIKE '%SEMI TRUCK%'
              OR UPPER(TRIM(CAST(vehicle_type_code2 AS STRING))) LIKE '%SEMI-TRUCK%'
              OR UPPER(TRIM(CAST(vehicle_type_code2 AS STRING))) LIKE '%SEMI TRAIL%'
              OR UPPER(TRIM(CAST(vehicle_type_code2 AS STRING))) LIKE '%FREIGHTLIN%'
              OR UPPER(TRIM(CAST(vehicle_type_code2 AS STRING))) LIKE '%18 WHEEL%'
              OR UPPER(TRIM(CAST(vehicle_type_code2 AS STRING))) LIKE '%18WHEEL%'
              OR UPPER(TRIM(CAST(vehicle_type_code2 AS STRING))) IN ('SEMI','SEMI-','TRACTOR','MACK','KENWORTH T',
                 'FUSO TRUCK','18 WH','18 WHEELER','18 WEELER','18 WH','18 Wh',
                 'TRACTOR TRUCK DIESEL','TRACTOR TRUCK GASOLINE','MACK TRUCK','Mack Truck','Mack truck','Macktruck',
                 'FREIG','FRHT','FRT','FLTRL','LTRL','NTTRL','LCOM','LCOMM','SCOMM')
                THEN 'Tractor/Semi-Truck'

            WHEN UPPER(TRIM(CAST(vehicle_type_code2 AS STRING))) LIKE '%DUMP TRUCK%'
              OR UPPER(TRIM(CAST(vehicle_type_code2 AS STRING))) LIKE '%DUMP TR%'
              OR UPPER(TRIM(CAST(vehicle_type_code2 AS STRING))) IN ('DUMP','DUMPT','DUMPTRUCK','DUMP TRUK','DUMPS','DUMPSTER','DUMPSTER T','DUMPTRUCK')
                THEN 'Dump Truck'

            WHEN UPPER(TRIM(CAST(vehicle_type_code2 AS STRING))) LIKE '%SANITAT%'
              OR UPPER(TRIM(CAST(vehicle_type_code2 AS STRING))) LIKE '%DSNY%'
              OR UPPER(TRIM(CAST(vehicle_type_code2 AS STRING))) LIKE '%GARBAGE%'
              OR UPPER(TRIM(CAST(vehicle_type_code2 AS STRING))) LIKE '%REFUSE%'
              OR UPPER(TRIM(CAST(vehicle_type_code2 AS STRING))) LIKE '%WASTE TR%'
              OR UPPER(TRIM(CAST(vehicle_type_code2 AS STRING))) IN ('SANAT','SANTI','SANMEN COU','SANIT','Garbage or Refuse',
                 'sanitaion','sanitaton','santiation','santa','Solid wast')
                THEN 'Sanitation/Garbage'

            WHEN UPPER(TRIM(CAST(vehicle_type_code2 AS STRING))) LIKE '%TOW TRUCK%'
              OR UPPER(TRIM(CAST(vehicle_type_code2 AS STRING))) LIKE '%TOWTRUCK%'
              OR UPPER(TRIM(CAST(vehicle_type_code2 AS STRING))) LIKE '%TOW-TRUCK%'
              OR UPPER(TRIM(CAST(vehicle_type_code2 AS STRING))) LIKE '%WRECKER%'
              OR UPPER(TRIM(CAST(vehicle_type_code2 AS STRING))) IN ('TOW T','TOWTR','TOW R','TOW TRICK','TOWE','TOWIN','TOWMA',
                 'Tow Truck / Wrecker','Tow t','Tow-t','PICKUP TOW','PICKUP-TOW','X TOW','G TOW','E TOW')
                THEN 'Tow Truck'

            WHEN UPPER(TRIM(CAST(vehicle_type_code1 AS STRING))) LIKE '%FOOD TRUCK%'
              OR UPPER(TRIM(CAST(vehicle_type_code1 AS STRING))) LIKE '%FOOD CART%'
              OR UPPER(TRIM(CAST(vehicle_type_code1 AS STRING))) LIKE '%FOOD TRAIL%'
              OR UPPER(TRIM(CAST(vehicle_type_code1 AS STRING))) IN ('FOOD','FOOD VENDE','FOOD DELIV','HOTDO','LUNCH WAGON','VENDOR CHA','VENDOR FOO','Mobile foo','Small Food')
                THEN 'Food Truck/Cart'

            WHEN UPPER(TRIM(CAST(vehicle_type_code2 AS STRING))) LIKE '%SPRINTER%'
              OR UPPER(TRIM(CAST(vehicle_type_code2 AS STRING))) LIKE '%ECONOLINE%'
              OR UPPER(TRIM(CAST(vehicle_type_code2 AS STRING))) LIKE '%MINIVAN%'
              OR UPPER(TRIM(CAST(vehicle_type_code2 AS STRING))) LIKE '%MINI VAN%'
              OR UPPER(TRIM(CAST(vehicle_type_code2 AS STRING))) LIKE '%CARGO VAN%'
              OR UPPER(TRIM(CAST(vehicle_type_code2 AS STRING))) LIKE '%TRANSIT VA%'
              OR UPPER(TRIM(CAST(vehicle_type_code2 AS STRING))) IN ('VAN','VAM','VANT','VANG','VAN`','VAV','VANET','VAN/T',
                 'VAN T','VAN C','VAN W','VAN A','VAN/B','VAN/TRUCK','VAN TRUCK',
                 'PASS VAN','COM VAN','COMM VAN','CARGO VAN','CHEVY VAN','FORD VAN','GMC VAN',
                 'PANEL VAN','SAVANA VAN','SAVANA','SPRIN','SPR','PROMASTER','ECONO',
                 'ECOLINE VA','ECONOLINE','CHEVY EXPR','MINIV','MINI VAHN',
                 'Van','Van T','Van truck','Van/Truck','Vanette','Cargo Van','Cargo van')
                THEN 'Van/Minivan'

            WHEN UPPER(TRIM(CAST(vehicle_type_code2 AS STRING))) LIKE '%SUV%'
              OR UPPER(TRIM(CAST(vehicle_type_code2 AS STRING))) LIKE '%SUBURBAN%'
              OR UPPER(TRIM(CAST(vehicle_type_code2 AS STRING))) LIKE '%SPORT UTIL%'
              OR UPPER(TRIM(CAST(vehicle_type_code2 AS STRING))) LIKE '%STATION WAG%'
              OR UPPER(TRIM(CAST(vehicle_type_code2 AS STRING))) IN ('SW','SW/SUV','SW/VAN','SPORT UTILITY / STATION WAGON',
                 'SURBURBAN','SUBN','SUBUR','SUBR','SYBN','SBN','WUBN','Station Wagon/Sport Utility Vehicle',
                 'Subn','Subur','Surburban','Suv','SUDAN','SUDN','HIGHL','SEDONA','SIERRA','SENIORCARE')
                THEN 'SUV/Station Wagon'

            WHEN UPPER(TRIM(CAST(vehicle_type_code2 AS STRING))) LIKE '%MOTORCYCLE%'
              OR UPPER(TRIM(CAST(vehicle_type_code2 AS STRING))) LIKE '%MOTORBIKE%'
              OR UPPER(TRIM(CAST(vehicle_type_code2 AS STRING))) IN ('MC','MCY','MCR','MCY B','MOT','MNI-MOTORC',
                 'MINICYCLE','MINIBIKE','MOTOR','ELE MOTORC','ELEC. UNIC','MOTOR UNIC',
                 'Motorbike','Motorcycle','Motorscooter','MOTORSCOOT','MOTO-SCOOT')
                THEN 'Motorcycle'

            WHEN UPPER(TRIM(CAST(vehicle_type_code2 AS STRING))) LIKE '%MOPED%'
              OR UPPER(TRIM(CAST(vehicle_type_code2 AS STRING))) LIKE '%MOPAD%'
              OR UPPER(TRIM(CAST(vehicle_type_code2 AS STRING))) IN ('MOPD','MOPET','MOPPED','MOPEN','MOPER','MOPOED',
                 'MO PED','MO-PED','MO PE','MOOPER','MOP','GAS MO-PED','GAS MOPED',
                 'MOped','Moped','Moped bike','Moped clas','Moped elec','Mopen','Moper','Mopoed','Mopped')
                THEN 'Moped'

            WHEN UPPER(TRIM(CAST(vehicle_type_code2 AS STRING))) LIKE '%E-BIKE%'
              OR UPPER(TRIM(CAST(vehicle_type_code2 AS STRING))) LIKE '%E BIKE%'
              OR UPPER(TRIM(CAST(vehicle_type_code2 AS STRING))) LIKE '%EBIKE%'
              OR UPPER(TRIM(CAST(vehicle_type_code2 AS STRING))) LIKE '%ELECTRIC BIKE%'
              OR UPPER(TRIM(CAST(vehicle_type_code2 AS STRING))) LIKE '%ELECTRIC B%'
              OR UPPER(TRIM(CAST(vehicle_type_code2 AS STRING))) IN ('E BIK','E-BIK','E/BIK','ECOM','E COM',
                 'UNI E-BIKE','E- BI','E- MOTOR B','E1','Ebike','ebike','e bik','e bike','e-bik','e-bike',
                 'E BIKE NO PLATE','E-BIKE NO','ELECTRIC M','ELEC','ELECT')
                THEN 'E-Bike'

            WHEN UPPER(TRIM(CAST(vehicle_type_code2 AS STRING))) LIKE '%E-SCOOTER%'
              OR UPPER(TRIM(CAST(vehicle_type_code2 AS STRING))) LIKE '%E SCOOTER%'
              OR UPPER(TRIM(CAST(vehicle_type_code2 AS STRING))) LIKE '%ESCOOTER%'
              OR UPPER(TRIM(CAST(vehicle_type_code1 AS STRING))) LIKE '%REVEL%'
              OR UPPER(TRIM(CAST(vehicle_type_code2 AS STRING))) LIKE '%LIME SCOOT%'
              OR UPPER(TRIM(CAST(vehicle_type_code2 AS STRING))) LIKE '%NINEBOT%'
              OR UPPER(TRIM(CAST(vehicle_type_code2 AS STRING))) IN ('E SCO','E-SCO','E- SCOOTER','ESCOO',
                 'MOTOR SCOO','MOTOR SKAT','MOTORIZED','MOTORIZEDS',
                 'E REVEL SCO','SPARK150 S','BEYOND SCO','RIDE ON SC',
                 'e sco','e scooter','e-scooter','eScoo','escooter','Escooter')
                THEN 'E-Scooter'

            WHEN UPPER(TRIM(CAST(vehicle_type_code2 AS STRING))) LIKE '%SCOOTER%'
              OR UPPER(TRIM(CAST(vehicle_type_code2 AS STRING))) IN ('SCL','SCOM','SCOOT','SCOO','GAS SCOOTE','GAS S',
                 'GAS PWR SC','VESPA','SCOOTOR','SCOTTER','SCOMM','GAS SCOOTER (G',
                 'SEATED SCO','STAND UP S','STANDUP SC','STANDING S','PUSH SCOOT',
                 'KICK SCOOT','RAZOR SCOO','MANUAL SCO','BLACK SCOO','RED SCOOTE',
                 'Scooter','Scoot','scoot','scooter','Kick scoot','Push scoot','Razor scoo',
                 'Seated sco','Stand Up S','Stand up s','Stand-up S','Standing S','Standing s')
                THEN 'Scooter (Gas)'

            WHEN UPPER(TRIM(CAST(vehicle_type_code2 AS STRING))) LIKE '%BICYCLE%'
              OR UPPER(TRIM(CAST(vehicle_type_code2 AS STRING))) LIKE '%BICYC%'
              OR UPPER(TRIM(CAST(vehicle_type_code2 AS STRING))) IN ('BIKE','CITIBIKE','PEDAL BIKE','GAS BICYCL',
                 'GAS BIKE','Bicycle','Bicyc','Bike','Citi bike','Gas bicycl','Gas bike','bicycle','bike')
                THEN 'Bicycle'

            WHEN UPPER(TRIM(CAST(vehicle_type_code2 AS STRING))) LIKE '%DIRT BIKE%'
              OR UPPER(TRIM(CAST(vehicle_type_code2 AS STRING))) LIKE '%DIRTBIKE%'
              OR UPPER(TRIM(CAST(vehicle_type_code2 AS STRING))) IN ('DIRT','DIRTB','DIRT-','Dart bike','Dirt Bike','Dirt bike','dirtbike','dirt bike')
                THEN 'Dirt Bike'

            WHEN UPPER(TRIM(CAST(vehicle_type_code2 AS STRING))) LIKE '%SKATEBOARD%'
              OR UPPER(TRIM(CAST(vehicle_type_code2 AS STRING))) LIKE '%HOVERBOARD%'
              OR UPPER(TRIM(CAST(vehicle_type_code2 AS STRING))) LIKE '%E-SKATEBO%'
              OR UPPER(TRIM(CAST(vehicle_type_code2 AS STRING))) LIKE '%E SKATEBOA%'
              OR UPPER(TRIM(CAST(vehicle_type_code2 AS STRING))) IN ('SKATE','ROLLERBLAD','IN LINE SK','SKATBOARD',
                 'E SKATEBOA','E-SKATEBOA','E-SKA','MOTOR SKAT','EvolveSkat',
                 'Skate','Skate boar','Skateboard','skate','skateboard','e skate bo','e-skateboa')
                THEN 'Skateboard/Hoverboard'

            WHEN UPPER(TRIM(CAST(vehicle_type_code2 AS STRING))) LIKE '%WHEELCHAIR%'
              OR UPPER(TRIM(CAST(vehicle_type_code2 AS STRING))) LIKE '%ACCESS-A-R%'
              OR UPPER(TRIM(CAST(vehicle_type_code2 AS STRING))) LIKE '%ACCESS A R%'
              OR UPPER(TRIM(CAST(vehicle_type_code2 AS STRING))) LIKE '%MOBILITY%'
              OR UPPER(TRIM(CAST(vehicle_type_code2 AS STRING))) LIKE '%ACCES%'
              OR UPPER(TRIM(CAST(vehicle_type_code2 AS STRING))) IN ('WC','WHEEL','E Wheelcha','APPOR','APPORTIONE','APORT',
                 'ACCESS-A-','ACCESS-ARI','ACCEE','ACCESS RID',
                 'Acces','Access A R','Access a R','Access-A-R','Apportione',
                 'Handicap S','Motor whee','Mobility S','MOBILTY SC','MOBILITY S')
                THEN 'Wheelchair/Mobility'

            WHEN UPPER(TRIM(CAST(vehicle_type_code2 AS STRING))) LIKE '%BACKHOE%'
              OR UPPER(TRIM(CAST(vehicle_type_code2 AS STRING))) LIKE '%EXCAVAT%'
              OR UPPER(TRIM(CAST(vehicle_type_code2 AS STRING))) LIKE '%ESCAVAT%'
              OR UPPER(TRIM(CAST(vehicle_type_code2 AS STRING))) LIKE '%BULLDOZ%'
              OR UPPER(TRIM(CAST(vehicle_type_code2 AS STRING))) LIKE '%FORKLIFT%'
              OR UPPER(TRIM(CAST(vehicle_type_code2 AS STRING))) LIKE '%FORK LIFT%'
              OR UPPER(TRIM(CAST(vehicle_type_code2 AS STRING))) LIKE '%BOBCAT%'
              OR UPPER(TRIM(CAST(vehicle_type_code2 AS STRING))) LIKE '%CRANE%'
              OR UPPER(TRIM(CAST(vehicle_type_code2 AS STRING))) LIKE '%PAYLOAD%'
              OR UPPER(TRIM(CAST(vehicle_type_code2 AS STRING))) LIKE '%SKID LOAD%'
              OR UPPER(TRIM(CAST(vehicle_type_code2 AS STRING))) LIKE '%SKID STEER%'
              OR UPPER(TRIM(CAST(vehicle_type_code2 AS STRING))) LIKE '%FRONT END%'
              OR UPPER(TRIM(CAST(vehicle_type_code2 AS STRING))) LIKE '%FRONT LOAD%'
              OR UPPER(TRIM(CAST(vehicle_type_code2 AS STRING))) LIKE '%BOOM LIFT%'
              OR UPPER(TRIM(CAST(vehicle_type_code2 AS STRING))) LIKE '%CATERPILLA%'
              OR UPPER(TRIM(CAST(vehicle_type_code2 AS STRING))) LIKE '%KOMATSU%'
              OR UPPER(TRIM(CAST(vehicle_type_code2 AS STRING))) IN ('BACK HOE','BACKH','BKHOE','HOE-L','LOADE',
                 'BUCKE','BUDGE','BULDOZER','BULL DOZER','BULLD','FORK','FORK-','FORKL',
                 'CAT','CAT 4','CATER','CATIP','CAT.','CASE','COMPACT LO','SKID','SKID-',
                 'SKIDSTEERL','LULL','FOGLIT','FOLK LIFT','HI LO','HI-LO','HILOW',
                 'Backhoe','Backh','Bobcat','Boom','Boom Lift','Bucke','Bucket Tru','Bucket tru',
                 'Bulldozer','Bull dozer','Cater','Caterpilla','Comp skid','Excav','Excavator',
                 'Escavator','Fork','Fork Lift','Fork lift','Forkl','Forklift','Front End',
                 'Front load','Front-Load','Hyster For','Liebh','Lift','Loade','Paylo','Skid','Skid steer',
                 'Swingloade','Telehandle','back ho','backh','backhoe','bobca','boom','bucke',
                 'bulld','cat','cate','forklift','front','hi-lo','hilow','lull','paylo','skid')
                THEN 'Construction Equipment'

            WHEN UPPER(TRIM(CAST(vehicle_type_code2 AS STRING))) LIKE '%SNOW PLOW%'
              OR UPPER(TRIM(CAST(vehicle_type_code2 AS STRING))) LIKE '%SNOWPLOW%'
              OR UPPER(TRIM(CAST(vehicle_type_code2 AS STRING))) LIKE '%STREET SWE%'
              OR UPPER(TRIM(CAST(vehicle_type_code2 AS STRING))) LIKE '%ROAD SWEEP%'
              OR UPPER(TRIM(CAST(vehicle_type_code2 AS STRING))) LIKE '%SWEEPER%'
              OR UPPER(TRIM(CAST(vehicle_type_code2 AS STRING))) IN ('PLOW','PLOW TRUCK','BROOM','SALT','SALTSPREAD',
                 'ROAD','ROADS','STREE','STREET CLE','STREET SWE','SWEEP','SWEPE','SWT',
                 'DSNY SWEEP','ROAD SWEEP','RD BLDNG M','Plow  truc','Plow truck','Road Sweep',
                 'Road sweep','Street Cle','Street Swe','Street swe','Sweep','Sweeper','dsny sweep',
                 'road sweep','salt','street cle','street swe','sweep','sweeper')
                THEN 'Plow/Sweeper'

            WHEN UPPER(TRIM(CAST(vehicle_type_code2 AS STRING))) LIKE '%TANKER%'
              OR UPPER(TRIM(CAST(vehicle_type_code2 AS STRING))) LIKE '%CEMENT MIX%'
              OR UPPER(TRIM(CAST(vehicle_type_code2 AS STRING))) LIKE '%CONCRETE M%'
              OR UPPER(TRIM(CAST(vehicle_type_code2 AS STRING))) IN ('TANK','TANK TRUCK','TANK WH','TANKE','OIL T',
                 'OIL TANKER','CONCR','CMIX','CMIXER','CEMENT TRU','CEMEN',
                 'Tank','Tank truck','Tanker','Oil Tanker','Cement Tru','Cement tru',
                 'Concrete Mixer','cemen','concr','tank')
                THEN 'Tank/Cement Truck'

            WHEN UPPER(TRIM(CAST(vehicle_type_code2 AS STRING))) LIKE '%GOLF CART%'
              OR UPPER(TRIM(CAST(vehicle_type_code2 AS STRING))) LIKE '%GOLF CAR%'
              OR UPPER(TRIM(CAST(vehicle_type_code2 AS STRING))) LIKE '%GOLFCART%'
              OR UPPER(TRIM(CAST(vehicle_type_code2 AS STRING))) LIKE '%GATOR%'
              OR UPPER(TRIM(CAST(vehicle_type_code2 AS STRING))) IN ('ATV','UTV','QUAD','GOLF','GO KART','GOLF KART',
                 'All-Terrain Vehicle','Gator','Gator 4x4','Golf','Golf Cart','Golf cart',
                 'Go kart','Quadricycl','atv p','gokar','golf','golf cart','gator','utv bobcat')
                THEN 'Golf Cart/ATV'

            WHEN UPPER(TRIM(CAST(vehicle_type_code2 AS STRING))) LIKE '%MOTOR HOME%'
              OR UPPER(TRIM(CAST(vehicle_type_code2 AS STRING))) LIKE '%MOTORHOME%'
              OR UPPER(TRIM(CAST(vehicle_type_code2 AS STRING))) LIKE '%WINNEBA%'
              OR UPPER(TRIM(CAST(vehicle_type_code2 AS STRING))) LIKE '%CAMPER%'
              OR UPPER(TRIM(CAST(vehicle_type_code2 AS STRING))) IN ('RV','R/V','MTR H','RV/VAN','RV/Tr','RV motorho',
                 'MOTORIZED HOME','Motorized Home','Rec Vehicl','winne','Motorhome','motorhome')
                THEN 'RV/Motorhome'

            WHEN UPPER(TRIM(CAST(vehicle_type_code2 AS STRING))) LIKE '%HORSE%'
              OR UPPER(TRIM(CAST(vehicle_type_code2 AS STRING))) IN ('HRSE','HOSRE','HOSRE DRAW','HURSE',
                 'Horse','Horse Carr','Horse Trai','Horse carr','Horse trai','Hrse','horse','hrse')
                THEN 'Horse Carriage'

            WHEN UPPER(TRIM(CAST(vehicle_type_code2 AS STRING))) LIKE '%NYPD%'
              OR UPPER(TRIM(CAST(vehicle_type_code2 AS STRING))) LIKE '%POLICE%'
              OR UPPER(TRIM(CAST(vehicle_type_code2 AS STRING))) IN ('RMP','R.M.P.','ESU','ESU T','ESU REP','ESU RESCUE',
                 'MARKED RMP','MARKED VAN','F550 ESU R','NYPD RMP','NYPD ESU T',
                 'Rmp','rmp','Nypd','nypd','police van','police veh','Polic','polic')
                THEN 'Police Vehicle'

            WHEN UPPER(TRIM(CAST(vehicle_type_code2 AS STRING))) IN (
                    'SEDAN','PASSENGER','PASSENGER VEHICLE','PASS','COUPE',
                    '2 DR','2DR','4 DOOR','4DR','4 DR SEDAN','2 DR SEDAN',
                    '4D','4DS','4SEDN','4door','4dsd','2 DOO','2 DR','2 doo',
                    'BMW','DODGE','DODGE RAM','RAM','CHEVY','CHEVROLET','CHEVR',
                    'GMC','NISSAN','NISSA','TOYOTA','TOYOT','MERCEDES',
                    'VOLVO','ACUR','ASTRO','SONATA','SIERRA','RIDGELINE',
                    'JEEP','AUDI','HYUND','IMPAL','FORD','CHEV','CHVEY',
                    'SMART','SMART CAR','FUSION','DODGE','RAM PRM','RAM COMM.',
                    'HERTZ RAM','HONDA HRV','MINI','ARIEL','ARCIMOTO',
                    'Dodge','Dodge ram','Jeep','Ram','Ram Promas','Smart',
                    'Chevr','Chevy','Ford','Gmc pick u','Gmc savann','Nissan',
                    'Supercab','Ridgeline','ford','chevy','dodge','toyota','nissan','bmw','jeep','volvo'
                )
              OR UPPER(TRIM(CAST(vehicle_type_code2 AS STRING))) LIKE '%PASSENGER%'
              OR UPPER(TRIM(CAST(vehicle_type_code2 AS STRING))) LIKE '%CHEVROLET%'
              OR UPPER(TRIM(CAST(vehicle_type_code2 AS STRING))) LIKE '%DODGE%'
              OR UPPER(TRIM(CAST(vehicle_type_code2 AS STRING))) LIKE '%TOYOTA%'
              OR UPPER(TRIM(CAST(vehicle_type_code2 AS STRING))) LIKE '%NISSAN%'
                THEN 'Passenger Vehicle'

            WHEN UPPER(TRIM(CAST(vehicle_type_code2 AS STRING))) IN (
                    'UNKNOWN','UNKNOW','UNKNO','UNKNW','UNKOWN','UNKWN','UNKWOWN',
                    'UNK','UNKN','UK','UKN','UKNOWN','UNNKO','UNNOWN','UNKNW','UNKOW',
                    'UNKOWM','UNKOWN','UNKWN','UKNOWN','UNKNO','UNKNW','UNKN',
                    'N/A','NA','N/a','NONE','NULL','0','00','000','0000','00000',
                    '00000','-','.','','?','A','B','C','D','E3','G1','H1','J1','L1',
                    'None','none','na','n/a','unk','unkn','unkno','unknown','unkow','unkown',
                    'UK','UKN','UKNOWN','UNK/L','UNL','UNNKO','UNNOWN',
                    '1','2','4','5','7','197209','2000','2003','263','787',
                    '9999','99999','0','00','000','13','17','430','985','994','997','999',
                    'NTTRL','YNK','YPS','-','.',',','omm'
                )
                THEN 'Unknown'
            WHEN vehicle_type_code2 IS NULL THEN NULL
            ELSE 'Other'
        END AS vehicle_type_2,

        CASE
            WHEN UPPER(TRIM(CAST(vehicle_type_code_3 AS STRING))) LIKE '%AMBULAN%'
              OR UPPER(TRIM(CAST(vehicle_type_code_3 AS STRING))) LIKE '%AMBUL%'
              OR UPPER(TRIM(CAST(vehicle_type_code_3 AS STRING))) IN ('AMB','AMBU','AMBUL','EAMB','E AMB','G AMB','NS AM','X AMB',
                 'EMS','EMS AMBULA','EMS AMBULE','EMT','EMT AMBULA','FDNY EMT',
                 'NYS AMBULA','REG.AMBULA','PRIV AMBUL','GEN  AMBUL','FORD AMBUL',
                 'FD AMBULAN','EMBULANCE','EMERGANCY','EMERGENCY','A bulance',
                 'abulance','almbulance','amdu','amulance','anbul','AMUBL','AMUBULANCE')
                THEN 'Ambulance'

            WHEN UPPER(TRIM(CAST(vehicle_type_code_3 AS STRING))) LIKE '%FDNY%'
              OR UPPER(TRIM(CAST(vehicle_type_code_3 AS STRING))) LIKE '%FIRETRUCK%'
              OR UPPER(TRIM(CAST(vehicle_type_code_3 AS STRING))) LIKE '%FIRE TRUCK%'
              OR UPPER(TRIM(CAST(vehicle_type_code_3 AS STRING))) LIKE '%FIRE APPAR%'
              OR UPPER(TRIM(CAST(vehicle_type_code_3 AS STRING))) LIKE '%FIRE ENG%'
              OR UPPER(TRIM(CAST(vehicle_type_code_3 AS STRING))) LIKE '%FIRE DEPT%'
              OR UPPER(TRIM(CAST(vehicle_type_code_3 AS STRING))) LIKE '%FIRE LADD%'
              OR UPPER(TRIM(CAST(vehicle_type_code_3 AS STRING))) LIKE '%FIRET%'
              OR UPPER(TRIM(CAST(vehicle_type_code_3 AS STRING))) LIKE '%FD TR%'
              OR UPPER(TRIM(CAST(vehicle_type_code_3 AS STRING))) LIKE '%FD EN%'
              OR UPPER(TRIM(CAST(vehicle_type_code_3 AS STRING))) LIKE '%FD LA%'
              OR UPPER(TRIM(CAST(vehicle_type_code_3 AS STRING))) IN ('FIRE','FIRE RUCK','FIRER','FIRTRUCK','FIRETURCK','FNDY EMS','FDNYLadder','FDNYTRUCKF')
                THEN 'Fire Apparatus'

            WHEN UPPER(TRIM(CAST(vehicle_type_code_3 AS STRING))) LIKE '%SCHOOL BUS%'
              OR UPPER(TRIM(CAST(vehicle_type_code_3 AS STRING))) LIKE '%SCHOOLBUS%'
              OR UPPER(TRIM(CAST(vehicle_type_code_3 AS STRING))) LIKE '%SCHOOL VAN%'
              OR UPPER(TRIM(CAST(vehicle_type_code_3 AS STRING))) IN ('YELLOW BUS','YELLOWBUS','YW SCHOOL','SMYELLSCHO',
                 'SHORT SCHO','MINI SCHOO','SM YW','YLL P','SHCOO','SCHOO','SCHOO LBUS',
                 'SCHOOL  BU','Yellow bus','Yellow sch','Small Bus','Small scho','Short Bus')
                THEN 'School Bus'

            WHEN UPPER(TRIM(CAST(vehicle_type_code_3 AS STRING))) LIKE '%MTA BUS%'
              OR UPPER(TRIM(CAST(vehicle_type_code_3 AS STRING))) LIKE '%CITY BUS%'
              OR UPPER(TRIM(CAST(vehicle_type_code_3 AS STRING))) LIKE '%TRANSIT%'
              OR UPPER(TRIM(CAST(vehicle_type_code_3 AS STRING))) LIKE '%OMNIBUS%'
              OR UPPER(TRIM(CAST(vehicle_type_code_3 AS STRING))) IN ('BUS','BUSS','TOUR BUS','SHUTTLE BU','MINI BUS',
                 'COACH','NICE BUS','BLU BUS','BUS M','BUs','ORION','NEW FLYER','LIVERY BUS','Livery Omn','Livery Bus')
                THEN 'Bus'

            WHEN UPPER(TRIM(CAST(vehicle_type_code_3 AS STRING))) LIKE '%TAXI%'
              OR UPPER(TRIM(CAST(vehicle_type_code_3 AS STRING))) LIKE '%YELLOW CAB%'
              OR UPPER(TRIM(CAST(vehicle_type_code_3 AS STRING))) IN ('YELLO','DOLLAR VAN','PETIT CAB','Yellow Cab','Yellow cab')
                THEN 'Taxi'

            WHEN UPPER(TRIM(CAST(vehicle_type_code_3 AS STRING))) LIKE '%LIVERY%'
              OR UPPER(TRIM(CAST(vehicle_type_code_3 AS STRING))) LIKE '%MEDALLION%'
              OR UPPER(TRIM(CAST(vehicle_type_code_3 AS STRING))) LIKE '%TLC%'
                THEN 'Livery/TLC'

            WHEN UPPER(TRIM(CAST(vehicle_type_code_3 AS STRING))) LIKE '%LIMO%'
                THEN 'Limousine'

            WHEN UPPER(TRIM(CAST(vehicle_type_code_3 AS STRING))) LIKE '%USPS%'
              OR UPPER(TRIM(CAST(vehicle_type_code_3 AS STRING))) LIKE '%US POSTAL%'
              OR UPPER(TRIM(CAST(vehicle_type_code_3 AS STRING))) LIKE '%US MAIL%'
              OR UPPER(TRIM(CAST(vehicle_type_code_3 AS STRING))) LIKE '%POSTAL%'
              OR UPPER(TRIM(CAST(vehicle_type_code_3 AS STRING))) LIKE '%MAIL TRUCK%'
              OR UPPER(TRIM(CAST(vehicle_type_code_3 AS STRING))) LIKE '%MAILTRUCK%'
              OR UPPER(TRIM(CAST(vehicle_type_code_3 AS STRING))) IN ('LLV','LLV MAIL T','U.S. POSTA','U.S.P','US PO','US Po')
                THEN 'Postal/Mail'

            WHEN UPPER(TRIM(CAST(vehicle_type_code_3 AS STRING))) LIKE '%FEDEX%'
              OR UPPER(TRIM(CAST(vehicle_type_code_3 AS STRING))) LIKE '%FED EX%'
              OR UPPER(TRIM(CAST(vehicle_type_code_3 AS STRING))) LIKE '%AMAZON%'
              OR UPPER(TRIM(CAST(vehicle_type_code_3 AS STRING))) LIKE '%DHL%'
              OR UPPER(TRIM(CAST(vehicle_type_code_3 AS STRING))) LIKE '%DELIVERY%'
              OR UPPER(TRIM(CAST(vehicle_type_code_3 AS STRING))) LIKE '%DELIV%'
              OR UPPER(TRIM(CAST(vehicle_type_code_3 AS STRING))) LIKE '%COURIER%'
              OR UPPER(TRIM(CAST(vehicle_type_code_3 AS STRING))) IN ('UPS','UPS T','UPS VAN','UPS M','DLEV','DLVR','DELV','DELVR','DEL','DEL T')
                THEN 'Delivery Vehicle'

            WHEN UPPER(TRIM(CAST(vehicle_type_code_3 AS STRING))) LIKE '%U-HAUL%'
              OR UPPER(TRIM(CAST(vehicle_type_code_3 AS STRING))) LIKE '%UHAUL%'
              OR UPPER(TRIM(CAST(vehicle_type_code_3 AS STRING))) LIKE '%U HAUL%'
              OR UPPER(TRIM(CAST(vehicle_type_code_3 AS STRING))) LIKE '%UHUAL%'
              OR UPPER(TRIM(CAST(vehicle_type_code_3 AS STRING))) IN ('RYDER','PENSKE BOX','U-TRU','UHAL','UHAL TRUCK')
                THEN 'Rental Truck'

            WHEN UPPER(TRIM(CAST(vehicle_type_code_3 AS STRING))) LIKE '%PICKUP%'
              OR UPPER(TRIM(CAST(vehicle_type_code_3 AS STRING))) LIKE '%PICK UP%'
              OR UPPER(TRIM(CAST(vehicle_type_code_3 AS STRING))) LIKE '%PICK-UP%'
              OR UPPER(TRIM(CAST(vehicle_type_code_3 AS STRING))) IN ('PU','PICKU','PK','PKUP','P/U','PICK','PICK-')
                THEN 'Pickup Truck'

            WHEN UPPER(TRIM(CAST(vehicle_type_code_3 AS STRING))) LIKE '%BOX TRUCK%'
              OR UPPER(TRIM(CAST(vehicle_type_code_3 AS STRING))) LIKE '%BOXTRUCK%'
              OR UPPER(TRIM(CAST(vehicle_type_code_3 AS STRING))) IN ('BOX T','BOXTR','BOX VAN','BOX CAR','BOX CARGO','BOX','BOX H','EMPTYBOX T')
                THEN 'Box Truck'

            WHEN UPPER(TRIM(CAST(vehicle_type_code_3 AS STRING))) LIKE '%FLATBED%'
              OR UPPER(TRIM(CAST(vehicle_type_code_3 AS STRING))) LIKE '%FLAT BED%'
              OR UPPER(TRIM(CAST(vehicle_type_code_3 AS STRING))) IN ('FLAT','FLAT RACK','FLAT-','FLAT/','PLATF')
                THEN 'Flatbed Truck'

            WHEN UPPER(TRIM(CAST(vehicle_type_code_3 AS STRING))) LIKE '%TRACTOR TR%'
              OR UPPER(TRIM(CAST(vehicle_type_code_3 AS STRING))) LIKE '%SEMI TRUCK%'
              OR UPPER(TRIM(CAST(vehicle_type_code_3 AS STRING))) LIKE '%SEMI-TRUCK%'
              OR UPPER(TRIM(CAST(vehicle_type_code_3 AS STRING))) LIKE '%SEMI TRAIL%'
              OR UPPER(TRIM(CAST(vehicle_type_code_3 AS STRING))) LIKE '%FREIGHTLIN%'
              OR UPPER(TRIM(CAST(vehicle_type_code_3 AS STRING))) LIKE '%18 WHEEL%'
              OR UPPER(TRIM(CAST(vehicle_type_code_3 AS STRING))) LIKE '%18WHEEL%'
              OR UPPER(TRIM(CAST(vehicle_type_code_3 AS STRING))) IN ('SEMI','SEMI-','TRACTOR','MACK','KENWORTH T',
                 'FUSO TRUCK','18 WH','18 WHEELER','18 WEELER','18 WH','18 Wh',
                 'TRACTOR TRUCK DIESEL','TRACTOR TRUCK GASOLINE','MACK TRUCK','Mack Truck','Mack truck','Macktruck',
                 'FREIG','FRHT','FRT','FLTRL','LTRL','NTTRL','LCOM','LCOMM','SCOMM')
                THEN 'Tractor/Semi-Truck'

            WHEN UPPER(TRIM(CAST(vehicle_type_code_3 AS STRING))) LIKE '%DUMP TRUCK%'
              OR UPPER(TRIM(CAST(vehicle_type_code_3 AS STRING))) LIKE '%DUMP TR%'
              OR UPPER(TRIM(CAST(vehicle_type_code_3 AS STRING))) IN ('DUMP','DUMPT','DUMPTRUCK','DUMP TRUK','DUMPS','DUMPSTER','DUMPSTER T','DUMPTRUCK')
                THEN 'Dump Truck'

            WHEN UPPER(TRIM(CAST(vehicle_type_code_3 AS STRING))) LIKE '%SANITAT%'
              OR UPPER(TRIM(CAST(vehicle_type_code_3 AS STRING))) LIKE '%DSNY%'
              OR UPPER(TRIM(CAST(vehicle_type_code_3 AS STRING))) LIKE '%GARBAGE%'
              OR UPPER(TRIM(CAST(vehicle_type_code_3 AS STRING))) LIKE '%REFUSE%'
              OR UPPER(TRIM(CAST(vehicle_type_code_3 AS STRING))) LIKE '%WASTE TR%'
              OR UPPER(TRIM(CAST(vehicle_type_code_3 AS STRING))) IN ('SANAT','SANTI','SANMEN COU','SANIT','Garbage or Refuse',
                 'sanitaion','sanitaton','santiation','santa','Solid wast')
                THEN 'Sanitation/Garbage'

            WHEN UPPER(TRIM(CAST(vehicle_type_code_3 AS STRING))) LIKE '%TOW TRUCK%'
              OR UPPER(TRIM(CAST(vehicle_type_code_3 AS STRING))) LIKE '%TOWTRUCK%'
              OR UPPER(TRIM(CAST(vehicle_type_code_3 AS STRING))) LIKE '%TOW-TRUCK%'
              OR UPPER(TRIM(CAST(vehicle_type_code_3 AS STRING))) LIKE '%WRECKER%'
              OR UPPER(TRIM(CAST(vehicle_type_code_3 AS STRING))) IN ('TOW T','TOWTR','TOW R','TOW TRICK','TOWE','TOWIN','TOWMA',
                 'Tow Truck / Wrecker','Tow t','Tow-t','PICKUP TOW','PICKUP-TOW','X TOW','G TOW','E TOW')
                THEN 'Tow Truck'

            WHEN UPPER(TRIM(CAST(vehicle_type_code_3 AS STRING))) LIKE '%FOOD TRUCK%'
              OR UPPER(TRIM(CAST(vehicle_type_code_3 AS STRING))) LIKE '%FOOD CART%'
              OR UPPER(TRIM(CAST(vehicle_type_code_3 AS STRING))) LIKE '%FOOD TRAIL%'
              OR UPPER(TRIM(CAST(vehicle_type_code_3 AS STRING))) IN ('FOOD','FOOD VENDE','FOOD DELIV','HOTDO','LUNCH WAGON','VENDOR CHA','VENDOR FOO','Mobile foo','Small Food')
                THEN 'Food Truck/Cart'

            WHEN UPPER(TRIM(CAST(vehicle_type_code_3 AS STRING))) LIKE '%SPRINTER%'
              OR UPPER(TRIM(CAST(vehicle_type_code_3 AS STRING))) LIKE '%ECONOLINE%'
              OR UPPER(TRIM(CAST(vehicle_type_code_3 AS STRING))) LIKE '%MINIVAN%'
              OR UPPER(TRIM(CAST(vehicle_type_code_3 AS STRING))) LIKE '%MINI VAN%'
              OR UPPER(TRIM(CAST(vehicle_type_code_3 AS STRING))) LIKE '%CARGO VAN%'
              OR UPPER(TRIM(CAST(vehicle_type_code_3 AS STRING))) LIKE '%TRANSIT VA%'
              OR UPPER(TRIM(CAST(vehicle_type_code_3 AS STRING))) IN ('VAN','VAM','VANT','VANG','VAN`','VAV','VANET','VAN/T',
                 'VAN T','VAN C','VAN W','VAN A','VAN/B','VAN/TRUCK','VAN TRUCK',
                 'PASS VAN','COM VAN','COMM VAN','CARGO VAN','CHEVY VAN','FORD VAN','GMC VAN',
                 'PANEL VAN','SAVANA VAN','SAVANA','SPRIN','SPR','PROMASTER','ECONO',
                 'ECOLINE VA','ECONOLINE','CHEVY EXPR','MINIV','MINI VAHN',
                 'Van','Van T','Van truck','Van/Truck','Vanette','Cargo Van','Cargo van')
                THEN 'Van/Minivan'

            WHEN UPPER(TRIM(CAST(vehicle_type_code_3 AS STRING))) LIKE '%SUV%'
              OR UPPER(TRIM(CAST(vehicle_type_code_3 AS STRING))) LIKE '%SUBURBAN%'
              OR UPPER(TRIM(CAST(vehicle_type_code_3 AS STRING))) LIKE '%SPORT UTIL%'
              OR UPPER(TRIM(CAST(vehicle_type_code_3 AS STRING))) LIKE '%STATION WAG%'
              OR UPPER(TRIM(CAST(vehicle_type_code_3 AS STRING))) IN ('SW','SW/SUV','SW/VAN','SPORT UTILITY / STATION WAGON',
                 'SURBURBAN','SUBN','SUBUR','SUBR','SYBN','SBN','WUBN','Station Wagon/Sport Utility Vehicle',
                 'Subn','Subur','Surburban','Suv','SUDAN','SUDN','HIGHL','SEDONA','SIERRA','SENIORCARE')
                THEN 'SUV/Station Wagon'

            WHEN UPPER(TRIM(CAST(vehicle_type_code_3 AS STRING))) LIKE '%MOTORCYCLE%'
              OR UPPER(TRIM(CAST(vehicle_type_code_3 AS STRING))) LIKE '%MOTORBIKE%'
              OR UPPER(TRIM(CAST(vehicle_type_code_3 AS STRING))) IN ('MC','MCY','MCR','MCY B','MOT','MNI-MOTORC',
                 'MINICYCLE','MINIBIKE','MOTOR','ELE MOTORC','ELEC. UNIC','MOTOR UNIC',
                 'Motorbike','Motorcycle','Motorscooter','MOTORSCOOT','MOTO-SCOOT')
                THEN 'Motorcycle'

            WHEN UPPER(TRIM(CAST(vehicle_type_code_3 AS STRING))) LIKE '%MOPED%'
              OR UPPER(TRIM(CAST(vehicle_type_code_3 AS STRING))) LIKE '%MOPAD%'
              OR UPPER(TRIM(CAST(vehicle_type_code_3 AS STRING))) IN ('MOPD','MOPET','MOPPED','MOPEN','MOPER','MOPOED',
                 'MO PED','MO-PED','MO PE','MOOPER','MOP','GAS MO-PED','GAS MOPED',
                 'MOped','Moped','Moped bike','Moped clas','Moped elec','Mopen','Moper','Mopoed','Mopped')
                THEN 'Moped'

            WHEN UPPER(TRIM(CAST(vehicle_type_code_3 AS STRING))) LIKE '%E-BIKE%'
              OR UPPER(TRIM(CAST(vehicle_type_code_3 AS STRING))) LIKE '%E BIKE%'
              OR UPPER(TRIM(CAST(vehicle_type_code_3 AS STRING))) LIKE '%EBIKE%'
              OR UPPER(TRIM(CAST(vehicle_type_code_3 AS STRING))) LIKE '%ELECTRIC BIKE%'
              OR UPPER(TRIM(CAST(vehicle_type_code_3 AS STRING))) LIKE '%ELECTRIC B%'
              OR UPPER(TRIM(CAST(vehicle_type_code_3 AS STRING))) IN ('E BIK','E-BIK','E/BIK','ECOM','E COM',
                 'UNI E-BIKE','E- BI','E- MOTOR B','E1','Ebike','ebike','e bik','e bike','e-bik','e-bike',
                 'E BIKE NO PLATE','E-BIKE NO','ELECTRIC M','ELEC','ELECT')
                THEN 'E-Bike'

            WHEN UPPER(TRIM(CAST(vehicle_type_code_3 AS STRING))) LIKE '%E-SCOOTER%'
              OR UPPER(TRIM(CAST(vehicle_type_code_3 AS STRING))) LIKE '%E SCOOTER%'
              OR UPPER(TRIM(CAST(vehicle_type_code_3 AS STRING))) LIKE '%ESCOOTER%'
              OR UPPER(TRIM(CAST(vehicle_type_code_3 AS STRING))) LIKE '%REVEL%'
              OR UPPER(TRIM(CAST(vehicle_type_code_3 AS STRING))) LIKE '%LIME SCOOT%'
              OR UPPER(TRIM(CAST(vehicle_type_code_3 AS STRING))) LIKE '%NINEBOT%'
              OR UPPER(TRIM(CAST(vehicle_type_code_3 AS STRING))) IN ('E SCO','E-SCO','E- SCOOTER','ESCOO',
                 'MOTOR SCOO','MOTOR SKAT','MOTORIZED','MOTORIZEDS',
                 'E REVEL SCO','SPARK150 S','BEYOND SCO','RIDE ON SC',
                 'e sco','e scooter','e-scooter','eScoo','escooter','Escooter')
                THEN 'E-Scooter'

            WHEN UPPER(TRIM(CAST(vehicle_type_code_3 AS STRING))) LIKE '%SCOOTER%'
              OR UPPER(TRIM(CAST(vehicle_type_code_3 AS STRING))) IN ('SCL','SCOM','SCOOT','SCOO','GAS SCOOTE','GAS S',
                 'GAS PWR SC','VESPA','SCOOTOR','SCOTTER','SCOMM','GAS SCOOTER (G',
                 'SEATED SCO','STAND UP S','STANDUP SC','STANDING S','PUSH SCOOT',
                 'KICK SCOOT','RAZOR SCOO','MANUAL SCO','BLACK SCOO','RED SCOOTE',
                 'Scooter','Scoot','scoot','scooter','Kick scoot','Push scoot','Razor scoo',
                 'Seated sco','Stand Up S','Stand up s','Stand-up S','Standing S','Standing s')
                THEN 'Scooter (Gas)'

            WHEN UPPER(TRIM(CAST(vehicle_type_code_3 AS STRING))) LIKE '%BICYCLE%'
              OR UPPER(TRIM(CAST(vehicle_type_code_3 AS STRING))) LIKE '%BICYC%'
              OR UPPER(TRIM(CAST(vehicle_type_code_3 AS STRING))) IN ('BIKE','CITIBIKE','PEDAL BIKE','GAS BICYCL',
                 'GAS BIKE','Bicycle','Bicyc','Bike','Citi bike','Gas bicycl','Gas bike','bicycle','bike')
                THEN 'Bicycle'

            WHEN UPPER(TRIM(CAST(vehicle_type_code_3 AS STRING))) LIKE '%DIRT BIKE%'
              OR UPPER(TRIM(CAST(vehicle_type_code_3 AS STRING))) LIKE '%DIRTBIKE%'
              OR UPPER(TRIM(CAST(vehicle_type_code_3 AS STRING))) IN ('DIRT','DIRTB','DIRT-','Dart bike','Dirt Bike','Dirt bike','dirtbike','dirt bike')
                THEN 'Dirt Bike'

            WHEN UPPER(TRIM(CAST(vehicle_type_code_3 AS STRING))) LIKE '%SKATEBOARD%'
              OR UPPER(TRIM(CAST(vehicle_type_code_3 AS STRING))) LIKE '%HOVERBOARD%'
              OR UPPER(TRIM(CAST(vehicle_type_code_3 AS STRING))) LIKE '%E-SKATEBO%'
              OR UPPER(TRIM(CAST(vehicle_type_code_3 AS STRING))) LIKE '%E SKATEBOA%'
              OR UPPER(TRIM(CAST(vehicle_type_code_3 AS STRING))) IN ('SKATE','ROLLERBLAD','IN LINE SK','SKATBOARD',
                 'E SKATEBOA','E-SKATEBOA','E-SKA','MOTOR SKAT','EvolveSkat',
                 'Skate','Skate boar','Skateboard','skate','skateboard','e skate bo','e-skateboa')
                THEN 'Skateboard/Hoverboard'

            WHEN UPPER(TRIM(CAST(vehicle_type_code_3 AS STRING))) LIKE '%WHEELCHAIR%'
              OR UPPER(TRIM(CAST(vehicle_type_code_3 AS STRING))) LIKE '%ACCESS-A-R%'
              OR UPPER(TRIM(CAST(vehicle_type_code_3 AS STRING))) LIKE '%ACCESS A R%'
              OR UPPER(TRIM(CAST(vehicle_type_code_3 AS STRING))) LIKE '%MOBILITY%'
              OR UPPER(TRIM(CAST(vehicle_type_code_3 AS STRING))) LIKE '%ACCES%'
              OR UPPER(TRIM(CAST(vehicle_type_code_3 AS STRING))) IN ('WC','WHEEL','E Wheelcha','APPOR','APPORTIONE','APORT',
                 'ACCESS-A-','ACCESS-ARI','ACCEE','ACCESS RID',
                 'Acces','Access A R','Access a R','Access-A-R','Apportione',
                 'Handicap S','Motor whee','Mobility S','MOBILTY SC','MOBILITY S')
                THEN 'Wheelchair/Mobility'

            WHEN UPPER(TRIM(CAST(vehicle_type_code_3 AS STRING))) LIKE '%BACKHOE%'
              OR UPPER(TRIM(CAST(vehicle_type_code_3 AS STRING))) LIKE '%EXCAVAT%'
              OR UPPER(TRIM(CAST(vehicle_type_code_3 AS STRING))) LIKE '%ESCAVAT%'
              OR UPPER(TRIM(CAST(vehicle_type_code_3 AS STRING))) LIKE '%BULLDOZ%'
              OR UPPER(TRIM(CAST(vehicle_type_code_3 AS STRING))) LIKE '%FORKLIFT%'
              OR UPPER(TRIM(CAST(vehicle_type_code_3 AS STRING))) LIKE '%FORK LIFT%'
              OR UPPER(TRIM(CAST(vehicle_type_code_3 AS STRING))) LIKE '%BOBCAT%'
              OR UPPER(TRIM(CAST(vehicle_type_code_3 AS STRING))) LIKE '%CRANE%'
              OR UPPER(TRIM(CAST(vehicle_type_code_3 AS STRING))) LIKE '%PAYLOAD%'
              OR UPPER(TRIM(CAST(vehicle_type_code_3 AS STRING))) LIKE '%SKID LOAD%'
              OR UPPER(TRIM(CAST(vehicle_type_code_3 AS STRING))) LIKE '%SKID STEER%'
              OR UPPER(TRIM(CAST(vehicle_type_code_3 AS STRING))) LIKE '%FRONT END%'
              OR UPPER(TRIM(CAST(vehicle_type_code_3 AS STRING))) LIKE '%FRONT LOAD%'
              OR UPPER(TRIM(CAST(vehicle_type_code_3 AS STRING))) LIKE '%BOOM LIFT%'
              OR UPPER(TRIM(CAST(vehicle_type_code_3 AS STRING))) LIKE '%CATERPILLA%'
              OR UPPER(TRIM(CAST(vehicle_type_code_3 AS STRING))) LIKE '%KOMATSU%'
              OR UPPER(TRIM(CAST(vehicle_type_code_3 AS STRING))) IN ('BACK HOE','BACKH','BKHOE','HOE-L','LOADE',
                 'BUCKE','BUDGE','BULDOZER','BULL DOZER','BULLD','FORK','FORK-','FORKL',
                 'CAT','CAT 4','CATER','CATIP','CAT.','CASE','COMPACT LO','SKID','SKID-',
                 'SKIDSTEERL','LULL','FOGLIT','FOLK LIFT','HI LO','HI-LO','HILOW',
                 'Backhoe','Backh','Bobcat','Boom','Boom Lift','Bucke','Bucket Tru','Bucket tru',
                 'Bulldozer','Bull dozer','Cater','Caterpilla','Comp skid','Excav','Excavator',
                 'Escavator','Fork','Fork Lift','Fork lift','Forkl','Forklift','Front End',
                 'Front load','Front-Load','Hyster For','Liebh','Lift','Loade','Paylo','Skid','Skid steer',
                 'Swingloade','Telehandle','back ho','backh','backhoe','bobca','boom','bucke',
                 'bulld','cat','cate','forklift','front','hi-lo','hilow','lull','paylo','skid')
                THEN 'Construction Equipment'

            WHEN UPPER(TRIM(CAST(vehicle_type_code_3 AS STRING))) LIKE '%SNOW PLOW%'
              OR UPPER(TRIM(CAST(vehicle_type_code_3 AS STRING))) LIKE '%SNOWPLOW%'
              OR UPPER(TRIM(CAST(vehicle_type_code_3 AS STRING))) LIKE '%STREET SWE%'
              OR UPPER(TRIM(CAST(vehicle_type_code_3 AS STRING))) LIKE '%ROAD SWEEP%'
              OR UPPER(TRIM(CAST(vehicle_type_code_3 AS STRING))) LIKE '%SWEEPER%'
              OR UPPER(TRIM(CAST(vehicle_type_code_3 AS STRING))) IN ('PLOW','PLOW TRUCK','BROOM','SALT','SALTSPREAD',
                 'ROAD','ROADS','STREE','STREET CLE','STREET SWE','SWEEP','SWEPE','SWT',
                 'DSNY SWEEP','ROAD SWEEP','RD BLDNG M','Plow  truc','Plow truck','Road Sweep',
                 'Road sweep','Street Cle','Street Swe','Street swe','Sweep','Sweeper','dsny sweep',
                 'road sweep','salt','street cle','street swe','sweep','sweeper')
                THEN 'Plow/Sweeper'

            WHEN UPPER(TRIM(CAST(vehicle_type_code_3 AS STRING))) LIKE '%TANKER%'
              OR UPPER(TRIM(CAST(vehicle_type_code_3 AS STRING))) LIKE '%CEMENT MIX%'
              OR UPPER(TRIM(CAST(vehicle_type_code_3 AS STRING))) LIKE '%CONCRETE M%'
              OR UPPER(TRIM(CAST(vehicle_type_code_3 AS STRING))) IN ('TANK','TANK TRUCK','TANK WH','TANKE','OIL T',
                 'OIL TANKER','CONCR','CMIX','CMIXER','CEMENT TRU','CEMEN',
                 'Tank','Tank truck','Tanker','Oil Tanker','Cement Tru','Cement tru',
                 'Concrete Mixer','cemen','concr','tank')
                THEN 'Tank/Cement Truck'

            WHEN UPPER(TRIM(CAST(vehicle_type_code_3 AS STRING))) LIKE '%GOLF CART%'
              OR UPPER(TRIM(CAST(vehicle_type_code_3 AS STRING))) LIKE '%GOLF CAR%'
              OR UPPER(TRIM(CAST(vehicle_type_code_3 AS STRING))) LIKE '%GOLFCART%'
              OR UPPER(TRIM(CAST(vehicle_type_code_3 AS STRING))) LIKE '%GATOR%'
              OR UPPER(TRIM(CAST(vehicle_type_code_3 AS STRING))) IN ('ATV','UTV','QUAD','GOLF','GO KART','GOLF KART',
                 'All-Terrain Vehicle','Gator','Gator 4x4','Golf','Golf Cart','Golf cart',
                 'Go kart','Quadricycl','atv p','gokar','golf','golf cart','gator','utv bobcat')
                THEN 'Golf Cart/ATV'

            WHEN UPPER(TRIM(CAST(vehicle_type_code_3 AS STRING))) LIKE '%MOTOR HOME%'
              OR UPPER(TRIM(CAST(vehicle_type_code_3 AS STRING))) LIKE '%MOTORHOME%'
              OR UPPER(TRIM(CAST(vehicle_type_code_3 AS STRING))) LIKE '%WINNEBA%'
              OR UPPER(TRIM(CAST(vehicle_type_code_3 AS STRING))) LIKE '%CAMPER%'
              OR UPPER(TRIM(CAST(vehicle_type_code_3 AS STRING))) IN ('RV','R/V','MTR H','RV/VAN','RV/Tr','RV motorho',
                 'MOTORIZED HOME','Motorized Home','Rec Vehicl','winne','Motorhome','motorhome')
                THEN 'RV/Motorhome'

            WHEN UPPER(TRIM(CAST(vehicle_type_code_3 AS STRING))) LIKE '%HORSE%'
              OR UPPER(TRIM(CAST(vehicle_type_code_3 AS STRING))) IN ('HRSE','HOSRE','HOSRE DRAW','HURSE',
                 'Horse','Horse Carr','Horse Trai','Horse carr','Horse trai','Hrse','horse','hrse')
                THEN 'Horse Carriage'

            WHEN UPPER(TRIM(CAST(vehicle_type_code_3 AS STRING))) LIKE '%NYPD%'
              OR UPPER(TRIM(CAST(vehicle_type_code_3 AS STRING))) LIKE '%POLICE%'
              OR UPPER(TRIM(CAST(vehicle_type_code_3 AS STRING))) IN ('RMP','R.M.P.','ESU','ESU T','ESU REP','ESU RESCUE',
                 'MARKED RMP','MARKED VAN','F550 ESU R','NYPD RMP','NYPD ESU T',
                 'Rmp','rmp','Nypd','nypd','police van','police veh','Polic','polic')
                THEN 'Police Vehicle'

            WHEN UPPER(TRIM(CAST(vehicle_type_code_3 AS STRING))) IN (
                    'SEDAN','PASSENGER','PASSENGER VEHICLE','PASS','COUPE',
                    '2 DR','2DR','4 DOOR','4DR','4 DR SEDAN','2 DR SEDAN',
                    '4D','4DS','4SEDN','4door','4dsd','2 DOO','2 DR','2 doo',
                    'BMW','DODGE','DODGE RAM','RAM','CHEVY','CHEVROLET','CHEVR',
                    'GMC','NISSAN','NISSA','TOYOTA','TOYOT','MERCEDES',
                    'VOLVO','ACUR','ASTRO','SONATA','SIERRA','RIDGELINE',
                    'JEEP','AUDI','HYUND','IMPAL','FORD','CHEV','CHVEY',
                    'SMART','SMART CAR','FUSION','DODGE','RAM PRM','RAM COMM.',
                    'HERTZ RAM','HONDA HRV','MINI','ARIEL','ARCIMOTO',
                    'Dodge','Dodge ram','Jeep','Ram','Ram Promas','Smart',
                    'Chevr','Chevy','Ford','Gmc pick u','Gmc savann','Nissan',
                    'Supercab','Ridgeline','ford','chevy','dodge','toyota','nissan','bmw','jeep','volvo'
                )
              OR UPPER(TRIM(CAST(vehicle_type_code_3 AS STRING))) LIKE '%PASSENGER%'
              OR UPPER(TRIM(CAST(vehicle_type_code_3 AS STRING))) LIKE '%CHEVROLET%'
              OR UPPER(TRIM(CAST(vehicle_type_code_3 AS STRING))) LIKE '%DODGE%'
              OR UPPER(TRIM(CAST(vehicle_type_code_3 AS STRING))) LIKE '%TOYOTA%'
              OR UPPER(TRIM(CAST(vehicle_type_code_3 AS STRING))) LIKE '%NISSAN%'
                THEN 'Passenger Vehicle'

            WHEN UPPER(TRIM(CAST(vehicle_type_code_3 AS STRING))) IN (
                    'UNKNOWN','UNKNOW','UNKNO','UNKNW','UNKOWN','UNKWN','UNKWOWN',
                    'UNK','UNKN','UK','UKN','UKNOWN','UNNKO','UNNOWN','UNKNW','UNKOW',
                    'UNKOWM','UNKOWN','UNKWN','UKNOWN','UNKNO','UNKNW','UNKN',
                    'N/A','NA','N/a','NONE','NULL','0','00','000','0000','00000',
                    '00000','-','.','','?','A','B','C','D','E3','G1','H1','J1','L1',
                    'None','none','na','n/a','unk','unkn','unkno','unknown','unkow','unkown',
                    'UK','UKN','UKNOWN','UNK/L','UNL','UNNKO','UNNOWN',
                    '1','2','4','5','7','197209','2000','2003','263','787',
                    '9999','99999','0','00','000','13','17','430','985','994','997','999',
                    'NTTRL','YNK','YPS','-','.',',','omm'
                )
                THEN 'Unknown'
            WHEN vehicle_type_code_3 IS NULL THEN NULL
            ELSE 'Other'
        END AS vehicle_type_3,

        CASE
            WHEN UPPER(TRIM(CAST(vehicle_type_code_4 AS STRING))) LIKE '%AMBULAN%'
              OR UPPER(TRIM(CAST(vehicle_type_code_4 AS STRING))) LIKE '%AMBUL%'
              OR UPPER(TRIM(CAST(vehicle_type_code_4 AS STRING))) IN ('AMB','AMBU','AMBUL','EAMB','E AMB','G AMB','NS AM','X AMB',
                 'EMS','EMS AMBULA','EMS AMBULE','EMT','EMT AMBULA','FDNY EMT',
                 'NYS AMBULA','REG.AMBULA','PRIV AMBUL','GEN  AMBUL','FORD AMBUL',
                 'FD AMBULAN','EMBULANCE','EMERGANCY','EMERGENCY','A bulance',
                 'abulance','almbulance','amdu','amulance','anbul','AMUBL','AMUBULANCE')
                THEN 'Ambulance'

            WHEN UPPER(TRIM(CAST(vehicle_type_code_4 AS STRING))) LIKE '%FDNY%'
              OR UPPER(TRIM(CAST(vehicle_type_code_4 AS STRING))) LIKE '%FIRETRUCK%'
              OR UPPER(TRIM(CAST(vehicle_type_code_4 AS STRING))) LIKE '%FIRE TRUCK%'
              OR UPPER(TRIM(CAST(vehicle_type_code_4 AS STRING))) LIKE '%FIRE APPAR%'
              OR UPPER(TRIM(CAST(vehicle_type_code_4 AS STRING))) LIKE '%FIRE ENG%'
              OR UPPER(TRIM(CAST(vehicle_type_code_4 AS STRING))) LIKE '%FIRE DEPT%'
              OR UPPER(TRIM(CAST(vehicle_type_code_4 AS STRING))) LIKE '%FIRE LADD%'
              OR UPPER(TRIM(CAST(vehicle_type_code_4 AS STRING))) LIKE '%FIRET%'
              OR UPPER(TRIM(CAST(vehicle_type_code_4 AS STRING))) LIKE '%FD TR%'
              OR UPPER(TRIM(CAST(vehicle_type_code_4 AS STRING))) LIKE '%FD EN%'
              OR UPPER(TRIM(CAST(vehicle_type_code_4 AS STRING))) LIKE '%FD LA%'
              OR UPPER(TRIM(CAST(vehicle_type_code_4 AS STRING))) IN ('FIRE','FIRE RUCK','FIRER','FIRTRUCK','FIRETURCK','FNDY EMS','FDNYLadder','FDNYTRUCKF')
                THEN 'Fire Apparatus'

            WHEN UPPER(TRIM(CAST(vehicle_type_code_4 AS STRING))) LIKE '%SCHOOL BUS%'
              OR UPPER(TRIM(CAST(vehicle_type_code_4 AS STRING))) LIKE '%SCHOOLBUS%'
              OR UPPER(TRIM(CAST(vehicle_type_code_4 AS STRING))) LIKE '%SCHOOL VAN%'
              OR UPPER(TRIM(CAST(vehicle_type_code_4 AS STRING))) IN ('YELLOW BUS','YELLOWBUS','YW SCHOOL','SMYELLSCHO',
                 'SHORT SCHO','MINI SCHOO','SM YW','YLL P','SHCOO','SCHOO','SCHOO LBUS',
                 'SCHOOL  BU','Yellow bus','Yellow sch','Small Bus','Small scho','Short Bus')
                THEN 'School Bus'

            WHEN UPPER(TRIM(CAST(vehicle_type_code_4 AS STRING))) LIKE '%MTA BUS%'
              OR UPPER(TRIM(CAST(vehicle_type_code_4 AS STRING))) LIKE '%CITY BUS%'
              OR UPPER(TRIM(CAST(vehicle_type_code_4 AS STRING))) LIKE '%TRANSIT%'
              OR UPPER(TRIM(CAST(vehicle_type_code_4 AS STRING))) LIKE '%OMNIBUS%'
              OR UPPER(TRIM(CAST(vehicle_type_code_4 AS STRING))) IN ('BUS','BUSS','TOUR BUS','SHUTTLE BU','MINI BUS',
                 'COACH','NICE BUS','BLU BUS','BUS M','BUs','ORION','NEW FLYER','LIVERY BUS','Livery Omn','Livery Bus')
                THEN 'Bus'

            WHEN UPPER(TRIM(CAST(vehicle_type_code_4 AS STRING))) LIKE '%TAXI%'
              OR UPPER(TRIM(CAST(vehicle_type_code_4 AS STRING))) LIKE '%YELLOW CAB%'
              OR UPPER(TRIM(CAST(vehicle_type_code_4 AS STRING))) IN ('YELLO','DOLLAR VAN','PETIT CAB','Yellow Cab','Yellow cab')
                THEN 'Taxi'

            WHEN UPPER(TRIM(CAST(vehicle_type_code_4 AS STRING))) LIKE '%LIVERY%'
              OR UPPER(TRIM(CAST(vehicle_type_code_4 AS STRING))) LIKE '%MEDALLION%'
              OR UPPER(TRIM(CAST(vehicle_type_code_4 AS STRING))) LIKE '%TLC%'
                THEN 'Livery/TLC'

            WHEN UPPER(TRIM(CAST(vehicle_type_code_4 AS STRING))) LIKE '%LIMO%'
                THEN 'Limousine'

            WHEN UPPER(TRIM(CAST(vehicle_type_code_4 AS STRING))) LIKE '%USPS%'
              OR UPPER(TRIM(CAST(vehicle_type_code_4 AS STRING))) LIKE '%US POSTAL%'
              OR UPPER(TRIM(CAST(vehicle_type_code_4 AS STRING))) LIKE '%US MAIL%'
              OR UPPER(TRIM(CAST(vehicle_type_code_4 AS STRING))) LIKE '%POSTAL%'
              OR UPPER(TRIM(CAST(vehicle_type_code_4 AS STRING))) LIKE '%MAIL TRUCK%'
              OR UPPER(TRIM(CAST(vehicle_type_code_4 AS STRING))) LIKE '%MAILTRUCK%'
              OR UPPER(TRIM(CAST(vehicle_type_code_4 AS STRING))) IN ('LLV','LLV MAIL T','U.S. POSTA','U.S.P','US PO','US Po')
                THEN 'Postal/Mail'

            WHEN UPPER(TRIM(CAST(vehicle_type_code_4 AS STRING))) LIKE '%FEDEX%'
              OR UPPER(TRIM(CAST(vehicle_type_code_4 AS STRING))) LIKE '%FED EX%'
              OR UPPER(TRIM(CAST(vehicle_type_code_4 AS STRING))) LIKE '%AMAZON%'
              OR UPPER(TRIM(CAST(vehicle_type_code_4 AS STRING))) LIKE '%DHL%'
              OR UPPER(TRIM(CAST(vehicle_type_code_4 AS STRING))) LIKE '%DELIVERY%'
              OR UPPER(TRIM(CAST(vehicle_type_code_4 AS STRING))) LIKE '%DELIV%'
              OR UPPER(TRIM(CAST(vehicle_type_code_4 AS STRING))) LIKE '%COURIER%'
              OR UPPER(TRIM(CAST(vehicle_type_code_4 AS STRING))) IN ('UPS','UPS T','UPS VAN','UPS M','DLEV','DLVR','DELV','DELVR','DEL','DEL T')
                THEN 'Delivery Vehicle'

            WHEN UPPER(TRIM(CAST(vehicle_type_code_4 AS STRING))) LIKE '%U-HAUL%'
              OR UPPER(TRIM(CAST(vehicle_type_code_4 AS STRING))) LIKE '%UHAUL%'
              OR UPPER(TRIM(CAST(vehicle_type_code_4 AS STRING))) LIKE '%U HAUL%'
              OR UPPER(TRIM(CAST(vehicle_type_code_4 AS STRING))) LIKE '%UHUAL%'
              OR UPPER(TRIM(CAST(vehicle_type_code_4 AS STRING))) IN ('RYDER','PENSKE BOX','U-TRU','UHAL','UHAL TRUCK')
                THEN 'Rental Truck'

            WHEN UPPER(TRIM(CAST(vehicle_type_code_4 AS STRING))) LIKE '%PICKUP%'
              OR UPPER(TRIM(CAST(vehicle_type_code_4 AS STRING))) LIKE '%PICK UP%'
              OR UPPER(TRIM(CAST(vehicle_type_code_4 AS STRING))) LIKE '%PICK-UP%'
              OR UPPER(TRIM(CAST(vehicle_type_code_4 AS STRING))) IN ('PU','PICKU','PK','PKUP','P/U','PICK','PICK-')
                THEN 'Pickup Truck'

            WHEN UPPER(TRIM(CAST(vehicle_type_code_4 AS STRING))) LIKE '%BOX TRUCK%'
              OR UPPER(TRIM(CAST(vehicle_type_code_4 AS STRING))) LIKE '%BOXTRUCK%'
              OR UPPER(TRIM(CAST(vehicle_type_code_4 AS STRING))) IN ('BOX T','BOXTR','BOX VAN','BOX CAR','BOX CARGO','BOX','BOX H','EMPTYBOX T')
                THEN 'Box Truck'

            WHEN UPPER(TRIM(CAST(vehicle_type_code_4 AS STRING))) LIKE '%FLATBED%'
              OR UPPER(TRIM(CAST(vehicle_type_code_4 AS STRING))) LIKE '%FLAT BED%'
              OR UPPER(TRIM(CAST(vehicle_type_code_4 AS STRING))) IN ('FLAT','FLAT RACK','FLAT-','FLAT/','PLATF')
                THEN 'Flatbed Truck'

            WHEN UPPER(TRIM(CAST(vehicle_type_code_4 AS STRING))) LIKE '%TRACTOR TR%'
              OR UPPER(TRIM(CAST(vehicle_type_code_4 AS STRING))) LIKE '%SEMI TRUCK%'
              OR UPPER(TRIM(CAST(vehicle_type_code_4 AS STRING))) LIKE '%SEMI-TRUCK%'
              OR UPPER(TRIM(CAST(vehicle_type_code_4 AS STRING))) LIKE '%SEMI TRAIL%'
              OR UPPER(TRIM(CAST(vehicle_type_code_4 AS STRING))) LIKE '%FREIGHTLIN%'
              OR UPPER(TRIM(CAST(vehicle_type_code_4 AS STRING))) LIKE '%18 WHEEL%'
              OR UPPER(TRIM(CAST(vehicle_type_code_4 AS STRING))) LIKE '%18WHEEL%'
              OR UPPER(TRIM(CAST(vehicle_type_code_4 AS STRING))) IN ('SEMI','SEMI-','TRACTOR','MACK','KENWORTH T',
                 'FUSO TRUCK','18 WH','18 WHEELER','18 WEELER','18 WH','18 Wh',
                 'TRACTOR TRUCK DIESEL','TRACTOR TRUCK GASOLINE','MACK TRUCK','Mack Truck','Mack truck','Macktruck',
                 'FREIG','FRHT','FRT','FLTRL','LTRL','NTTRL','LCOM','LCOMM','SCOMM')
                THEN 'Tractor/Semi-Truck'

            WHEN UPPER(TRIM(CAST(vehicle_type_code_4 AS STRING))) LIKE '%DUMP TRUCK%'
              OR UPPER(TRIM(CAST(vehicle_type_code_4 AS STRING))) LIKE '%DUMP TR%'
              OR UPPER(TRIM(CAST(vehicle_type_code_4 AS STRING))) IN ('DUMP','DUMPT','DUMPTRUCK','DUMP TRUK','DUMPS','DUMPSTER','DUMPSTER T','DUMPTRUCK')
                THEN 'Dump Truck'

            WHEN UPPER(TRIM(CAST(vehicle_type_code_4 AS STRING))) LIKE '%SANITAT%'
              OR UPPER(TRIM(CAST(vehicle_type_code_4 AS STRING))) LIKE '%DSNY%'
              OR UPPER(TRIM(CAST(vehicle_type_code_4 AS STRING))) LIKE '%GARBAGE%'
              OR UPPER(TRIM(CAST(vehicle_type_code_4 AS STRING))) LIKE '%REFUSE%'
              OR UPPER(TRIM(CAST(vehicle_type_code_4 AS STRING))) LIKE '%WASTE TR%'
              OR UPPER(TRIM(CAST(vehicle_type_code_4 AS STRING))) IN ('SANAT','SANTI','SANMEN COU','SANIT','Garbage or Refuse',
                 'sanitaion','sanitaton','santiation','santa','Solid wast')
                THEN 'Sanitation/Garbage'

            WHEN UPPER(TRIM(CAST(vehicle_type_code_4 AS STRING))) LIKE '%TOW TRUCK%'
              OR UPPER(TRIM(CAST(vehicle_type_code_4 AS STRING))) LIKE '%TOWTRUCK%'
              OR UPPER(TRIM(CAST(vehicle_type_code_4 AS STRING))) LIKE '%TOW-TRUCK%'
              OR UPPER(TRIM(CAST(vehicle_type_code_4 AS STRING))) LIKE '%WRECKER%'
              OR UPPER(TRIM(CAST(vehicle_type_code_4 AS STRING))) IN ('TOW T','TOWTR','TOW R','TOW TRICK','TOWE','TOWIN','TOWMA',
                 'Tow Truck / Wrecker','Tow t','Tow-t','PICKUP TOW','PICKUP-TOW','X TOW','G TOW','E TOW')
                THEN 'Tow Truck'

            WHEN UPPER(TRIM(CAST(vehicle_type_code_4 AS STRING))) LIKE '%FOOD TRUCK%'
              OR UPPER(TRIM(CAST(vehicle_type_code_4 AS STRING))) LIKE '%FOOD CART%'
              OR UPPER(TRIM(CAST(vehicle_type_code_4 AS STRING))) LIKE '%FOOD TRAIL%'
              OR UPPER(TRIM(CAST(vehicle_type_code_4 AS STRING))) IN ('FOOD','FOOD VENDE','FOOD DELIV','HOTDO','LUNCH WAGON','VENDOR CHA','VENDOR FOO','Mobile foo','Small Food')
                THEN 'Food Truck/Cart'

            WHEN UPPER(TRIM(CAST(vehicle_type_code_4 AS STRING))) LIKE '%SPRINTER%'
              OR UPPER(TRIM(CAST(vehicle_type_code_4 AS STRING))) LIKE '%ECONOLINE%'
              OR UPPER(TRIM(CAST(vehicle_type_code_4 AS STRING))) LIKE '%MINIVAN%'
              OR UPPER(TRIM(CAST(vehicle_type_code_4 AS STRING))) LIKE '%MINI VAN%'
              OR UPPER(TRIM(CAST(vehicle_type_code_4 AS STRING))) LIKE '%CARGO VAN%'
              OR UPPER(TRIM(CAST(vehicle_type_code_4 AS STRING))) LIKE '%TRANSIT VA%'
              OR UPPER(TRIM(CAST(vehicle_type_code_4 AS STRING))) IN ('VAN','VAM','VANT','VANG','VAN`','VAV','VANET','VAN/T',
                 'VAN T','VAN C','VAN W','VAN A','VAN/B','VAN/TRUCK','VAN TRUCK',
                 'PASS VAN','COM VAN','COMM VAN','CARGO VAN','CHEVY VAN','FORD VAN','GMC VAN',
                 'PANEL VAN','SAVANA VAN','SAVANA','SPRIN','SPR','PROMASTER','ECONO',
                 'ECOLINE VA','ECONOLINE','CHEVY EXPR','MINIV','MINI VAHN',
                 'Van','Van T','Van truck','Van/Truck','Vanette','Cargo Van','Cargo van')
                THEN 'Van/Minivan'

            WHEN UPPER(TRIM(CAST(vehicle_type_code_4 AS STRING))) LIKE '%SUV%'
              OR UPPER(TRIM(CAST(vehicle_type_code_4 AS STRING))) LIKE '%SUBURBAN%'
              OR UPPER(TRIM(CAST(vehicle_type_code_4 AS STRING))) LIKE '%SPORT UTIL%'
              OR UPPER(TRIM(CAST(vehicle_type_code_4 AS STRING))) LIKE '%STATION WAG%'
              OR UPPER(TRIM(CAST(vehicle_type_code_4 AS STRING))) IN ('SW','SW/SUV','SW/VAN','SPORT UTILITY / STATION WAGON',
                 'SURBURBAN','SUBN','SUBUR','SUBR','SYBN','SBN','WUBN','Station Wagon/Sport Utility Vehicle',
                 'Subn','Subur','Surburban','Suv','SUDAN','SUDN','HIGHL','SEDONA','SIERRA','SENIORCARE')
                THEN 'SUV/Station Wagon'

            WHEN UPPER(TRIM(CAST(vehicle_type_code_4 AS STRING))) LIKE '%MOTORCYCLE%'
              OR UPPER(TRIM(CAST(vehicle_type_code_4 AS STRING))) LIKE '%MOTORBIKE%'
              OR UPPER(TRIM(CAST(vehicle_type_code_4 AS STRING))) IN ('MC','MCY','MCR','MCY B','MOT','MNI-MOTORC',
                 'MINICYCLE','MINIBIKE','MOTOR','ELE MOTORC','ELEC. UNIC','MOTOR UNIC',
                 'Motorbike','Motorcycle','Motorscooter','MOTORSCOOT','MOTO-SCOOT')
                THEN 'Motorcycle'

            WHEN UPPER(TRIM(CAST(vehicle_type_code_4 AS STRING))) LIKE '%MOPED%'
              OR UPPER(TRIM(CAST(vehicle_type_code_4 AS STRING))) LIKE '%MOPAD%'
              OR UPPER(TRIM(CAST(vehicle_type_code_4 AS STRING))) IN ('MOPD','MOPET','MOPPED','MOPEN','MOPER','MOPOED',
                 'MO PED','MO-PED','MO PE','MOOPER','MOP','GAS MO-PED','GAS MOPED',
                 'MOped','Moped','Moped bike','Moped clas','Moped elec','Mopen','Moper','Mopoed','Mopped')
                THEN 'Moped'

            WHEN UPPER(TRIM(CAST(vehicle_type_code_4 AS STRING))) LIKE '%E-BIKE%'
              OR UPPER(TRIM(CAST(vehicle_type_code_4 AS STRING))) LIKE '%E BIKE%'
              OR UPPER(TRIM(CAST(vehicle_type_code_4 AS STRING))) LIKE '%EBIKE%'
              OR UPPER(TRIM(CAST(vehicle_type_code_4 AS STRING))) LIKE '%ELECTRIC BIKE%'
              OR UPPER(TRIM(CAST(vehicle_type_code_4 AS STRING))) LIKE '%ELECTRIC B%'
              OR UPPER(TRIM(CAST(vehicle_type_code_4 AS STRING))) IN ('E BIK','E-BIK','E/BIK','ECOM','E COM',
                 'UNI E-BIKE','E- BI','E- MOTOR B','E1','Ebike','ebike','e bik','e bike','e-bik','e-bike',
                 'E BIKE NO PLATE','E-BIKE NO','ELECTRIC M','ELEC','ELECT')
                THEN 'E-Bike'

            WHEN UPPER(TRIM(CAST(vehicle_type_code_4 AS STRING))) LIKE '%E-SCOOTER%'
              OR UPPER(TRIM(CAST(vehicle_type_code_4 AS STRING))) LIKE '%E SCOOTER%'
              OR UPPER(TRIM(CAST(vehicle_type_code_4 AS STRING))) LIKE '%ESCOOTER%'
              OR UPPER(TRIM(CAST(vehicle_type_code_4 AS STRING))) LIKE '%REVEL%'
              OR UPPER(TRIM(CAST(vehicle_type_code_4 AS STRING))) LIKE '%LIME SCOOT%'
              OR UPPER(TRIM(CAST(vehicle_type_code_4 AS STRING))) LIKE '%NINEBOT%'
              OR UPPER(TRIM(CAST(vehicle_type_code_4 AS STRING))) IN ('E SCO','E-SCO','E- SCOOTER','ESCOO',
                 'MOTOR SCOO','MOTOR SKAT','MOTORIZED','MOTORIZEDS',
                 'E REVEL SCO','SPARK150 S','BEYOND SCO','RIDE ON SC',
                 'e sco','e scooter','e-scooter','eScoo','escooter','Escooter')
                THEN 'E-Scooter'

            WHEN UPPER(TRIM(CAST(vehicle_type_code_4 AS STRING))) LIKE '%SCOOTER%'
              OR UPPER(TRIM(CAST(vehicle_type_code_4 AS STRING))) IN ('SCL','SCOM','SCOOT','SCOO','GAS SCOOTE','GAS S',
                 'GAS PWR SC','VESPA','SCOOTOR','SCOTTER','SCOMM','GAS SCOOTER (G',
                 'SEATED SCO','STAND UP S','STANDUP SC','STANDING S','PUSH SCOOT',
                 'KICK SCOOT','RAZOR SCOO','MANUAL SCO','BLACK SCOO','RED SCOOTE',
                 'Scooter','Scoot','scoot','scooter','Kick scoot','Push scoot','Razor scoo',
                 'Seated sco','Stand Up S','Stand up s','Stand-up S','Standing S','Standing s')
                THEN 'Scooter (Gas)'

            WHEN UPPER(TRIM(CAST(vehicle_type_code_4 AS STRING))) LIKE '%BICYCLE%'
              OR UPPER(TRIM(CAST(vehicle_type_code_4 AS STRING))) LIKE '%BICYC%'
              OR UPPER(TRIM(CAST(vehicle_type_code_4 AS STRING))) IN ('BIKE','CITIBIKE','PEDAL BIKE','GAS BICYCL',
                 'GAS BIKE','Bicycle','Bicyc','Bike','Citi bike','Gas bicycl','Gas bike','bicycle','bike')
                THEN 'Bicycle'

            WHEN UPPER(TRIM(CAST(vehicle_type_code_4 AS STRING))) LIKE '%DIRT BIKE%'
              OR UPPER(TRIM(CAST(vehicle_type_code_4 AS STRING))) LIKE '%DIRTBIKE%'
              OR UPPER(TRIM(CAST(vehicle_type_code_4 AS STRING))) IN ('DIRT','DIRTB','DIRT-','Dart bike','Dirt Bike','Dirt bike','dirtbike','dirt bike')
                THEN 'Dirt Bike'

            WHEN UPPER(TRIM(CAST(vehicle_type_code_4 AS STRING))) LIKE '%SKATEBOARD%'
              OR UPPER(TRIM(CAST(vehicle_type_code_4 AS STRING))) LIKE '%HOVERBOARD%'
              OR UPPER(TRIM(CAST(vehicle_type_code_4 AS STRING))) LIKE '%E-SKATEBO%'
              OR UPPER(TRIM(CAST(vehicle_type_code_4 AS STRING))) LIKE '%E SKATEBOA%'
              OR UPPER(TRIM(CAST(vehicle_type_code_4 AS STRING))) IN ('SKATE','ROLLERBLAD','IN LINE SK','SKATBOARD',
                 'E SKATEBOA','E-SKATEBOA','E-SKA','MOTOR SKAT','EvolveSkat',
                 'Skate','Skate boar','Skateboard','skate','skateboard','e skate bo','e-skateboa')
                THEN 'Skateboard/Hoverboard'

            WHEN UPPER(TRIM(CAST(vehicle_type_code_4 AS STRING))) LIKE '%WHEELCHAIR%'
              OR UPPER(TRIM(CAST(vehicle_type_code_4 AS STRING))) LIKE '%ACCESS-A-R%'
              OR UPPER(TRIM(CAST(vehicle_type_code_4 AS STRING))) LIKE '%ACCESS A R%'
              OR UPPER(TRIM(CAST(vehicle_type_code_4 AS STRING))) LIKE '%MOBILITY%'
              OR UPPER(TRIM(CAST(vehicle_type_code_4 AS STRING))) LIKE '%ACCES%'
              OR UPPER(TRIM(CAST(vehicle_type_code_4 AS STRING))) IN ('WC','WHEEL','E Wheelcha','APPOR','APPORTIONE','APORT',
                 'ACCESS-A-','ACCESS-ARI','ACCEE','ACCESS RID',
                 'Acces','Access A R','Access a R','Access-A-R','Apportione',
                 'Handicap S','Motor whee','Mobility S','MOBILTY SC','MOBILITY S')
                THEN 'Wheelchair/Mobility'

            WHEN UPPER(TRIM(CAST(vehicle_type_code_4 AS STRING))) LIKE '%BACKHOE%'
              OR UPPER(TRIM(CAST(vehicle_type_code_4 AS STRING))) LIKE '%EXCAVAT%'
              OR UPPER(TRIM(CAST(vehicle_type_code_4 AS STRING))) LIKE '%ESCAVAT%'
              OR UPPER(TRIM(CAST(vehicle_type_code_4 AS STRING))) LIKE '%BULLDOZ%'
              OR UPPER(TRIM(CAST(vehicle_type_code_4 AS STRING))) LIKE '%FORKLIFT%'
              OR UPPER(TRIM(CAST(vehicle_type_code_4 AS STRING))) LIKE '%FORK LIFT%'
              OR UPPER(TRIM(CAST(vehicle_type_code_4 AS STRING))) LIKE '%BOBCAT%'
              OR UPPER(TRIM(CAST(vehicle_type_code_4 AS STRING))) LIKE '%CRANE%'
              OR UPPER(TRIM(CAST(vehicle_type_code_4 AS STRING))) LIKE '%PAYLOAD%'
              OR UPPER(TRIM(CAST(vehicle_type_code_4 AS STRING))) LIKE '%SKID LOAD%'
              OR UPPER(TRIM(CAST(vehicle_type_code_4 AS STRING))) LIKE '%SKID STEER%'
              OR UPPER(TRIM(CAST(vehicle_type_code_4 AS STRING))) LIKE '%FRONT END%'
              OR UPPER(TRIM(CAST(vehicle_type_code_4 AS STRING))) LIKE '%FRONT LOAD%'
              OR UPPER(TRIM(CAST(vehicle_type_code_4 AS STRING))) LIKE '%BOOM LIFT%'
              OR UPPER(TRIM(CAST(vehicle_type_code_4 AS STRING))) LIKE '%CATERPILLA%'
              OR UPPER(TRIM(CAST(vehicle_type_code_4 AS STRING))) LIKE '%KOMATSU%'
              OR UPPER(TRIM(CAST(vehicle_type_code_4 AS STRING))) IN ('BACK HOE','BACKH','BKHOE','HOE-L','LOADE',
                 'BUCKE','BUDGE','BULDOZER','BULL DOZER','BULLD','FORK','FORK-','FORKL',
                 'CAT','CAT 4','CATER','CATIP','CAT.','CASE','COMPACT LO','SKID','SKID-',
                 'SKIDSTEERL','LULL','FOGLIT','FOLK LIFT','HI LO','HI-LO','HILOW',
                 'Backhoe','Backh','Bobcat','Boom','Boom Lift','Bucke','Bucket Tru','Bucket tru',
                 'Bulldozer','Bull dozer','Cater','Caterpilla','Comp skid','Excav','Excavator',
                 'Escavator','Fork','Fork Lift','Fork lift','Forkl','Forklift','Front End',
                 'Front load','Front-Load','Hyster For','Liebh','Lift','Loade','Paylo','Skid','Skid steer',
                 'Swingloade','Telehandle','back ho','backh','backhoe','bobca','boom','bucke',
                 'bulld','cat','cate','forklift','front','hi-lo','hilow','lull','paylo','skid')
                THEN 'Construction Equipment'

            WHEN UPPER(TRIM(CAST(vehicle_type_code_4 AS STRING))) LIKE '%SNOW PLOW%'
              OR UPPER(TRIM(CAST(vehicle_type_code_4 AS STRING))) LIKE '%SNOWPLOW%'
              OR UPPER(TRIM(CAST(vehicle_type_code_4 AS STRING))) LIKE '%STREET SWE%'
              OR UPPER(TRIM(CAST(vehicle_type_code_4 AS STRING))) LIKE '%ROAD SWEEP%'
              OR UPPER(TRIM(CAST(vehicle_type_code_4 AS STRING))) LIKE '%SWEEPER%'
              OR UPPER(TRIM(CAST(vehicle_type_code_4 AS STRING))) IN ('PLOW','PLOW TRUCK','BROOM','SALT','SALTSPREAD',
                 'ROAD','ROADS','STREE','STREET CLE','STREET SWE','SWEEP','SWEPE','SWT',
                 'DSNY SWEEP','ROAD SWEEP','RD BLDNG M','Plow  truc','Plow truck','Road Sweep',
                 'Road sweep','Street Cle','Street Swe','Street swe','Sweep','Sweeper','dsny sweep',
                 'road sweep','salt','street cle','street swe','sweep','sweeper')
                THEN 'Plow/Sweeper'

            WHEN UPPER(TRIM(CAST(vehicle_type_code_4 AS STRING))) LIKE '%TANKER%'
              OR UPPER(TRIM(CAST(vehicle_type_code_4 AS STRING))) LIKE '%CEMENT MIX%'
              OR UPPER(TRIM(CAST(vehicle_type_code_4 AS STRING))) LIKE '%CONCRETE M%'
              OR UPPER(TRIM(CAST(vehicle_type_code_4 AS STRING))) IN ('TANK','TANK TRUCK','TANK WH','TANKE','OIL T',
                 'OIL TANKER','CONCR','CMIX','CMIXER','CEMENT TRU','CEMEN',
                 'Tank','Tank truck','Tanker','Oil Tanker','Cement Tru','Cement tru',
                 'Concrete Mixer','cemen','concr','tank')
                THEN 'Tank/Cement Truck'

            WHEN UPPER(TRIM(CAST(vehicle_type_code_4 AS STRING))) LIKE '%GOLF CART%'
              OR UPPER(TRIM(CAST(vehicle_type_code_4 AS STRING))) LIKE '%GOLF CAR%'
              OR UPPER(TRIM(CAST(vehicle_type_code_4 AS STRING))) LIKE '%GOLFCART%'
              OR UPPER(TRIM(CAST(vehicle_type_code_4 AS STRING))) LIKE '%GATOR%'
              OR UPPER(TRIM(CAST(vehicle_type_code_4 AS STRING))) IN ('ATV','UTV','QUAD','GOLF','GO KART','GOLF KART',
                 'All-Terrain Vehicle','Gator','Gator 4x4','Golf','Golf Cart','Golf cart',
                 'Go kart','Quadricycl','atv p','gokar','golf','golf cart','gator','utv bobcat')
                THEN 'Golf Cart/ATV'

            WHEN UPPER(TRIM(CAST(vehicle_type_code_4 AS STRING))) LIKE '%MOTOR HOME%'
              OR UPPER(TRIM(CAST(vehicle_type_code_4 AS STRING))) LIKE '%MOTORHOME%'
              OR UPPER(TRIM(CAST(vehicle_type_code_4 AS STRING))) LIKE '%WINNEBA%'
              OR UPPER(TRIM(CAST(vehicle_type_code_4 AS STRING))) LIKE '%CAMPER%'
              OR UPPER(TRIM(CAST(vehicle_type_code_4 AS STRING))) IN ('RV','R/V','MTR H','RV/VAN','RV/Tr','RV motorho',
                 'MOTORIZED HOME','Motorized Home','Rec Vehicl','winne','Motorhome','motorhome')
                THEN 'RV/Motorhome'

            WHEN UPPER(TRIM(CAST(vehicle_type_code_4 AS STRING))) LIKE '%HORSE%'
              OR UPPER(TRIM(CAST(vehicle_type_code_4 AS STRING))) IN ('HRSE','HOSRE','HOSRE DRAW','HURSE',
                 'Horse','Horse Carr','Horse Trai','Horse carr','Horse trai','Hrse','horse','hrse')
                THEN 'Horse Carriage'

            WHEN UPPER(TRIM(CAST(vehicle_type_code_4 AS STRING))) LIKE '%NYPD%'
              OR UPPER(TRIM(CAST(vehicle_type_code_4 AS STRING))) LIKE '%POLICE%'
              OR UPPER(TRIM(CAST(vehicle_type_code_4 AS STRING))) IN ('RMP','R.M.P.','ESU','ESU T','ESU REP','ESU RESCUE',
                 'MARKED RMP','MARKED VAN','F550 ESU R','NYPD RMP','NYPD ESU T',
                 'Rmp','rmp','Nypd','nypd','police van','police veh','Polic','polic')
                THEN 'Police Vehicle'

            WHEN UPPER(TRIM(CAST(vehicle_type_code_4 AS STRING))) IN (
                    'SEDAN','PASSENGER','PASSENGER VEHICLE','PASS','COUPE',
                    '2 DR','2DR','4 DOOR','4DR','4 DR SEDAN','2 DR SEDAN',
                    '4D','4DS','4SEDN','4door','4dsd','2 DOO','2 DR','2 doo',
                    'BMW','DODGE','DODGE RAM','RAM','CHEVY','CHEVROLET','CHEVR',
                    'GMC','NISSAN','NISSA','TOYOTA','TOYOT','MERCEDES',
                    'VOLVO','ACUR','ASTRO','SONATA','SIERRA','RIDGELINE',
                    'JEEP','AUDI','HYUND','IMPAL','FORD','CHEV','CHVEY',
                    'SMART','SMART CAR','FUSION','DODGE','RAM PRM','RAM COMM.',
                    'HERTZ RAM','HONDA HRV','MINI','ARIEL','ARCIMOTO',
                    'Dodge','Dodge ram','Jeep','Ram','Ram Promas','Smart',
                    'Chevr','Chevy','Ford','Gmc pick u','Gmc savann','Nissan',
                    'Supercab','Ridgeline','ford','chevy','dodge','toyota','nissan','bmw','jeep','volvo'
                )
              OR UPPER(TRIM(CAST(vehicle_type_code_4 AS STRING))) LIKE '%PASSENGER%'
              OR UPPER(TRIM(CAST(vehicle_type_code_4 AS STRING))) LIKE '%CHEVROLET%'
              OR UPPER(TRIM(CAST(vehicle_type_code_4 AS STRING))) LIKE '%DODGE%'
              OR UPPER(TRIM(CAST(vehicle_type_code_4 AS STRING))) LIKE '%TOYOTA%'
              OR UPPER(TRIM(CAST(vehicle_type_code_4 AS STRING))) LIKE '%NISSAN%'
                THEN 'Passenger Vehicle'

            WHEN UPPER(TRIM(CAST(vehicle_type_code_4 AS STRING))) IN (
                    'UNKNOWN','UNKNOW','UNKNO','UNKNW','UNKOWN','UNKWN','UNKWOWN',
                    'UNK','UNKN','UK','UKN','UKNOWN','UNNKO','UNNOWN','UNKNW','UNKOW',
                    'UNKOWM','UNKOWN','UNKWN','UKNOWN','UNKNO','UNKNW','UNKN',
                    'N/A','NA','N/a','NONE','NULL','0','00','000','0000','00000',
                    '00000','-','.','','?','A','B','C','D','E3','G1','H1','J1','L1',
                    'None','none','na','n/a','unk','unkn','unkno','unknown','unkow','unkown',
                    'UK','UKN','UKNOWN','UNK/L','UNL','UNNKO','UNNOWN',
                    '1','2','4','5','7','197209','2000','2003','263','787',
                    '9999','99999','0','00','000','13','17','430','985','994','997','999',
                    'NTTRL','YNK','YPS','-','.',',','omm'
                )
                THEN 'Unknown'
            WHEN vehicle_type_code_4 IS NULL THEN NULL
            ELSE 'Other'
        END AS vehicle_type_4,

        CASE
            WHEN UPPER(TRIM(CAST(vehicle_type_code_5 AS STRING))) LIKE '%AMBULAN%'
              OR UPPER(TRIM(CAST(vehicle_type_code_5 AS STRING))) LIKE '%AMBUL%'
              OR UPPER(TRIM(CAST(vehicle_type_code_5 AS STRING))) IN ('AMB','AMBU','AMBUL','EAMB','E AMB','G AMB','NS AM','X AMB',
                 'EMS','EMS AMBULA','EMS AMBULE','EMT','EMT AMBULA','FDNY EMT',
                 'NYS AMBULA','REG.AMBULA','PRIV AMBUL','GEN  AMBUL','FORD AMBUL',
                 'FD AMBULAN','EMBULANCE','EMERGANCY','EMERGENCY','A bulance',
                 'abulance','almbulance','amdu','amulance','anbul','AMUBL','AMUBULANCE')
                THEN 'Ambulance'

            WHEN UPPER(TRIM(CAST(vehicle_type_code_5 AS STRING))) LIKE '%FDNY%'
              OR UPPER(TRIM(CAST(vehicle_type_code_5 AS STRING))) LIKE '%FIRETRUCK%'
              OR UPPER(TRIM(CAST(vehicle_type_code_5 AS STRING))) LIKE '%FIRE TRUCK%'
              OR UPPER(TRIM(CAST(vehicle_type_code_5 AS STRING))) LIKE '%FIRE APPAR%'
              OR UPPER(TRIM(CAST(vehicle_type_code_5 AS STRING))) LIKE '%FIRE ENG%'
              OR UPPER(TRIM(CAST(vehicle_type_code_5 AS STRING))) LIKE '%FIRE DEPT%'
              OR UPPER(TRIM(CAST(vehicle_type_code_5 AS STRING))) LIKE '%FIRE LADD%'
              OR UPPER(TRIM(CAST(vehicle_type_code_5 AS STRING))) LIKE '%FIRET%'
              OR UPPER(TRIM(CAST(vehicle_type_code_5 AS STRING))) LIKE '%FD TR%'
              OR UPPER(TRIM(CAST(vehicle_type_code_5 AS STRING))) LIKE '%FD EN%'
              OR UPPER(TRIM(CAST(vehicle_type_code_5 AS STRING))) LIKE '%FD LA%'
              OR UPPER(TRIM(CAST(vehicle_type_code_5 AS STRING))) IN ('FIRE','FIRE RUCK','FIRER','FIRTRUCK','FIRETURCK','FNDY EMS','FDNYLadder','FDNYTRUCKF')
                THEN 'Fire Apparatus'

            WHEN UPPER(TRIM(CAST(vehicle_type_code_5 AS STRING))) LIKE '%SCHOOL BUS%'
              OR UPPER(TRIM(CAST(vehicle_type_code_5 AS STRING))) LIKE '%SCHOOLBUS%'
              OR UPPER(TRIM(CAST(vehicle_type_code_5 AS STRING))) LIKE '%SCHOOL VAN%'
              OR UPPER(TRIM(CAST(vehicle_type_code_5 AS STRING))) IN ('YELLOW BUS','YELLOWBUS','YW SCHOOL','SMYELLSCHO',
                 'SHORT SCHO','MINI SCHOO','SM YW','YLL P','SHCOO','SCHOO','SCHOO LBUS',
                 'SCHOOL  BU','Yellow bus','Yellow sch','Small Bus','Small scho','Short Bus')
                THEN 'School Bus'

            WHEN UPPER(TRIM(CAST(vehicle_type_code_5 AS STRING))) LIKE '%MTA BUS%'
              OR UPPER(TRIM(CAST(vehicle_type_code_5 AS STRING))) LIKE '%CITY BUS%'
              OR UPPER(TRIM(CAST(vehicle_type_code_5 AS STRING))) LIKE '%TRANSIT%'
              OR UPPER(TRIM(CAST(vehicle_type_code_5 AS STRING))) LIKE '%OMNIBUS%'
              OR UPPER(TRIM(CAST(vehicle_type_code_5 AS STRING))) IN ('BUS','BUSS','TOUR BUS','SHUTTLE BU','MINI BUS',
                 'COACH','NICE BUS','BLU BUS','BUS M','BUs','ORION','NEW FLYER','LIVERY BUS','Livery Omn','Livery Bus')
                THEN 'Bus'

            WHEN UPPER(TRIM(CAST(vehicle_type_code_5 AS STRING))) LIKE '%TAXI%'
              OR UPPER(TRIM(CAST(vehicle_type_code_5 AS STRING))) LIKE '%YELLOW CAB%'
              OR UPPER(TRIM(CAST(vehicle_type_code_5 AS STRING))) IN ('YELLO','DOLLAR VAN','PETIT CAB','Yellow Cab','Yellow cab')
                THEN 'Taxi'

            WHEN UPPER(TRIM(CAST(vehicle_type_code_5 AS STRING))) LIKE '%LIVERY%'
              OR UPPER(TRIM(CAST(vehicle_type_code_5 AS STRING))) LIKE '%MEDALLION%'
              OR UPPER(TRIM(CAST(vehicle_type_code_5 AS STRING))) LIKE '%TLC%'
                THEN 'Livery/TLC'

            WHEN UPPER(TRIM(CAST(vehicle_type_code_5 AS STRING))) LIKE '%LIMO%'
                THEN 'Limousine'

            WHEN UPPER(TRIM(CAST(vehicle_type_code_5 AS STRING))) LIKE '%USPS%'
              OR UPPER(TRIM(CAST(vehicle_type_code_5 AS STRING))) LIKE '%US POSTAL%'
              OR UPPER(TRIM(CAST(vehicle_type_code_5 AS STRING))) LIKE '%US MAIL%'
              OR UPPER(TRIM(CAST(vehicle_type_code_5 AS STRING))) LIKE '%POSTAL%'
              OR UPPER(TRIM(CAST(vehicle_type_code_5 AS STRING))) LIKE '%MAIL TRUCK%'
              OR UPPER(TRIM(CAST(vehicle_type_code_5 AS STRING))) LIKE '%MAILTRUCK%'
              OR UPPER(TRIM(CAST(vehicle_type_code_5 AS STRING))) IN ('LLV','LLV MAIL T','U.S. POSTA','U.S.P','US PO','US Po')
                THEN 'Postal/Mail'

            WHEN UPPER(TRIM(CAST(vehicle_type_code_5 AS STRING))) LIKE '%FEDEX%'
              OR UPPER(TRIM(CAST(vehicle_type_code_5 AS STRING))) LIKE '%FED EX%'
              OR UPPER(TRIM(CAST(vehicle_type_code_5 AS STRING))) LIKE '%AMAZON%'
              OR UPPER(TRIM(CAST(vehicle_type_code_5 AS STRING))) LIKE '%DHL%'
              OR UPPER(TRIM(CAST(vehicle_type_code_5 AS STRING))) LIKE '%DELIVERY%'
              OR UPPER(TRIM(CAST(vehicle_type_code_5 AS STRING))) LIKE '%DELIV%'
              OR UPPER(TRIM(CAST(vehicle_type_code_5 AS STRING))) LIKE '%COURIER%'
              OR UPPER(TRIM(CAST(vehicle_type_code_5 AS STRING))) IN ('UPS','UPS T','UPS VAN','UPS M','DLEV','DLVR','DELV','DELVR','DEL','DEL T')
                THEN 'Delivery Vehicle'

            WHEN UPPER(TRIM(CAST(vehicle_type_code_5 AS STRING))) LIKE '%U-HAUL%'
              OR UPPER(TRIM(CAST(vehicle_type_code_5 AS STRING))) LIKE '%UHAUL%'
              OR UPPER(TRIM(CAST(vehicle_type_code_5 AS STRING))) LIKE '%U HAUL%'
              OR UPPER(TRIM(CAST(vehicle_type_code_5 AS STRING))) LIKE '%UHUAL%'
              OR UPPER(TRIM(CAST(vehicle_type_code_5 AS STRING))) IN ('RYDER','PENSKE BOX','U-TRU','UHAL','UHAL TRUCK')
                THEN 'Rental Truck'

            WHEN UPPER(TRIM(CAST(vehicle_type_code_5 AS STRING))) LIKE '%PICKUP%'
              OR UPPER(TRIM(CAST(vehicle_type_code_5 AS STRING))) LIKE '%PICK UP%'
              OR UPPER(TRIM(CAST(vehicle_type_code_5 AS STRING))) LIKE '%PICK-UP%'
              OR UPPER(TRIM(CAST(vehicle_type_code_5 AS STRING))) IN ('PU','PICKU','PK','PKUP','P/U','PICK','PICK-')
                THEN 'Pickup Truck'

            WHEN UPPER(TRIM(CAST(vehicle_type_code_5 AS STRING))) LIKE '%BOX TRUCK%'
              OR UPPER(TRIM(CAST(vehicle_type_code_5 AS STRING))) LIKE '%BOXTRUCK%'
              OR UPPER(TRIM(CAST(vehicle_type_code_5 AS STRING))) IN ('BOX T','BOXTR','BOX VAN','BOX CAR','BOX CARGO','BOX','BOX H','EMPTYBOX T')
                THEN 'Box Truck'

            WHEN UPPER(TRIM(CAST(vehicle_type_code_5 AS STRING))) LIKE '%FLATBED%'
              OR UPPER(TRIM(CAST(vehicle_type_code_5 AS STRING))) LIKE '%FLAT BED%'
              OR UPPER(TRIM(CAST(vehicle_type_code_5 AS STRING))) IN ('FLAT','FLAT RACK','FLAT-','FLAT/','PLATF')
                THEN 'Flatbed Truck'

            WHEN UPPER(TRIM(CAST(vehicle_type_code_5 AS STRING))) LIKE '%TRACTOR TR%'
              OR UPPER(TRIM(CAST(vehicle_type_code_5 AS STRING))) LIKE '%SEMI TRUCK%'
              OR UPPER(TRIM(CAST(vehicle_type_code_5 AS STRING))) LIKE '%SEMI-TRUCK%'
              OR UPPER(TRIM(CAST(vehicle_type_code_5 AS STRING))) LIKE '%SEMI TRAIL%'
              OR UPPER(TRIM(CAST(vehicle_type_code_5 AS STRING))) LIKE '%FREIGHTLIN%'
              OR UPPER(TRIM(CAST(vehicle_type_code_5 AS STRING))) LIKE '%18 WHEEL%'
              OR UPPER(TRIM(CAST(vehicle_type_code_5 AS STRING))) LIKE '%18WHEEL%'
              OR UPPER(TRIM(CAST(vehicle_type_code_5 AS STRING))) IN ('SEMI','SEMI-','TRACTOR','MACK','KENWORTH T',
                 'FUSO TRUCK','18 WH','18 WHEELER','18 WEELER','18 WH','18 Wh',
                 'TRACTOR TRUCK DIESEL','TRACTOR TRUCK GASOLINE','MACK TRUCK','Mack Truck','Mack truck','Macktruck',
                 'FREIG','FRHT','FRT','FLTRL','LTRL','NTTRL','LCOM','LCOMM','SCOMM')
                THEN 'Tractor/Semi-Truck'

            WHEN UPPER(TRIM(CAST(vehicle_type_code_5 AS STRING))) LIKE '%DUMP TRUCK%'
              OR UPPER(TRIM(CAST(vehicle_type_code_5 AS STRING))) LIKE '%DUMP TR%'
              OR UPPER(TRIM(CAST(vehicle_type_code_5 AS STRING))) IN ('DUMP','DUMPT','DUMPTRUCK','DUMP TRUK','DUMPS','DUMPSTER','DUMPSTER T','DUMPTRUCK')
                THEN 'Dump Truck'

            WHEN UPPER(TRIM(CAST(vehicle_type_code_5 AS STRING))) LIKE '%SANITAT%'
              OR UPPER(TRIM(CAST(vehicle_type_code_5 AS STRING))) LIKE '%DSNY%'
              OR UPPER(TRIM(CAST(vehicle_type_code_5 AS STRING))) LIKE '%GARBAGE%'
              OR UPPER(TRIM(CAST(vehicle_type_code_5 AS STRING))) LIKE '%REFUSE%'
              OR UPPER(TRIM(CAST(vehicle_type_code_5 AS STRING))) LIKE '%WASTE TR%'
              OR UPPER(TRIM(CAST(vehicle_type_code_5 AS STRING))) IN ('SANAT','SANTI','SANMEN COU','SANIT','Garbage or Refuse',
                 'sanitaion','sanitaton','santiation','santa','Solid wast')
                THEN 'Sanitation/Garbage'

            WHEN UPPER(TRIM(CAST(vehicle_type_code_5 AS STRING))) LIKE '%TOW TRUCK%'
              OR UPPER(TRIM(CAST(vehicle_type_code_5 AS STRING))) LIKE '%TOWTRUCK%'
              OR UPPER(TRIM(CAST(vehicle_type_code_5 AS STRING))) LIKE '%TOW-TRUCK%'
              OR UPPER(TRIM(CAST(vehicle_type_code_5 AS STRING))) LIKE '%WRECKER%'
              OR UPPER(TRIM(CAST(vehicle_type_code_5 AS STRING))) IN ('TOW T','TOWTR','TOW R','TOW TRICK','TOWE','TOWIN','TOWMA',
                 'Tow Truck / Wrecker','Tow t','Tow-t','PICKUP TOW','PICKUP-TOW','X TOW','G TOW','E TOW')
                THEN 'Tow Truck'

            WHEN UPPER(TRIM(CAST(vehicle_type_code_5 AS STRING))) LIKE '%FOOD TRUCK%'
              OR UPPER(TRIM(CAST(vehicle_type_code_5 AS STRING))) LIKE '%FOOD CART%'
              OR UPPER(TRIM(CAST(vehicle_type_code_5 AS STRING))) LIKE '%FOOD TRAIL%'
              OR UPPER(TRIM(CAST(vehicle_type_code_5 AS STRING))) IN ('FOOD','FOOD VENDE','FOOD DELIV','HOTDO','LUNCH WAGON','VENDOR CHA','VENDOR FOO','Mobile foo','Small Food')
                THEN 'Food Truck/Cart'

            WHEN UPPER(TRIM(CAST(vehicle_type_code_5 AS STRING))) LIKE '%SPRINTER%'
              OR UPPER(TRIM(CAST(vehicle_type_code_5 AS STRING))) LIKE '%ECONOLINE%'
              OR UPPER(TRIM(CAST(vehicle_type_code_5 AS STRING))) LIKE '%MINIVAN%'
              OR UPPER(TRIM(CAST(vehicle_type_code_5 AS STRING))) LIKE '%MINI VAN%'
              OR UPPER(TRIM(CAST(vehicle_type_code_5 AS STRING))) LIKE '%CARGO VAN%'
              OR UPPER(TRIM(CAST(vehicle_type_code_5 AS STRING))) LIKE '%TRANSIT VA%'
              OR UPPER(TRIM(CAST(vehicle_type_code_5 AS STRING))) IN ('VAN','VAM','VANT','VANG','VAN`','VAV','VANET','VAN/T',
                 'VAN T','VAN C','VAN W','VAN A','VAN/B','VAN/TRUCK','VAN TRUCK',
                 'PASS VAN','COM VAN','COMM VAN','CARGO VAN','CHEVY VAN','FORD VAN','GMC VAN',
                 'PANEL VAN','SAVANA VAN','SAVANA','SPRIN','SPR','PROMASTER','ECONO',
                 'ECOLINE VA','ECONOLINE','CHEVY EXPR','MINIV','MINI VAHN',
                 'Van','Van T','Van truck','Van/Truck','Vanette','Cargo Van','Cargo van')
                THEN 'Van/Minivan'

            WHEN UPPER(TRIM(CAST(vehicle_type_code_5 AS STRING))) LIKE '%SUV%'
              OR UPPER(TRIM(CAST(vehicle_type_code_5 AS STRING))) LIKE '%SUBURBAN%'
              OR UPPER(TRIM(CAST(vehicle_type_code_5 AS STRING))) LIKE '%SPORT UTIL%'
              OR UPPER(TRIM(CAST(vehicle_type_code_5 AS STRING))) LIKE '%STATION WAG%'
              OR UPPER(TRIM(CAST(vehicle_type_code_5 AS STRING))) IN ('SW','SW/SUV','SW/VAN','SPORT UTILITY / STATION WAGON',
                 'SURBURBAN','SUBN','SUBUR','SUBR','SYBN','SBN','WUBN','Station Wagon/Sport Utility Vehicle',
                 'Subn','Subur','Surburban','Suv','SUDAN','SUDN','HIGHL','SEDONA','SIERRA','SENIORCARE')
                THEN 'SUV/Station Wagon'

            WHEN UPPER(TRIM(CAST(vehicle_type_code_5 AS STRING))) LIKE '%MOTORCYCLE%'
              OR UPPER(TRIM(CAST(vehicle_type_code_5 AS STRING))) LIKE '%MOTORBIKE%'
              OR UPPER(TRIM(CAST(vehicle_type_code_5 AS STRING))) IN ('MC','MCY','MCR','MCY B','MOT','MNI-MOTORC',
                 'MINICYCLE','MINIBIKE','MOTOR','ELE MOTORC','ELEC. UNIC','MOTOR UNIC',
                 'Motorbike','Motorcycle','Motorscooter','MOTORSCOOT','MOTO-SCOOT')
                THEN 'Motorcycle'

            WHEN UPPER(TRIM(CAST(vehicle_type_code_5 AS STRING))) LIKE '%MOPED%'
              OR UPPER(TRIM(CAST(vehicle_type_code_5 AS STRING))) LIKE '%MOPAD%'
              OR UPPER(TRIM(CAST(vehicle_type_code_5 AS STRING))) IN ('MOPD','MOPET','MOPPED','MOPEN','MOPER','MOPOED',
                 'MO PED','MO-PED','MO PE','MOOPER','MOP','GAS MO-PED','GAS MOPED',
                 'MOped','Moped','Moped bike','Moped clas','Moped elec','Mopen','Moper','Mopoed','Mopped')
                THEN 'Moped'

            WHEN UPPER(TRIM(CAST(vehicle_type_code_5 AS STRING))) LIKE '%E-BIKE%'
              OR UPPER(TRIM(CAST(vehicle_type_code_5 AS STRING))) LIKE '%E BIKE%'
              OR UPPER(TRIM(CAST(vehicle_type_code_5 AS STRING))) LIKE '%EBIKE%'
              OR UPPER(TRIM(CAST(vehicle_type_code_5 AS STRING))) LIKE '%ELECTRIC BIKE%'
              OR UPPER(TRIM(CAST(vehicle_type_code_5 AS STRING))) LIKE '%ELECTRIC B%'
              OR UPPER(TRIM(CAST(vehicle_type_code_5 AS STRING))) IN ('E BIK','E-BIK','E/BIK','ECOM','E COM',
                 'UNI E-BIKE','E- BI','E- MOTOR B','E1','Ebike','ebike','e bik','e bike','e-bik','e-bike',
                 'E BIKE NO PLATE','E-BIKE NO','ELECTRIC M','ELEC','ELECT')
                THEN 'E-Bike'

            WHEN UPPER(TRIM(CAST(vehicle_type_code_5 AS STRING))) LIKE '%E-SCOOTER%'
              OR UPPER(TRIM(CAST(vehicle_type_code_5 AS STRING))) LIKE '%E SCOOTER%'
              OR UPPER(TRIM(CAST(vehicle_type_code_5 AS STRING))) LIKE '%ESCOOTER%'
              OR UPPER(TRIM(CAST(vehicle_type_code_5 AS STRING))) LIKE '%REVEL%'
              OR UPPER(TRIM(CAST(vehicle_type_code_5 AS STRING))) LIKE '%LIME SCOOT%'
              OR UPPER(TRIM(CAST(vehicle_type_code_5 AS STRING))) LIKE '%NINEBOT%'
              OR UPPER(TRIM(CAST(vehicle_type_code_5 AS STRING))) IN ('E SCO','E-SCO','E- SCOOTER','ESCOO',
                 'MOTOR SCOO','MOTOR SKAT','MOTORIZED','MOTORIZEDS',
                 'E REVEL SCO','SPARK150 S','BEYOND SCO','RIDE ON SC',
                 'e sco','e scooter','e-scooter','eScoo','escooter','Escooter')
                THEN 'E-Scooter'

            WHEN UPPER(TRIM(CAST(vehicle_type_code_5 AS STRING))) LIKE '%SCOOTER%'
              OR UPPER(TRIM(CAST(vehicle_type_code_5 AS STRING))) IN ('SCL','SCOM','SCOOT','SCOO','GAS SCOOTE','GAS S',
                 'GAS PWR SC','VESPA','SCOOTOR','SCOTTER','SCOMM','GAS SCOOTER (G',
                 'SEATED SCO','STAND UP S','STANDUP SC','STANDING S','PUSH SCOOT',
                 'KICK SCOOT','RAZOR SCOO','MANUAL SCO','BLACK SCOO','RED SCOOTE',
                 'Scooter','Scoot','scoot','scooter','Kick scoot','Push scoot','Razor scoo',
                 'Seated sco','Stand Up S','Stand up s','Stand-up S','Standing S','Standing s')
                THEN 'Scooter (Gas)'

            WHEN UPPER(TRIM(CAST(vehicle_type_code_5 AS STRING))) LIKE '%BICYCLE%'
              OR UPPER(TRIM(CAST(vehicle_type_code_5 AS STRING))) LIKE '%BICYC%'
              OR UPPER(TRIM(CAST(vehicle_type_code_5 AS STRING))) IN ('BIKE','CITIBIKE','PEDAL BIKE','GAS BICYCL',
                 'GAS BIKE','Bicycle','Bicyc','Bike','Citi bike','Gas bicycl','Gas bike','bicycle','bike')
                THEN 'Bicycle'

            WHEN UPPER(TRIM(CAST(vehicle_type_code_5 AS STRING))) LIKE '%DIRT BIKE%'
              OR UPPER(TRIM(CAST(vehicle_type_code_5 AS STRING))) LIKE '%DIRTBIKE%'
              OR UPPER(TRIM(CAST(vehicle_type_code_5 AS STRING))) IN ('DIRT','DIRTB','DIRT-','Dart bike','Dirt Bike','Dirt bike','dirtbike','dirt bike')
                THEN 'Dirt Bike'

            WHEN UPPER(TRIM(CAST(vehicle_type_code_5 AS STRING))) LIKE '%SKATEBOARD%'
              OR UPPER(TRIM(CAST(vehicle_type_code_5 AS STRING))) LIKE '%HOVERBOARD%'
              OR UPPER(TRIM(CAST(vehicle_type_code_5 AS STRING))) LIKE '%E-SKATEBO%'
              OR UPPER(TRIM(CAST(vehicle_type_code_5 AS STRING))) LIKE '%E SKATEBOA%'
              OR UPPER(TRIM(CAST(vehicle_type_code_5 AS STRING))) IN ('SKATE','ROLLERBLAD','IN LINE SK','SKATBOARD',
                 'E SKATEBOA','E-SKATEBOA','E-SKA','MOTOR SKAT','EvolveSkat',
                 'Skate','Skate boar','Skateboard','skate','skateboard','e skate bo','e-skateboa')
                THEN 'Skateboard/Hoverboard'

            WHEN UPPER(TRIM(CAST(vehicle_type_code_5 AS STRING))) LIKE '%WHEELCHAIR%'
              OR UPPER(TRIM(CAST(vehicle_type_code_5 AS STRING))) LIKE '%ACCESS-A-R%'
              OR UPPER(TRIM(CAST(vehicle_type_code_5 AS STRING))) LIKE '%ACCESS A R%'
              OR UPPER(TRIM(CAST(vehicle_type_code_5 AS STRING))) LIKE '%MOBILITY%'
              OR UPPER(TRIM(CAST(vehicle_type_code_5 AS STRING))) LIKE '%ACCES%'
              OR UPPER(TRIM(CAST(vehicle_type_code_5 AS STRING))) IN ('WC','WHEEL','E Wheelcha','APPOR','APPORTIONE','APORT',
                 'ACCESS-A-','ACCESS-ARI','ACCEE','ACCESS RID',
                 'Acces','Access A R','Access a R','Access-A-R','Apportione',
                 'Handicap S','Motor whee','Mobility S','MOBILTY SC','MOBILITY S')
                THEN 'Wheelchair/Mobility'

            WHEN UPPER(TRIM(CAST(vehicle_type_code_5 AS STRING))) LIKE '%BACKHOE%'
              OR UPPER(TRIM(CAST(vehicle_type_code_5 AS STRING))) LIKE '%EXCAVAT%'
              OR UPPER(TRIM(CAST(vehicle_type_code_5 AS STRING))) LIKE '%ESCAVAT%'
              OR UPPER(TRIM(CAST(vehicle_type_code_5 AS STRING))) LIKE '%BULLDOZ%'
              OR UPPER(TRIM(CAST(vehicle_type_code_5 AS STRING))) LIKE '%FORKLIFT%'
              OR UPPER(TRIM(CAST(vehicle_type_code_5 AS STRING))) LIKE '%FORK LIFT%'
              OR UPPER(TRIM(CAST(vehicle_type_code_5 AS STRING))) LIKE '%BOBCAT%'
              OR UPPER(TRIM(CAST(vehicle_type_code_5 AS STRING))) LIKE '%CRANE%'
              OR UPPER(TRIM(CAST(vehicle_type_code_5 AS STRING))) LIKE '%PAYLOAD%'
              OR UPPER(TRIM(CAST(vehicle_type_code_5 AS STRING))) LIKE '%SKID LOAD%'
              OR UPPER(TRIM(CAST(vehicle_type_code_5 AS STRING))) LIKE '%SKID STEER%'
              OR UPPER(TRIM(CAST(vehicle_type_code_5 AS STRING))) LIKE '%FRONT END%'
              OR UPPER(TRIM(CAST(vehicle_type_code_5 AS STRING))) LIKE '%FRONT LOAD%'
              OR UPPER(TRIM(CAST(vehicle_type_code_5 AS STRING))) LIKE '%BOOM LIFT%'
              OR UPPER(TRIM(CAST(vehicle_type_code_5 AS STRING))) LIKE '%CATERPILLA%'
              OR UPPER(TRIM(CAST(vehicle_type_code_5 AS STRING))) LIKE '%KOMATSU%'
              OR UPPER(TRIM(CAST(vehicle_type_code_5 AS STRING))) IN ('BACK HOE','BACKH','BKHOE','HOE-L','LOADE',
                 'BUCKE','BUDGE','BULDOZER','BULL DOZER','BULLD','FORK','FORK-','FORKL',
                 'CAT','CAT 4','CATER','CATIP','CAT.','CASE','COMPACT LO','SKID','SKID-',
                 'SKIDSTEERL','LULL','FOGLIT','FOLK LIFT','HI LO','HI-LO','HILOW',
                 'Backhoe','Backh','Bobcat','Boom','Boom Lift','Bucke','Bucket Tru','Bucket tru',
                 'Bulldozer','Bull dozer','Cater','Caterpilla','Comp skid','Excav','Excavator',
                 'Escavator','Fork','Fork Lift','Fork lift','Forkl','Forklift','Front End',
                 'Front load','Front-Load','Hyster For','Liebh','Lift','Loade','Paylo','Skid','Skid steer',
                 'Swingloade','Telehandle','back ho','backh','backhoe','bobca','boom','bucke',
                 'bulld','cat','cate','forklift','front','hi-lo','hilow','lull','paylo','skid')
                THEN 'Construction Equipment'

            WHEN UPPER(TRIM(CAST(vehicle_type_code_5 AS STRING))) LIKE '%SNOW PLOW%'
              OR UPPER(TRIM(CAST(vehicle_type_code_5 AS STRING))) LIKE '%SNOWPLOW%'
              OR UPPER(TRIM(CAST(vehicle_type_code_5 AS STRING))) LIKE '%STREET SWE%'
              OR UPPER(TRIM(CAST(vehicle_type_code_5 AS STRING))) LIKE '%ROAD SWEEP%'
              OR UPPER(TRIM(CAST(vehicle_type_code_5 AS STRING))) LIKE '%SWEEPER%'
              OR UPPER(TRIM(CAST(vehicle_type_code_5 AS STRING))) IN ('PLOW','PLOW TRUCK','BROOM','SALT','SALTSPREAD',
                 'ROAD','ROADS','STREE','STREET CLE','STREET SWE','SWEEP','SWEPE','SWT',
                 'DSNY SWEEP','ROAD SWEEP','RD BLDNG M','Plow  truc','Plow truck','Road Sweep',
                 'Road sweep','Street Cle','Street Swe','Street swe','Sweep','Sweeper','dsny sweep',
                 'road sweep','salt','street cle','street swe','sweep','sweeper')
                THEN 'Plow/Sweeper'

            WHEN UPPER(TRIM(CAST(vehicle_type_code_5 AS STRING))) LIKE '%TANKER%'
              OR UPPER(TRIM(CAST(vehicle_type_code_5 AS STRING))) LIKE '%CEMENT MIX%'
              OR UPPER(TRIM(CAST(vehicle_type_code_5 AS STRING))) LIKE '%CONCRETE M%'
              OR UPPER(TRIM(CAST(vehicle_type_code_5 AS STRING))) IN ('TANK','TANK TRUCK','TANK WH','TANKE','OIL T',
                 'OIL TANKER','CONCR','CMIX','CMIXER','CEMENT TRU','CEMEN',
                 'Tank','Tank truck','Tanker','Oil Tanker','Cement Tru','Cement tru',
                 'Concrete Mixer','cemen','concr','tank')
                THEN 'Tank/Cement Truck'

            WHEN UPPER(TRIM(CAST(vehicle_type_code_5 AS STRING))) LIKE '%GOLF CART%'
              OR UPPER(TRIM(CAST(vehicle_type_code_5 AS STRING))) LIKE '%GOLF CAR%'
              OR UPPER(TRIM(CAST(vehicle_type_code_5 AS STRING))) LIKE '%GOLFCART%'
              OR UPPER(TRIM(CAST(vehicle_type_code_5 AS STRING))) LIKE '%GATOR%'
              OR UPPER(TRIM(CAST(vehicle_type_code_5 AS STRING))) IN ('ATV','UTV','QUAD','GOLF','GO KART','GOLF KART',
                 'All-Terrain Vehicle','Gator','Gator 4x4','Golf','Golf Cart','Golf cart',
                 'Go kart','Quadricycl','atv p','gokar','golf','golf cart','gator','utv bobcat')
                THEN 'Golf Cart/ATV'

            WHEN UPPER(TRIM(CAST(vehicle_type_code_5 AS STRING))) LIKE '%MOTOR HOME%'
              OR UPPER(TRIM(CAST(vehicle_type_code_5 AS STRING))) LIKE '%MOTORHOME%'
              OR UPPER(TRIM(CAST(vehicle_type_code_5 AS STRING))) LIKE '%WINNEBA%'
              OR UPPER(TRIM(CAST(vehicle_type_code_5 AS STRING))) LIKE '%CAMPER%'
              OR UPPER(TRIM(CAST(vehicle_type_code_5 AS STRING))) IN ('RV','R/V','MTR H','RV/VAN','RV/Tr','RV motorho',
                 'MOTORIZED HOME','Motorized Home','Rec Vehicl','winne','Motorhome','motorhome')
                THEN 'RV/Motorhome'

            WHEN UPPER(TRIM(CAST(vehicle_type_code_5 AS STRING))) LIKE '%HORSE%'
              OR UPPER(TRIM(CAST(vehicle_type_code_5 AS STRING))) IN ('HRSE','HOSRE','HOSRE DRAW','HURSE',
                 'Horse','Horse Carr','Horse Trai','Horse carr','Horse trai','Hrse','horse','hrse')
                THEN 'Horse Carriage'

            WHEN UPPER(TRIM(CAST(vehicle_type_code_5 AS STRING))) LIKE '%NYPD%'
              OR UPPER(TRIM(CAST(vehicle_type_code_5 AS STRING))) LIKE '%POLICE%'
              OR UPPER(TRIM(CAST(vehicle_type_code_5 AS STRING))) IN ('RMP','R.M.P.','ESU','ESU T','ESU REP','ESU RESCUE',
                 'MARKED RMP','MARKED VAN','F550 ESU R','NYPD RMP','NYPD ESU T',
                 'Rmp','rmp','Nypd','nypd','police van','police veh','Polic','polic')
                THEN 'Police Vehicle'

            WHEN UPPER(TRIM(CAST(vehicle_type_code_5 AS STRING))) IN (
                    'SEDAN','PASSENGER','PASSENGER VEHICLE','PASS','COUPE',
                    '2 DR','2DR','4 DOOR','4DR','4 DR SEDAN','2 DR SEDAN',
                    '4D','4DS','4SEDN','4door','4dsd','2 DOO','2 DR','2 doo',
                    'BMW','DODGE','DODGE RAM','RAM','CHEVY','CHEVROLET','CHEVR',
                    'GMC','NISSAN','NISSA','TOYOTA','TOYOT','MERCEDES',
                    'VOLVO','ACUR','ASTRO','SONATA','SIERRA','RIDGELINE',
                    'JEEP','AUDI','HYUND','IMPAL','FORD','CHEV','CHVEY',
                    'SMART','SMART CAR','FUSION','DODGE','RAM PRM','RAM COMM.',
                    'HERTZ RAM','HONDA HRV','MINI','ARIEL','ARCIMOTO',
                    'Dodge','Dodge ram','Jeep','Ram','Ram Promas','Smart',
                    'Chevr','Chevy','Ford','Gmc pick u','Gmc savann','Nissan',
                    'Supercab','Ridgeline','ford','chevy','dodge','toyota','nissan','bmw','jeep','volvo'
                )
              OR UPPER(TRIM(CAST(vehicle_type_code_5 AS STRING))) LIKE '%PASSENGER%'
              OR UPPER(TRIM(CAST(vehicle_type_code_5 AS STRING))) LIKE '%CHEVROLET%'
              OR UPPER(TRIM(CAST(vehicle_type_code_5 AS STRING))) LIKE '%DODGE%'
              OR UPPER(TRIM(CAST(vehicle_type_code_5 AS STRING))) LIKE '%TOYOTA%'
              OR UPPER(TRIM(CAST(vehicle_type_code_5 AS STRING))) LIKE '%NISSAN%'
                THEN 'Passenger Vehicle'

            WHEN UPPER(TRIM(CAST(vehicle_type_code_5 AS STRING))) IN (
                    'UNKNOWN','UNKNOW','UNKNO','UNKNW','UNKOWN','UNKWN','UNKWOWN',
                    'UNK','UNKN','UK','UKN','UKNOWN','UNNKO','UNNOWN','UNKNW','UNKOW',
                    'UNKOWM','UNKOWN','UNKWN','UKNOWN','UNKNO','UNKNW','UNKN',
                    'N/A','NA','N/a','NONE','NULL','0','00','000','0000','00000',
                    '00000','-','.','','?','A','B','C','D','E3','G1','H1','J1','L1',
                    'None','none','na','n/a','unk','unkn','unkno','unknown','unkow','unkown',
                    'UK','UKN','UKNOWN','UNK/L','UNL','UNNKO','UNNOWN',
                    '1','2','4','5','7','197209','2000','2003','263','787',
                    '9999','99999','0','00','000','13','17','430','985','994','997','999',
                    'NTTRL','YNK','YPS','-','.',',','omm'
                )
                THEN 'Unknown'
            WHEN vehicle_type_code_5 IS NULL THEN NULL
            ELSE 'Other'
        END AS vehicle_type_5,

        -- Contributing factors
        CAST(contributing_factor_vehicle_1 AS STRING) AS contributing_factor_vehicle_1,
        CAST(contributing_factor_vehicle_2 AS STRING) AS contributing_factor_vehicle_2,
        CAST(contributing_factor_vehicle_3 AS STRING) AS contributing_factor_vehicle_3,
        CAST(contributing_factor_vehicle_4 AS STRING) AS contributing_factor_vehicle_4,
        CAST(contributing_factor_vehicle_5 AS STRING) AS contributing_factor_vehicle_5,

        -- Counts
        SAFE_CAST(number_of_persons_injured AS INT64) AS number_of_persons_injured,
        SAFE_CAST(number_of_persons_killed AS INT64) AS number_of_persons_killed,
        SAFE_CAST(number_of_pedestrians_injured AS INT64) AS number_of_pedestrians_injured,
        SAFE_CAST(number_of_pedestrians_killed AS INT64) AS number_of_pedestrians_killed,
        SAFE_CAST(number_of_cyclist_injured AS INT64) AS number_of_cyclist_injured,
        SAFE_CAST(number_of_cyclist_killed AS INT64) AS number_of_cyclist_killed,
        SAFE_CAST(number_of_motorist_injured AS INT64) AS number_of_motorist_injured,
        SAFE_CAST(number_of_motorist_killed AS INT64) AS number_of_motorist_killed,

        -- Metadata
        CURRENT_TIMESTAMP() AS _stg_loaded_at

    FROM source
    WHERE collision_id IS NOT NULL
      AND crash_date IS NOT NULL

    QUALIFY ROW_NUMBER() OVER (
        PARTITION BY collision_id
        ORDER BY DATE(SAFE_CAST(crash_date AS TIMESTAMP)) DESC
    ) = 1
)

SELECT *
FROM cleaned
