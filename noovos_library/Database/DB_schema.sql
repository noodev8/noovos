--
-- PostgreSQL database dump
--

-- Dumped from database version 11.18 (Debian 11.18-0+deb10u1)
-- Dumped by pg_dump version 17.1

-- Started on 2025-04-14 18:55:44

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET transaction_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- TOC entry 9 (class 2615 OID 2200)
-- Name: public; Type: SCHEMA; Schema: -; Owner: postgres
--

-- *not* creating schema, since initdb creates it


ALTER SCHEMA public OWNER TO postgres;

--
-- TOC entry 3 (class 3079 OID 20521)
-- Name: pg_trgm; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS pg_trgm WITH SCHEMA public;


--
-- TOC entry 3376 (class 0 OID 0)
-- Dependencies: 3
-- Name: EXTENSION pg_trgm; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION pg_trgm IS 'text similarity measurement and index searching based on trigrams';


--
-- TOC entry 2 (class 3079 OID 20843)
-- Name: pgcrypto; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS pgcrypto WITH SCHEMA public;


--
-- TOC entry 3377 (class 0 OID 0)
-- Dependencies: 2
-- Name: EXTENSION pgcrypto; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION pgcrypto IS 'cryptographic functions';


SET default_tablespace = '';

--
-- TOC entry 199 (class 1259 OID 20072)
-- Name: app_user; Type: TABLE; Schema: public; Owner: noovos_dev
--

CREATE TABLE public.app_user (
    id integer NOT NULL,
    user_type character varying(20) NOT NULL,
    first_name character varying(100) NOT NULL,
    last_name character varying(100) NOT NULL,
    email character varying(255) NOT NULL,
    mobile character varying(20),
    password_hash text NOT NULL,
    date_of_birth date,
    business_name character varying(255),
    business_verified boolean DEFAULT false,
    profile_picture text,
    address text,
    city character varying(100),
    postcode character varying(20),
    country character varying(100),
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    role character varying(20) DEFAULT 'consumer'::character varying,
    landline character varying(20)
);


ALTER TABLE public.app_user OWNER TO noovos_dev;

--
-- TOC entry 217 (class 1259 OID 20410)
-- Name: audit_log; Type: TABLE; Schema: public; Owner: noovos_dev
--

CREATE TABLE public.audit_log (
    id integer NOT NULL,
    appuser_id integer,
    action character varying(255) NOT NULL,
    entity character varying(100) NOT NULL,
    entity_id integer,
    ip_address character varying(45),
    user_agent text,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.audit_log OWNER TO noovos_dev;

--
-- TOC entry 216 (class 1259 OID 20408)
-- Name: audit_log_id_seq; Type: SEQUENCE; Schema: public; Owner: noovos_dev
--

CREATE SEQUENCE public.audit_log_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.audit_log_id_seq OWNER TO noovos_dev;

--
-- TOC entry 3378 (class 0 OID 0)
-- Dependencies: 216
-- Name: audit_log_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: noovos_dev
--

ALTER SEQUENCE public.audit_log_id_seq OWNED BY public.audit_log.id;


--
-- TOC entry 223 (class 1259 OID 20729)
-- Name: available_slot; Type: TABLE; Schema: public; Owner: noovos_dev
--

CREATE TABLE public.available_slot (
    id integer NOT NULL,
    service_id integer NOT NULL,
    staff_id integer,
    date date NOT NULL,
    start_time time without time zone NOT NULL,
    end_time time without time zone NOT NULL,
    is_booked boolean DEFAULT false,
    customer_id integer
);


ALTER TABLE public.available_slot OWNER TO noovos_dev;

--
-- TOC entry 222 (class 1259 OID 20727)
-- Name: available_slot_id_seq; Type: SEQUENCE; Schema: public; Owner: noovos_dev
--

CREATE SEQUENCE public.available_slot_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.available_slot_id_seq OWNER TO noovos_dev;

--
-- TOC entry 3379 (class 0 OID 0)
-- Dependencies: 222
-- Name: available_slot_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: noovos_dev
--

ALTER SEQUENCE public.available_slot_id_seq OWNED BY public.available_slot.id;


--
-- TOC entry 225 (class 1259 OID 20757)
-- Name: booking; Type: TABLE; Schema: public; Owner: noovos_dev
--

CREATE TABLE public.booking (
    id integer NOT NULL,
    slot_id integer NOT NULL,
    customer_id integer NOT NULL,
    status character varying(20) DEFAULT 'pending'::character varying,
    created_at timestamp without time zone DEFAULT now(),
    updated_at timestamp without time zone DEFAULT now()
);


ALTER TABLE public.booking OWNER TO noovos_dev;

--
-- TOC entry 224 (class 1259 OID 20755)
-- Name: booking_id_seq; Type: SEQUENCE; Schema: public; Owner: noovos_dev
--

CREATE SEQUENCE public.booking_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.booking_id_seq OWNER TO noovos_dev;

--
-- TOC entry 3380 (class 0 OID 0)
-- Dependencies: 224
-- Name: booking_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: noovos_dev
--

ALTER SEQUENCE public.booking_id_seq OWNED BY public.booking.id;


--
-- TOC entry 201 (class 1259 OID 20186)
-- Name: business; Type: TABLE; Schema: public; Owner: noovos_dev
--

CREATE TABLE public.business (
    id integer NOT NULL,
    appuser_id integer NOT NULL,
    name text NOT NULL,
    email character varying(255) NOT NULL,
    phone text,
    website text,
    address text,
    city text,
    postcode text,
    country text,
    description text,
    business_verified boolean DEFAULT false NOT NULL,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    category_name text,
    time_zone text,
    parking_available boolean DEFAULT false,
    parking_description text,
    business_type text
);


ALTER TABLE public.business OWNER TO noovos_dev;

--
-- TOC entry 253 (class 1259 OID 22049)
-- Name: business_billing_address; Type: TABLE; Schema: public; Owner: noovos_dev
--

CREATE TABLE public.business_billing_address (
    id integer NOT NULL,
    business_id integer,
    billing_name text,
    address_line_1 text NOT NULL,
    address_line_2 text,
    city text NOT NULL,
    postcode text NOT NULL,
    country text NOT NULL,
    notes text
);


ALTER TABLE public.business_billing_address OWNER TO noovos_dev;

--
-- TOC entry 252 (class 1259 OID 22047)
-- Name: business_billing_address_id_seq; Type: SEQUENCE; Schema: public; Owner: noovos_dev
--

CREATE SEQUENCE public.business_billing_address_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.business_billing_address_id_seq OWNER TO noovos_dev;

--
-- TOC entry 3381 (class 0 OID 0)
-- Dependencies: 252
-- Name: business_billing_address_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: noovos_dev
--

ALTER SEQUENCE public.business_billing_address_id_seq OWNED BY public.business_billing_address.id;


--
-- TOC entry 249 (class 1259 OID 22023)
-- Name: business_contact_preference; Type: TABLE; Schema: public; Owner: noovos_dev
--

CREATE TABLE public.business_contact_preference (
    id integer NOT NULL,
    business_id integer,
    contact_method text NOT NULL,
    is_preferred boolean DEFAULT false,
    notes text
);


ALTER TABLE public.business_contact_preference OWNER TO noovos_dev;

--
-- TOC entry 248 (class 1259 OID 22021)
-- Name: business_contact_preference_id_seq; Type: SEQUENCE; Schema: public; Owner: noovos_dev
--

CREATE SEQUENCE public.business_contact_preference_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.business_contact_preference_id_seq OWNER TO noovos_dev;

--
-- TOC entry 3382 (class 0 OID 0)
-- Dependencies: 248
-- Name: business_contact_preference_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: noovos_dev
--

ALTER SEQUENCE public.business_contact_preference_id_seq OWNED BY public.business_contact_preference.id;


--
-- TOC entry 239 (class 1259 OID 21961)
-- Name: business_employee; Type: TABLE; Schema: public; Owner: noovos_dev
--

CREATE TABLE public.business_employee (
    id integer NOT NULL,
    business_id integer,
    employee_name text NOT NULL,
    employee_title text,
    image_name text,
    bio text
);


ALTER TABLE public.business_employee OWNER TO noovos_dev;

--
-- TOC entry 238 (class 1259 OID 21959)
-- Name: business_employee_id_seq; Type: SEQUENCE; Schema: public; Owner: noovos_dev
--

CREATE SEQUENCE public.business_employee_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.business_employee_id_seq OWNER TO noovos_dev;

--
-- TOC entry 3383 (class 0 OID 0)
-- Dependencies: 238
-- Name: business_employee_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: noovos_dev
--

ALTER SEQUENCE public.business_employee_id_seq OWNED BY public.business_employee.id;


--
-- TOC entry 241 (class 1259 OID 21975)
-- Name: business_employee_service; Type: TABLE; Schema: public; Owner: noovos_dev
--

CREATE TABLE public.business_employee_service (
    id integer NOT NULL,
    business_employee_id integer,
    service_id integer
);


ALTER TABLE public.business_employee_service OWNER TO noovos_dev;

--
-- TOC entry 240 (class 1259 OID 21973)
-- Name: business_employee_service_id_seq; Type: SEQUENCE; Schema: public; Owner: noovos_dev
--

CREATE SEQUENCE public.business_employee_service_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.business_employee_service_id_seq OWNER TO noovos_dev;

--
-- TOC entry 3384 (class 0 OID 0)
-- Dependencies: 240
-- Name: business_employee_service_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: noovos_dev
--

ALTER SEQUENCE public.business_employee_service_id_seq OWNED BY public.business_employee_service.id;


--
-- TOC entry 247 (class 1259 OID 22010)
-- Name: business_feature; Type: TABLE; Schema: public; Owner: noovos_dev
--

CREATE TABLE public.business_feature (
    id integer NOT NULL,
    business_id integer,
    feature_name text NOT NULL,
    is_available boolean DEFAULT false
);


ALTER TABLE public.business_feature OWNER TO noovos_dev;

--
-- TOC entry 246 (class 1259 OID 22008)
-- Name: business_feature_id_seq; Type: SEQUENCE; Schema: public; Owner: noovos_dev
--

CREATE SEQUENCE public.business_feature_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.business_feature_id_seq OWNER TO noovos_dev;

--
-- TOC entry 3385 (class 0 OID 0)
-- Dependencies: 246
-- Name: business_feature_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: noovos_dev
--

ALTER SEQUENCE public.business_feature_id_seq OWNED BY public.business_feature.id;


--
-- TOC entry 237 (class 1259 OID 21948)
-- Name: business_hours; Type: TABLE; Schema: public; Owner: noovos_dev
--

CREATE TABLE public.business_hours (
    id integer NOT NULL,
    business_id integer,
    day_of_week text NOT NULL,
    open_time time without time zone NOT NULL,
    close_time time without time zone NOT NULL,
    is_closed boolean DEFAULT false
);


ALTER TABLE public.business_hours OWNER TO noovos_dev;

--
-- TOC entry 236 (class 1259 OID 21946)
-- Name: business_hours_id_seq; Type: SEQUENCE; Schema: public; Owner: noovos_dev
--

CREATE SEQUENCE public.business_hours_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.business_hours_id_seq OWNER TO noovos_dev;

--
-- TOC entry 3386 (class 0 OID 0)
-- Dependencies: 236
-- Name: business_hours_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: noovos_dev
--

ALTER SEQUENCE public.business_hours_id_seq OWNED BY public.business_hours.id;


--
-- TOC entry 200 (class 1259 OID 20184)
-- Name: business_id_seq; Type: SEQUENCE; Schema: public; Owner: noovos_dev
--

CREATE SEQUENCE public.business_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.business_id_seq OWNER TO noovos_dev;

--
-- TOC entry 3387 (class 0 OID 0)
-- Dependencies: 200
-- Name: business_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: noovos_dev
--

ALTER SEQUENCE public.business_id_seq OWNED BY public.business.id;


--
-- TOC entry 245 (class 1259 OID 21998)
-- Name: business_insurance; Type: TABLE; Schema: public; Owner: noovos_dev
--

CREATE TABLE public.business_insurance (
    id integer NOT NULL,
    business_id integer,
    provider_name text NOT NULL,
    policy_number text,
    issue_date date,
    expiry_date date,
    document_image_name text
);


ALTER TABLE public.business_insurance OWNER TO noovos_dev;

--
-- TOC entry 244 (class 1259 OID 21996)
-- Name: business_insurance_id_seq; Type: SEQUENCE; Schema: public; Owner: noovos_dev
--

CREATE SEQUENCE public.business_insurance_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.business_insurance_id_seq OWNER TO noovos_dev;

--
-- TOC entry 3388 (class 0 OID 0)
-- Dependencies: 244
-- Name: business_insurance_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: noovos_dev
--

ALTER SEQUENCE public.business_insurance_id_seq OWNED BY public.business_insurance.id;


--
-- TOC entry 251 (class 1259 OID 22036)
-- Name: business_language; Type: TABLE; Schema: public; Owner: noovos_dev
--

CREATE TABLE public.business_language (
    id integer NOT NULL,
    business_id integer,
    language_name text NOT NULL,
    is_primary boolean DEFAULT false
);


ALTER TABLE public.business_language OWNER TO noovos_dev;

--
-- TOC entry 250 (class 1259 OID 22034)
-- Name: business_language_id_seq; Type: SEQUENCE; Schema: public; Owner: noovos_dev
--

CREATE SEQUENCE public.business_language_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.business_language_id_seq OWNER TO noovos_dev;

--
-- TOC entry 3389 (class 0 OID 0)
-- Dependencies: 250
-- Name: business_language_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: noovos_dev
--

ALTER SEQUENCE public.business_language_id_seq OWNED BY public.business_language.id;


--
-- TOC entry 235 (class 1259 OID 21936)
-- Name: business_social_link; Type: TABLE; Schema: public; Owner: noovos_dev
--

CREATE TABLE public.business_social_link (
    id integer NOT NULL,
    business_id integer,
    platform_name text NOT NULL,
    url text NOT NULL
);


ALTER TABLE public.business_social_link OWNER TO noovos_dev;

--
-- TOC entry 234 (class 1259 OID 21934)
-- Name: business_social_link_id_seq; Type: SEQUENCE; Schema: public; Owner: noovos_dev
--

CREATE SEQUENCE public.business_social_link_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.business_social_link_id_seq OWNER TO noovos_dev;

--
-- TOC entry 3390 (class 0 OID 0)
-- Dependencies: 234
-- Name: business_social_link_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: noovos_dev
--

ALTER SEQUENCE public.business_social_link_id_seq OWNED BY public.business_social_link.id;


--
-- TOC entry 233 (class 1259 OID 21922)
-- Name: business_subcategory; Type: TABLE; Schema: public; Owner: noovos_dev
--

CREATE TABLE public.business_subcategory (
    id integer NOT NULL,
    business_id integer,
    subcategory_name text NOT NULL
);


ALTER TABLE public.business_subcategory OWNER TO noovos_dev;

--
-- TOC entry 232 (class 1259 OID 21920)
-- Name: business_subcategory_id_seq; Type: SEQUENCE; Schema: public; Owner: noovos_dev
--

CREATE SEQUENCE public.business_subcategory_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.business_subcategory_id_seq OWNER TO noovos_dev;

--
-- TOC entry 3391 (class 0 OID 0)
-- Dependencies: 232
-- Name: business_subcategory_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: noovos_dev
--

ALTER SEQUENCE public.business_subcategory_id_seq OWNED BY public.business_subcategory.id;


--
-- TOC entry 229 (class 1259 OID 21874)
-- Name: category; Type: TABLE; Schema: public; Owner: noovos_dev
--

CREATE TABLE public.category (
    id integer NOT NULL,
    name character varying(100) NOT NULL,
    description text,
    icon_url text
);


ALTER TABLE public.category OWNER TO noovos_dev;

--
-- TOC entry 228 (class 1259 OID 21872)
-- Name: category_id_seq; Type: SEQUENCE; Schema: public; Owner: noovos_dev
--

CREATE SEQUENCE public.category_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.category_id_seq OWNER TO noovos_dev;

--
-- TOC entry 3392 (class 0 OID 0)
-- Dependencies: 228
-- Name: category_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: noovos_dev
--

ALTER SEQUENCE public.category_id_seq OWNED BY public.category.id;


--
-- TOC entry 209 (class 1259 OID 20324)
-- Name: customer_notes; Type: TABLE; Schema: public; Owner: noovos_dev
--

CREATE TABLE public.customer_notes (
    id integer NOT NULL,
    business_id integer NOT NULL,
    appuser_id integer NOT NULL,
    staff_id integer NOT NULL,
    note text NOT NULL,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.customer_notes OWNER TO noovos_dev;

--
-- TOC entry 208 (class 1259 OID 20322)
-- Name: customer_notes_id_seq; Type: SEQUENCE; Schema: public; Owner: noovos_dev
--

CREATE SEQUENCE public.customer_notes_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.customer_notes_id_seq OWNER TO noovos_dev;

--
-- TOC entry 3393 (class 0 OID 0)
-- Dependencies: 208
-- Name: customer_notes_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: noovos_dev
--

ALTER SEQUENCE public.customer_notes_id_seq OWNED BY public.customer_notes.id;


--
-- TOC entry 231 (class 1259 OID 21894)
-- Name: media; Type: TABLE; Schema: public; Owner: noovos_dev
--

CREATE TABLE public.media (
    id integer NOT NULL,
    business_id integer,
    service_id integer,
    image_name text NOT NULL,
    "position" integer DEFAULT 1 NOT NULL,
    media_type text DEFAULT 'image'::text NOT NULL,
    caption text,
    duration_seconds integer,
    business_employee_id integer,
    is_active boolean DEFAULT true
);


ALTER TABLE public.media OWNER TO noovos_dev;

--
-- TOC entry 230 (class 1259 OID 21892)
-- Name: image_id_seq; Type: SEQUENCE; Schema: public; Owner: noovos_dev
--

CREATE SEQUENCE public.image_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.image_id_seq OWNER TO noovos_dev;

--
-- TOC entry 3394 (class 0 OID 0)
-- Dependencies: 230
-- Name: image_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: noovos_dev
--

ALTER SEQUENCE public.image_id_seq OWNED BY public.media.id;


--
-- TOC entry 213 (class 1259 OID 20375)
-- Name: notifications; Type: TABLE; Schema: public; Owner: noovos_dev
--

CREATE TABLE public.notifications (
    id integer NOT NULL,
    appuser_id integer NOT NULL,
    type character varying(50) NOT NULL,
    message text NOT NULL,
    is_read boolean DEFAULT false,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.notifications OWNER TO noovos_dev;

--
-- TOC entry 212 (class 1259 OID 20373)
-- Name: notifications_id_seq; Type: SEQUENCE; Schema: public; Owner: noovos_dev
--

CREATE SEQUENCE public.notifications_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.notifications_id_seq OWNER TO noovos_dev;

--
-- TOC entry 3395 (class 0 OID 0)
-- Dependencies: 212
-- Name: notifications_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: noovos_dev
--

ALTER SEQUENCE public.notifications_id_seq OWNED BY public.notifications.id;


--
-- TOC entry 205 (class 1259 OID 20256)
-- Name: payment; Type: TABLE; Schema: public; Owner: noovos_dev
--

CREATE TABLE public.payment (
    id integer NOT NULL,
    appuser_id integer NOT NULL,
    amount numeric(10,2) NOT NULL,
    currency character varying(3) DEFAULT 'GBP'::character varying,
    payment_status character varying(50) DEFAULT 'pending'::character varying,
    payment_method character varying(50),
    transaction_id character varying(255),
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    booking_id integer
);


ALTER TABLE public.payment OWNER TO noovos_dev;

--
-- TOC entry 204 (class 1259 OID 20254)
-- Name: payment_id_seq; Type: SEQUENCE; Schema: public; Owner: noovos_dev
--

CREATE SEQUENCE public.payment_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.payment_id_seq OWNER TO noovos_dev;

--
-- TOC entry 3396 (class 0 OID 0)
-- Dependencies: 204
-- Name: payment_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: noovos_dev
--

ALTER SEQUENCE public.payment_id_seq OWNED BY public.payment.id;


--
-- TOC entry 243 (class 1259 OID 21985)
-- Name: qualification; Type: TABLE; Schema: public; Owner: noovos_dev
--

CREATE TABLE public.qualification (
    id integer NOT NULL,
    business_id integer,
    business_employee_id integer,
    qualification_name text NOT NULL,
    issued_by text,
    issue_date date,
    expiry_date date,
    document_image_name text
);


ALTER TABLE public.qualification OWNER TO noovos_dev;

--
-- TOC entry 242 (class 1259 OID 21983)
-- Name: qualification_id_seq; Type: SEQUENCE; Schema: public; Owner: noovos_dev
--

CREATE SEQUENCE public.qualification_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.qualification_id_seq OWNER TO noovos_dev;

--
-- TOC entry 3397 (class 0 OID 0)
-- Dependencies: 242
-- Name: qualification_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: noovos_dev
--

ALTER SEQUENCE public.qualification_id_seq OWNED BY public.qualification.id;


--
-- TOC entry 211 (class 1259 OID 20351)
-- Name: reviews; Type: TABLE; Schema: public; Owner: noovos_dev
--

CREATE TABLE public.reviews (
    id integer NOT NULL,
    business_id integer NOT NULL,
    appuser_id integer NOT NULL,
    rating integer NOT NULL,
    review_text text,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT reviews_rating_check CHECK (((rating >= 1) AND (rating <= 5)))
);


ALTER TABLE public.reviews OWNER TO noovos_dev;

--
-- TOC entry 210 (class 1259 OID 20349)
-- Name: reviews_id_seq; Type: SEQUENCE; Schema: public; Owner: noovos_dev
--

CREATE SEQUENCE public.reviews_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.reviews_id_seq OWNER TO noovos_dev;

--
-- TOC entry 3398 (class 0 OID 0)
-- Dependencies: 210
-- Name: reviews_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: noovos_dev
--

ALTER SEQUENCE public.reviews_id_seq OWNED BY public.reviews.id;


--
-- TOC entry 221 (class 1259 OID 20615)
-- Name: search_log; Type: TABLE; Schema: public; Owner: noovos_dev
--

CREATE TABLE public.search_log (
    id integer NOT NULL,
    search_term text NOT NULL,
    search_timestamp timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    search_user integer
);


ALTER TABLE public.search_log OWNER TO noovos_dev;

--
-- TOC entry 220 (class 1259 OID 20613)
-- Name: search_logs_id_seq; Type: SEQUENCE; Schema: public; Owner: noovos_dev
--

CREATE SEQUENCE public.search_logs_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.search_logs_id_seq OWNER TO noovos_dev;

--
-- TOC entry 3399 (class 0 OID 0)
-- Dependencies: 220
-- Name: search_logs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: noovos_dev
--

ALTER SEQUENCE public.search_logs_id_seq OWNED BY public.search_log.id;


--
-- TOC entry 203 (class 1259 OID 20207)
-- Name: service; Type: TABLE; Schema: public; Owner: noovos_dev
--

CREATE TABLE public.service (
    id integer NOT NULL,
    business_id integer NOT NULL,
    service_name text NOT NULL,
    description text,
    duration integer NOT NULL,
    price numeric(10,2) NOT NULL,
    currency character varying(3) DEFAULT 'GBP'::character varying,
    active boolean DEFAULT true NOT NULL,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    buffer_time integer DEFAULT 0,
    category_id integer
);


ALTER TABLE public.service OWNER TO noovos_dev;

--
-- TOC entry 202 (class 1259 OID 20205)
-- Name: service_id_seq; Type: SEQUENCE; Schema: public; Owner: noovos_dev
--

CREATE SEQUENCE public.service_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.service_id_seq OWNER TO noovos_dev;

--
-- TOC entry 3400 (class 0 OID 0)
-- Dependencies: 202
-- Name: service_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: noovos_dev
--

ALTER SEQUENCE public.service_id_seq OWNED BY public.service.id;


--
-- TOC entry 227 (class 1259 OID 20781)
-- Name: service_staff; Type: TABLE; Schema: public; Owner: noovos_dev
--

CREATE TABLE public.service_staff (
    id integer NOT NULL,
    service_id integer NOT NULL,
    staff_id integer NOT NULL
);


ALTER TABLE public.service_staff OWNER TO noovos_dev;

--
-- TOC entry 226 (class 1259 OID 20779)
-- Name: service_staff_id_seq; Type: SEQUENCE; Schema: public; Owner: noovos_dev
--

CREATE SEQUENCE public.service_staff_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.service_staff_id_seq OWNER TO noovos_dev;

--
-- TOC entry 3401 (class 0 OID 0)
-- Dependencies: 226
-- Name: service_staff_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: noovos_dev
--

ALTER SEQUENCE public.service_staff_id_seq OWNED BY public.service_staff.id;


--
-- TOC entry 207 (class 1259 OID 20302)
-- Name: staff; Type: TABLE; Schema: public; Owner: noovos_dev
--

CREATE TABLE public.staff (
    id integer NOT NULL,
    business_id integer NOT NULL,
    appuser_id integer NOT NULL,
    role character varying(100) DEFAULT 'staff'::character varying,
    is_active boolean DEFAULT true,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.staff OWNER TO noovos_dev;

--
-- TOC entry 206 (class 1259 OID 20300)
-- Name: staff_id_seq; Type: SEQUENCE; Schema: public; Owner: noovos_dev
--

CREATE SEQUENCE public.staff_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.staff_id_seq OWNER TO noovos_dev;

--
-- TOC entry 3402 (class 0 OID 0)
-- Dependencies: 206
-- Name: staff_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: noovos_dev
--

ALTER SEQUENCE public.staff_id_seq OWNED BY public.staff.id;


--
-- TOC entry 215 (class 1259 OID 20393)
-- Name: subscription; Type: TABLE; Schema: public; Owner: noovos_dev
--

CREATE TABLE public.subscription (
    id integer NOT NULL,
    appuser_id integer NOT NULL,
    plan_name character varying(100) NOT NULL,
    price numeric(10,2) NOT NULL,
    currency character varying(3) DEFAULT 'GBP'::character varying,
    status character varying(50) DEFAULT 'active'::character varying,
    start_date timestamp without time zone NOT NULL,
    end_date timestamp without time zone,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.subscription OWNER TO noovos_dev;

--
-- TOC entry 214 (class 1259 OID 20391)
-- Name: subscription_id_seq; Type: SEQUENCE; Schema: public; Owner: noovos_dev
--

CREATE SEQUENCE public.subscription_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.subscription_id_seq OWNER TO noovos_dev;

--
-- TOC entry 3403 (class 0 OID 0)
-- Dependencies: 214
-- Name: subscription_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: noovos_dev
--

ALTER SEQUENCE public.subscription_id_seq OWNED BY public.subscription.id;


--
-- TOC entry 219 (class 1259 OID 20601)
-- Name: synonyms; Type: TABLE; Schema: public; Owner: noovos_dev
--

CREATE TABLE public.synonyms (
    id integer NOT NULL,
    word text NOT NULL,
    synonyms text[] NOT NULL
);


ALTER TABLE public.synonyms OWNER TO noovos_dev;

--
-- TOC entry 218 (class 1259 OID 20599)
-- Name: synonyms_id_seq; Type: SEQUENCE; Schema: public; Owner: noovos_dev
--

CREATE SEQUENCE public.synonyms_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.synonyms_id_seq OWNER TO noovos_dev;

--
-- TOC entry 3404 (class 0 OID 0)
-- Dependencies: 218
-- Name: synonyms_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: noovos_dev
--

ALTER SEQUENCE public.synonyms_id_seq OWNED BY public.synonyms.id;


--
-- TOC entry 198 (class 1259 OID 20070)
-- Name: users_id_seq; Type: SEQUENCE; Schema: public; Owner: noovos_dev
--

CREATE SEQUENCE public.users_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.users_id_seq OWNER TO noovos_dev;

--
-- TOC entry 3405 (class 0 OID 0)
-- Dependencies: 198
-- Name: users_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: noovos_dev
--

ALTER SEQUENCE public.users_id_seq OWNED BY public.app_user.id;


--
-- TOC entry 3045 (class 2604 OID 20075)
-- Name: app_user id; Type: DEFAULT; Schema: public; Owner: noovos_dev
--

ALTER TABLE ONLY public.app_user ALTER COLUMN id SET DEFAULT nextval('public.users_id_seq'::regclass);


--
-- TOC entry 3083 (class 2604 OID 20413)
-- Name: audit_log id; Type: DEFAULT; Schema: public; Owner: noovos_dev
--

ALTER TABLE ONLY public.audit_log ALTER COLUMN id SET DEFAULT nextval('public.audit_log_id_seq'::regclass);


--
-- TOC entry 3088 (class 2604 OID 20732)
-- Name: available_slot id; Type: DEFAULT; Schema: public; Owner: noovos_dev
--

ALTER TABLE ONLY public.available_slot ALTER COLUMN id SET DEFAULT nextval('public.available_slot_id_seq'::regclass);


--
-- TOC entry 3090 (class 2604 OID 20760)
-- Name: booking id; Type: DEFAULT; Schema: public; Owner: noovos_dev
--

ALTER TABLE ONLY public.booking ALTER COLUMN id SET DEFAULT nextval('public.booking_id_seq'::regclass);


--
-- TOC entry 3050 (class 2604 OID 20189)
-- Name: business id; Type: DEFAULT; Schema: public; Owner: noovos_dev
--

ALTER TABLE ONLY public.business ALTER COLUMN id SET DEFAULT nextval('public.business_id_seq'::regclass);


--
-- TOC entry 3114 (class 2604 OID 22052)
-- Name: business_billing_address id; Type: DEFAULT; Schema: public; Owner: noovos_dev
--

ALTER TABLE ONLY public.business_billing_address ALTER COLUMN id SET DEFAULT nextval('public.business_billing_address_id_seq'::regclass);


--
-- TOC entry 3110 (class 2604 OID 22026)
-- Name: business_contact_preference id; Type: DEFAULT; Schema: public; Owner: noovos_dev
--

ALTER TABLE ONLY public.business_contact_preference ALTER COLUMN id SET DEFAULT nextval('public.business_contact_preference_id_seq'::regclass);


--
-- TOC entry 3104 (class 2604 OID 21964)
-- Name: business_employee id; Type: DEFAULT; Schema: public; Owner: noovos_dev
--

ALTER TABLE ONLY public.business_employee ALTER COLUMN id SET DEFAULT nextval('public.business_employee_id_seq'::regclass);


--
-- TOC entry 3105 (class 2604 OID 21978)
-- Name: business_employee_service id; Type: DEFAULT; Schema: public; Owner: noovos_dev
--

ALTER TABLE ONLY public.business_employee_service ALTER COLUMN id SET DEFAULT nextval('public.business_employee_service_id_seq'::regclass);


--
-- TOC entry 3108 (class 2604 OID 22013)
-- Name: business_feature id; Type: DEFAULT; Schema: public; Owner: noovos_dev
--

ALTER TABLE ONLY public.business_feature ALTER COLUMN id SET DEFAULT nextval('public.business_feature_id_seq'::regclass);


--
-- TOC entry 3102 (class 2604 OID 21951)
-- Name: business_hours id; Type: DEFAULT; Schema: public; Owner: noovos_dev
--

ALTER TABLE ONLY public.business_hours ALTER COLUMN id SET DEFAULT nextval('public.business_hours_id_seq'::regclass);


--
-- TOC entry 3107 (class 2604 OID 22001)
-- Name: business_insurance id; Type: DEFAULT; Schema: public; Owner: noovos_dev
--

ALTER TABLE ONLY public.business_insurance ALTER COLUMN id SET DEFAULT nextval('public.business_insurance_id_seq'::regclass);


--
-- TOC entry 3112 (class 2604 OID 22039)
-- Name: business_language id; Type: DEFAULT; Schema: public; Owner: noovos_dev
--

ALTER TABLE ONLY public.business_language ALTER COLUMN id SET DEFAULT nextval('public.business_language_id_seq'::regclass);


--
-- TOC entry 3101 (class 2604 OID 21939)
-- Name: business_social_link id; Type: DEFAULT; Schema: public; Owner: noovos_dev
--

ALTER TABLE ONLY public.business_social_link ALTER COLUMN id SET DEFAULT nextval('public.business_social_link_id_seq'::regclass);


--
-- TOC entry 3100 (class 2604 OID 21925)
-- Name: business_subcategory id; Type: DEFAULT; Schema: public; Owner: noovos_dev
--

ALTER TABLE ONLY public.business_subcategory ALTER COLUMN id SET DEFAULT nextval('public.business_subcategory_id_seq'::regclass);


--
-- TOC entry 3095 (class 2604 OID 21877)
-- Name: category id; Type: DEFAULT; Schema: public; Owner: noovos_dev
--

ALTER TABLE ONLY public.category ALTER COLUMN id SET DEFAULT nextval('public.category_id_seq'::regclass);


--
-- TOC entry 3071 (class 2604 OID 20327)
-- Name: customer_notes id; Type: DEFAULT; Schema: public; Owner: noovos_dev
--

ALTER TABLE ONLY public.customer_notes ALTER COLUMN id SET DEFAULT nextval('public.customer_notes_id_seq'::regclass);


--
-- TOC entry 3096 (class 2604 OID 21897)
-- Name: media id; Type: DEFAULT; Schema: public; Owner: noovos_dev
--

ALTER TABLE ONLY public.media ALTER COLUMN id SET DEFAULT nextval('public.image_id_seq'::regclass);


--
-- TOC entry 3075 (class 2604 OID 20378)
-- Name: notifications id; Type: DEFAULT; Schema: public; Owner: noovos_dev
--

ALTER TABLE ONLY public.notifications ALTER COLUMN id SET DEFAULT nextval('public.notifications_id_seq'::regclass);


--
-- TOC entry 3061 (class 2604 OID 20259)
-- Name: payment id; Type: DEFAULT; Schema: public; Owner: noovos_dev
--

ALTER TABLE ONLY public.payment ALTER COLUMN id SET DEFAULT nextval('public.payment_id_seq'::regclass);


--
-- TOC entry 3106 (class 2604 OID 21988)
-- Name: qualification id; Type: DEFAULT; Schema: public; Owner: noovos_dev
--

ALTER TABLE ONLY public.qualification ALTER COLUMN id SET DEFAULT nextval('public.qualification_id_seq'::regclass);


--
-- TOC entry 3073 (class 2604 OID 20354)
-- Name: reviews id; Type: DEFAULT; Schema: public; Owner: noovos_dev
--

ALTER TABLE ONLY public.reviews ALTER COLUMN id SET DEFAULT nextval('public.reviews_id_seq'::regclass);


--
-- TOC entry 3086 (class 2604 OID 20618)
-- Name: search_log id; Type: DEFAULT; Schema: public; Owner: noovos_dev
--

ALTER TABLE ONLY public.search_log ALTER COLUMN id SET DEFAULT nextval('public.search_logs_id_seq'::regclass);


--
-- TOC entry 3055 (class 2604 OID 20210)
-- Name: service id; Type: DEFAULT; Schema: public; Owner: noovos_dev
--

ALTER TABLE ONLY public.service ALTER COLUMN id SET DEFAULT nextval('public.service_id_seq'::regclass);


--
-- TOC entry 3094 (class 2604 OID 20784)
-- Name: service_staff id; Type: DEFAULT; Schema: public; Owner: noovos_dev
--

ALTER TABLE ONLY public.service_staff ALTER COLUMN id SET DEFAULT nextval('public.service_staff_id_seq'::regclass);


--
-- TOC entry 3066 (class 2604 OID 20305)
-- Name: staff id; Type: DEFAULT; Schema: public; Owner: noovos_dev
--

ALTER TABLE ONLY public.staff ALTER COLUMN id SET DEFAULT nextval('public.staff_id_seq'::regclass);


--
-- TOC entry 3078 (class 2604 OID 20396)
-- Name: subscription id; Type: DEFAULT; Schema: public; Owner: noovos_dev
--

ALTER TABLE ONLY public.subscription ALTER COLUMN id SET DEFAULT nextval('public.subscription_id_seq'::regclass);


--
-- TOC entry 3085 (class 2604 OID 20604)
-- Name: synonyms id; Type: DEFAULT; Schema: public; Owner: noovos_dev
--

ALTER TABLE ONLY public.synonyms ALTER COLUMN id SET DEFAULT nextval('public.synonyms_id_seq'::regclass);


--
-- TOC entry 3161 (class 2606 OID 20419)
-- Name: audit_log audit_log_pkey; Type: CONSTRAINT; Schema: public; Owner: noovos_dev
--

ALTER TABLE ONLY public.audit_log
    ADD CONSTRAINT audit_log_pkey PRIMARY KEY (id);


--
-- TOC entry 3170 (class 2606 OID 20735)
-- Name: available_slot available_slot_pkey; Type: CONSTRAINT; Schema: public; Owner: noovos_dev
--

ALTER TABLE ONLY public.available_slot
    ADD CONSTRAINT available_slot_pkey PRIMARY KEY (id);


--
-- TOC entry 3177 (class 2606 OID 20765)
-- Name: booking booking_pkey; Type: CONSTRAINT; Schema: public; Owner: noovos_dev
--

ALTER TABLE ONLY public.booking
    ADD CONSTRAINT booking_pkey PRIMARY KEY (id);


--
-- TOC entry 3227 (class 2606 OID 22057)
-- Name: business_billing_address business_billing_address_pkey; Type: CONSTRAINT; Schema: public; Owner: noovos_dev
--

ALTER TABLE ONLY public.business_billing_address
    ADD CONSTRAINT business_billing_address_pkey PRIMARY KEY (id);


--
-- TOC entry 3221 (class 2606 OID 22032)
-- Name: business_contact_preference business_contact_preference_pkey; Type: CONSTRAINT; Schema: public; Owner: noovos_dev
--

ALTER TABLE ONLY public.business_contact_preference
    ADD CONSTRAINT business_contact_preference_pkey PRIMARY KEY (id);


--
-- TOC entry 3125 (class 2606 OID 20199)
-- Name: business business_email_key; Type: CONSTRAINT; Schema: public; Owner: noovos_dev
--

ALTER TABLE ONLY public.business
    ADD CONSTRAINT business_email_key UNIQUE (email);


--
-- TOC entry 3204 (class 2606 OID 21969)
-- Name: business_employee business_employee_pkey; Type: CONSTRAINT; Schema: public; Owner: noovos_dev
--

ALTER TABLE ONLY public.business_employee
    ADD CONSTRAINT business_employee_pkey PRIMARY KEY (id);


--
-- TOC entry 3207 (class 2606 OID 21980)
-- Name: business_employee_service business_employee_service_pkey; Type: CONSTRAINT; Schema: public; Owner: noovos_dev
--

ALTER TABLE ONLY public.business_employee_service
    ADD CONSTRAINT business_employee_service_pkey PRIMARY KEY (id);


--
-- TOC entry 3218 (class 2606 OID 22019)
-- Name: business_feature business_feature_pkey; Type: CONSTRAINT; Schema: public; Owner: noovos_dev
--

ALTER TABLE ONLY public.business_feature
    ADD CONSTRAINT business_feature_pkey PRIMARY KEY (id);


--
-- TOC entry 3201 (class 2606 OID 21957)
-- Name: business_hours business_hours_pkey; Type: CONSTRAINT; Schema: public; Owner: noovos_dev
--

ALTER TABLE ONLY public.business_hours
    ADD CONSTRAINT business_hours_pkey PRIMARY KEY (id);


--
-- TOC entry 3215 (class 2606 OID 22006)
-- Name: business_insurance business_insurance_pkey; Type: CONSTRAINT; Schema: public; Owner: noovos_dev
--

ALTER TABLE ONLY public.business_insurance
    ADD CONSTRAINT business_insurance_pkey PRIMARY KEY (id);


--
-- TOC entry 3224 (class 2606 OID 22045)
-- Name: business_language business_language_pkey; Type: CONSTRAINT; Schema: public; Owner: noovos_dev
--

ALTER TABLE ONLY public.business_language
    ADD CONSTRAINT business_language_pkey PRIMARY KEY (id);


--
-- TOC entry 3127 (class 2606 OID 20197)
-- Name: business business_pkey; Type: CONSTRAINT; Schema: public; Owner: noovos_dev
--

ALTER TABLE ONLY public.business
    ADD CONSTRAINT business_pkey PRIMARY KEY (id);


--
-- TOC entry 3198 (class 2606 OID 21944)
-- Name: business_social_link business_social_link_pkey; Type: CONSTRAINT; Schema: public; Owner: noovos_dev
--

ALTER TABLE ONLY public.business_social_link
    ADD CONSTRAINT business_social_link_pkey PRIMARY KEY (id);


--
-- TOC entry 3195 (class 2606 OID 21930)
-- Name: business_subcategory business_subcategory_pkey; Type: CONSTRAINT; Schema: public; Owner: noovos_dev
--

ALTER TABLE ONLY public.business_subcategory
    ADD CONSTRAINT business_subcategory_pkey PRIMARY KEY (id);


--
-- TOC entry 3186 (class 2606 OID 21884)
-- Name: category category_name_key; Type: CONSTRAINT; Schema: public; Owner: noovos_dev
--

ALTER TABLE ONLY public.category
    ADD CONSTRAINT category_name_key UNIQUE (name);


--
-- TOC entry 3188 (class 2606 OID 21882)
-- Name: category category_pkey; Type: CONSTRAINT; Schema: public; Owner: noovos_dev
--

ALTER TABLE ONLY public.category
    ADD CONSTRAINT category_pkey PRIMARY KEY (id);


--
-- TOC entry 3153 (class 2606 OID 20333)
-- Name: customer_notes customer_notes_pkey; Type: CONSTRAINT; Schema: public; Owner: noovos_dev
--

ALTER TABLE ONLY public.customer_notes
    ADD CONSTRAINT customer_notes_pkey PRIMARY KEY (id);


--
-- TOC entry 3193 (class 2606 OID 21903)
-- Name: media media_pkey; Type: CONSTRAINT; Schema: public; Owner: noovos_dev
--

ALTER TABLE ONLY public.media
    ADD CONSTRAINT media_pkey PRIMARY KEY (id);


--
-- TOC entry 3157 (class 2606 OID 20385)
-- Name: notifications notifications_pkey; Type: CONSTRAINT; Schema: public; Owner: noovos_dev
--

ALTER TABLE ONLY public.notifications
    ADD CONSTRAINT notifications_pkey PRIMARY KEY (id);


--
-- TOC entry 3145 (class 2606 OID 20265)
-- Name: payment payment_pkey; Type: CONSTRAINT; Schema: public; Owner: noovos_dev
--

ALTER TABLE ONLY public.payment
    ADD CONSTRAINT payment_pkey PRIMARY KEY (id);


--
-- TOC entry 3147 (class 2606 OID 20267)
-- Name: payment payment_transaction_id_key; Type: CONSTRAINT; Schema: public; Owner: noovos_dev
--

ALTER TABLE ONLY public.payment
    ADD CONSTRAINT payment_transaction_id_key UNIQUE (transaction_id);


--
-- TOC entry 3213 (class 2606 OID 21993)
-- Name: qualification qualification_pkey; Type: CONSTRAINT; Schema: public; Owner: noovos_dev
--

ALTER TABLE ONLY public.qualification
    ADD CONSTRAINT qualification_pkey PRIMARY KEY (id);


--
-- TOC entry 3155 (class 2606 OID 20361)
-- Name: reviews reviews_pkey; Type: CONSTRAINT; Schema: public; Owner: noovos_dev
--

ALTER TABLE ONLY public.reviews
    ADD CONSTRAINT reviews_pkey PRIMARY KEY (id);


--
-- TOC entry 3168 (class 2606 OID 20624)
-- Name: search_log search_logs_pkey; Type: CONSTRAINT; Schema: public; Owner: noovos_dev
--

ALTER TABLE ONLY public.search_log
    ADD CONSTRAINT search_logs_pkey PRIMARY KEY (id);


--
-- TOC entry 3140 (class 2606 OID 20219)
-- Name: service service_pkey; Type: CONSTRAINT; Schema: public; Owner: noovos_dev
--

ALTER TABLE ONLY public.service
    ADD CONSTRAINT service_pkey PRIMARY KEY (id);


--
-- TOC entry 3184 (class 2606 OID 20786)
-- Name: service_staff service_staff_pkey; Type: CONSTRAINT; Schema: public; Owner: noovos_dev
--

ALTER TABLE ONLY public.service_staff
    ADD CONSTRAINT service_staff_pkey PRIMARY KEY (id);


--
-- TOC entry 3151 (class 2606 OID 20311)
-- Name: staff staff_pkey; Type: CONSTRAINT; Schema: public; Owner: noovos_dev
--

ALTER TABLE ONLY public.staff
    ADD CONSTRAINT staff_pkey PRIMARY KEY (id);


--
-- TOC entry 3159 (class 2606 OID 20402)
-- Name: subscription subscription_pkey; Type: CONSTRAINT; Schema: public; Owner: noovos_dev
--

ALTER TABLE ONLY public.subscription
    ADD CONSTRAINT subscription_pkey PRIMARY KEY (id);


--
-- TOC entry 3164 (class 2606 OID 20609)
-- Name: synonyms synonyms_pkey; Type: CONSTRAINT; Schema: public; Owner: noovos_dev
--

ALTER TABLE ONLY public.synonyms
    ADD CONSTRAINT synonyms_pkey PRIMARY KEY (id);


--
-- TOC entry 3166 (class 2606 OID 20611)
-- Name: synonyms synonyms_word_key; Type: CONSTRAINT; Schema: public; Owner: noovos_dev
--

ALTER TABLE ONLY public.synonyms
    ADD CONSTRAINT synonyms_word_key UNIQUE (word);


--
-- TOC entry 3119 (class 2606 OID 20086)
-- Name: app_user users_email_key; Type: CONSTRAINT; Schema: public; Owner: noovos_dev
--

ALTER TABLE ONLY public.app_user
    ADD CONSTRAINT users_email_key UNIQUE (email);


--
-- TOC entry 3121 (class 2606 OID 20088)
-- Name: app_user users_phone_key; Type: CONSTRAINT; Schema: public; Owner: noovos_dev
--

ALTER TABLE ONLY public.app_user
    ADD CONSTRAINT users_phone_key UNIQUE (mobile);


--
-- TOC entry 3123 (class 2606 OID 20084)
-- Name: app_user users_pkey; Type: CONSTRAINT; Schema: public; Owner: noovos_dev
--

ALTER TABLE ONLY public.app_user
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- TOC entry 3116 (class 1259 OID 20425)
-- Name: idx_appuser_email; Type: INDEX; Schema: public; Owner: noovos_dev
--

CREATE INDEX idx_appuser_email ON public.app_user USING btree (email);


--
-- TOC entry 3117 (class 1259 OID 20426)
-- Name: idx_appuser_mobile; Type: INDEX; Schema: public; Owner: noovos_dev
--

CREATE INDEX idx_appuser_mobile ON public.app_user USING btree (mobile);


--
-- TOC entry 3171 (class 1259 OID 20753)
-- Name: idx_available_slot_date; Type: INDEX; Schema: public; Owner: noovos_dev
--

CREATE INDEX idx_available_slot_date ON public.available_slot USING btree (date);


--
-- TOC entry 3172 (class 1259 OID 20754)
-- Name: idx_available_slot_is_booked; Type: INDEX; Schema: public; Owner: noovos_dev
--

CREATE INDEX idx_available_slot_is_booked ON public.available_slot USING btree (is_booked);


--
-- TOC entry 3173 (class 1259 OID 20751)
-- Name: idx_available_slot_service; Type: INDEX; Schema: public; Owner: noovos_dev
--

CREATE INDEX idx_available_slot_service ON public.available_slot USING btree (service_id);


--
-- TOC entry 3174 (class 1259 OID 20804)
-- Name: idx_available_slot_service_date; Type: INDEX; Schema: public; Owner: noovos_dev
--

CREATE INDEX idx_available_slot_service_date ON public.available_slot USING btree (service_id, date);


--
-- TOC entry 3175 (class 1259 OID 20752)
-- Name: idx_available_slot_staff; Type: INDEX; Schema: public; Owner: noovos_dev
--

CREATE INDEX idx_available_slot_staff ON public.available_slot USING btree (staff_id);


--
-- TOC entry 3228 (class 1259 OID 22058)
-- Name: idx_billing_address_business_id; Type: INDEX; Schema: public; Owner: noovos_dev
--

CREATE INDEX idx_billing_address_business_id ON public.business_billing_address USING btree (business_id);


--
-- TOC entry 3178 (class 1259 OID 20777)
-- Name: idx_booking_customer; Type: INDEX; Schema: public; Owner: noovos_dev
--

CREATE INDEX idx_booking_customer ON public.booking USING btree (customer_id);


--
-- TOC entry 3179 (class 1259 OID 20776)
-- Name: idx_booking_slot; Type: INDEX; Schema: public; Owner: noovos_dev
--

CREATE INDEX idx_booking_slot ON public.booking USING btree (slot_id);


--
-- TOC entry 3180 (class 1259 OID 20778)
-- Name: idx_booking_status; Type: INDEX; Schema: public; Owner: noovos_dev
--

CREATE INDEX idx_booking_status ON public.booking USING btree (status);


--
-- TOC entry 3128 (class 1259 OID 20645)
-- Name: idx_business_city; Type: INDEX; Schema: public; Owner: noovos_dev
--

CREATE INDEX idx_business_city ON public.business USING btree (city);


--
-- TOC entry 3129 (class 1259 OID 21889)
-- Name: idx_business_city_trgm; Type: INDEX; Schema: public; Owner: noovos_dev
--

CREATE INDEX idx_business_city_trgm ON public.business USING gin (city public.gin_trgm_ops);


--
-- TOC entry 3222 (class 1259 OID 22033)
-- Name: idx_business_contact_preference_business_id; Type: INDEX; Schema: public; Owner: noovos_dev
--

CREATE INDEX idx_business_contact_preference_business_id ON public.business_contact_preference USING btree (business_id);


--
-- TOC entry 3205 (class 1259 OID 21970)
-- Name: idx_business_employee_business_id; Type: INDEX; Schema: public; Owner: noovos_dev
--

CREATE INDEX idx_business_employee_business_id ON public.business_employee USING btree (business_id);


--
-- TOC entry 3219 (class 1259 OID 22020)
-- Name: idx_business_feature_business_id; Type: INDEX; Schema: public; Owner: noovos_dev
--

CREATE INDEX idx_business_feature_business_id ON public.business_feature USING btree (business_id);


--
-- TOC entry 3202 (class 1259 OID 21958)
-- Name: idx_business_hours_business_id; Type: INDEX; Schema: public; Owner: noovos_dev
--

CREATE INDEX idx_business_hours_business_id ON public.business_hours USING btree (business_id);


--
-- TOC entry 3216 (class 1259 OID 22007)
-- Name: idx_business_insurance_business_id; Type: INDEX; Schema: public; Owner: noovos_dev
--

CREATE INDEX idx_business_insurance_business_id ON public.business_insurance USING btree (business_id);


--
-- TOC entry 3225 (class 1259 OID 22046)
-- Name: idx_business_language_business_id; Type: INDEX; Schema: public; Owner: noovos_dev
--

CREATE INDEX idx_business_language_business_id ON public.business_language USING btree (business_id);


--
-- TOC entry 3130 (class 1259 OID 20644)
-- Name: idx_business_name; Type: INDEX; Schema: public; Owner: noovos_dev
--

CREATE INDEX idx_business_name ON public.business USING btree (name);


--
-- TOC entry 3131 (class 1259 OID 21888)
-- Name: idx_business_name_trgm; Type: INDEX; Schema: public; Owner: noovos_dev
--

CREATE INDEX idx_business_name_trgm ON public.business USING gin (name public.gin_trgm_ops);


--
-- TOC entry 3132 (class 1259 OID 21890)
-- Name: idx_business_postcode_trgm; Type: INDEX; Schema: public; Owner: noovos_dev
--

CREATE INDEX idx_business_postcode_trgm ON public.business USING gin (postcode public.gin_trgm_ops);


--
-- TOC entry 3199 (class 1259 OID 21945)
-- Name: idx_business_social_link_business_id; Type: INDEX; Schema: public; Owner: noovos_dev
--

CREATE INDEX idx_business_social_link_business_id ON public.business_social_link USING btree (business_id);


--
-- TOC entry 3196 (class 1259 OID 21931)
-- Name: idx_business_subcategory_business_id; Type: INDEX; Schema: public; Owner: noovos_dev
--

CREATE INDEX idx_business_subcategory_business_id ON public.business_subcategory USING btree (business_id);


--
-- TOC entry 3208 (class 1259 OID 21981)
-- Name: idx_employee_service_employee_id; Type: INDEX; Schema: public; Owner: noovos_dev
--

CREATE INDEX idx_employee_service_employee_id ON public.business_employee_service USING btree (business_employee_id);


--
-- TOC entry 3209 (class 1259 OID 21982)
-- Name: idx_employee_service_service_id; Type: INDEX; Schema: public; Owner: noovos_dev
--

CREATE INDEX idx_employee_service_service_id ON public.business_employee_service USING btree (service_id);


--
-- TOC entry 3189 (class 1259 OID 22061)
-- Name: idx_media_business_id; Type: INDEX; Schema: public; Owner: noovos_dev
--

CREATE INDEX idx_media_business_id ON public.media USING btree (business_id);


--
-- TOC entry 3190 (class 1259 OID 22063)
-- Name: idx_media_employee_id; Type: INDEX; Schema: public; Owner: noovos_dev
--

CREATE INDEX idx_media_employee_id ON public.media USING btree (business_employee_id);


--
-- TOC entry 3191 (class 1259 OID 22062)
-- Name: idx_media_service_id; Type: INDEX; Schema: public; Owner: noovos_dev
--

CREATE INDEX idx_media_service_id ON public.media USING btree (service_id);


--
-- TOC entry 3141 (class 1259 OID 20434)
-- Name: idx_payment_appuser_id; Type: INDEX; Schema: public; Owner: noovos_dev
--

CREATE INDEX idx_payment_appuser_id ON public.payment USING btree (appuser_id);


--
-- TOC entry 3142 (class 1259 OID 20435)
-- Name: idx_payment_status; Type: INDEX; Schema: public; Owner: noovos_dev
--

CREATE INDEX idx_payment_status ON public.payment USING btree (payment_status);


--
-- TOC entry 3143 (class 1259 OID 20436)
-- Name: idx_payment_transaction_id; Type: INDEX; Schema: public; Owner: noovos_dev
--

CREATE INDEX idx_payment_transaction_id ON public.payment USING btree (transaction_id);


--
-- TOC entry 3210 (class 1259 OID 21995)
-- Name: idx_qualification_business_employee_id; Type: INDEX; Schema: public; Owner: noovos_dev
--

CREATE INDEX idx_qualification_business_employee_id ON public.qualification USING btree (business_employee_id);


--
-- TOC entry 3211 (class 1259 OID 21994)
-- Name: idx_qualification_business_id; Type: INDEX; Schema: public; Owner: noovos_dev
--

CREATE INDEX idx_qualification_business_id ON public.qualification USING btree (business_id);


--
-- TOC entry 3133 (class 1259 OID 20429)
-- Name: idx_service_business_id; Type: INDEX; Schema: public; Owner: noovos_dev
--

CREATE INDEX idx_service_business_id ON public.service USING btree (business_id);


--
-- TOC entry 3134 (class 1259 OID 21891)
-- Name: idx_service_category_id; Type: INDEX; Schema: public; Owner: noovos_dev
--

CREATE INDEX idx_service_category_id ON public.service USING btree (category_id);


--
-- TOC entry 3135 (class 1259 OID 21887)
-- Name: idx_service_description_trgm; Type: INDEX; Schema: public; Owner: noovos_dev
--

CREATE INDEX idx_service_description_trgm ON public.service USING gin (description public.gin_trgm_ops);


--
-- TOC entry 3136 (class 1259 OID 21885)
-- Name: idx_service_fulltext; Type: INDEX; Schema: public; Owner: noovos_dev
--

CREATE INDEX idx_service_fulltext ON public.service USING gin (to_tsvector('english'::regconfig, ((service_name || ' '::text) || description)));


--
-- TOC entry 3137 (class 1259 OID 21886)
-- Name: idx_service_name_trgm; Type: INDEX; Schema: public; Owner: noovos_dev
--

CREATE INDEX idx_service_name_trgm ON public.service USING gin (service_name public.gin_trgm_ops);


--
-- TOC entry 3181 (class 1259 OID 20797)
-- Name: idx_service_staff_service; Type: INDEX; Schema: public; Owner: noovos_dev
--

CREATE INDEX idx_service_staff_service ON public.service_staff USING btree (service_id);


--
-- TOC entry 3182 (class 1259 OID 20798)
-- Name: idx_service_staff_staff; Type: INDEX; Schema: public; Owner: noovos_dev
--

CREATE INDEX idx_service_staff_staff ON public.service_staff USING btree (staff_id);


--
-- TOC entry 3138 (class 1259 OID 20626)
-- Name: idx_service_trigram; Type: INDEX; Schema: public; Owner: noovos_dev
--

CREATE INDEX idx_service_trigram ON public.service USING gin (service_name public.gin_trgm_ops);


--
-- TOC entry 3148 (class 1259 OID 20441)
-- Name: idx_staff_appuser_id; Type: INDEX; Schema: public; Owner: noovos_dev
--

CREATE INDEX idx_staff_appuser_id ON public.staff USING btree (appuser_id);


--
-- TOC entry 3149 (class 1259 OID 20440)
-- Name: idx_staff_business_id; Type: INDEX; Schema: public; Owner: noovos_dev
--

CREATE INDEX idx_staff_business_id ON public.staff USING btree (business_id);


--
-- TOC entry 3162 (class 1259 OID 20612)
-- Name: idx_synonyms_word; Type: INDEX; Schema: public; Owner: noovos_dev
--

CREATE INDEX idx_synonyms_word ON public.synonyms USING btree (word);


--
-- TOC entry 3242 (class 2606 OID 20420)
-- Name: audit_log audit_log_appuser_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: noovos_dev
--

ALTER TABLE ONLY public.audit_log
    ADD CONSTRAINT audit_log_appuser_id_fkey FOREIGN KEY (appuser_id) REFERENCES public.app_user(id);


--
-- TOC entry 3243 (class 2606 OID 20746)
-- Name: available_slot available_slot_customer_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: noovos_dev
--

ALTER TABLE ONLY public.available_slot
    ADD CONSTRAINT available_slot_customer_id_fkey FOREIGN KEY (customer_id) REFERENCES public.app_user(id) ON DELETE SET NULL;


--
-- TOC entry 3244 (class 2606 OID 20736)
-- Name: available_slot available_slot_service_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: noovos_dev
--

ALTER TABLE ONLY public.available_slot
    ADD CONSTRAINT available_slot_service_id_fkey FOREIGN KEY (service_id) REFERENCES public.service(id) ON DELETE CASCADE;


--
-- TOC entry 3245 (class 2606 OID 20771)
-- Name: booking booking_customer_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: noovos_dev
--

ALTER TABLE ONLY public.booking
    ADD CONSTRAINT booking_customer_id_fkey FOREIGN KEY (customer_id) REFERENCES public.app_user(id) ON DELETE CASCADE;


--
-- TOC entry 3246 (class 2606 OID 20766)
-- Name: booking booking_slot_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: noovos_dev
--

ALTER TABLE ONLY public.booking
    ADD CONSTRAINT booking_slot_id_fkey FOREIGN KEY (slot_id) REFERENCES public.available_slot(id) ON DELETE CASCADE;


--
-- TOC entry 3229 (class 2606 OID 20200)
-- Name: business business_appuser_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: noovos_dev
--

ALTER TABLE ONLY public.business
    ADD CONSTRAINT business_appuser_id_fkey FOREIGN KEY (appuser_id) REFERENCES public.app_user(id);


--
-- TOC entry 3235 (class 2606 OID 20339)
-- Name: customer_notes customer_notes_appuser_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: noovos_dev
--

ALTER TABLE ONLY public.customer_notes
    ADD CONSTRAINT customer_notes_appuser_id_fkey FOREIGN KEY (appuser_id) REFERENCES public.app_user(id);


--
-- TOC entry 3236 (class 2606 OID 20334)
-- Name: customer_notes customer_notes_business_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: noovos_dev
--

ALTER TABLE ONLY public.customer_notes
    ADD CONSTRAINT customer_notes_business_id_fkey FOREIGN KEY (business_id) REFERENCES public.business(id);


--
-- TOC entry 3237 (class 2606 OID 20344)
-- Name: customer_notes customer_notes_staff_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: noovos_dev
--

ALTER TABLE ONLY public.customer_notes
    ADD CONSTRAINT customer_notes_staff_id_fkey FOREIGN KEY (staff_id) REFERENCES public.staff(id);


--
-- TOC entry 3240 (class 2606 OID 20386)
-- Name: notifications notifications_appuser_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: noovos_dev
--

ALTER TABLE ONLY public.notifications
    ADD CONSTRAINT notifications_appuser_id_fkey FOREIGN KEY (appuser_id) REFERENCES public.app_user(id);


--
-- TOC entry 3231 (class 2606 OID 20273)
-- Name: payment payment_appuser_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: noovos_dev
--

ALTER TABLE ONLY public.payment
    ADD CONSTRAINT payment_appuser_id_fkey FOREIGN KEY (appuser_id) REFERENCES public.app_user(id);


--
-- TOC entry 3232 (class 2606 OID 20799)
-- Name: payment payment_booking_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: noovos_dev
--

ALTER TABLE ONLY public.payment
    ADD CONSTRAINT payment_booking_id_fkey FOREIGN KEY (booking_id) REFERENCES public.booking(id) ON DELETE CASCADE;


--
-- TOC entry 3238 (class 2606 OID 20367)
-- Name: reviews reviews_appuser_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: noovos_dev
--

ALTER TABLE ONLY public.reviews
    ADD CONSTRAINT reviews_appuser_id_fkey FOREIGN KEY (appuser_id) REFERENCES public.app_user(id);


--
-- TOC entry 3239 (class 2606 OID 20362)
-- Name: reviews reviews_business_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: noovos_dev
--

ALTER TABLE ONLY public.reviews
    ADD CONSTRAINT reviews_business_id_fkey FOREIGN KEY (business_id) REFERENCES public.business(id);


--
-- TOC entry 3230 (class 2606 OID 20220)
-- Name: service service_business_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: noovos_dev
--

ALTER TABLE ONLY public.service
    ADD CONSTRAINT service_business_id_fkey FOREIGN KEY (business_id) REFERENCES public.business(id);


--
-- TOC entry 3247 (class 2606 OID 20787)
-- Name: service_staff service_staff_service_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: noovos_dev
--

ALTER TABLE ONLY public.service_staff
    ADD CONSTRAINT service_staff_service_id_fkey FOREIGN KEY (service_id) REFERENCES public.service(id) ON DELETE CASCADE;


--
-- TOC entry 3248 (class 2606 OID 20792)
-- Name: service_staff service_staff_staff_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: noovos_dev
--

ALTER TABLE ONLY public.service_staff
    ADD CONSTRAINT service_staff_staff_id_fkey FOREIGN KEY (staff_id) REFERENCES public.staff(id) ON DELETE CASCADE;


--
-- TOC entry 3233 (class 2606 OID 20317)
-- Name: staff staff_appuser_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: noovos_dev
--

ALTER TABLE ONLY public.staff
    ADD CONSTRAINT staff_appuser_id_fkey FOREIGN KEY (appuser_id) REFERENCES public.app_user(id);


--
-- TOC entry 3234 (class 2606 OID 20312)
-- Name: staff staff_business_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: noovos_dev
--

ALTER TABLE ONLY public.staff
    ADD CONSTRAINT staff_business_id_fkey FOREIGN KEY (business_id) REFERENCES public.business(id);


--
-- TOC entry 3241 (class 2606 OID 20403)
-- Name: subscription subscription_appuser_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: noovos_dev
--

ALTER TABLE ONLY public.subscription
    ADD CONSTRAINT subscription_appuser_id_fkey FOREIGN KEY (appuser_id) REFERENCES public.app_user(id);


--
-- TOC entry 3375 (class 0 OID 0)
-- Dependencies: 9
-- Name: SCHEMA public; Type: ACL; Schema: -; Owner: postgres
--

REVOKE USAGE ON SCHEMA public FROM PUBLIC;
GRANT ALL ON SCHEMA public TO PUBLIC;


-- Completed on 2025-04-14 18:55:46

--
-- PostgreSQL database dump complete
--

