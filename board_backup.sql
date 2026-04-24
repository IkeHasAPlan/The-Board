--
-- PostgreSQL database dump
--

\restrict 7a0t0Nen8XaebhLccfUmpRTz3w9BNWVv7VrXpzryi0jMn2L8gImY1jt1IAnaww1

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

--
-- Name: log_ticket_assignment_change(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.log_ticket_assignment_change() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
  IF NEW.assigned_technician_id IS DISTINCT FROM OLD.assigned_technician_id THEN
    INSERT INTO ticket_events(
      ticket_id,
      event_type,
      technician_id
    )
    VALUES (
      NEW.ticket_id,
      'ASSIGNMENT_CHANGE',
      NEW.assigned_technician_id
    );
  END IF;

  RETURN NEW;
END;
$$;


ALTER FUNCTION public.log_ticket_assignment_change() OWNER TO postgres;

--
-- Name: log_ticket_created(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.log_ticket_created() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
  INSERT INTO ticket_events(ticket_id, event_type, technician_id)
  VALUES (NEW.ticket_id, 'CREATED', NEW.assigned_technician_id);

  RETURN NEW;
END;
$$;


ALTER FUNCTION public.log_ticket_created() OWNER TO postgres;

--
-- Name: log_ticket_status_change(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.log_ticket_status_change() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
  IF NEW.current_status IS DISTINCT FROM OLD.current_status THEN
    INSERT INTO ticket_events(
      ticket_id,
      event_type,
      old_status,
      new_status,
      technician_id
    )
    VALUES (
      NEW.ticket_id,
      'STATUS_CHANGE',
      OLD.current_status,
      NEW.current_status,
      NEW.assigned_technician_id
    );
  END IF;

  RETURN NEW;
END;
$$;


ALTER FUNCTION public.log_ticket_status_change() OWNER TO postgres;

--
-- Name: set_ticket_lifecycle_timestamps(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.set_ticket_lifecycle_timestamps() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
  IF NEW.current_status IS DISTINCT FROM OLD.current_status THEN

    IF NEW.current_status = 'In Progress' AND OLD.started_at IS NULL THEN
      NEW.started_at = COALESCE(NEW.started_at, CURRENT_TIMESTAMP);
    END IF;

    IF NEW.current_status = 'Done' THEN
      NEW.completed_at = COALESCE(NEW.completed_at, CURRENT_TIMESTAMP);
    END IF;

    IF OLD.current_status = 'Done' AND NEW.current_status <> 'Done' THEN
      NEW.completed_at = NULL;
    END IF;

  END IF;

  RETURN NEW;
END;
$$;


ALTER FUNCTION public.set_ticket_lifecycle_timestamps() OWNER TO postgres;

--
-- Name: set_ticket_updated_at(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.set_ticket_updated_at() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
  NEW.updated_at = CURRENT_TIMESTAMP;
  RETURN NEW;
END;
$$;


ALTER FUNCTION public.set_ticket_updated_at() OWNER TO postgres;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: technicians; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.technicians (
    technician_id integer NOT NULL,
    name character varying(100) NOT NULL,
    email character varying(100) NOT NULL,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
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
    CONSTRAINT event_type_check CHECK (((event_type)::text = ANY ((ARRAY['CREATED'::character varying, 'STATUS_CHANGE'::character varying, 'ASSIGNMENT_CHANGE'::character varying, 'PRIORITY_CHANGE'::character varying])::text[])))
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

COPY public.technicians (technician_id, name, email, created_at) FROM stdin;
1	Christian	christian@board.com	2026-04-13 15:45:29.654295
2	Tai	tai@board.com	2026-04-13 15:45:29.654295
3	Dakota	dakota@board.com	2026-04-13 15:45:29.654295
4	Isaac	isaac@board.com	2026-04-13 15:45:29.654295
5	Donovan	donovan@board.com	2026-04-13 15:45:29.654295
6	Josh	josh@board.com	2026-04-13 15:45:29.654295
7	David	david@board.com	2026-04-13 15:45:29.654295
\.


--
-- Data for Name: ticket_events; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.ticket_events (event_id, ticket_id, event_type, old_status, new_status, technician_id, event_timestamp) FROM stdin;
1	9	CREATED	\N	\N	\N	2026-04-13 16:16:45.845799
2	9	ASSIGNMENT_CHANGE	\N	\N	5	2026-04-13 16:17:55.589036
3	9	STATUS_CHANGE	Waiting to Start	In Progress	5	2026-04-13 16:17:55.589036
4	9	ASSIGNMENT_CHANGE	\N	\N	6	2026-04-13 16:18:26.868956
5	9	STATUS_CHANGE	In Progress	Done	6	2026-04-13 16:18:36.871148
6	2	ASSIGNMENT_CHANGE	\N	\N	2	2026-04-13 16:22:22.04334
7	2	STATUS_CHANGE	Waiting to Start	In Progress	2	2026-04-13 16:22:22.04334
8	1	ASSIGNMENT_CHANGE	\N	\N	3	2026-04-13 16:27:33.963576
9	1	STATUS_CHANGE	Waiting to Start	In Progress	3	2026-04-13 16:27:33.963576
10	1	ASSIGNMENT_CHANGE	\N	\N	5	2026-04-13 16:27:37.186545
11	2	ASSIGNMENT_CHANGE	\N	\N	3	2026-04-13 17:24:44.013541
12	7	STATUS_CHANGE	Waiting to Start	In Progress	4	2026-04-15 00:06:50.226292
13	7	ASSIGNMENT_CHANGE	\N	\N	6	2026-04-15 00:06:52.883903
14	7	STATUS_CHANGE	In Progress	Done	6	2026-04-15 00:06:55.479434
15	3	ASSIGNMENT_CHANGE	\N	\N	\N	2026-04-15 00:08:00.048283
16	3	STATUS_CHANGE	In Progress	Waiting to Start	\N	2026-04-15 00:08:00.048283
\.


--
-- Data for Name: tickets; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.tickets (ticket_id, ticket_number, cust_name, issue_summary, device_description, device_type, priority_level, current_status, assigned_technician_id, created_at, started_at, completed_at, updated_at, sort_order) FROM stdin;
4	T2004	Lu Lee	OS reinstall	\N	Desktop	Normal	Waiting for Customer Response	2	2026-04-13 15:45:29.660516	\N	\N	2026-04-13 15:45:29.660516	1000
5	T2005	Iron Man	Keyboard replacement (parts pending)	\N	Laptop	Normal	Waiting for Part	2	2026-04-13 15:45:29.660516	\N	\N	2026-04-13 15:45:29.660516	1000
6	T2006	Joohn Ceeena	Data transfer	\N	Laptop	Normal	In Progress	4	2026-04-13 15:45:29.660516	\N	\N	2026-04-13 15:45:29.660516	0
8	58	Isaac Rivera	NVMe Upgrade	HP Envy	Laptop	Normal	Done	6	2026-04-13 15:54:25.733412	\N	\N	2026-04-13 15:54:25.733412	1000
9	1	testing ticket	testing	Dell Inspiron	Laptop	Normal	Done	6	2026-04-13 16:16:45.845799	2026-04-13 16:17:55.589036	2026-04-13 16:18:36.871148	2026-04-13 16:18:36.871148	1000
1	T2001	Taco Bell	Screen replacement	\N	Laptop	High	In Progress	5	2026-04-13 15:45:29.660516	2026-04-13 16:27:33.963576	\N	2026-04-13 16:27:37.186545	1000
2	T2002	Professor X	Virus removal	\N	Desktop	Normal	In Progress	3	2026-04-13 15:45:29.660516	2026-04-13 16:22:22.04334	\N	2026-04-13 17:24:44.013541	1000
7	T2007	Daft Punk	Device running slow	\N	Desktop	Low	Done	6	2026-04-13 15:45:29.660516	2026-04-15 00:06:50.226292	2026-04-15 00:06:55.479434	2026-04-15 00:06:55.479434	1000
3	T2003	Toronto Raptors	Battery not charging	\N	Laptop	Urgent	Waiting to Start	\N	2026-04-13 15:45:29.660516	\N	\N	2026-04-15 00:08:00.048283	0
\.


--
-- Name: technicians_technician_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.technicians_technician_id_seq', 7, true);


--
-- Name: ticket_events_event_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.ticket_events_event_id_seq', 16, true);


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
-- Name: tickets trigger_assignment_change; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trigger_assignment_change AFTER UPDATE OF assigned_technician_id ON public.tickets FOR EACH ROW EXECUTE FUNCTION public.log_ticket_assignment_change();


--
-- Name: tickets trigger_set_lifecycle_timestamps; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trigger_set_lifecycle_timestamps BEFORE UPDATE OF current_status ON public.tickets FOR EACH ROW EXECUTE FUNCTION public.set_ticket_lifecycle_timestamps();


--
-- Name: tickets trigger_status_change; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trigger_status_change AFTER UPDATE OF current_status ON public.tickets FOR EACH ROW EXECUTE FUNCTION public.log_ticket_status_change();


--
-- Name: tickets trigger_ticket_created; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trigger_ticket_created AFTER INSERT ON public.tickets FOR EACH ROW EXECUTE FUNCTION public.log_ticket_created();


--
-- Name: tickets trigger_ticket_updated_at; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trigger_ticket_updated_at BEFORE UPDATE ON public.tickets FOR EACH ROW EXECUTE FUNCTION public.set_ticket_updated_at();


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

\unrestrict 7a0t0Nen8XaebhLccfUmpRTz3w9BNWVv7VrXpzryi0jMn2L8gImY1jt1IAnaww1

