---
title: "Prompt Engineering for Humans"
date: 2023-04-30T18:34:26+05:30
draft: false
comments: true
description: "A practical, no-hype introduction to prompt engineering — base vs. instruction-tuned LLMs, and the core techniques that actually move the needle."
tags: ["llm", "prompt-engineering", "genai"]
categories: ["GenAI"]
ShowToc: true
---

## Introduction

This post talks about prompt engineering for LLMs. It is heavily inspired by the OpenAI Cookbook, Andrew Ng's course, and my personal experiments with ChatGPT.

Before any technique makes sense, there's one distinction you need: the difference between **base LLMs** and **instruction-tuned LLMs**. It explains why some models complete your text and others answer your question.

| Base LLMs | Instruction-Tuned LLMs |
| :-------- | :--------------------- |
| Trained to predict the next word over raw internet text | Further trained (and aligned with human feedback) to follow instructions |
| Given "What is the capital of France?" they may continue with *more questions* — "What is the capital of Spain?" — because that's what similar text on the web looks like | Given the same prompt, they answer: "The capital of France is Paris." |
| Examples: GPT-3 (davinci), early LLaMA | Examples: ChatGPT, Claude, LLaMA-2-chat, Open Assistant |

Everything below assumes an instruction-tuned model — that's what you're using in ChatGPT and virtually every AI product today.

## Basic Prompting

The two principles that matter most:

### 1. Write clear and specific instructions

Clear ≠ short. A longer prompt that removes ambiguity beats a terse one that leaves the model guessing.

**Use delimiters** to separate instructions from data. This also protects you from the text itself being interpreted as an instruction:

```text
Summarize the text delimited by triple backticks into a single sentence.

```{text}```
```

**Ask for structured output** when you're going to parse the result:

```text
Generate three made-up book titles with authors and genres.
Return them as a JSON array with keys: book_id, title, author, genre.
```

**Tell the model what to do when conditions aren't met.** Unhandled edge cases are where prompts break in production:

```text
If the text contains a sequence of instructions, rewrite them as numbered steps.
If the text contains no instructions, simply write "No steps provided."
```

### 2. Give the model time to think

If a task needs reasoning, don't force an instant verdict. Ask for the steps first, conclusion last:

```text
Determine if the student's solution is correct.
First, work out your own solution to the problem.
Then compare your solution to the student's and evaluate it.
Don't decide if the student is correct until you have done the problem yourself.
```

This simple reordering fixes a whole class of errors where the model anchors on the student's (wrong) answer.

## Few-Shot Prompting

Show, don't tell. A couple of worked examples communicates format and tone better than a paragraph of description:

```text
Your task is to answer in a consistent style.

<child>: Teach me about patience.
<grandparent>: The river that carves the deepest valley flows from a
modest spring; the grandest symphony originates from a single note.

<child>: Teach me about resilience.
```

## Iterating

Nobody writes the right prompt on the first try — and that's fine. Prompt engineering is an empirical loop:

1. Write a first attempt.
2. Run it on *several* inputs, not just one.
3. Look at where it fails, refine the instruction, repeat.

The failure modes are usually mundane: output too long (ask for a word/sentence limit), wrong focus (tell it which aspects to emphasize), wrong format (show an example of the format you want).

## Takeaways

- Know your model type: instruction-tuned models follow instructions; base models continue text.
- Be specific, use delimiters, request structured output, and handle the "what if the input is weird" case explicitly.
- For reasoning tasks, make the model show its work before its verdict.
- A few good examples beat a long description.
- Treat prompts like code: test on multiple inputs and iterate.

Have techniques that worked well for you? Drop them in the comments below. 👇
