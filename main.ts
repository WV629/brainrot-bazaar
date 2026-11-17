// Brainrot Bazaar: the program that hands this entry in.
//
// It runs on Node 22 with the standard library only, in a container
// with no network, a read-only copy of this repository and a writable
// output directory. It copies the built place (game.rbxl), the Luau
// sources (src/), the screenshots and PLAY.json into the output
// directory, then writes dossier.json there with the vendored
// make.fun library, which is the summary the judge reads.
//
// The grader fails an entry whose output holds any name that does not
// start with a letter, a digit or _ (a file such as .gitkeep or
// .DS_Store), so every copy below skips names that start with a dot,
// at any depth.
//
// Run it the way the grader does, writing out/ in place of /output:
//   mkdir -p out && MAKEFUN_OUTPUT_DIR=out node main.ts

import { copyFileSync, cpSync, existsSync, mkdirSync, writeFileSync } from "node:fs";
import { basename, join } from "node:path";
import { fileURLToPath } from "node:url";
import { buildDossier } from "./vendor/makefun-roblox.ts";

// The repository root is the directory this file lives in.
const repoRoot = fileURLToPath(new URL(".", import.meta.url));
// The grader sets /output; locally MAKEFUN_OUTPUT_DIR stands in for it.
const outputDir = process.env.MAKEFUN_OUTPUT_DIR ?? "/output";

// Skip every file and directory whose name starts with a dot.
const isVisibleName = (path: string): boolean => !basename(path).startsWith(".");

// The place file and the play link go over as single files.
copyFileSync(join(repoRoot, "game.rbxl"), join(outputDir, "game.rbxl"));
copyFileSync(join(repoRoot, "PLAY.json"), join(outputDir, "PLAY.json"));

// The sources and the screenshots go over as whole trees.
cpSync(join(repoRoot, "src"), join(outputDir, "src"), { recursive: true, filter: isVisibleName });
mkdirSync(join(outputDir, "screenshots"), { recursive: true });
if (existsSync(join(repoRoot, "screenshots"))) {
	cpSync(join(repoRoot, "screenshots"), join(outputDir, "screenshots"), {
		recursive: true,
		filter: isVisibleName,
	});
}

// The dossier is built from what was just copied, with the gate's own
// caps: at most 4 screenshots of at most 256 KiB, a place of at most
// 500,000 instances, scripts of at most 8 MiB of source in all and at
// most 1,048,576 characters of script paths in all. Only the text cap
// shapes the bytes; the rest refuse an entry the scorer would refuse.
writeFileSync(
	join(outputDir, "dossier.json"),
	buildDossier(outputDir, {
		text_max_bytes: 65536,
		screenshots: { max: 4, max_bytes: 262144 },
		max_instances: 500000,
		scripts_max_source_bytes: 8388608,
		scripts_max_path_chars: 1048576,
	}),
);
