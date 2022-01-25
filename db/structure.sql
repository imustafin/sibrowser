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

--
-- Name: pg_trgm; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS pg_trgm WITH SCHEMA public;


--
-- Name: actual_categories(jsonb); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.actual_categories(scores jsonb) RETURNS jsonb
    LANGUAGE sql IMMUTABLE
    AS $_$
        WITH cats AS (
          SELECT
            jsonb_array_elements_text(jsonb_path_query_array(scores, '$.*.*.*')) AS cat
        ),
        with_counts AS (SELECT cat, COUNT(*) FROM cats GROUP BY cat ORDER BY COUNT(*) DESC),
        with_ratios AS (
          SELECT cat,
                count / GREATEST((SELECT SUM(count) FROM with_counts), 1) AS ratio
          FROM with_counts
        )

        SELECT jsonb_object_agg(cat, ratio) FROM with_ratios
          WHERE (ratio > 0.8 * (SELECT MAX(ratio) FROM with_ratios))
      $_$;


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
    searchable tsvector GENERATED ALWAYS AS (((((((setweight(to_tsvector('russian'::regconfig, (COALESCE(name, ''::character varying))::text), 'A'::"char") || setweight(to_tsvector('russian'::regconfig, (COALESCE(filename, ''::character varying))::text), 'A'::"char")) || setweight(to_tsvector('russian'::regconfig, COALESCE(authors, '{}'::jsonb)), 'B'::"char")) || setweight(to_tsvector('russian'::regconfig, COALESCE(tags, '{}'::jsonb)), 'B'::"char")) || setweight(to_tsvector('russian'::regconfig, COALESCE(jsonb_path_query_array(structure, '$[*]."name"'::jsonpath), '{}'::jsonb)), 'B'::"char")) || setweight(to_tsvector('russian'::regconfig, COALESCE(jsonb_path_query_array(structure, '$[*]."themes"[*]."name"'::jsonpath), '{}'::jsonb)), 'B'::"char")) || setweight(to_tsvector('russian'::regconfig, COALESCE(post_text, ''::text)), 'C'::"char"))) STORED,
    category_scores jsonb,
    manual_categories jsonb,
    predicted_categories jsonb,
    categories jsonb GENERATED ALWAYS AS (public.actual_categories(predicted_categories)) STORED,
    disappeared_at timestamp without time zone,
    vk_owner_id character varying NOT NULL,
    vk_download_url character varying,
    superseded_ids bigint[] DEFAULT '{}'::bigint[] NOT NULL,
    downloads jsonb DEFAULT '{}'::jsonb NOT NULL
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
-- Name: sibrowser_configs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.sibrowser_configs (
    id bigint NOT NULL,
    tags_to_cats jsonb
);


--
-- Name: sibrowser_configs_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.sibrowser_configs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: sibrowser_configs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.sibrowser_configs_id_seq OWNED BY public.sibrowser_configs.id;


--
-- Name: packages id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.packages ALTER COLUMN id SET DEFAULT nextval('public.packages_id_seq'::regclass);


--
-- Name: sibrowser_configs id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sibrowser_configs ALTER COLUMN id SET DEFAULT nextval('public.sibrowser_configs_id_seq'::regclass);


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
-- Name: sibrowser_configs sibrowser_configs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sibrowser_configs
    ADD CONSTRAINT sibrowser_configs_pkey PRIMARY KEY (id);


--
-- Name: authors_icase_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX authors_icase_index ON public.packages USING gin (((lower((authors)::text))::jsonb));


--
-- Name: index_packages_on_disappeared_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_packages_on_disappeared_at ON public.packages USING btree (disappeared_at);


--
-- Name: index_packages_on_searchable; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_packages_on_searchable ON public.packages USING gin (searchable);


--
-- Name: index_packages_on_superseded_ids; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_packages_on_superseded_ids ON public.packages USING gin (superseded_ids);


--
-- Name: index_packages_on_vk_document_id_and_vk_owner_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_packages_on_vk_document_id_and_vk_owner_id ON public.packages USING btree (vk_document_id, vk_owner_id);


--
-- Name: tags_icase_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX tags_icase_index ON public.packages USING gin (((lower((tags)::text))::jsonb));


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
('20210531215651'),
('20210606162204'),
('20210607220249'),
('20210712210249'),
('20210714194116'),
('20210714194426'),
('20210715131534'),
('20210716002417'),
('20210716152440'),
('20210725194413'),
('20210725195147'),
('20210804172614'),
('20210815193621'),
('20220119170220'),
('20220119181737'),
('20220123162121'),
('20220123200144'),
('20220125171004');


