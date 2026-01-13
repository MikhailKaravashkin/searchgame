import { Server } from "@modelcontextprotocol/sdk/server/index.js";
import { StdioServerTransport } from "@modelcontextprotocol/sdk/server/stdio.js";
import { z } from "@modelcontextprotocol/sdk/shared/zod.js";
import { execFile } from "node:child_process";
import { promisify } from "node:util";
import path from "node:path";

const execFileAsync = promisify(execFile);

const server = new Server(
  {
    name: "searchgame-assets",
    version: "0.1.0",
  },
  {
    capabilities: {
      tools: {},
    },
  }
);

const GenerateAssetsInput = z.object({
  background: z.boolean().default(true).describe("Generate background image(s)"),
  duck: z.boolean().default(true).describe("Generate duck sprite"),
});

server.tool(
  "generate_assets",
  "Generate (or regenerate) game assets into SearchGame/Resources/Generated using scripts/generate_assets.py",
  GenerateAssetsInput,
  async (_args) => {
    // For now, scripts/generate_assets.py always generates bg_farm_day + duck.
    // We keep args for future extension.
    const repoRoot = path.resolve(new URL("../..", import.meta.url).pathname);
    const script = path.join(repoRoot, "scripts", "generate_assets.py");

    try {
      const { stdout, stderr } = await execFileAsync("python3", [script], {
        cwd: repoRoot,
        env: process.env,
        timeout: 10 * 60 * 1000,
        maxBuffer: 10 * 1024 * 1024,
      });

      const text = [stdout, stderr].filter(Boolean).join("\n").trim();

      return {
        content: [
          {
            type: "text",
            text:
              (text ? text + "\n\n" : "") +
              "Generated files should be in SearchGame/Resources/Generated (e.g., bg_farm_day.png, duck.png).",
          },
        ],
      };
    } catch (e) {
      const msg = e?.message ?? String(e);
      return {
        content: [{ type: "text", text: `Generation failed: ${msg}` }],
        isError: true,
      };
    }
  }
);

const transport = new StdioServerTransport();
await server.connect(transport);
