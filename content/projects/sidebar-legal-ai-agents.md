---
title: "Sidebar & VerifAI — AI Agents for Legal Teams"
date: 2025-10-01
summary: "Multi-agent LLM platform for legal teams at SpotDraft: agent orchestration, hybrid retrieval, knowledge-graph RAG, and a document pipeline processing millions of contracts. $500K revenue in 3 months of private beta."
description: "The architecture behind SpotDraft's Sidebar — a production multi-agent system for legal work."
tags: ["llm-agents", "rag", "langgraph", "production-ai", "professional"]
weight: 1
cover:
  hidden: true
---

**Role:** Lead engineer · **Company:** [SpotDraft](https://www.spotdraft.com/) · **Status:** In production

Sidebar is SpotDraft's flagship AI product — a team of specialized LLM agents that legal teams use for policy Q&A, regulatory compliance, and strategic legal guidance, deeply integrated with SpotDraft's Contract Lifecycle Management platform. Alongside it, **VerifAI** performs AI contract review. Together they drove **$500K in new product revenue within 3 months** of private beta and **70%+ efficiency gains** for customers.

## What I built

- **System architecture & backend** — designed the overall architecture and built the Python (FastAPI) backend services powering both products.
- **Multi-agent orchestration** — end-to-end LangGraph system with specialized sub-agents, API contracts, and integrations with the CLM platform and external legal databases.
- **Search & retrieval stack from scratch** — semantic search, hybrid retrieval (sparse BM25/BM42 + dense embeddings), relevance ranking, and knowledge-graph-augmented RAG over contract repositories, company policies, and regulatory databases.
- **Document pipeline at scale** — high-throughput, fault-tolerant processing of 100K to millions of documents on Apache Beam / Google Cloud Dataflow: metadata extraction, layout-aware chunking, embedding generation, and indexing into vector and knowledge-graph stores.
- **Three-tier agentic evaluation framework** — agent-level, integration, and end-to-end evals with structured execution traces enabling precise failure attribution (think: a stack trace for agent systems) and automated regression detection.
- **Multi-model routing** — LiteLLM-based orchestration across GPT-4, Claude, and other models for cost/latency/accuracy trade-offs with production fallbacks; fine-tuned embedding models for legal retrieval.

**Tech:** Python · LangGraph · LangChain · LiteLLM · OpenAI · Claude · Apache Beam · Google Cloud Dataflow · FastAPI · Vector DBs · Knowledge Graphs · GCP · Azure
