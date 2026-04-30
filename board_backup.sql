--
-- PostgreSQL database dump
--

\restrict ItKsAWGUQUSDgsz8oKKTYG0t4Op6nZKStSJrYaxd9wZlUZtOetDaIRyBHhEsuEB

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
    priority_level character varying(20) DEFAULT 'Normal'::character varying NOT NULL,
    current_status character varying(50) DEFAULT 'Waiting to Start'::character varying NOT NULL,
    assigned_technician_id integer,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    started_at timestamp without time zone,
    completed_at timestamp without time zone,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    sort_order integer DEFAULT 1000,
    sub_status character varying(100),
    is_archived boolean DEFAULT false,
    picked_up_at timestamp without time zone,
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
2	Tai	tai@board.com	t	2026-04-23 17:18:30.589253	2026-04-23 17:18:30.589253
3	Dakota	dakota@board.com	t	2026-04-23 17:18:30.589253	2026-04-23 17:18:30.589253
4	Isaac	isaac@board.com	t	2026-04-23 17:18:30.589253	2026-04-23 17:18:30.589253
5	Donovan	donovan@board.com	t	2026-04-23 17:18:30.589253	2026-04-23 17:18:30.589253
8	Garrett	garrett@placeholder.local	f	2026-04-23 20:30:09.827316	2026-04-23 20:30:34.216487
1	Christian	christian@board.com	f	2026-04-23 17:18:30.589253	2026-04-23 20:38:09.861289
6	Josh	josh@board.com	t	2026-04-23 17:18:30.589253	2026-04-23 20:38:12.487317
7	David	david@board.com	t	2026-04-23 17:18:30.589253	2026-04-28 11:21:45.180112
\.


--
-- Data for Name: ticket_events; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.ticket_events (event_id, ticket_id, event_type, old_status, new_status, technician_id, event_timestamp) FROM stdin;
37	12	ASSIGNMENT_CHANGE	\N	\N	4	2026-04-23 20:04:48.303706
38	12	STATUS_CHANGE	Waiting to Start	Done	4	2026-04-23 20:04:49.177941
39	16	ASSIGNMENT_CHANGE	\N	\N	4	2026-04-28 11:16:27.720206
40	16	ASSIGNMENT_CHANGE	\N	\N	5	2026-04-28 11:17:14.853912
41	16	STATUS_CHANGE	Waiting to Start	Done	5	2026-04-28 11:17:55.461922
42	17	ASSIGNMENT_CHANGE	\N	\N	5	2026-04-28 11:25:31.061925
43	17	ASSIGNMENT_CHANGE	\N	\N	6	2026-04-28 11:25:45.61183
44	17	SUB_STATUS_CHANGE	\N	Waiting for Part	6	2026-04-28 11:26:20.803887
45	17	ASSIGNMENT_CHANGE	\N	\N	\N	2026-04-29 21:10:00.629491
46	16	STATUS_CHANGE	Done	Waiting to Start	\N	2026-04-29 21:10:01.959852
47	16	ASSIGNMENT_CHANGE	\N	\N	\N	2026-04-29 21:10:01.959852
48	15	ASSIGNMENT_CHANGE	\N	\N	4	2026-04-29 21:10:08.728742
49	17	ASSIGNMENT_CHANGE	\N	\N	2	2026-04-29 21:10:17.543114
50	17	SUB_STATUS_CHANGE	Waiting for Part	Waiting for Customer Response	2	2026-04-29 21:10:22.730422
\.


--
-- Data for Name: tickets; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.tickets (ticket_id, ticket_number, cust_name, issue_summary, device_description, device_type, priority_level, current_status, assigned_technician_id, created_at, started_at, completed_at, updated_at, sort_order, sub_status, is_archived, picked_up_at) FROM stdin;
12	1	Archived Customer	[Archived]	\N	Laptop	Normal	Done	4	2026-04-23 20:04:44.940505	2026-04-23 20:04:48.303	2026-04-23 20:04:49.178	2026-04-23 20:04:55.869307	1000	\N	t	2026-04-23 20:04:55.869307
16	5	Kris Culmer	Screen Replacement	Mac	Laptop	Normal	Waiting to Start	\N	2026-04-28 11:16:01.614962	2026-04-28 11:16:27.719	\N	2026-04-29 21:10:01.959852	1000	\N	f	\N
15	1280	Kris Culmer	Screen Replacement	Mac	Laptop	Normal	Waiting to Start	4	2026-04-28 11:15:43.34621	2026-04-29 21:10:08.729	\N	2026-04-29 21:10:08.728742	1000	\N	f	\N
17	6	Fang Wang	Virus Removal	Dell	Laptop	Normal	Waiting to Start	2	2026-04-28 11:25:08.307282	2026-04-28 11:25:31.068	\N	2026-04-29 21:10:22.730422	1000	Waiting for Customer Response	f	\N
\.


--
-- Name: technicians_technician_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.technicians_technician_id_seq', 8, true);


--
-- Name: ticket_events_event_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.ticket_events_event_id_seq', 50, true);


--
-- Name: tickets_ticket_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.tickets_ticket_id_seq', 17, true);


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

\unrestrict ItKsAWGUQUSDgsz8oKKTYG0t4Op6nZKStSJrYaxd9wZlUZtOetDaIRyBHhEsuEB

