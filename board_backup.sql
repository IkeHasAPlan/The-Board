--
-- PostgreSQL database dump
--

\restrict w7tnRtHC3oESZA1vWCMNJXngZ7AvHzr1mxNYBN5bUqleD8erFF75plYOhqs9EPa

-- Dumped from database version 18.3
-- Dumped by pg_dump version 18.3

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

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: technicians; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.technicians (
    technician_id integer NOT NULL,
    name character varying(100) NOT NULL,
    email character varying(100) NOT NULL,
    is_active boolean DEFAULT true NOT NULL,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.technicians OWNER TO postgres;

--
-- Name: technicians_technician_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.technicians_technician_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.technicians_technician_id_seq OWNER TO postgres;

--
-- Name: technicians_technician_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.technicians_technician_id_seq OWNED BY public.technicians.technician_id;


--
-- Name: ticket_events; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ticket_events (
    event_id integer NOT NULL,
    ticket_id integer NOT NULL,
    event_type character varying(50) NOT NULL,
    old_status character varying(50),
    new_status character varying(50),
    technician_id integer,
    event_timestamp timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT event_type_check CHECK (((event_type)::text = ANY ((ARRAY['CREATED'::character varying, 'STATUS_CHANGE'::character varying, 'ASSIGNMENT_CHANGE'::character varying, 'PRIORITY_CHANGE'::character varying, 'SUB_STATUS_CHANGE'::character varying])::text[])))
);


ALTER TABLE public.ticket_events OWNER TO postgres;

--
-- Name: ticket_events_event_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.ticket_events_event_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.ticket_events_event_id_seq OWNER TO postgres;

--
-- Name: ticket_events_event_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.ticket_events_event_id_seq OWNED BY public.ticket_events.event_id;


--
-- Name: tickets; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.tickets (
    ticket_id integer NOT NULL,
    ticket_number character varying(50) NOT NULL,
    cust_name character varying(100) NOT NULL,
    issue_summary text NOT NULL,
    device_description text,
    device_type character varying(100),
    warranty boolean,
    priority_level character varying(20) DEFAULT 'Normal'::character varying NOT NULL,
    current_status character varying(50) DEFAULT 'Waiting to Start'::character varying NOT NULL,
    sub_status character varying(100),
    assigned_technician_id integer,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    started_at timestamp without time zone,
    completed_at timestamp without time zone,
    is_archived boolean DEFAULT false,
    picked_up_at timestamp without time zone,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    sort_order integer DEFAULT 1000,
    CONSTRAINT priority_check CHECK (((priority_level)::text = ANY ((ARRAY['Low'::character varying, 'Normal'::character varying, 'High'::character varying, 'Urgent'::character varying])::text[]))),
    CONSTRAINT status_check CHECK (((current_status)::text = ANY ((ARRAY['Waiting to Start'::character varying, 'In Progress'::character varying, 'Waiting for Customer Response'::character varying, 'Waiting for Part'::character varying, 'Done'::character varying])::text[])))
);


ALTER TABLE public.tickets OWNER TO postgres;

--
-- Name: tickets_ticket_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.tickets_ticket_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.tickets_ticket_id_seq OWNER TO postgres;

--
-- Name: tickets_ticket_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.tickets_ticket_id_seq OWNED BY public.tickets.ticket_id;


--
-- Name: technicians technician_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.technicians ALTER COLUMN technician_id SET DEFAULT nextval('public.technicians_technician_id_seq'::regclass);


--
-- Name: ticket_events event_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.ticket_events ALTER COLUMN event_id SET DEFAULT nextval('public.ticket_events_event_id_seq'::regclass);


--
-- Name: tickets ticket_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tickets ALTER COLUMN ticket_id SET DEFAULT nextval('public.tickets_ticket_id_seq'::regclass);


--
-- Data for Name: technicians; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.technicians (technician_id, name, email, is_active, created_at, updated_at) FROM stdin;
1	Tai	tai@board.com	t	2026-05-04 17:09:22.306966	2026-05-04 17:09:22.306966
2	Dakota	dakota@board.com	t	2026-05-04 17:09:22.306966	2026-05-04 17:09:22.306966
3	Isaac	isaac@board.com	t	2026-05-04 17:09:22.306966	2026-05-04 17:09:22.306966
4	Donovan	donovan@board.com	t	2026-05-04 17:09:22.306966	2026-05-04 17:09:22.306966
5	Josh	josh@board.com	t	2026-05-04 17:09:22.306966	2026-05-04 17:09:22.306966
6	David	david@board.com	t	2026-05-04 17:09:22.306966	2026-05-04 17:09:22.306966
\.


--
-- Data for Name: ticket_events; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.ticket_events (event_id, ticket_id, event_type, old_status, new_status, technician_id, event_timestamp) FROM stdin;
1	1	CREATED	\N	Waiting to Start	\N	2026-04-29 17:09:22.326984
2	2	CREATED	\N	Waiting to Start	\N	2026-04-28 17:09:22.326984
3	3	CREATED	\N	Waiting to Start	\N	2026-04-27 17:09:22.326984
4	4	CREATED	\N	Waiting to Start	\N	2026-04-30 17:09:22.326984
5	5	CREATED	\N	Waiting to Start	\N	2026-05-02 17:09:22.326984
6	6	CREATED	\N	Waiting to Start	\N	2026-05-01 17:09:22.326984
7	7	CREATED	\N	Waiting to Start	\N	2026-04-30 17:09:22.326984
8	8	CREATED	\N	Waiting to Start	\N	2026-05-01 17:09:22.326984
9	1	ASSIGNMENT_CHANGE	\N	\N	1	2026-04-30 10:59:22.326984
10	2	ASSIGNMENT_CHANGE	\N	\N	2	2026-04-29 16:59:22.326984
11	3	ASSIGNMENT_CHANGE	\N	\N	3	2026-04-28 16:59:22.326984
12	4	ASSIGNMENT_CHANGE	\N	\N	4	2026-05-01 08:59:22.326984
13	5	ASSIGNMENT_CHANGE	\N	\N	5	2026-05-02 22:59:22.326984
14	6	ASSIGNMENT_CHANGE	\N	\N	6	2026-05-02 06:59:22.326984
15	7	ASSIGNMENT_CHANGE	\N	\N	1	2026-05-01 10:59:22.326984
16	8	ASSIGNMENT_CHANGE	\N	\N	2	2026-05-02 04:59:22.326984
17	1	STATUS_CHANGE	Waiting to Start	In Progress	1	2026-04-30 11:09:22.326984
18	2	STATUS_CHANGE	Waiting to Start	In Progress	2	2026-04-29 17:09:22.326984
19	3	STATUS_CHANGE	Waiting to Start	In Progress	3	2026-04-28 17:09:22.326984
20	4	STATUS_CHANGE	Waiting to Start	In Progress	4	2026-05-01 09:09:22.326984
21	5	STATUS_CHANGE	Waiting to Start	In Progress	5	2026-05-02 23:09:22.326984
22	6	STATUS_CHANGE	Waiting to Start	In Progress	6	2026-05-02 07:09:22.326984
23	7	STATUS_CHANGE	Waiting to Start	In Progress	1	2026-05-01 11:09:22.326984
24	8	STATUS_CHANGE	Waiting to Start	In Progress	2	2026-05-02 05:09:22.326984
25	1	STATUS_CHANGE	In Progress	Done	1	2026-04-30 17:09:22.326984
26	2	STATUS_CHANGE	In Progress	Done	2	2026-05-01 17:09:22.326984
27	4	STATUS_CHANGE	In Progress	Done	4	2026-05-01 17:09:22.326984
28	6	STATUS_CHANGE	In Progress	Done	6	2026-05-02 17:09:22.326984
29	7	STATUS_CHANGE	In Progress	Done	1	2026-05-01 17:09:22.326984
30	3	STATUS_CHANGE	In Progress	Waiting for Part	3	2026-04-29 17:09:22.326984
31	8	STATUS_CHANGE	In Progress	Waiting for Customer Response	2	2026-05-03 05:09:22.326984
32	3	STATUS_CHANGE	Waiting for Part	Done	3	2026-05-04 17:10:45.56194
33	9	STATUS_CHANGE	Waiting to Start	In Progress	2	2026-05-04 17:11:26.91239
34	9	ASSIGNMENT_CHANGE	\N	\N	2	2026-05-04 17:11:26.91239
35	8	SUB_STATUS_CHANGE	Diagnostic complete; waiting on approval	Waiting for Part	2	2026-05-04 17:11:29.668722
36	8	SUB_STATUS_CHANGE	Waiting for Part	\N	2	2026-05-04 17:11:31.262926
37	9	SUB_STATUS_CHANGE	\N	Waiting for Customer Response	2	2026-05-04 17:11:33.13839
38	8	SUB_STATUS_CHANGE	\N	Waiting for Part	2	2026-05-04 17:11:34.835851
39	5	ASSIGNMENT_CHANGE	\N	\N	2	2026-05-04 17:11:39.432233
\.


--
-- Data for Name: tickets; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.tickets (ticket_id, ticket_number, cust_name, issue_summary, device_description, device_type, warranty, priority_level, current_status, sub_status, assigned_technician_id, created_at, started_at, completed_at, is_archived, picked_up_at, updated_at, sort_order) FROM stdin;
2	59382	Michael Tompkins	Blender crashes laptop	HP Envy	Laptop	t	Urgent	Done	Thermal repair completed	2	2026-04-28 17:09:22.326984	2026-04-29 17:09:22.326984	2026-05-01 17:09:22.326984	f	\N	2026-05-04 17:09:22.326984	110
4	66104	Chip Gubera	Screen replacement	HP Notebook	Laptop	f	Normal	Done	Screen replaced and tested	4	2026-04-30 17:09:22.326984	2026-05-01 09:09:22.326984	2026-05-01 17:09:22.326984	f	\N	2026-05-04 17:09:22.326984	130
6	33862	Scottie Murrell	WiFi won't work	ASUS Zenbook	Laptop	f	Normal	Done	Wireless driver repaired	6	2026-05-01 17:09:22.326984	2026-05-02 07:09:22.326984	2026-05-02 17:09:22.326984	f	\N	2026-05-04 17:09:22.326984	150
7	44091	Noor Al-Shakarji	Virus removal	Lenovo Ideapad	Laptop	f	Normal	Done	Malware removed and system cleaned	1	2026-04-30 17:09:22.326984	2026-05-01 11:09:22.326984	2026-05-01 17:09:22.326984	f	\N	2026-05-04 17:09:22.326984	160
3	77429	Kristofferson Culmer	Motherboard replacement	MacBook	Laptop	t	Urgent	Done	Motherboard ordered	3	2026-04-27 17:09:22.326984	2026-04-28 17:09:22.326	2026-05-04 17:10:45.563	f	\N	2026-05-04 17:10:45.56194	120
9	12	poopy poo	isaac	isaac	Desktop	f	Normal	In Progress	Waiting for Customer Response	2	2026-05-04 17:11:22.50492	2026-05-04 17:11:26.912	\N	f	\N	2026-05-04 17:11:33.13839	1000
8	72844	Michael Tompkins	Full diagnostic	HP Pavilion	Laptop	f	Normal	Waiting for Customer Response	Waiting for Part	2	2026-05-01 17:09:22.326984	2026-05-02 05:09:22.326	\N	f	\N	2026-05-04 17:11:34.835851	170
5	90517	Jiaming Jiang	Corrupted OS	Dell XPS	Laptop	t	Urgent	In Progress	OS reinstall in progress	2	2026-05-02 17:09:22.326984	2026-05-02 23:09:22.326	\N	f	\N	2026-05-04 17:11:39.432233	140
1	48213	Archived Customer	[Archived]	\N	Laptop	f	Normal	Done	\N	1	2026-04-29 17:09:22.326984	2026-04-30 11:09:22.326984	2026-04-30 17:09:22.326984	t	2026-05-04 17:11:48.715015	2026-05-04 17:11:48.715015	100
\.


--
-- Name: technicians_technician_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.technicians_technician_id_seq', 12, true);


--
-- Name: ticket_events_event_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.ticket_events_event_id_seq', 39, true);


--
-- Name: tickets_ticket_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.tickets_ticket_id_seq', 9, true);


--
-- Name: technicians technicians_email_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.technicians
    ADD CONSTRAINT technicians_email_key UNIQUE (email);


--
-- Name: technicians technicians_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.technicians
    ADD CONSTRAINT technicians_pkey PRIMARY KEY (technician_id);


--
-- Name: ticket_events ticket_events_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.ticket_events
    ADD CONSTRAINT ticket_events_pkey PRIMARY KEY (event_id);


--
-- Name: tickets tickets_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tickets
    ADD CONSTRAINT tickets_pkey PRIMARY KEY (ticket_id);


--
-- Name: tickets tickets_ticket_number_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tickets
    ADD CONSTRAINT tickets_ticket_number_key UNIQUE (ticket_number);


--
-- Name: idx_events_ticket; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_events_ticket ON public.ticket_events USING btree (ticket_id);


--
-- Name: idx_events_ticket_time_desc; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_events_ticket_time_desc ON public.ticket_events USING btree (ticket_id, event_timestamp DESC);


--
-- Name: idx_events_timestamp; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_events_timestamp ON public.ticket_events USING btree (event_timestamp);


--
-- Name: idx_ticket_board; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_ticket_board ON public.tickets USING btree (assigned_technician_id, current_status, sort_order, created_at);


--
-- Name: idx_ticket_completed_at; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_ticket_completed_at ON public.tickets USING btree (completed_at);


--
-- Name: idx_ticket_created; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_ticket_created ON public.tickets USING btree (created_at);


--
-- Name: idx_ticket_status; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_ticket_status ON public.tickets USING btree (current_status);


--
-- Name: idx_ticket_technician; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_ticket_technician ON public.tickets USING btree (assigned_technician_id);


--
-- Name: tickets fk_assigned_technician; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tickets
    ADD CONSTRAINT fk_assigned_technician FOREIGN KEY (assigned_technician_id) REFERENCES public.technicians(technician_id) ON DELETE SET NULL;


--
-- Name: ticket_events fk_event_technician; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.ticket_events
    ADD CONSTRAINT fk_event_technician FOREIGN KEY (technician_id) REFERENCES public.technicians(technician_id) ON DELETE SET NULL;


--
-- Name: ticket_events fk_event_ticket; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.ticket_events
    ADD CONSTRAINT fk_event_ticket FOREIGN KEY (ticket_id) REFERENCES public.tickets(ticket_id) ON DELETE CASCADE;


--
-- PostgreSQL database dump complete
--

\unrestrict w7tnRtHC3oESZA1vWCMNJXngZ7AvHzr1mxNYBN5bUqleD8erFF75plYOhqs9EPa

