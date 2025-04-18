PGDMP      ;                }        
   noovos_dev    11.18 (Debian 11.18-0+deb10u1)    17.4 �               0    0    ENCODING    ENCODING        SET client_encoding = 'UTF8';
                           false                       0    0 
   STDSTRINGS 
   STDSTRINGS     (   SET standard_conforming_strings = 'on';
                           false                       0    0 
   SEARCHPATH 
   SEARCHPATH     8   SELECT pg_catalog.set_config('search_path', '', false);
                           false                       1262    20068 
   noovos_dev    DATABASE     v   CREATE DATABASE noovos_dev WITH TEMPLATE = template0 ENCODING = 'UTF8' LOCALE_PROVIDER = libc LOCALE = 'en_US.UTF-8';
    DROP DATABASE noovos_dev;
                     noovos_dev_user    false                       0    0    DATABASE noovos_dev    ACL     p   REVOKE ALL ON DATABASE noovos_dev FROM noovos_dev_user;
GRANT CREATE ON DATABASE noovos_dev TO noovos_dev_user;
                        noovos_dev_user    false    3346            	            2615    2200    public    SCHEMA     2   -- *not* creating schema, since initdb creates it
 2   -- *not* dropping schema, since initdb creates it
                     postgres    false                       0    0    SCHEMA public    ACL     Q   REVOKE USAGE ON SCHEMA public FROM PUBLIC;
GRANT ALL ON SCHEMA public TO PUBLIC;
                        postgres    false    9                        3079    20521    pg_trgm 	   EXTENSION     ;   CREATE EXTENSION IF NOT EXISTS pg_trgm WITH SCHEMA public;
    DROP EXTENSION pg_trgm;
                        false    9                       0    0    EXTENSION pg_trgm    COMMENT     e   COMMENT ON EXTENSION pg_trgm IS 'text similarity measurement and index searching based on trigrams';
                             false    3                        3079    20843    pgcrypto 	   EXTENSION     <   CREATE EXTENSION IF NOT EXISTS pgcrypto WITH SCHEMA public;
    DROP EXTENSION pgcrypto;
                        false    9                       0    0    EXTENSION pgcrypto    COMMENT     <   COMMENT ON EXTENSION pgcrypto IS 'cryptographic functions';
                             false    2            �            1259    20072    app_user    TABLE       CREATE TABLE public.app_user (
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
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    role character varying(20) DEFAULT 'consumer'::character varying,
    landline character varying(20)
);
    DROP TABLE public.app_user;
       public         r       noovos_dev_user    false    9            �            1259    22161    appuser_business_role    TABLE     �   CREATE TABLE public.appuser_business_role (
    id integer NOT NULL,
    appuser_id integer NOT NULL,
    business_id integer NOT NULL,
    role character varying(100) NOT NULL
);
 )   DROP TABLE public.appuser_business_role;
       public         r       noovos_dev_user    false    9            �            1259    22159    appuser_business_role_id_seq    SEQUENCE     �   ALTER TABLE public.appuser_business_role ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.appuser_business_role_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);
            public               noovos_dev_user    false    251    9            �            1259    20410 	   audit_log    TABLE     C  CREATE TABLE public.audit_log (
    id integer NOT NULL,
    appuser_id integer,
    action character varying(255) NOT NULL,
    entity character varying(100) NOT NULL,
    entity_id integer,
    ip_address character varying(45),
    user_agent text,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);
    DROP TABLE public.audit_log;
       public         r       noovos_dev_user    false    9            �            1259    20408    audit_log_id_seq    SEQUENCE     �   CREATE SEQUENCE public.audit_log_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 '   DROP SEQUENCE public.audit_log_id_seq;
       public               noovos_dev_user    false    215    9                       0    0    audit_log_id_seq    SEQUENCE OWNED BY     E   ALTER SEQUENCE public.audit_log_id_seq OWNED BY public.audit_log.id;
          public               noovos_dev_user    false    214            �            1259    22122    available_slot    TABLE     �   CREATE TABLE public.available_slot (
    id integer NOT NULL,
    service_id integer NOT NULL,
    appuser_id integer,
    slot_start timestamp with time zone NOT NULL,
    slot_end timestamp with time zone NOT NULL
);
 "   DROP TABLE public.available_slot;
       public         r       noovos_dev_user    false    9            �            1259    22120    available_slot_id_seq    SEQUENCE     �   ALTER TABLE public.available_slot ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.available_slot_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);
            public               noovos_dev_user    false    9    247            �            1259    22129    booking    TABLE     I  CREATE TABLE public.booking (
    id integer NOT NULL,
    slot_id integer NOT NULL,
    customer_id integer NOT NULL,
    status character varying(20) DEFAULT 'pending'::character varying NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);
    DROP TABLE public.booking;
       public         r       noovos_dev_user    false    9            �            1259    22127    booking_id_seq    SEQUENCE     �   ALTER TABLE public.booking ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.booking_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);
            public               noovos_dev_user    false    249    9            �            1259    20186    business    TABLE       CREATE TABLE public.business (
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
    DROP TABLE public.business;
       public         r       noovos_dev_user    false    9            �            1259    22049    business_billing_address    TABLE       CREATE TABLE public.business_billing_address (
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
 ,   DROP TABLE public.business_billing_address;
       public         r       noovos_dev_user    false    9            �            1259    22047    business_billing_address_id_seq    SEQUENCE     �   CREATE SEQUENCE public.business_billing_address_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 6   DROP SEQUENCE public.business_billing_address_id_seq;
       public               noovos_dev_user    false    9    241                       0    0    business_billing_address_id_seq    SEQUENCE OWNED BY     c   ALTER SEQUENCE public.business_billing_address_id_seq OWNED BY public.business_billing_address.id;
          public               noovos_dev_user    false    240            �            1259    22023    business_contact_preference    TABLE     �   CREATE TABLE public.business_contact_preference (
    id integer NOT NULL,
    business_id integer,
    contact_method text NOT NULL,
    is_preferred boolean DEFAULT false,
    notes text
);
 /   DROP TABLE public.business_contact_preference;
       public         r       noovos_dev_user    false    9            �            1259    22021 "   business_contact_preference_id_seq    SEQUENCE     �   CREATE SEQUENCE public.business_contact_preference_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 9   DROP SEQUENCE public.business_contact_preference_id_seq;
       public               noovos_dev_user    false    9    237                       0    0 "   business_contact_preference_id_seq    SEQUENCE OWNED BY     i   ALTER SEQUENCE public.business_contact_preference_id_seq OWNED BY public.business_contact_preference.id;
          public               noovos_dev_user    false    236            �            1259    22010    business_feature    TABLE     �   CREATE TABLE public.business_feature (
    id integer NOT NULL,
    business_id integer,
    feature_name text NOT NULL,
    is_available boolean DEFAULT false
);
 $   DROP TABLE public.business_feature;
       public         r       noovos_dev_user    false    9            �            1259    22008    business_feature_id_seq    SEQUENCE     �   CREATE SEQUENCE public.business_feature_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 .   DROP SEQUENCE public.business_feature_id_seq;
       public               noovos_dev_user    false    235    9                       0    0    business_feature_id_seq    SEQUENCE OWNED BY     S   ALTER SEQUENCE public.business_feature_id_seq OWNED BY public.business_feature.id;
          public               noovos_dev_user    false    234            �            1259    21948    business_hours    TABLE     �   CREATE TABLE public.business_hours (
    id integer NOT NULL,
    business_id integer,
    day_of_week text NOT NULL,
    open_time time without time zone NOT NULL,
    close_time time without time zone NOT NULL,
    is_closed boolean DEFAULT false
);
 "   DROP TABLE public.business_hours;
       public         r       noovos_dev_user    false    9            �            1259    21946    business_hours_id_seq    SEQUENCE     �   CREATE SEQUENCE public.business_hours_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 ,   DROP SEQUENCE public.business_hours_id_seq;
       public               noovos_dev_user    false    229    9                       0    0    business_hours_id_seq    SEQUENCE OWNED BY     O   ALTER SEQUENCE public.business_hours_id_seq OWNED BY public.business_hours.id;
          public               noovos_dev_user    false    228            �            1259    20184    business_id_seq    SEQUENCE     �   CREATE SEQUENCE public.business_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 &   DROP SEQUENCE public.business_id_seq;
       public               noovos_dev_user    false    201    9                       0    0    business_id_seq    SEQUENCE OWNED BY     C   ALTER SEQUENCE public.business_id_seq OWNED BY public.business.id;
          public               noovos_dev_user    false    200            �            1259    21998    business_insurance    TABLE     �   CREATE TABLE public.business_insurance (
    id integer NOT NULL,
    business_id integer,
    provider_name text NOT NULL,
    policy_number text,
    issue_date date,
    expiry_date date,
    document_image_name text
);
 &   DROP TABLE public.business_insurance;
       public         r       noovos_dev_user    false    9            �            1259    21996    business_insurance_id_seq    SEQUENCE     �   CREATE SEQUENCE public.business_insurance_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 0   DROP SEQUENCE public.business_insurance_id_seq;
       public               noovos_dev_user    false    233    9                       0    0    business_insurance_id_seq    SEQUENCE OWNED BY     W   ALTER SEQUENCE public.business_insurance_id_seq OWNED BY public.business_insurance.id;
          public               noovos_dev_user    false    232            �            1259    22036    business_language    TABLE     �   CREATE TABLE public.business_language (
    id integer NOT NULL,
    business_id integer,
    language_name text NOT NULL,
    is_primary boolean DEFAULT false
);
 %   DROP TABLE public.business_language;
       public         r       noovos_dev_user    false    9            �            1259    22034    business_language_id_seq    SEQUENCE     �   CREATE SEQUENCE public.business_language_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 /   DROP SEQUENCE public.business_language_id_seq;
       public               noovos_dev_user    false    9    239                       0    0    business_language_id_seq    SEQUENCE OWNED BY     U   ALTER SEQUENCE public.business_language_id_seq OWNED BY public.business_language.id;
          public               noovos_dev_user    false    238            �            1259    21936    business_social_link    TABLE     �   CREATE TABLE public.business_social_link (
    id integer NOT NULL,
    business_id integer,
    platform_name text NOT NULL,
    url text NOT NULL
);
 (   DROP TABLE public.business_social_link;
       public         r       noovos_dev_user    false    9            �            1259    21934    business_social_link_id_seq    SEQUENCE     �   CREATE SEQUENCE public.business_social_link_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 2   DROP SEQUENCE public.business_social_link_id_seq;
       public               noovos_dev_user    false    9    227                       0    0    business_social_link_id_seq    SEQUENCE OWNED BY     [   ALTER SEQUENCE public.business_social_link_id_seq OWNED BY public.business_social_link.id;
          public               noovos_dev_user    false    226            �            1259    21922    business_subcategory    TABLE     �   CREATE TABLE public.business_subcategory (
    id integer NOT NULL,
    business_id integer,
    subcategory_name text NOT NULL
);
 (   DROP TABLE public.business_subcategory;
       public         r       noovos_dev_user    false    9            �            1259    21920    business_subcategory_id_seq    SEQUENCE     �   CREATE SEQUENCE public.business_subcategory_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 2   DROP SEQUENCE public.business_subcategory_id_seq;
       public               noovos_dev_user    false    9    225                        0    0    business_subcategory_id_seq    SEQUENCE OWNED BY     [   ALTER SEQUENCE public.business_subcategory_id_seq OWNED BY public.business_subcategory.id;
          public               noovos_dev_user    false    224            �            1259    21874    category    TABLE     �   CREATE TABLE public.category (
    id integer NOT NULL,
    name character varying(100) NOT NULL,
    description text,
    icon_url text
);
    DROP TABLE public.category;
       public         r       noovos_dev_user    false    9            �            1259    21872    category_id_seq    SEQUENCE     �   CREATE SEQUENCE public.category_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 &   DROP SEQUENCE public.category_id_seq;
       public               noovos_dev_user    false    9    221            !           0    0    category_id_seq    SEQUENCE OWNED BY     C   ALTER SEQUENCE public.category_id_seq OWNED BY public.category.id;
          public               noovos_dev_user    false    220            �            1259    20324    customer_notes    TABLE        CREATE TABLE public.customer_notes (
    id integer NOT NULL,
    business_id integer NOT NULL,
    appuser_id integer NOT NULL,
    staff_id integer NOT NULL,
    note text NOT NULL,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);
 "   DROP TABLE public.customer_notes;
       public         r       noovos_dev_user    false    9            �            1259    20322    customer_notes_id_seq    SEQUENCE     �   CREATE SEQUENCE public.customer_notes_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 ,   DROP SEQUENCE public.customer_notes_id_seq;
       public               noovos_dev_user    false    207    9            "           0    0    customer_notes_id_seq    SEQUENCE OWNED BY     O   ALTER SEQUENCE public.customer_notes_id_seq OWNED BY public.customer_notes.id;
          public               noovos_dev_user    false    206            �            1259    21894    media    TABLE     [  CREATE TABLE public.media (
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
    DROP TABLE public.media;
       public         r       noovos_dev_user    false    9            �            1259    21892    image_id_seq    SEQUENCE     �   CREATE SEQUENCE public.image_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 #   DROP SEQUENCE public.image_id_seq;
       public               noovos_dev_user    false    223    9            #           0    0    image_id_seq    SEQUENCE OWNED BY     =   ALTER SEQUENCE public.image_id_seq OWNED BY public.media.id;
          public               noovos_dev_user    false    222            �            1259    20375    notifications    TABLE       CREATE TABLE public.notifications (
    id integer NOT NULL,
    appuser_id integer NOT NULL,
    type character varying(50) NOT NULL,
    message text NOT NULL,
    is_read boolean DEFAULT false,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);
 !   DROP TABLE public.notifications;
       public         r       noovos_dev_user    false    9            �            1259    20373    notifications_id_seq    SEQUENCE     �   CREATE SEQUENCE public.notifications_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 +   DROP SEQUENCE public.notifications_id_seq;
       public               noovos_dev_user    false    211    9            $           0    0    notifications_id_seq    SEQUENCE OWNED BY     M   ALTER SEQUENCE public.notifications_id_seq OWNED BY public.notifications.id;
          public               noovos_dev_user    false    210            �            1259    20256    payment    TABLE     	  CREATE TABLE public.payment (
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
    DROP TABLE public.payment;
       public         r       noovos_dev_user    false    9            �            1259    20254    payment_id_seq    SEQUENCE     �   CREATE SEQUENCE public.payment_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 %   DROP SEQUENCE public.payment_id_seq;
       public               noovos_dev_user    false    205    9            %           0    0    payment_id_seq    SEQUENCE OWNED BY     A   ALTER SEQUENCE public.payment_id_seq OWNED BY public.payment.id;
          public               noovos_dev_user    false    204            �            1259    21985    qualification    TABLE     �   CREATE TABLE public.qualification (
    id integer NOT NULL,
    business_id integer,
    business_employee_id integer,
    qualification_name text NOT NULL,
    issued_by text,
    issue_date date,
    expiry_date date,
    document_image_name text
);
 !   DROP TABLE public.qualification;
       public         r       noovos_dev_user    false    9            �            1259    21983    qualification_id_seq    SEQUENCE     �   CREATE SEQUENCE public.qualification_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 +   DROP SEQUENCE public.qualification_id_seq;
       public               noovos_dev_user    false    231    9            &           0    0    qualification_id_seq    SEQUENCE OWNED BY     M   ALTER SEQUENCE public.qualification_id_seq OWNED BY public.qualification.id;
          public               noovos_dev_user    false    230            �            1259    20351    reviews    TABLE     D  CREATE TABLE public.reviews (
    id integer NOT NULL,
    business_id integer NOT NULL,
    appuser_id integer NOT NULL,
    rating integer NOT NULL,
    review_text text,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT reviews_rating_check CHECK (((rating >= 1) AND (rating <= 5)))
);
    DROP TABLE public.reviews;
       public         r       noovos_dev_user    false    9            �            1259    20349    reviews_id_seq    SEQUENCE     �   CREATE SEQUENCE public.reviews_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 %   DROP SEQUENCE public.reviews_id_seq;
       public               noovos_dev_user    false    209    9            '           0    0    reviews_id_seq    SEQUENCE OWNED BY     A   ALTER SEQUENCE public.reviews_id_seq OWNED BY public.reviews.id;
          public               noovos_dev_user    false    208            �            1259    20615 
   search_log    TABLE     �   CREATE TABLE public.search_log (
    id integer NOT NULL,
    search_term text NOT NULL,
    search_timestamp timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    search_user integer
);
    DROP TABLE public.search_log;
       public         r       noovos_dev_user    false    9            �            1259    20613    search_logs_id_seq    SEQUENCE     �   CREATE SEQUENCE public.search_logs_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 )   DROP SEQUENCE public.search_logs_id_seq;
       public               noovos_dev_user    false    219    9            (           0    0    search_logs_id_seq    SEQUENCE OWNED BY     H   ALTER SEQUENCE public.search_logs_id_seq OWNED BY public.search_log.id;
          public               noovos_dev_user    false    218            �            1259    20207    service    TABLE       CREATE TABLE public.service (
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
    DROP TABLE public.service;
       public         r       noovos_dev_user    false    9            �            1259    20205    service_id_seq    SEQUENCE     �   CREATE SEQUENCE public.service_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 %   DROP SEQUENCE public.service_id_seq;
       public               noovos_dev_user    false    203    9            )           0    0    service_id_seq    SEQUENCE OWNED BY     A   ALTER SEQUENCE public.service_id_seq OWNED BY public.service.id;
          public               noovos_dev_user    false    202            �            1259    22113    service_staff    TABLE     �   CREATE TABLE public.service_staff (
    id integer NOT NULL,
    service_id integer NOT NULL,
    appuser_id integer NOT NULL
);
 !   DROP TABLE public.service_staff;
       public         r       noovos_dev_user    false    9            �            1259    22111    service_staff_id_seq    SEQUENCE     �   ALTER TABLE public.service_staff ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.service_staff_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);
            public               noovos_dev_user    false    245    9            �            1259    22097    staff    TABLE     s  CREATE TABLE public.staff (
    id integer NOT NULL,
    business_id integer NOT NULL,
    appuser_id integer,
    role character varying(50),
    image_name character varying(255),
    bio text,
    is_active boolean DEFAULT true NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);
    DROP TABLE public.staff;
       public         r       noovos_dev_user    false    9            �            1259    22095    staff_id_seq    SEQUENCE     �   ALTER TABLE public.staff ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.staff_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);
            public               noovos_dev_user    false    243    9            �            1259    20393    subscription    TABLE     %  CREATE TABLE public.subscription (
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
     DROP TABLE public.subscription;
       public         r       noovos_dev_user    false    9            �            1259    20391    subscription_id_seq    SEQUENCE     �   CREATE SEQUENCE public.subscription_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 *   DROP SEQUENCE public.subscription_id_seq;
       public               noovos_dev_user    false    9    213            *           0    0    subscription_id_seq    SEQUENCE OWNED BY     K   ALTER SEQUENCE public.subscription_id_seq OWNED BY public.subscription.id;
          public               noovos_dev_user    false    212            �            1259    20601    synonyms    TABLE     p   CREATE TABLE public.synonyms (
    id integer NOT NULL,
    word text NOT NULL,
    synonyms text[] NOT NULL
);
    DROP TABLE public.synonyms;
       public         r       noovos_dev_user    false    9            �            1259    20599    synonyms_id_seq    SEQUENCE     �   CREATE SEQUENCE public.synonyms_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 &   DROP SEQUENCE public.synonyms_id_seq;
       public               noovos_dev_user    false    9    217            +           0    0    synonyms_id_seq    SEQUENCE OWNED BY     C   ALTER SEQUENCE public.synonyms_id_seq OWNED BY public.synonyms.id;
          public               noovos_dev_user    false    216            �            1259    20070    users_id_seq    SEQUENCE     �   CREATE SEQUENCE public.users_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 #   DROP SEQUENCE public.users_id_seq;
       public               noovos_dev_user    false    199    9            ,           0    0    users_id_seq    SEQUENCE OWNED BY     @   ALTER SEQUENCE public.users_id_seq OWNED BY public.app_user.id;
          public               noovos_dev_user    false    198            �           2604    20075    app_user id    DEFAULT     g   ALTER TABLE ONLY public.app_user ALTER COLUMN id SET DEFAULT nextval('public.users_id_seq'::regclass);
 :   ALTER TABLE public.app_user ALTER COLUMN id DROP DEFAULT;
       public               noovos_dev_user    false    198    199    199                        2604    20413    audit_log id    DEFAULT     l   ALTER TABLE ONLY public.audit_log ALTER COLUMN id SET DEFAULT nextval('public.audit_log_id_seq'::regclass);
 ;   ALTER TABLE public.audit_log ALTER COLUMN id DROP DEFAULT;
       public               noovos_dev_user    false    215    214    215            �           2604    20189    business id    DEFAULT     j   ALTER TABLE ONLY public.business ALTER COLUMN id SET DEFAULT nextval('public.business_id_seq'::regclass);
 :   ALTER TABLE public.business ALTER COLUMN id DROP DEFAULT;
       public               noovos_dev_user    false    200    201    201                       2604    22052    business_billing_address id    DEFAULT     �   ALTER TABLE ONLY public.business_billing_address ALTER COLUMN id SET DEFAULT nextval('public.business_billing_address_id_seq'::regclass);
 J   ALTER TABLE public.business_billing_address ALTER COLUMN id DROP DEFAULT;
       public               noovos_dev_user    false    241    240    241                       2604    22026    business_contact_preference id    DEFAULT     �   ALTER TABLE ONLY public.business_contact_preference ALTER COLUMN id SET DEFAULT nextval('public.business_contact_preference_id_seq'::regclass);
 M   ALTER TABLE public.business_contact_preference ALTER COLUMN id DROP DEFAULT;
       public               noovos_dev_user    false    236    237    237                       2604    22013    business_feature id    DEFAULT     z   ALTER TABLE ONLY public.business_feature ALTER COLUMN id SET DEFAULT nextval('public.business_feature_id_seq'::regclass);
 B   ALTER TABLE public.business_feature ALTER COLUMN id DROP DEFAULT;
       public               noovos_dev_user    false    235    234    235                       2604    21951    business_hours id    DEFAULT     v   ALTER TABLE ONLY public.business_hours ALTER COLUMN id SET DEFAULT nextval('public.business_hours_id_seq'::regclass);
 @   ALTER TABLE public.business_hours ALTER COLUMN id DROP DEFAULT;
       public               noovos_dev_user    false    229    228    229                       2604    22001    business_insurance id    DEFAULT     ~   ALTER TABLE ONLY public.business_insurance ALTER COLUMN id SET DEFAULT nextval('public.business_insurance_id_seq'::regclass);
 D   ALTER TABLE public.business_insurance ALTER COLUMN id DROP DEFAULT;
       public               noovos_dev_user    false    233    232    233                       2604    22039    business_language id    DEFAULT     |   ALTER TABLE ONLY public.business_language ALTER COLUMN id SET DEFAULT nextval('public.business_language_id_seq'::regclass);
 C   ALTER TABLE public.business_language ALTER COLUMN id DROP DEFAULT;
       public               noovos_dev_user    false    238    239    239                       2604    21939    business_social_link id    DEFAULT     �   ALTER TABLE ONLY public.business_social_link ALTER COLUMN id SET DEFAULT nextval('public.business_social_link_id_seq'::regclass);
 F   ALTER TABLE public.business_social_link ALTER COLUMN id DROP DEFAULT;
       public               noovos_dev_user    false    226    227    227            
           2604    21925    business_subcategory id    DEFAULT     �   ALTER TABLE ONLY public.business_subcategory ALTER COLUMN id SET DEFAULT nextval('public.business_subcategory_id_seq'::regclass);
 F   ALTER TABLE public.business_subcategory ALTER COLUMN id DROP DEFAULT;
       public               noovos_dev_user    false    224    225    225                       2604    21877    category id    DEFAULT     j   ALTER TABLE ONLY public.category ALTER COLUMN id SET DEFAULT nextval('public.category_id_seq'::regclass);
 :   ALTER TABLE public.category ALTER COLUMN id DROP DEFAULT;
       public               noovos_dev_user    false    220    221    221            �           2604    20327    customer_notes id    DEFAULT     v   ALTER TABLE ONLY public.customer_notes ALTER COLUMN id SET DEFAULT nextval('public.customer_notes_id_seq'::regclass);
 @   ALTER TABLE public.customer_notes ALTER COLUMN id DROP DEFAULT;
       public               noovos_dev_user    false    207    206    207                       2604    21897    media id    DEFAULT     d   ALTER TABLE ONLY public.media ALTER COLUMN id SET DEFAULT nextval('public.image_id_seq'::regclass);
 7   ALTER TABLE public.media ALTER COLUMN id DROP DEFAULT;
       public               noovos_dev_user    false    223    222    223            �           2604    20378    notifications id    DEFAULT     t   ALTER TABLE ONLY public.notifications ALTER COLUMN id SET DEFAULT nextval('public.notifications_id_seq'::regclass);
 ?   ALTER TABLE public.notifications ALTER COLUMN id DROP DEFAULT;
       public               noovos_dev_user    false    211    210    211            �           2604    20259 
   payment id    DEFAULT     h   ALTER TABLE ONLY public.payment ALTER COLUMN id SET DEFAULT nextval('public.payment_id_seq'::regclass);
 9   ALTER TABLE public.payment ALTER COLUMN id DROP DEFAULT;
       public               noovos_dev_user    false    205    204    205                       2604    21988    qualification id    DEFAULT     t   ALTER TABLE ONLY public.qualification ALTER COLUMN id SET DEFAULT nextval('public.qualification_id_seq'::regclass);
 ?   ALTER TABLE public.qualification ALTER COLUMN id DROP DEFAULT;
       public               noovos_dev_user    false    231    230    231            �           2604    20354 
   reviews id    DEFAULT     h   ALTER TABLE ONLY public.reviews ALTER COLUMN id SET DEFAULT nextval('public.reviews_id_seq'::regclass);
 9   ALTER TABLE public.reviews ALTER COLUMN id DROP DEFAULT;
       public               noovos_dev_user    false    208    209    209                       2604    20618    search_log id    DEFAULT     o   ALTER TABLE ONLY public.search_log ALTER COLUMN id SET DEFAULT nextval('public.search_logs_id_seq'::regclass);
 <   ALTER TABLE public.search_log ALTER COLUMN id DROP DEFAULT;
       public               noovos_dev_user    false    219    218    219            �           2604    20210 
   service id    DEFAULT     h   ALTER TABLE ONLY public.service ALTER COLUMN id SET DEFAULT nextval('public.service_id_seq'::regclass);
 9   ALTER TABLE public.service ALTER COLUMN id DROP DEFAULT;
       public               noovos_dev_user    false    203    202    203            �           2604    20396    subscription id    DEFAULT     r   ALTER TABLE ONLY public.subscription ALTER COLUMN id SET DEFAULT nextval('public.subscription_id_seq'::regclass);
 >   ALTER TABLE public.subscription ALTER COLUMN id DROP DEFAULT;
       public               noovos_dev_user    false    213    212    213                       2604    20604    synonyms id    DEFAULT     j   ALTER TABLE ONLY public.synonyms ALTER COLUMN id SET DEFAULT nextval('public.synonyms_id_seq'::regclass);
 :   ALTER TABLE public.synonyms ALTER COLUMN id DROP DEFAULT;
       public               noovos_dev_user    false    216    217    217            �           2606    22186 K   appuser_business_role appuser_business_role_appuser_id_business_id_role_key 
   CONSTRAINT     �   ALTER TABLE ONLY public.appuser_business_role
    ADD CONSTRAINT appuser_business_role_appuser_id_business_id_role_key UNIQUE (appuser_id, business_id, role);
 u   ALTER TABLE ONLY public.appuser_business_role DROP CONSTRAINT appuser_business_role_appuser_id_business_id_role_key;
       public                 noovos_dev_user    false    251    251    251            �           2606    22165 0   appuser_business_role appuser_business_role_pkey 
   CONSTRAINT     n   ALTER TABLE ONLY public.appuser_business_role
    ADD CONSTRAINT appuser_business_role_pkey PRIMARY KEY (id);
 Z   ALTER TABLE ONLY public.appuser_business_role DROP CONSTRAINT appuser_business_role_pkey;
       public                 noovos_dev_user    false    251            G           2606    20419    audit_log audit_log_pkey 
   CONSTRAINT     V   ALTER TABLE ONLY public.audit_log
    ADD CONSTRAINT audit_log_pkey PRIMARY KEY (id);
 B   ALTER TABLE ONLY public.audit_log DROP CONSTRAINT audit_log_pkey;
       public                 noovos_dev_user    false    215            }           2606    22126 "   available_slot available_slot_pkey 
   CONSTRAINT     `   ALTER TABLE ONLY public.available_slot
    ADD CONSTRAINT available_slot_pkey PRIMARY KEY (id);
 L   ALTER TABLE ONLY public.available_slot DROP CONSTRAINT available_slot_pkey;
       public                 noovos_dev_user    false    247            �           2606    22136    booking booking_pkey 
   CONSTRAINT     R   ALTER TABLE ONLY public.booking
    ADD CONSTRAINT booking_pkey PRIMARY KEY (id);
 >   ALTER TABLE ONLY public.booking DROP CONSTRAINT booking_pkey;
       public                 noovos_dev_user    false    249            �           2606    22138    booking booking_slot_id_key 
   CONSTRAINT     Y   ALTER TABLE ONLY public.booking
    ADD CONSTRAINT booking_slot_id_key UNIQUE (slot_id);
 E   ALTER TABLE ONLY public.booking DROP CONSTRAINT booking_slot_id_key;
       public                 noovos_dev_user    false    249            r           2606    22057 6   business_billing_address business_billing_address_pkey 
   CONSTRAINT     t   ALTER TABLE ONLY public.business_billing_address
    ADD CONSTRAINT business_billing_address_pkey PRIMARY KEY (id);
 `   ALTER TABLE ONLY public.business_billing_address DROP CONSTRAINT business_billing_address_pkey;
       public                 noovos_dev_user    false    241            l           2606    22032 <   business_contact_preference business_contact_preference_pkey 
   CONSTRAINT     z   ALTER TABLE ONLY public.business_contact_preference
    ADD CONSTRAINT business_contact_preference_pkey PRIMARY KEY (id);
 f   ALTER TABLE ONLY public.business_contact_preference DROP CONSTRAINT business_contact_preference_pkey;
       public                 noovos_dev_user    false    237            '           2606    20199    business business_email_key 
   CONSTRAINT     W   ALTER TABLE ONLY public.business
    ADD CONSTRAINT business_email_key UNIQUE (email);
 E   ALTER TABLE ONLY public.business DROP CONSTRAINT business_email_key;
       public                 noovos_dev_user    false    201            i           2606    22019 &   business_feature business_feature_pkey 
   CONSTRAINT     d   ALTER TABLE ONLY public.business_feature
    ADD CONSTRAINT business_feature_pkey PRIMARY KEY (id);
 P   ALTER TABLE ONLY public.business_feature DROP CONSTRAINT business_feature_pkey;
       public                 noovos_dev_user    false    235            _           2606    21957 "   business_hours business_hours_pkey 
   CONSTRAINT     `   ALTER TABLE ONLY public.business_hours
    ADD CONSTRAINT business_hours_pkey PRIMARY KEY (id);
 L   ALTER TABLE ONLY public.business_hours DROP CONSTRAINT business_hours_pkey;
       public                 noovos_dev_user    false    229            f           2606    22006 *   business_insurance business_insurance_pkey 
   CONSTRAINT     h   ALTER TABLE ONLY public.business_insurance
    ADD CONSTRAINT business_insurance_pkey PRIMARY KEY (id);
 T   ALTER TABLE ONLY public.business_insurance DROP CONSTRAINT business_insurance_pkey;
       public                 noovos_dev_user    false    233            o           2606    22045 (   business_language business_language_pkey 
   CONSTRAINT     f   ALTER TABLE ONLY public.business_language
    ADD CONSTRAINT business_language_pkey PRIMARY KEY (id);
 R   ALTER TABLE ONLY public.business_language DROP CONSTRAINT business_language_pkey;
       public                 noovos_dev_user    false    239            )           2606    20197    business business_pkey 
   CONSTRAINT     T   ALTER TABLE ONLY public.business
    ADD CONSTRAINT business_pkey PRIMARY KEY (id);
 @   ALTER TABLE ONLY public.business DROP CONSTRAINT business_pkey;
       public                 noovos_dev_user    false    201            \           2606    21944 .   business_social_link business_social_link_pkey 
   CONSTRAINT     l   ALTER TABLE ONLY public.business_social_link
    ADD CONSTRAINT business_social_link_pkey PRIMARY KEY (id);
 X   ALTER TABLE ONLY public.business_social_link DROP CONSTRAINT business_social_link_pkey;
       public                 noovos_dev_user    false    227            Y           2606    21930 .   business_subcategory business_subcategory_pkey 
   CONSTRAINT     l   ALTER TABLE ONLY public.business_subcategory
    ADD CONSTRAINT business_subcategory_pkey PRIMARY KEY (id);
 X   ALTER TABLE ONLY public.business_subcategory DROP CONSTRAINT business_subcategory_pkey;
       public                 noovos_dev_user    false    225            P           2606    21884    category category_name_key 
   CONSTRAINT     U   ALTER TABLE ONLY public.category
    ADD CONSTRAINT category_name_key UNIQUE (name);
 D   ALTER TABLE ONLY public.category DROP CONSTRAINT category_name_key;
       public                 noovos_dev_user    false    221            R           2606    21882    category category_pkey 
   CONSTRAINT     T   ALTER TABLE ONLY public.category
    ADD CONSTRAINT category_pkey PRIMARY KEY (id);
 @   ALTER TABLE ONLY public.category DROP CONSTRAINT category_pkey;
       public                 noovos_dev_user    false    221            ?           2606    20333 "   customer_notes customer_notes_pkey 
   CONSTRAINT     `   ALTER TABLE ONLY public.customer_notes
    ADD CONSTRAINT customer_notes_pkey PRIMARY KEY (id);
 L   ALTER TABLE ONLY public.customer_notes DROP CONSTRAINT customer_notes_pkey;
       public                 noovos_dev_user    false    207            W           2606    21903    media media_pkey 
   CONSTRAINT     N   ALTER TABLE ONLY public.media
    ADD CONSTRAINT media_pkey PRIMARY KEY (id);
 :   ALTER TABLE ONLY public.media DROP CONSTRAINT media_pkey;
       public                 noovos_dev_user    false    223            C           2606    20385     notifications notifications_pkey 
   CONSTRAINT     ^   ALTER TABLE ONLY public.notifications
    ADD CONSTRAINT notifications_pkey PRIMARY KEY (id);
 J   ALTER TABLE ONLY public.notifications DROP CONSTRAINT notifications_pkey;
       public                 noovos_dev_user    false    211            ;           2606    20265    payment payment_pkey 
   CONSTRAINT     R   ALTER TABLE ONLY public.payment
    ADD CONSTRAINT payment_pkey PRIMARY KEY (id);
 >   ALTER TABLE ONLY public.payment DROP CONSTRAINT payment_pkey;
       public                 noovos_dev_user    false    205            =           2606    20267 "   payment payment_transaction_id_key 
   CONSTRAINT     g   ALTER TABLE ONLY public.payment
    ADD CONSTRAINT payment_transaction_id_key UNIQUE (transaction_id);
 L   ALTER TABLE ONLY public.payment DROP CONSTRAINT payment_transaction_id_key;
       public                 noovos_dev_user    false    205            d           2606    21993     qualification qualification_pkey 
   CONSTRAINT     ^   ALTER TABLE ONLY public.qualification
    ADD CONSTRAINT qualification_pkey PRIMARY KEY (id);
 J   ALTER TABLE ONLY public.qualification DROP CONSTRAINT qualification_pkey;
       public                 noovos_dev_user    false    231            A           2606    20361    reviews reviews_pkey 
   CONSTRAINT     R   ALTER TABLE ONLY public.reviews
    ADD CONSTRAINT reviews_pkey PRIMARY KEY (id);
 >   ALTER TABLE ONLY public.reviews DROP CONSTRAINT reviews_pkey;
       public                 noovos_dev_user    false    209            N           2606    20624    search_log search_logs_pkey 
   CONSTRAINT     Y   ALTER TABLE ONLY public.search_log
    ADD CONSTRAINT search_logs_pkey PRIMARY KEY (id);
 E   ALTER TABLE ONLY public.search_log DROP CONSTRAINT search_logs_pkey;
       public                 noovos_dev_user    false    219            6           2606    20219    service service_pkey 
   CONSTRAINT     R   ALTER TABLE ONLY public.service
    ADD CONSTRAINT service_pkey PRIMARY KEY (id);
 >   ALTER TABLE ONLY public.service DROP CONSTRAINT service_pkey;
       public                 noovos_dev_user    false    203            {           2606    22117     service_staff service_staff_pkey 
   CONSTRAINT     ^   ALTER TABLE ONLY public.service_staff
    ADD CONSTRAINT service_staff_pkey PRIMARY KEY (id);
 J   ALTER TABLE ONLY public.service_staff DROP CONSTRAINT service_staff_pkey;
       public                 noovos_dev_user    false    245            w           2606    22107    staff staff_pkey 
   CONSTRAINT     N   ALTER TABLE ONLY public.staff
    ADD CONSTRAINT staff_pkey PRIMARY KEY (id);
 :   ALTER TABLE ONLY public.staff DROP CONSTRAINT staff_pkey;
       public                 noovos_dev_user    false    243            E           2606    20402    subscription subscription_pkey 
   CONSTRAINT     \   ALTER TABLE ONLY public.subscription
    ADD CONSTRAINT subscription_pkey PRIMARY KEY (id);
 H   ALTER TABLE ONLY public.subscription DROP CONSTRAINT subscription_pkey;
       public                 noovos_dev_user    false    213            J           2606    20609    synonyms synonyms_pkey 
   CONSTRAINT     T   ALTER TABLE ONLY public.synonyms
    ADD CONSTRAINT synonyms_pkey PRIMARY KEY (id);
 @   ALTER TABLE ONLY public.synonyms DROP CONSTRAINT synonyms_pkey;
       public                 noovos_dev_user    false    217            L           2606    20611    synonyms synonyms_word_key 
   CONSTRAINT     U   ALTER TABLE ONLY public.synonyms
    ADD CONSTRAINT synonyms_word_key UNIQUE (word);
 D   ALTER TABLE ONLY public.synonyms DROP CONSTRAINT synonyms_word_key;
       public                 noovos_dev_user    false    217            !           2606    20086    app_user users_email_key 
   CONSTRAINT     T   ALTER TABLE ONLY public.app_user
    ADD CONSTRAINT users_email_key UNIQUE (email);
 B   ALTER TABLE ONLY public.app_user DROP CONSTRAINT users_email_key;
       public                 noovos_dev_user    false    199            #           2606    20088    app_user users_phone_key 
   CONSTRAINT     U   ALTER TABLE ONLY public.app_user
    ADD CONSTRAINT users_phone_key UNIQUE (mobile);
 B   ALTER TABLE ONLY public.app_user DROP CONSTRAINT users_phone_key;
       public                 noovos_dev_user    false    199            %           2606    20084    app_user users_pkey 
   CONSTRAINT     Q   ALTER TABLE ONLY public.app_user
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);
 =   ALTER TABLE ONLY public.app_user DROP CONSTRAINT users_pkey;
       public                 noovos_dev_user    false    199            �           1259    22168    idx_abr_appuser_id    INDEX     Z   CREATE INDEX idx_abr_appuser_id ON public.appuser_business_role USING btree (appuser_id);
 &   DROP INDEX public.idx_abr_appuser_id;
       public                 noovos_dev_user    false    251            �           1259    22169    idx_abr_business_id    INDEX     \   CREATE INDEX idx_abr_business_id ON public.appuser_business_role USING btree (business_id);
 '   DROP INDEX public.idx_abr_business_id;
       public                 noovos_dev_user    false    251                       1259    20425    idx_appuser_email    INDEX     G   CREATE INDEX idx_appuser_email ON public.app_user USING btree (email);
 %   DROP INDEX public.idx_appuser_email;
       public                 noovos_dev_user    false    199                       1259    20426    idx_appuser_mobile    INDEX     I   CREATE INDEX idx_appuser_mobile ON public.app_user USING btree (mobile);
 &   DROP INDEX public.idx_appuser_mobile;
       public                 noovos_dev_user    false    199            ~           1259    22139    idx_available_slot_service_id    INDEX     ^   CREATE INDEX idx_available_slot_service_id ON public.available_slot USING btree (service_id);
 1   DROP INDEX public.idx_available_slot_service_id;
       public                 noovos_dev_user    false    247                       1259    22140    idx_available_slot_unassigned    INDEX     y   CREATE INDEX idx_available_slot_unassigned ON public.available_slot USING btree (slot_start) WHERE (appuser_id IS NULL);
 1   DROP INDEX public.idx_available_slot_unassigned;
       public                 noovos_dev_user    false    247    247            s           1259    22058    idx_billing_address_business_id    INDEX     k   CREATE INDEX idx_billing_address_business_id ON public.business_billing_address USING btree (business_id);
 3   DROP INDEX public.idx_billing_address_business_id;
       public                 noovos_dev_user    false    241            �           1259    22141    idx_booking_customer_id    INDEX     R   CREATE INDEX idx_booking_customer_id ON public.booking USING btree (customer_id);
 +   DROP INDEX public.idx_booking_customer_id;
       public                 noovos_dev_user    false    249            *           1259    20645    idx_business_city    INDEX     F   CREATE INDEX idx_business_city ON public.business USING btree (city);
 %   DROP INDEX public.idx_business_city;
       public                 noovos_dev_user    false    201            +           1259    21889    idx_business_city_trgm    INDEX     ]   CREATE INDEX idx_business_city_trgm ON public.business USING gin (city public.gin_trgm_ops);
 *   DROP INDEX public.idx_business_city_trgm;
       public                 noovos_dev_user    false    201    3    9    3    3    9    9    3    3    9    9    3    9    3    9    3    9    3    3    9    9    3    3    9    9            m           1259    22033 +   idx_business_contact_preference_business_id    INDEX     z   CREATE INDEX idx_business_contact_preference_business_id ON public.business_contact_preference USING btree (business_id);
 ?   DROP INDEX public.idx_business_contact_preference_business_id;
       public                 noovos_dev_user    false    237            j           1259    22020     idx_business_feature_business_id    INDEX     d   CREATE INDEX idx_business_feature_business_id ON public.business_feature USING btree (business_id);
 4   DROP INDEX public.idx_business_feature_business_id;
       public                 noovos_dev_user    false    235            `           1259    21958    idx_business_hours_business_id    INDEX     `   CREATE INDEX idx_business_hours_business_id ON public.business_hours USING btree (business_id);
 2   DROP INDEX public.idx_business_hours_business_id;
       public                 noovos_dev_user    false    229            g           1259    22007 "   idx_business_insurance_business_id    INDEX     h   CREATE INDEX idx_business_insurance_business_id ON public.business_insurance USING btree (business_id);
 6   DROP INDEX public.idx_business_insurance_business_id;
       public                 noovos_dev_user    false    233            p           1259    22046 !   idx_business_language_business_id    INDEX     f   CREATE INDEX idx_business_language_business_id ON public.business_language USING btree (business_id);
 5   DROP INDEX public.idx_business_language_business_id;
       public                 noovos_dev_user    false    239            ,           1259    20644    idx_business_name    INDEX     F   CREATE INDEX idx_business_name ON public.business USING btree (name);
 %   DROP INDEX public.idx_business_name;
       public                 noovos_dev_user    false    201            -           1259    21888    idx_business_name_trgm    INDEX     ]   CREATE INDEX idx_business_name_trgm ON public.business USING gin (name public.gin_trgm_ops);
 *   DROP INDEX public.idx_business_name_trgm;
       public                 noovos_dev_user    false    3    9    3    3    9    9    3    3    9    9    3    9    3    9    3    9    3    3    9    9    3    3    9    9    201            .           1259    21890    idx_business_postcode_trgm    INDEX     e   CREATE INDEX idx_business_postcode_trgm ON public.business USING gin (postcode public.gin_trgm_ops);
 .   DROP INDEX public.idx_business_postcode_trgm;
       public                 noovos_dev_user    false    3    9    3    3    9    9    3    3    9    9    3    9    3    9    3    9    3    3    9    9    3    3    9    9    201            ]           1259    21945 $   idx_business_social_link_business_id    INDEX     l   CREATE INDEX idx_business_social_link_business_id ON public.business_social_link USING btree (business_id);
 8   DROP INDEX public.idx_business_social_link_business_id;
       public                 noovos_dev_user    false    227            Z           1259    21931 $   idx_business_subcategory_business_id    INDEX     l   CREATE INDEX idx_business_subcategory_business_id ON public.business_subcategory USING btree (business_id);
 8   DROP INDEX public.idx_business_subcategory_business_id;
       public                 noovos_dev_user    false    225            S           1259    22061    idx_media_business_id    INDEX     N   CREATE INDEX idx_media_business_id ON public.media USING btree (business_id);
 )   DROP INDEX public.idx_media_business_id;
       public                 noovos_dev_user    false    223            T           1259    22063    idx_media_employee_id    INDEX     W   CREATE INDEX idx_media_employee_id ON public.media USING btree (business_employee_id);
 )   DROP INDEX public.idx_media_employee_id;
       public                 noovos_dev_user    false    223            U           1259    22062    idx_media_service_id    INDEX     L   CREATE INDEX idx_media_service_id ON public.media USING btree (service_id);
 (   DROP INDEX public.idx_media_service_id;
       public                 noovos_dev_user    false    223            7           1259    20434    idx_payment_appuser_id    INDEX     P   CREATE INDEX idx_payment_appuser_id ON public.payment USING btree (appuser_id);
 *   DROP INDEX public.idx_payment_appuser_id;
       public                 noovos_dev_user    false    205            8           1259    20435    idx_payment_status    INDEX     P   CREATE INDEX idx_payment_status ON public.payment USING btree (payment_status);
 &   DROP INDEX public.idx_payment_status;
       public                 noovos_dev_user    false    205            9           1259    20436    idx_payment_transaction_id    INDEX     X   CREATE INDEX idx_payment_transaction_id ON public.payment USING btree (transaction_id);
 .   DROP INDEX public.idx_payment_transaction_id;
       public                 noovos_dev_user    false    205            a           1259    21995 &   idx_qualification_business_employee_id    INDEX     p   CREATE INDEX idx_qualification_business_employee_id ON public.qualification USING btree (business_employee_id);
 :   DROP INDEX public.idx_qualification_business_employee_id;
       public                 noovos_dev_user    false    231            b           1259    21994    idx_qualification_business_id    INDEX     ^   CREATE INDEX idx_qualification_business_id ON public.qualification USING btree (business_id);
 1   DROP INDEX public.idx_qualification_business_id;
       public                 noovos_dev_user    false    231            /           1259    20429    idx_service_business_id    INDEX     R   CREATE INDEX idx_service_business_id ON public.service USING btree (business_id);
 +   DROP INDEX public.idx_service_business_id;
       public                 noovos_dev_user    false    203            0           1259    21891    idx_service_category_id    INDEX     R   CREATE INDEX idx_service_category_id ON public.service USING btree (category_id);
 +   DROP INDEX public.idx_service_category_id;
       public                 noovos_dev_user    false    203            1           1259    21887    idx_service_description_trgm    INDEX     i   CREATE INDEX idx_service_description_trgm ON public.service USING gin (description public.gin_trgm_ops);
 0   DROP INDEX public.idx_service_description_trgm;
       public                 noovos_dev_user    false    203    3    9    3    3    9    9    3    3    9    9    3    9    3    9    3    9    3    3    9    9    3    3    9    9            2           1259    21885    idx_service_fulltext    INDEX     �   CREATE INDEX idx_service_fulltext ON public.service USING gin (to_tsvector('english'::regconfig, ((service_name || ' '::text) || description)));
 (   DROP INDEX public.idx_service_fulltext;
       public                 noovos_dev_user    false    203    203    203            3           1259    21886    idx_service_name_trgm    INDEX     c   CREATE INDEX idx_service_name_trgm ON public.service USING gin (service_name public.gin_trgm_ops);
 )   DROP INDEX public.idx_service_name_trgm;
       public                 noovos_dev_user    false    203    3    9    3    3    9    9    3    3    9    9    3    9    3    9    3    9    3    3    9    9    3    3    9    9            x           1259    22118    idx_service_staff_appuser_id    INDEX     \   CREATE INDEX idx_service_staff_appuser_id ON public.service_staff USING btree (appuser_id);
 0   DROP INDEX public.idx_service_staff_appuser_id;
       public                 noovos_dev_user    false    245            y           1259    22119    idx_service_staff_service_id    INDEX     \   CREATE INDEX idx_service_staff_service_id ON public.service_staff USING btree (service_id);
 0   DROP INDEX public.idx_service_staff_service_id;
       public                 noovos_dev_user    false    245            4           1259    20626    idx_service_trigram    INDEX     a   CREATE INDEX idx_service_trigram ON public.service USING gin (service_name public.gin_trgm_ops);
 '   DROP INDEX public.idx_service_trigram;
       public                 noovos_dev_user    false    3    9    3    3    9    9    3    3    9    9    3    9    3    9    3    9    3    3    9    9    3    3    9    9    203            t           1259    22109    idx_staff_appuser_id    INDEX     L   CREATE INDEX idx_staff_appuser_id ON public.staff USING btree (appuser_id);
 (   DROP INDEX public.idx_staff_appuser_id;
       public                 noovos_dev_user    false    243            u           1259    22108    idx_staff_business_id    INDEX     N   CREATE INDEX idx_staff_business_id ON public.staff USING btree (business_id);
 )   DROP INDEX public.idx_staff_business_id;
       public                 noovos_dev_user    false    243            H           1259    20612    idx_synonyms_word    INDEX     F   CREATE INDEX idx_synonyms_word ON public.synonyms USING btree (word);
 %   DROP INDEX public.idx_synonyms_word;
       public                 noovos_dev_user    false    217            �           2606    20420 #   audit_log audit_log_appuser_id_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.audit_log
    ADD CONSTRAINT audit_log_appuser_id_fkey FOREIGN KEY (appuser_id) REFERENCES public.app_user(id);
 M   ALTER TABLE ONLY public.audit_log DROP CONSTRAINT audit_log_appuser_id_fkey;
       public               noovos_dev_user    false    199    3109    215            �           2606    20200 !   business business_appuser_id_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.business
    ADD CONSTRAINT business_appuser_id_fkey FOREIGN KEY (appuser_id) REFERENCES public.app_user(id);
 K   ALTER TABLE ONLY public.business DROP CONSTRAINT business_appuser_id_fkey;
       public               noovos_dev_user    false    3109    199    201            �           2606    20339 -   customer_notes customer_notes_appuser_id_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.customer_notes
    ADD CONSTRAINT customer_notes_appuser_id_fkey FOREIGN KEY (appuser_id) REFERENCES public.app_user(id);
 W   ALTER TABLE ONLY public.customer_notes DROP CONSTRAINT customer_notes_appuser_id_fkey;
       public               noovos_dev_user    false    199    3109    207            �           2606    20334 .   customer_notes customer_notes_business_id_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.customer_notes
    ADD CONSTRAINT customer_notes_business_id_fkey FOREIGN KEY (business_id) REFERENCES public.business(id);
 X   ALTER TABLE ONLY public.customer_notes DROP CONSTRAINT customer_notes_business_id_fkey;
       public               noovos_dev_user    false    201    3113    207            �           2606    20386 +   notifications notifications_appuser_id_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.notifications
    ADD CONSTRAINT notifications_appuser_id_fkey FOREIGN KEY (appuser_id) REFERENCES public.app_user(id);
 U   ALTER TABLE ONLY public.notifications DROP CONSTRAINT notifications_appuser_id_fkey;
       public               noovos_dev_user    false    3109    199    211            �           2606    20273    payment payment_appuser_id_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.payment
    ADD CONSTRAINT payment_appuser_id_fkey FOREIGN KEY (appuser_id) REFERENCES public.app_user(id);
 I   ALTER TABLE ONLY public.payment DROP CONSTRAINT payment_appuser_id_fkey;
       public               noovos_dev_user    false    199    205    3109            �           2606    20367    reviews reviews_appuser_id_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.reviews
    ADD CONSTRAINT reviews_appuser_id_fkey FOREIGN KEY (appuser_id) REFERENCES public.app_user(id);
 I   ALTER TABLE ONLY public.reviews DROP CONSTRAINT reviews_appuser_id_fkey;
       public               noovos_dev_user    false    209    3109    199            �           2606    20362     reviews reviews_business_id_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.reviews
    ADD CONSTRAINT reviews_business_id_fkey FOREIGN KEY (business_id) REFERENCES public.business(id);
 J   ALTER TABLE ONLY public.reviews DROP CONSTRAINT reviews_business_id_fkey;
       public               noovos_dev_user    false    3113    201    209            �           2606    20403 )   subscription subscription_appuser_id_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.subscription
    ADD CONSTRAINT subscription_appuser_id_fkey FOREIGN KEY (appuser_id) REFERENCES public.app_user(id);
 S   ALTER TABLE ONLY public.subscription DROP CONSTRAINT subscription_appuser_id_fkey;
       public               noovos_dev_user    false    213    199    3109           