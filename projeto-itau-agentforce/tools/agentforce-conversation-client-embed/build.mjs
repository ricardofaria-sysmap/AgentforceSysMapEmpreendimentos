import * as esbuild from "esbuild";
import path from "node:path";
import { fileURLToPath } from "node:url";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const outfile = path.resolve(
  __dirname,
  "../../force-app/main/default/staticresources/AgentforceConversationClientEmbed.js"
);

await esbuild.build({
  entryPoints: [path.join(__dirname, "entry.js")],
  bundle: true,
  format: "iife",
  platform: "browser",
  legalComments: "none",
  outfile,
});

console.log("Wrote", outfile);
