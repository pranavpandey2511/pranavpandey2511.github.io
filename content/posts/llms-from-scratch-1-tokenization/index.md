---
title: "LLMs from Scratch — Part 1: Tokenization"
date: 2026-07-10T12:00:00+05:30
draft: false
comments: true
description: "Before a language model can predict anything, text has to become numbers. We build a byte-pair encoding (BPE) tokenizer from scratch in pure Python and see why tokenization explains so many LLM quirks."
summary: "Part 1 of building an LLM from scratch: what tokenization is, why character- and word-level approaches fail, how BPE works, and a complete BPE tokenizer implemented in ~50 lines of Python."
tags: ["llm", "tokenization", "bpe", "from-scratch"]
categories: ["GenAI"]
series: ["LLMs from Scratch"]
series_order: 1
ShowToc: true
TocOpen: false
math: false
---

Welcome to **LLMs from Scratch** — a series where we build up a working understanding of large language models from first principles, with real code at every step. No hand-waving: by the end of the series you'll have followed the entire pipeline from raw text to a model that generates it. The rough roadmap:

1. **Tokenization** (this post) — turning text into numbers
2. Embeddings — turning tokens into vectors
3. Attention — how tokens talk to each other
4. The Transformer block — assembling the architecture
5. Training — loss, data, and the optimization loop
6. Sampling & decoding — how models actually generate text

Let's start where every LLM starts: tokenization.

## The problem: models eat numbers, not text

A neural network is a pile of matrix multiplications. It cannot see the string `"hello"` — it needs numbers. So before anything else, we need a function that maps text to a sequence of integers, and back:

```text
"the cat sat"  →  [312, 1729, 5891]  →  model  →  [output ids]  →  "on the mat"
```

That mapping is the **tokenizer**, and the set of all integers it can produce is the **vocabulary**. Every design decision here — how many tokens, what they represent — silently shapes everything the model can and cannot do later. Tokenization is the unglamorous layer that explains a surprising number of LLM failures, which is exactly why it's worth building one ourselves.

## The two obvious approaches (and why they fail)

**Character-level:** give every character its own id. The vocabulary is tiny (a few hundred symbols for English), and you can represent anything. But sequences get very long — `"internationalization"` becomes 20 tokens — and attention cost grows quadratically with sequence length. Worse, each token carries almost no meaning, so the model burns capacity just learning that `t-h-e` is a word.

**Word-level:** give every word an id. Now `"internationalization"` is one token, sequences are short, and each token is meaningful. But the vocabulary explodes — English has hundreds of thousands of words, then plurals, typos, code, URLs, other languages... And any word not in the vocabulary at training time becomes `<UNK>` — the model is literally incapable of reading it.

What we want is something in between: **common strings get single tokens, rare strings get built from pieces**. That's subword tokenization, and the dominant algorithm is byte-pair encoding.

## Byte-pair encoding (BPE)

BPE was originally a 1994 compression trick, adapted for machine translation in 2016 (Sennrich et al.), and it's what GPT-style models use. The idea fits in one sentence:

> Start with a tiny alphabet of atomic symbols, then repeatedly merge the **most frequent adjacent pair** into a new symbol, until you reach your target vocabulary size.

Say our corpus is just: `"hug hug hug pug pun bun hug"`. Start at character level and count adjacent pairs: `("h","u")` appears 4 times, `("u","g")` 5 times, and so on. The most frequent pair is `("u","g")` → merge it into a new symbol `ug`. Recount: now `("h","ug")` appears 4 times → merge into `hug`. After a few rounds, whole common words are single tokens while rare words like `"pun"` remain as pieces (`p` + `un`). Frequency decides everything — the algorithm has no idea what a "word" is, it just compresses.

Modern tokenizers (GPT-2 onwards) run BPE **on bytes, not characters**: the atomic alphabet is the 256 possible byte values. This is elegant — any Unicode string is a byte sequence, so there is *no such thing* as an out-of-vocabulary input. Emoji, Hindi, code, binary garbage: everything tokenizes.

## Let's build it

Here is a complete, working byte-level BPE tokenizer. First, training — learn which pairs to merge:

```python
from collections import Counter

def get_pair_counts(ids):
    """Count adjacent pairs in a list of token ids."""
    return Counter(zip(ids, ids[1:]))

def merge(ids, pair, new_id):
    """Replace every occurrence of `pair` in `ids` with `new_id`."""
    out, i = [], 0
    while i < len(ids):
        if i < len(ids) - 1 and (ids[i], ids[i + 1]) == pair:
            out.append(new_id)
            i += 2
        else:
            out.append(ids[i])
            i += 1
    return out

def train(text, vocab_size):
    """Learn BPE merges from text. Returns the merge table."""
    assert vocab_size >= 256
    ids = list(text.encode("utf-8"))   # start from raw bytes: ids 0..255
    merges = {}                         # (id, id) -> new id
    for i in range(vocab_size - 256):
        counts = get_pair_counts(ids)
        if not counts:
            break
        pair = max(counts, key=counts.get)      # most frequent pair
        new_id = 256 + i
        ids = merge(ids, pair, new_id)
        merges[pair] = new_id
    return merges
```

Encoding applies the learned merges to new text — always in the order they were learned:

```python
def encode(text, merges):
    ids = list(text.encode("utf-8"))
    while len(ids) >= 2:
        counts = get_pair_counts(ids)
        # pick the mergeable pair that was learned EARLIEST
        pair = min(counts, key=lambda p: merges.get(p, float("inf")))
        if pair not in merges:
            break                       # nothing left to merge
        ids = merge(ids, pair, merges[pair])
    return ids
```

Decoding is just table lookup — build each token's bytes by expanding its merges:

```python
def build_vocab(merges):
    vocab = {i: bytes([i]) for i in range(256)}
    for (a, b), new_id in merges.items():   # dicts preserve insertion order
        vocab[new_id] = vocab[a] + vocab[b]
    return vocab

def decode(ids, vocab):
    return b"".join(vocab[i] for i in ids).decode("utf-8", errors="replace")
```

Try it:

```python
text = open("some_corpus.txt").read()
merges = train(text, vocab_size=1000)
vocab = build_vocab(merges)

ids = encode("hugging pugs", merges)
print(ids)                       # e.g. [credit: your corpus decides]
print(decode(ids, vocab))        # "hugging pugs" — lossless round-trip
```

That's a real tokenizer — the same core algorithm as GPT-2's, minus production details. The two that matter:

- **Pre-tokenization.** Production tokenizers first split text with a regex (on whitespace, letter/digit boundaries, etc.) and run BPE *within* those chunks, so merges never cross word boundaries. Without this you'd get tokens like `"the␣cat"` glued together.
- **Special tokens.** Ids reserved for control markers — `<|endoftext|>`, chat-turn delimiters — that are never produced by merges and get handled outside the BPE logic.

## Play with it

Reading about BPE is one thing — watching it work is better. The playground below runs the exact algorithm from this post, live in your browser. Edit the training corpus, drag the merge slider from 0 upward, and watch characters fuse into subwords; then type your own text and see how it tokenizes:

{{< widget src="widgets/bpe-playground.html" height="470" title="Interactive BPE tokenizer playground" >}}

Notice how words that appear often in the corpus (`the`, `hug…`) collapse into single tokens after a few dozen merges, while rare words stay fragmented — that's the whole trick.

## The tokenizer families you'll meet in the wild

- **Byte-level BPE** — GPT-2/3/4, Claude, Llama 3. What we just built.
- **WordPiece** — BERT. Same merge-loop shape, but picks the pair that maximizes corpus likelihood rather than raw frequency, and marks word-continuation pieces with `##`.
- **Unigram / SentencePiece** — T5, Llama 1/2, Gemma. Works top-down instead: start with a huge candidate vocabulary and prune tokens whose removal hurts corpus likelihood least. SentencePiece is technically the library, not the algorithm, but the names get used interchangeably.

Vocabulary sizes in practice: GPT-2 used ~50K tokens, GPT-4's `cl100k_base` ~100K, and recent models push 128K–200K+. Bigger vocab = shorter sequences (cheaper attention, more effective context) but a bigger embedding table and rarer, less-trained tokens. It's a genuine trade-off, not a free win.

To poke at a production tokenizer, `tiktoken` is the quickest way:

```python
import tiktoken
enc = tiktoken.get_encoding("cl100k_base")
print(enc.encode("hugging pugs"))          # [71, 36368, 281, 13602]
print([enc.decode([t]) for t in enc.encode("hugging pugs")])
# ['h', 'ugging', ' p', 'ugs']
```

Note that leading space — in byte-level BPE, `" pugs"` and `"pugs"` are *different tokens*. The space is part of the token.

## Why this explains half the weird LLM behavior you've seen

Once you know tokens are the model's atoms, a lot of quirks stop being mysterious:

- **"How many r's in strawberry?"** The model doesn't see letters — it may see `[str, awberry]`. Counting characters inside a token is like asking you to count neurons firing while you read: wrong level of abstraction.
- **Arithmetic is flaky.** `1234` might be one token and `1235` two (`123`, `5`), so digit structure is inconsistent. Newer models tokenize digits individually or in fixed groups partly for this reason.
- **Non-English text is expensive.** BPE merges reflect training-data frequency, so lower-resource languages get fragmented into many tokens — the same sentence can cost 3–5× more tokens in Hindi than English. That's real money and real context-window pressure (something I feel directly building multilingual document pipelines).
- **Glitch tokens.** Strings that made it into the vocabulary but barely appeared in training (leaked usernames, debug artifacts) have near-untrained embeddings, and feeding them to a model produces genuinely bizarre output.
- **Prompt costs and chunking.** Everything you're billed for and everything that fits in a context window is measured in tokens. If you build RAG systems, your chunk sizes, overlap, and retrieval budgets are all really token arithmetic.

## Wrapping up

We built a complete byte-level BPE tokenizer: train on a corpus by greedily merging frequent pairs, encode by replaying merges, decode by expanding them. Everything an LLM will ever "know" about text arrives through this pipe.

In **Part 2** we'll take these token ids and give them meaning: embedding matrices, what "directions in vector space" actually buy us, and why the embedding table is often the biggest single block of parameters in a small model.

Questions, corrections, or war stories about tokenizer bugs? The comments are open below. 👇
