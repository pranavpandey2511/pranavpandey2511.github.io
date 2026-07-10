---
title: "Introduction to Recommendation Systems"
date: 2023-05-01T11:02:07+05:30
draft: true
comments: true
description: "A gentle introduction to recommendation systems — collaborative filtering, content-based methods, and the cold-start problem."
tags: ["recommendation-systems", "machine-learning"]
categories: ["Machine Learning"]
ShowToc: true
---

Recommendation systems are everywhere, and they are crucial for any user-facing website or app where users have a wide variety of items to choose from.

## Collaborative Filtering

Collaborative filtering is one of the most commonly used methods for recommending products to users, but it is limited by the quality of interaction data.

It also suffers from the so-called **cold-start problem**: with no interaction history for a new user (or a new item), the system has nothing to base its recommendations on.

<!-- TODO: expand — content-based filtering, hybrid approaches, matrix factorization, and how we solved cold-start at Stybe with an implicit/explicit feedback loop. -->
