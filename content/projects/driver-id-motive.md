---
title: "Driver ID & Perception Models on 1M+ Dashcams"
date: 2023-01-15
summary: "Multi-task deep-learning models (detection, tracking, distance estimation) quantized for real-time inference on 1M+ edge devices, and an end-to-end facial-recognition pipeline serving 100K+ daily predictions at Motive."
description: "Perception ML at fleet scale — edge deployment on a million dashcams."
tags: ["computer-vision", "edge-ai", "deep-learning", "professional"]
weight: 4
cover:
  hidden: true
---

**Role:** ML Engineer, Perception · **Company:** [Motive](https://gomotive.com/) (formerly KeepTruckin) · **Status:** Shipped

Motive's dashcams run perception models on-device across one of the largest commercial fleets in North America.

## What I built

- **Multi-task deep-learning models** — shared-backbone architectures for object detection, multi-object tracking, and monocular distance estimation, optimized and quantized for real-time inference on **1M+ edge devices**.
- **Driver ID pipeline** — end-to-end facial recognition with backend services in Go and Python operating in the wild: **85%+ accuracy, 95% coverage, 100K+ daily predictions** at fleet scale.
- **GAN-based synthetic data** — ~500K generated frames for domain adaptation, mitigating dataset bias and improving edge-case generalization on large-scale real-world driving data.

**Tech:** Python · C++ · Go · PyTorch · Snowflake · SQL · Docker · Kubernetes
