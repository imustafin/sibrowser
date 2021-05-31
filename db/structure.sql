SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: ar_internal_metadata; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.ar_internal_metadata (
    key character varying NOT NULL,
    value character varying,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: packages; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.packages (
    id bigint NOT NULL,
    name character varying NOT NULL,
    source_link character varying NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    post_text text,
    filename character varying,
    published_at timestamp without time zone,
    vk_document_id character varying NOT NULL,
    version integer NOT NULL,
    authors jsonb,
    structure jsonb,
    tags jsonb,
    searchable tsvector GENERATED ALWAYS AS ((((((setweight(to_tsvector('russian'::regconfig, (COALESCE(name, ''::character varying))::text), 'A'::"char") || setweight(to_tsvector('russian'::regconfig, (COALESCE(filename, ''::character varying))::text), 'A'::"char")) || setweight(to_tsvector('russian'::regconfig, COALESCE(authors, '{}'::jsonb)), 'B'::"char")) || setweight(to_tsvector('russian'::regconfig, COALESCE(tags, '{}'::jsonb)), 'B'::"char")) || setweight(to_tsvector('russian'::regconfig, COALESCE(jsonb_path_query_array(structure, '$[*]."name"'::jsonpath), '{}'::jsonb)), 'B'::"char")) || setweight(to_tsvector('russian'::regconfig, COALESCE(post_text, ''::text)), 'C'::"char"))) STORED
);


--
-- Name: packages_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.packages_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: packages_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.packages_id_seq OWNED BY public.packages.id;


--
-- Name: schema_migrations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.schema_migrations (
    version character varying NOT NULL
);


--
-- Name: packages id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.packages ALTER COLUMN id SET DEFAULT nextval('public.packages_id_seq'::regclass);


--
-- Name: ar_internal_metadata ar_internal_metadata_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ar_internal_metadata
    ADD CONSTRAINT ar_internal_metadata_pkey PRIMARY KEY (key);


--
-- Name: packages packages_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.packages
    ADD CONSTRAINT packages_pkey PRIMARY KEY (id);


--
-- Name: schema_migrations schema_migrations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.schema_migrations
    ADD CONSTRAINT schema_migrations_pkey PRIMARY KEY (version);


--
-- Name: index_packages_on_searchable; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_packages_on_searchable ON public.packages USING gin (searchable);


--
-- Name: index_packages_on_vk_document_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_packages_on_vk_document_id ON public.packages USING btree (vk_document_id);


--
-- PostgreSQL database dump complete
--

SET search_path TO "$user", public;

INSERT INTO "schema_migrations" (version) VALUES
('20210519185202'),
('20210521195753'),
('20210521215311'),
('20210522085328'),
('20210522214151'),
('20210523142504'),
('20210524165613'),
('20210530233703'),
('20210531120921'),
('20210531205957'),
('20210531215651');


