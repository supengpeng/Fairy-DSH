#!/usr/bin/env node
// Cross-platform profile mount for isolated testing.
//
// The profile must live at $DSH_HOME/profiles/web, but its pnpm `link:`
// dependencies point back into this repository. Two platform-specific hazards
// make a plain `ln -s` insufficient on Windows:
//
// 1. Windows junctions carry relative targets poorly: mounting the profile
//    through an outer junction re-bases every nested relative link, so
//    resolution lands outside the repository.
// 2. pnpm writes `link:` targets as relative paths, which is correct on POSIX
//    (a symlink resolves against its own directory) and wrong through a
//    Windows junction chain.
//
// So the mount and every nested plugin link are (re)created with absolute
// targets. Run after `pnpm install` in profiles/web, and again whenever the
// install rewrites the links.
import { lstatSync, readlinkSync, readdirSync, rmSync, symlinkSync } from 'node:fs'
import { dirname, isAbsolute, join, resolve } from 'node:path'
import { fileURLToPath } from 'node:url'

const repoRoot = dirname(dirname(fileURLToPath(import.meta.url)))
const profileDir = join(repoRoot, 'profiles', 'web')

const home = process.env.DSH_HOME
if (home === undefined || home === '') {
  console.error('link-profile: DSH_HOME must be set to the isolated harness home')
  process.exit(1)
}
const mountDir = join(home, 'profiles', 'web')

/** Recreate `link` so it points at `target` through an absolute path. */
function absoluteLink(link, target) {
  let stat
  try {
    stat = lstatSync(link)
  } catch {
    stat = undefined
  }
  if (stat !== undefined) {
    // An unrelated directory or file at the mount point is a setup error the
    // operator must resolve; only links we can re-aim are ours to manage.
    if (!stat.isSymbolicLink() && !stat.isDirectory()) {
      throw new Error(`link-profile: ${link} exists and is not a link or directory`)
    }
    rmSync(link, { recursive: true, force: true })
  }
  symlinkSync(target, link, 'junction')
}

absoluteLink(mountDir, profileDir)

// Re-aim every nested `link:` dependency at its absolute repository target so
// resolution through the mount cannot drift. Non-link entries stay untouched.
const modulesDir = join(profileDir, 'node_modules')
let relinked = 0
function relinkDirectory(dir) {
  let names
  try {
    names = readdirSync(dir)
  } catch {
    return // absent: the caller links first and installs after.
  }
  for (const name of names) {
    const entry = join(dir, name)
    let target
    try {
      target = readlinkSync(entry)
    } catch {
      // A real file or directory from the hoisted linker — including a scoped
      // package directory, whose own children are visited next.
      if (name.startsWith('@') && !name.includes('/')) {
        try {
          if (lstatSync(entry).isDirectory()) relinkDirectory(entry)
        } catch {
          // a scoped entry that vanished mid-scan: nothing to relink
        }
      }
      continue
    }
    const absolute = isAbsolute(target) ? target : resolve(dirname(entry), target)
    rmSync(entry, { recursive: true, force: true })
    symlinkSync(absolute, entry, 'junction')
    relinked += 1
  }
}
relinkDirectory(modulesDir)
console.log(`link-profile: mounted ${mountDir} -> ${profileDir}, ${String(relinked)} plugin links re-aimed`)
