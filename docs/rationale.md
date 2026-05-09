# Rationale — HDISKCOPY

## Motivation

Floppy disk copying was time-consuming,\
and repeated copy operations made the waiting time noticeable.

This led to a simple question:

> Is there a way to reduce copy time?

From this point, the idea behind HDISKCOPY began to take shape.

---

## Key Idea

The standard `DISKCOPY` utility performs a full disk copy,\
including unused areas.

This led to a simple idea:

> Only copy clusters that actually contain data.

Since FAT already describes which clusters are in use,\
it should be possible to copy only meaningful data and skip empty regions.

This approach would significantly reduce copy time.

HDISKCOPY was created based on this idea.

---

## Media-Independent Copy

Initially, the tool was designed for floppy disks.

However, since the logic depends on FAT structure rather than physical media,\
it was extended to support copying between different devices of the same format:

* floppy disk ↔ floppy disk
* MO ↔ MO
* MO ↔ HDD

As long as the FAT layout is compatible,\
the same copying method can be applied regardless of the medium.

---

## Performance Characteristics

The original `DISKCOPY` works by copying one track at a time:

* read one track
* write one track
* repeat

HDISKCOPY uses a different approach.

It reads as much data as possible into memory before writing,\
reducing unnecessary drive movement.

For floppy disks, this often results in a near one-pass operation,\
minimizing mechanical overhead.

For larger media such as MO disks,\
multiple passes are still required,\
but the total number of operations is reduced as much as possible.

This not only improves speed,\
but also reduces the perceived waiting time during operation.

---

## Observation

During development, the behavior of the original `DISKCOPY` was examined closely.

Its track-by-track operation appeared conservative,\
likely prioritizing reliability over efficiency.

In contrast, HDISKCOPY was designed with a different balance:

> Maintain reliability while improving efficiency wherever possible.

---

## Summary

HDISKCOPY was developed from a practical need:

* reduce disk copy time
* avoid unnecessary data transfer
* improve usability in real workflows

By leveraging FAT structure and available memory,\
it provides a more efficient alternative to traditional disk copying,\
while maintaining compatibility and reliability.
