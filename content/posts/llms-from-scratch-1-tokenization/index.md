---
title: "LLMs from Scratch — Part 1: Tokenization"
date: 2026-07-10T12:00:00+05:30
draft: false
comments: true
description: "Before a language model can predict anything, text has to become numbers. We cover Unicode and UTF-8, the character/word/subword spectrum, build a byte-pair encoding (BPE) tokenizer from scratch in Python, and see how the vocabulary shapes cost, context length, and the model itself — with interactive widgets to play with each idea."
summary: "Part 1 of building an LLM from scratch: why tokenization is the most consequential design choice, how text becomes bytes (Unicode/UTF-8), the character vs word vs subword trade-off, a complete BPE tokenizer in ~50 lines of Python, how vocabulary size ties to model size and cost, and why tokenization explains so many LLM quirks."
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

## Why tokenization deserves a whole post

It's tempting to treat tokenization as boring plumbing — a preprocessing step you set up once and forget. It isn't. The tokenizer is arguably the single most consequential design decision you make about a language model, because it silently sets the terms for everything downstream:

- **Compute and cost.** Models process *tokens*, not characters. How many tokens your text becomes determines how much you pay per request and how much compute training burns.
- **Context length.** When you hear "128K context," that number is in tokens. A less efficient tokenizer means the same document eats more of your context window.
- **What the model can represent.** The vocabulary is fixed before training starts. It decides the size of the model's input and output layers, and it caps what the model can even "see."
- **Quality and coverage.** How well a tokenizer compresses different kinds of text — prose, code, numbers, different languages and scripts — shapes how well the model tends to do on them.

That's a lot of leverage for one component. So it's worth building one ourselves rather than importing a black box. Let's start at the bottom.

## The problem: models eat numbers, not text

A neural network is a pile of matrix multiplications. It cannot see the string `"hello"` — it needs numbers. So before anything else, we need a function that maps text to a sequence of integers, and back:

```text
"the cat sat"  →  [312, 1729, 5891]  →  model  →  [output ids]  →  "on the mat"
```

That mapping is the **tokenizer**, and the set of all integers it can produce is the **vocabulary**. Every design decision here — how many tokens, what they represent — shapes what the model can and cannot do later.

## Text is really bytes: Unicode and UTF-8

Before we can turn text into tokens, we have to be precise about what "text" even is to a computer. It's tempting to think of a string as a sequence of characters, but there are two layers underneath that word.

First, **Unicode** assigns every character a number called a **code point** — about 150,000 of them, covering every script, symbol, and emoji. `A` is code point U+0041 (65), `é` is U+00E9 (233), `世` is U+4E16, `😀` is U+1F600. A Python `str` is conceptually a sequence of these code points.

Second, to *store or transmit* those code points, you have to encode them into **bytes**, and the dominant encoding is **UTF-8**. UTF-8 is variable-length and cleverly designed:

- Code points 0–127 (plain ASCII) → **1 byte**. So `A` is just the byte `0x41`.
- Most Latin-with-accents, Greek, Cyrillic, Hebrew, Arabic → **2 bytes**.
- The rest of the common multilingual range, including many CJK characters → **3 bytes**.
- Emoji and rarer scripts → **4 bytes**.

Two properties make UTF-8 the default of the modern web: it's **backward-compatible with ASCII** (English text is unchanged), and it's **self-synchronizing** (you can always find character boundaries). The one consequence to internalize: *a character is not one byte.* `"café"` is 4 characters but 5 bytes, and `"😀"` is one character but 4 bytes.

Type into the explorer below and watch each character decompose into its code point and its UTF-8 bytes:

{{< widget src="widgets/utf8-explorer.html" height="360" title="UTF-8 byte explorer" >}}

Why belabor this? Because the best modern tokenizers operate on **bytes**, not characters — and this is what lets them tokenize *literally anything*, as we'll see shortly.

## The granularity spectrum: character, word, subword

The core question of tokenization is: **how big is a token?** There are three natural answers, and understanding why the middle one wins is the heart of this post.

**Character-level:** give every character its own id. The vocabulary is tiny, and you can represent anything — no input is ever unrepresentable. But sequences get very long: `"internationalization"` becomes 20 tokens. Since attention cost grows *quadratically* with sequence length, this is expensive. Worse, each token carries almost no meaning, so the model wastes capacity just learning that `t-h-e` spells a word.

**Word-level:** give every word an id. Now `"internationalization"` is one token, sequences are short, and each token is meaningful. But the vocabulary explodes — a language has hundreds of thousands of words, and then you need plurals, tenses, typos, code, URLs, and numbers too. Anything not in the vocabulary at training time becomes an `<UNK>` token — the model is *literally incapable* of reading it. A single misspelling can turn into a blind spot.

**Subword-level:** the compromise that everything modern uses. **Frequent words get a single token; rare words get built from smaller pieces.** `"token"` might be one token, while `"unhelpfulness"` becomes `un` + `help` + `ful` + `ness` — pieces the model has seen thousands of times in other words.

That last example points at something deeper: subword tokenization naturally captures **morphology**, the internal structure of words. Prefixes (`un-`, `re-`), suffixes (`-ing`, `-ed`, `-ness`), and roots recur across the language, and a subword vocabulary discovers them just from frequency. This is why subword models can read words — and even misspellings — they never saw whole during training: they reassemble them from familiar parts. The intelligence to *interpret* `colr` as `color` comes later, from the model; the tokenizer's job is just to break the unknown into known pieces so nothing is ever a hard `<UNK>` wall.

Here's the same sentence at all three granularities. Notice how the token counts differ, and how the subword row keeps common words whole while splitting the unusual ones:

{{< widget src="widgets/token-granularity.html" height="440" title="Character vs word vs subword tokenization" >}}

So we want an algorithm that *learns* a subword vocabulary from data — keeping frequent strings whole and splitting rare ones. That algorithm is byte-pair encoding.

## Byte-pair encoding (BPE)

BPE was originally a 1994 compression trick, adapted for machine translation in 2016 (Sennrich et al.), and it's what GPT-style models use. The idea fits in one sentence:

> Start with a tiny alphabet of atomic symbols, then repeatedly merge the **most frequent adjacent pair** into a new symbol, until you reach your target vocabulary size.

Say our corpus is just: `"hug hug hug pug pun bun hug"`. Start at character level and count adjacent pairs: `("h","u")` appears 4 times, `("u","g")` 5 times, and so on. The most frequent pair is `("u","g")` → merge it into a new symbol `ug`. Recount: now `("h","ug")` appears 4 times → merge into `hug`. After a few rounds, whole common words are single tokens while rare words like `"pun"` remain as pieces (`p` + `un`). Frequency decides everything — the algorithm has no idea what a "word" is, it just compresses.

Modern tokenizers (GPT-2 onwards) run BPE **on bytes, not characters**: the atomic alphabet is the 256 possible byte values from the previous section. This is the elegant payoff of understanding UTF-8 — since *any* string is a sequence of those 256 bytes, there is *no such thing* as an out-of-vocabulary input. Emoji, code, unusual symbols, binary garbage: everything tokenizes, worst case falling back to raw bytes.

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
print(ids)                       # ids depend on your corpus
print(decode(ids, vocab))        # "hugging pugs" — lossless round-trip
```

That's a real tokenizer — the same core algorithm as GPT-2's, minus a couple of production details we'll get to (pre-tokenization and special tokens).

## Play with it

Reading about BPE is one thing — watching it work is better. The playground below runs the exact algorithm from this post, live in your browser. Edit the training corpus, drag the merge slider from 0 upward, and watch characters fuse into subwords; then type your own text and see how it tokenizes:

{{< widget src="widgets/bpe-playground.html" height="470" title="Interactive BPE tokenizer playground" >}}

Notice how words that appear often in the corpus (`the`, `hug…`) collapse into single tokens after a few dozen merges, while rare words stay fragmented — that's the whole trick. Notice also that the merges are **learned from this specific corpus**: change the text and different tokens emerge. A tokenizer is only as good as the data it was trained on.

## Two production details: pre-tokenization and special tokens

Our from-scratch tokenizer works, but real ones add two things.

**Pre-tokenization.** Before BPE runs, the text is first split with a regular expression into chunks — runs of letters, runs of digits, punctuation, whitespace — and BPE runs *within* each chunk, never merging across the boundaries. Without this, BPE would happily learn a token like `"the␣"` or even `"the␣cat"` by gluing across spaces, wasting vocabulary on position-specific junk. The split pattern also decides how whitespace attaches and how numbers are grouped. A simplified, illustrative version of the idea:

```python
import regex as re
# Split into words, numbers (in short runs), punctuation, and whitespace.
pattern = re.compile(r"""\p{L}+|\p{N}{1,3}|[^\s\p{L}\p{N}]+|\s+""")
chunks = pattern.findall(text)   # run BPE inside each chunk independently
```

Production patterns (GPT-2, GPT-4, and others) are more elaborate — handling contractions, capping digit runs so numbers tokenize consistently, and treating leading spaces carefully — but the principle is exactly this: *pre-split, then merge within splits.*

**Special tokens.** These are ids reserved out-of-band that BPE never produces from text: an end-of-document marker, padding, and — critically for chat models — control tokens that delimit conversation structure (system / user / assistant turns, tool-call boundaries). They're added to the vocabulary manually and handled outside the merge logic. They're how the model knows where a user's message ends and its own answer should begin.

## The vocabulary is a set of fixed slots

Here's the idea that connects the tokenizer to the model itself, and it's the one people most often miss.

Every token id is a **slot decided before training begins**. Id 14 means one specific token, forever; you can't renumber or repurpose it later, because the model learns weights tied to those exact ids. Two of the biggest parameter blocks in the whole network are shaped directly by the vocabulary size `V`:

- The **input embedding table** is a `V × d_model` matrix — one learned vector per token.
- The **output layer** that produces next-token probabilities is `d_model × V` — the final softmax must have exactly one slot per possible token.

So if `V = 100,000` and `d_model = 4,096`, each of those is ~400M parameters. In smaller models the embedding and output layers can dominate the parameter count. This is the trade-off at the center of tokenizer design:

| | Small vocab | Large vocab |
|---|---|---|
| Sequence length | Longer (more tokens per text) | Shorter |
| Attention compute (∝ length²) | Higher | Lower |
| Context window usage | Worse | Better |
| Embedding + output params | Fewer | More |
| Rare-token training | Each token seen often | Rare tokens under-trained |

Bigger vocab means shorter sequences (cheaper attention, more text per context window) but a bigger embedding/output layer and more rarely-seen tokens whose vectors get little training signal. It's a genuine trade-off, not a free win — which is why practical sizes cluster in a range rather than growing without bound: ~30K (BERT), ~50K (GPT-2), ~100K (GPT-4's `cl100k_base`), and 128K–256K for recent models like Llama 3 and Gemma.

One more property to nail down: the tokenizer is **frozen and deterministic**. It's trained *once* on a fixed corpus, before the model. It has no notion of context — the same text always tokenizes to the same ids regardless of what surrounds it. All the "understanding" happens later, in the model; the tokenizer is a fixed, dumb, reversible codec. You can't extend it with new data mid-training, because every id already has weights depending on it.

## The tokenizer families you'll meet in the wild

- **Byte-level BPE** — GPT-2/3/4, Claude, Llama 3. What we just built.
- **WordPiece** — BERT. Same merge-loop shape, but picks the pair that maximizes corpus likelihood rather than raw frequency, and marks word-continuation pieces with `##`.
- **Unigram / SentencePiece** — T5, Llama 1/2, Gemma. Works top-down instead: start with a huge candidate vocabulary and prune tokens whose removal hurts corpus likelihood least. SentencePiece is technically the library, not the algorithm, but the names get used interchangeably.

To poke at a production tokenizer, `tiktoken` is the quickest way:

```python
import tiktoken
enc = tiktoken.get_encoding("cl100k_base")
print(enc.encode("hugging pugs"))          # [71, 36368, 281, 13602]
print([enc.decode([t]) for t in enc.encode("hugging pugs")])
# ['h', 'ugging', ' p', 'ugs']
```

Note that leading space — in byte-level BPE, `" pugs"` and `"pugs"` are *different tokens*. The space is part of the token.

## Measuring a tokenizer: compression efficiency

How do you tell a good tokenizer from a bad one? The headline metric is **compression** — how many characters (or bytes) it packs per token. More characters per token means fewer tokens for the same text, which means lower cost, shorter sequences, and more usable context.

The catch is that efficiency isn't a single number; it depends on how closely the input resembles the tokenizer's training data. Text that looks like what it was trained on compresses well. Text that doesn't fragments into many small tokens:

- **Ordinary prose** in a well-represented language compresses best — often ~4 characters per token.
- **Code** with lots of indentation and punctuation is usually less efficient, since whitespace and symbols fragment.
- **Long numbers** can be brutal — a tokenizer that never learned a specific digit run splits it into pieces, which is part of why models are shaky at arithmetic.
- **Under-represented languages and scripts** fragment more simply because the training corpus contained less of them, so fewer whole-word merges were learned. The same meaning can cost several times more tokens — real money and real context-window pressure.

You can feel all of this in the BPE playground above: paste in code, or a run of digits, or repeated unusual characters, and watch the chars-per-token number move. A tokenizer is a bet about what text will look like, and you pay for every place the bet is wrong.

## Why this explains half the weird LLM behavior you've seen

Once you know tokens are the model's atoms, a lot of quirks stop being mysterious:

- **"How many r's in strawberry?"** The model doesn't see letters — it may see `[str, awberry]`. Counting characters inside a token is the wrong level of abstraction; the letters were dissolved away at tokenization time.
- **Arithmetic is flaky.** `1234` might be one token and `1235` two (`123`, `5`), so digit structure is inconsistent from the model's point of view. Newer tokenizers deliberately split digits into fixed groups to make numbers more uniform.
- **Some text is far more expensive than other text.** Because compression depends on the training distribution, unusual formatting, heavy whitespace, or under-represented languages can cost several times more tokens for the same content — inflating both bills and context usage.
- **Glitch tokens.** Strings that made it into the vocabulary but barely appeared in training (leaked usernames, scraping artifacts) have near-untrained embeddings, and feeding them to a model can produce genuinely bizarre output.
- **Trailing spaces and formatting sensitivity.** Since a space is part of a token, a trailing space or an unusual break can push text onto a different, rarer token path than the model expects — sometimes hurting quality for reasons that have nothing to do with the content.
- **Prompt costs and chunking.** Everything you're billed for and everything that fits in a context window is measured in tokens. If you build RAG systems, your chunk sizes, overlap, and retrieval budgets are all really token arithmetic.

## Wrapping up

We went from raw text all the way to token ids: text is Unicode code points, stored as UTF-8 bytes; tokenization picks a granularity between characters and words; BPE learns a subword vocabulary by greedily merging frequent pairs; and that vocabulary — fixed, frozen, and finite — sets the model's input and output layers, its costs, and its context budget. Everything an LLM will ever "know" about text arrives through this pipe.

In **Part 2** we'll take these token ids and give them meaning: embedding matrices, what "directions in vector space" actually buy us, and why that `V × d_model` table we just met is often the biggest single block of parameters in a small model.

Questions, corrections, or war stories about tokenizer bugs? The comments are open below. 👇
