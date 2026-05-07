# The Board

> A modern touchscreen-first repair shop management system built for real technicians, real workflows, and real-world deployment.

---

## Overview

**The Board** is a full-stack repair ticket management platform developed for Columbia Computer Center as a capstone project by Isaac Rivera, Ashton Wooster, Bryson Allen, Michael Forness, and Gideon Masters.

Originally created to replace a paper-based workflow, The Board streamlines technician coordination, ticket tracking, event logging, repair status management, and administrative reporting through an intuitive touchscreen interface designed specifically for computer repair environments.

This is not a mockup or classroom-only prototype — the system was designed for live deployment in an active repair shop environment.

---

# Features

## Technician Workflow Management
- Drag-and-drop repair ticket organization
- Technician assignment tracking
- Real-time workflow updates
- Priority-based repair management
- Visual repair status indicators

## Touchscreen-Optimized Interface
- Large responsive UI elements
- Fast interaction design
- Repair-shop-friendly layout
- Built for kiosk and wall-mounted touchscreen displays

## Ticket Management
- Customer intake tracking
- Device and issue logging
- Status progression system
- Sub-status support
  - Waiting for Parts
  - Waiting for Customer Response
- Event history logging

## Administrative Tools
- Technician performance reporting
- Searchable repair history
- Detailed job reports
- Editable ticket records
- Inventory-aware workflow support

## Infrastructure & Deployment
- Dockerized application stack
- PostgreSQL database backend
- IIS reverse proxy deployment
- Linux + WSL development workflow
- Git/GitHub version control pipeline

---

# Tech Stack

## Frontend
- React
- Vite
- JavaScript
- HTML/CSS

## Backend
- Node.js
- Express.js

## Database
- PostgreSQL

## Deployment & Infrastructure
- Docker
- Docker Compose
- Windows IIS
- WSL (Windows Subsystem for Linux)
- GitHub

---

# Why The Board Exists

Most small repair shops still rely on:
- Whiteboards
- Sticky notes
- Paper tickets
- Verbal communication
- Fragmented workflow systems

The Board was created to modernize repair shop coordination without sacrificing speed or usability.

The goal was simple:

> Build a system technicians would actually WANT to use.

The result is a lightweight, visually intuitive workflow platform tailored specifically for fast-paced repair environments.

---

# Real-World Design Goals

- Fast enough for active repair intake
- Simple enough for non-technical staff
- Visual enough for wall-mounted displays
- Flexible enough for multiple technicians
- Reliable enough for business deployment

---

# Key System Concepts

## Technician Columns
Each technician receives an active workflow column displaying assigned jobs.

## Smart Status Organization
Jobs automatically organize based on workflow state:
- Active Repairs
- Waiting for Customer
- Waiting for Parts

## Event Logging
Every major workflow action can be tracked for accountability and repair history.

## Administrative Reporting
Managers can review:
- Technician activity
- Completed repairs
- Ticket history
- Workflow bottlenecks

---

# Development Highlights

- Replaced a real paper-based workflow system
- Built collaboratively during a university capstone sprint
- Iteratively improved through live repair-shop feedback
- Developed alongside active technician work

---

# Future Development Goals

- Authentication & role permissions
- Cloud deployment support
- SMS/email customer notifications
- Inventory management integration
- Analytics dashboard
- Mobile companion support
- Barcode/QR intake workflows

---
