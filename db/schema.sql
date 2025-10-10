-- =============================================
--   TRIGGERS
-- =============================================

-- Function to update the updated_at column on row modification
CREATE OR REPLACE FUNCTION update_updated_at ()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql ;

-- =============================================
--   PRODUCT AND BRAND                         
-- =============================================

CREATE TABLE brand (
id SERIAL PRIMARY KEY,
name VARCHAR (255) NOT NULL UNIQUE,
created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
) ;

CREATE TABLE product (
id SERIAL PRIMARY KEY,
name VARCHAR (255) NOT NULL,
description TEXT,
brand_id INT,
created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,

FOREIGN KEY (brand_id) REFERENCES brand (id) ON DELETE SET NULL
) ;

CREATE TABLE product_price (
id SERIAL PRIMARY KEY,
product_id INT,
price DECIMAL (10, 2) NOT NULL,
valid_from DATE NOT NULL DEFAULT CURRENT_DATE,
valid_to DATE,

FOREIGN KEY (product_id) REFERENCES product (id) ON DELETE CASCADE
) ;

-- =============================================
--   LOCATION                                  
-- =============================================

CREATE TABLE location (
id SERIAL PRIMARY KEY,
name VARCHAR (255) NOT NULL UNIQUE,
address TEXT,
coordinates geography (POINT, 4326),
created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
) ;

-- =============================================
--   BUSINESS                                  
-- =============================================

CREATE TABLE business (
id SERIAL PRIMARY KEY,
name VARCHAR (255) NOT NULL UNIQUE,
created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
) ;

-- =============================================
--   BENEFICIARY                               
-- =============================================

-- Relationship with an entity (cousin, sibling, etc.)
CREATE TABLE relationship (
id SERIAL PRIMARY KEY,
name VARCHAR (255) NOT NULL UNIQUE,
created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
) ;

-- Entities can be both individuals or objects. For example, a car or a house can be considered an entity.
CREATE TABLE entity (
id SERIAL PRIMARY KEY,
name VARCHAR (255) NOT NULL,
created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
) ;

-- Multiple relationships can be associated with an entity, for example, a family member
-- can be both part of "family" and "cousin" relationships.
CREATE TABLE relationship_entity (
relationship_id INT,
entity_id INT,
CONSTRAINT id PRIMARY KEY (relationship_id, entity_id),

FOREIGN KEY (relationship_id) REFERENCES relationship (id) ON DELETE CASCADE,
FOREIGN KEY (entity_id) REFERENCES entity (id) ON DELETE CASCADE
) ;

-- =============================================
--   OCCASION                                  
-- =============================================

CREATE TABLE occasion (
id SERIAL PRIMARY KEY,
short_name VARCHAR (100) NOT NULL UNIQUE,
description TEXT,
date DATE NULL,
created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
) ;

-- =============================================
--   TRANSACTION                               
-- =============================================

CREATE TABLE category (
id SERIAL PRIMARY KEY,
slug VARCHAR (100) NOT NULL UNIQUE,
name VARCHAR (255),
created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
) ;

-- Periodicity for recurring transactions (in the form of CRON expressions)
CREATE TABLE periodicity (
id SERIAL PRIMARY KEY,
minute INT CHECK (minute BETWEEN 0 AND 59),
hour INT CHECK (hour BETWEEN 0 AND 23),
day_of_month INT CHECK (day_of_month BETWEEN 1 AND 31),
month INT CHECK (month BETWEEN 1 AND 12),
day_of_week INT CHECK (day_of_week BETWEEN 0 AND 6)
) ;

CREATE TABLE transaction (
id SERIAL PRIMARY KEY,
description TEXT,
context TEXT,
quantity INT NOT NULL DEFAULT 1,
amount DECIMAL (10, 2) NOT NULL,
type VARCHAR (50) NOT NULL CHECK (type IN ('income', 'expense', 'transfer')),

invoice_id VARCHAR (100) UNIQUE,
location_id INT,
periodicity_id INT,

beneficiary_type VARCHAR (50) NOT NULL CHECK (beneficiary_type IN ('business',
'person')),
beneficiary_id INT,
payer_type VARCHAR (50) NOT NULL CHECK (payer_type IN ('business', 'person')),
payer_id INT,

transaction_timestamp TIMESTAMP NOT NULL DEFAULT CURRENT_DATE,
created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,

FOREIGN KEY (location_id) REFERENCES location (id) ON DELETE SET NULL
) ;

-- Many-to-Many relationship between transactions and occasions
CREATE TABLE transaction_occasion (
transaction_id INT,
occasion_id INT,
CONSTRAINT transaction_occasion_id PRIMARY KEY (transaction_id, occasion_id),
FOREIGN KEY (transaction_id) REFERENCES transaction (id) ON DELETE CASCADE,
FOREIGN KEY (occasion_id) REFERENCES occasion (id) ON DELETE CASCADE
) ;

-- Many-to-Many relationship between transactions and categories
CREATE TABLE transaction_category (
transaction_id INT,
category_id INT,
CONSTRAINT transaction_category_id PRIMARY KEY (transaction_id, category_id),

FOREIGN KEY (transaction_id) REFERENCES transaction (id) ON DELETE CASCADE,
FOREIGN KEY (category_id) REFERENCES category (id) ON DELETE CASCADE
) ;

-- Many-to-Many relationship between transactions and products
-- (a transaction can have multiple products and a product can be part of multiple transactions)
CREATE TABLE transaction_product (
transaction_id INT,
product_id INT,
CONSTRAINT transaction_product_id PRIMARY KEY (transaction_id, product_id),

FOREIGN KEY (transaction_id) REFERENCES transaction (id) ON DELETE CASCADE,
FOREIGN KEY (product_id) REFERENCES product (id) ON DELETE CASCADE
) ;

-- =============================================
--   TRIGGER ATTACHMENT                        
-- =============================================

-- Attach the update_updated_at trigger to all tables with an updated_at column
-- Notes:
-- 1. table_schema is usually 'public' for user-defined tables
-- 2. %I inserts variables (identifiers) safely to prevent SQL injection
DO $$
DECLARE
    table_names_record RECORD;
BEGIN
    FOR table_names_record IN
        SELECT table_schema, table_name, column_name
        FROM information_schema.columns
        WHERE column_name = 'updated_at'
          AND table_schema = 'public'
    LOOP
        EXECUTE format(
            'CREATE TRIGGER updated_at_trigger_%I
            BEFORE UPDATE ON %I.%I
            FOR EACH ROW
            EXECUTE FUNCTION update_updated_at();', 
            table_names_record.table_name, 
            table_names_record.table_schema, 
            table_names_record.table_name
        );
    END LOOP;
END $$ ;
