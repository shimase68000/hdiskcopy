# HDISKCOPY

High-speed disk copy tool for X68000, preserved as original implementation.

---

## Overview

HDISKCOPY is a disk copy tool that improves performance by copying\
only clusters that contain data.

Instead of copying the entire disk surface,\
it analyzes the FAT structure and copies only the necessary areas.

This significantly reduces copy time compared to conventional disk copy tools.

A full-sector copy mode is also available.

---

## Features

* Copies only used clusters by default
* Significantly faster than full disk copy
* Full-sector copy available via `/a` option
* Works with media that share the same FAT structure
* Designed for practical use in real environments

---

## Usage

```text
HDISKCOPY [options] <source drive> <destination drive>
```

Example:

```text
HDISKCOPY A: B:
```

---

## Options

* `/a`
  Copy all sectors instead of only used clusters

---

## Notes

* Source and destination drives must have the same capacity
* The tool operates based on FAT structure compatibility
* Data is copied at the cluster level in default mode

---

## Design Concept

HDISKCOPY was created to improve the performance of disk copy operations,\
particularly when working with large numbers of disks.

The key idea is simple:

> only clusters that contain data need to be copied

This allows efficient data transfer while avoiding unnecessary disk access.

---

## Status

This repository preserves the original implementation.

The source code and documentation are provided as-is,\
with minimal modification.

---

## License

MIT License
