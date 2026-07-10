---
title: "Apollo.io AI Assistant"
date: 2025-06-01
summary: "Agentic chatbot backend for lead generation, list building, and email sequencing — plus the LLM evaluation practice (golden datasets, automated eval pipelines, 87% coverage) built from scratch."
description: "Building the agent backend and LLM evaluation practice for Apollo.io's AI Assistant."
tags: ["llm-agents", "evals", "production-ai", "professional"]
weight: 2
cover:
  hidden: true
---

**Role:** Senior ML Engineer · **Company:** [Apollo.io](https://www.apollo.io/) · **Status:** Shipped

The Apollo.io AI Assistant is an agentic chatbot that helps sales teams generate leads, build lists, and set up email sequences over Apollo's data platform.

## What I built

- **Agent backend** — Python/FastAPI backend for the assistant; designed and empirically evaluated **supervisor, mesh, and ReAct** agent architectures, setting the foundation for the company's agent platform.
- **LLM evaluation practice from scratch** — golden datasets and automated eval pipelines on LangSmith and Langfuse, reaching **87% coverage** and catching regressions before release.
- **URL-prioritization at web scale** — scaled a company-site scraping prioritization system from 35% to **75%+ coverage** using LLM-generated ground truth and a custom multi-class classifier; replaced a third-party service with a self-hosted model-serving backend, saving **$84K/yr**.

**Tech:** Python · OpenAI GPT · LangGraph · LangSmith · Langfuse · LiteLLM · Elasticsearch · Vector DBs · FastAPI · Docker
