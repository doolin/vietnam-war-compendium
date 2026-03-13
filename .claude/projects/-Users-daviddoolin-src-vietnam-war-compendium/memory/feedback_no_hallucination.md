---
name: No fabricated content
description: Never fabricate references, URLs, context, or facts not present in source text
type: feedback
---

Do not "enrich" or fabricate content. Corroborating references, URLs, context fields, and facts not explicitly present in source text are hallucination.

**Why:** User caught a fabricated second reference on a March 12, 1975 entry. LLM-generated references and context look authoritative but are often wrong.

**How to apply:** When processing highlights or creating events, only use information explicitly stated in the source text. For references, cite only the actual source book. Leave fields empty rather than fill them with generated content. The user will add additional references themselves.
