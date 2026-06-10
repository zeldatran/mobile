-- PostgreSQL DDL Schema for E-Commerce Shopping App
-- Enable UUID extension if not already enabled in your PostgreSQL instance
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- 1. Create Roles Table
CREATE TABLE IF NOT EXISTS roles (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    role_name VARCHAR(255) NOT NULL,
    privileges TEXT
);

-- 2. Create Staff Accounts Table (with schema mismatch resolved: role_id is UUID)
CREATE TABLE IF NOT EXISTS staff_accounts (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    role_id UUID REFERENCES roles(id) ON DELETE SET NULL,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    phone_number VARCHAR(100) DEFAULT NULL,
    email VARCHAR(255) NOT NULL UNIQUE,
    password_hash TEXT NOT NULL,
    active BOOLEAN DEFAULT TRUE,
    image TEXT DEFAULT NULL,
    placeholder TEXT DEFAULT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_by UUID REFERENCES staff_accounts(id) ON DELETE SET NULL,
    updated_by UUID REFERENCES staff_accounts(id) ON DELETE SET NULL
);

-- Insert a default role for testing
INSERT INTO roles (id, role_name, privileges) 
VALUES ('c3b075e8-5b12-4c28-98e6-e3d8431e13e8', 'STAFF', 'read,write')
ON CONFLICT DO NOTHING;

-- 3. Create Tags Table
CREATE TABLE IF NOT EXISTS tags (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tag_name VARCHAR(255) NOT NULL,
    icon TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_by UUID REFERENCES staff_accounts(id) ON DELETE SET NULL,
    updated_by UUID REFERENCES staff_accounts(id) ON DELETE SET NULL
);

-- 4. Create Products Table
CREATE TABLE IF NOT EXISTS products (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    slug TEXT NOT NULL UNIQUE,
    product_name VARCHAR(255) NOT NULL,
    sku VARCHAR(255),
    sale_price NUMERIC NOT NULL DEFAULT 0,
    compare_price NUMERIC DEFAULT 0 CHECK (compare_price > sale_price OR compare_price = 0),
    buying_price NUMERIC DEFAULT NULL,
    quantity INTEGER NOT NULL DEFAULT 0,
    short_description VARCHAR(165) NOT NULL,
    product_description TEXT NOT NULL,
    product_type VARCHAR(64) CHECK (product_type IN ('simple', 'variable')),
    published BOOLEAN DEFAULT FALSE,
    disable_out_of_stock BOOLEAN DEFAULT TRUE,
    note TEXT,
    image TEXT DEFAULT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_by UUID REFERENCES staff_accounts(id) ON DELETE SET NULL,
    updated_by UUID REFERENCES staff_accounts(id) ON DELETE SET NULL
);

-- 5. Create Product Tags Join Table
CREATE TABLE IF NOT EXISTS product_tags (
    tag_id UUID REFERENCES tags(id) ON DELETE CASCADE NOT NULL,
    product_id UUID REFERENCES products(id) ON DELETE CASCADE NOT NULL,
    PRIMARY KEY (tag_id, product_id)
);
