# practice/

This directory contains the exam-prep layer for the CKA study roadmap — everything you need in the final days before the exam and in the exam itself. It sits alongside `cka-exercises/` (domain drills) and `break-fix/` (fault-injection scenarios). The intended flow is: complete the domain exercises, run at least two timed mocks using the resources in `mock-exams.md`, log every mistake in `gotchas.md`, and then on exam day follow `day-of-exam.md` step by step. The `exam-setup.md` file should be open in a second terminal at all times during the exam.

## Contents

- [`exam-setup.md`](exam-setup.md) — shell aliases, variables, autocompletion, JSONPath/output tricks, `.vimrc`, and tmux basics to paste in at the start of the exam.
- [`exam-bookmarks.md`](exam-bookmarks.md) — curated kubernetes.io URLs grouped by CKA domain, ready to load in the exam browser before the clock starts.
- [`mock-exams.md`](mock-exams.md) — the read → drill → timed-mock cadence, pointers to the free killer.sh simulator sessions and killercoda scenarios, and score/weak-area tracking tables.
- [`day-of-exam.md`](day-of-exam.md) — logistics checklist (ID, proctor scan, time budget, flag-and-move-on discipline) and the mandatory `kubectl config use-context` reminder for every task.
- [`gotchas.md`](gotchas.md) — running mistake log (date · mistake · fix/lesson table) seeded with common errors; also absorbs spaced-repetition review notes.
- [`break-fix/`](break-fix/) — intentionally broken cluster scenarios.
