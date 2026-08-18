#!/usr/bin/env node
import fs from "node:fs";
import path from "node:path";

const ROOT = path.resolve(path.dirname(new URL(import.meta.url).pathname), "..");
const DOCS = path.join(ROOT, "docs");
const BACKEND_DOCS = path.join(ROOT, "backend-docs");

const tools = [
  {
    name: "list_endpoints",
    description:
      "List API endpoints from backend-docs/endpoints_index.json (fallback: API_ENDPOINT_MATRIX.md).",
    inputSchema: {
      type: "object",
      properties: {
        search: { type: "string" },
        tag: { type: "string" },
        limit: { type: "number" }
      }
    }
  },
  {
    name: "get_endpoint",
    description: "Return endpoint index entries matching a path (partial match).",
    inputSchema: {
      type: "object",
      properties: { path: { type: "string" } },
      required: ["path"]
    }
  },
  {
    name: "search_endpoints",
    description: "Search endpoints by path, method, tag, or auth field.",
    inputSchema: {
      type: "object",
      properties: {
        query: { type: "string" },
        limit: { type: "number" }
      },
      required: ["query"]
    }
  },
  {
    name: "list_models",
    description: "List Prisma model names from backend-docs/schema.prisma.",
    inputSchema: {
      type: "object",
      properties: {
        search: { type: "string" },
        limit: { type: "number" }
      }
    }
  },
  {
    name: "get_model",
    description: "Return one Prisma model block from backend-docs/schema.prisma.",
    inputSchema: {
      type: "object",
      properties: { name: { type: "string" } },
      required: ["name"]
    }
  },
  {
    name: "search_schema",
    description: "Full-text search in backend-docs/schema.prisma.",
    inputSchema: {
      type: "object",
      properties: {
        query: { type: "string" },
        limit: { type: "number" }
      },
      required: ["query"]
    }
  },
  {
    name: "get_auth_flow",
    description: "Return the documented Canlifal mobile JWT/auth integration summary.",
    inputSchema: { type: "object", properties: {} }
  },
  {
    name: "read_audit",
    description: "Read one generated audit/matrix report from docs/.",
    inputSchema: {
      type: "object",
      properties: {
        file: {
          type: "string",
          enum: [
            "API_INTEGRATION_AUDIT.md",
            "API_ENDPOINT_MATRIX.md",
            "MCP_INTEGRATION_MATRIX.md",
            "API_PARITY_FINAL_REPORT.md",
            "BACKEND_FLUTTER_PARITY_AUDIT.md",
            "PHASE_PLAN.md"
          ]
        }
      },
      required: ["file"]
    }
  },
  {
    name: "read_backend_doc",
    description: "Read a file from backend-docs/ (OpenAPI excerpt, B1.12, etc.).",
    inputSchema: {
      type: "object",
      properties: {
        file: {
          type: "string",
          enum: [
            "README.md",
            "B1_12_API_MCP_FLUTTER_PARITY.md",
            "MCP_REGISTRY.md",
            "MCP_INVENTORY.md"
          ]
        }
      },
      required: ["file"]
    }
  }
];

let _endpointIndexCache;
function endpointIndex() {
  if (_endpointIndexCache) return _endpointIndexCache;
  const file = path.join(BACKEND_DOCS, "endpoints_index.json");
  if (!fs.existsSync(file)) return (_endpointIndexCache = []);
  _endpointIndexCache = JSON.parse(fs.readFileSync(file, "utf8"));
  return _endpointIndexCache;
}

function readDoc(file) {
  const full = path.resolve(DOCS, file);
  if (!full.startsWith(DOCS + path.sep)) {
    throw new Error("Invalid path");
  }
  return fs.readFileSync(full, "utf8");
}

function readBackendDoc(file) {
  const full = path.resolve(BACKEND_DOCS, file);
  if (!full.startsWith(BACKEND_DOCS + path.sep)) {
    throw new Error("Invalid path");
  }
  return fs.readFileSync(full, "utf8");
}

function endpointRows() {
  const md = readDoc("API_ENDPOINT_MATRIX.md");
  return md
    .split("\n")
    .filter((line) => line.startsWith("| `/api/"))
    .map((line) => line.trim());
}

function formatIndexEntry(e) {
  return `${e.method} ${e.path} [auth=${e.auth}, tag=${e.tag ?? "-"}]`;
}

function prismaText() {
  const file = path.join(BACKEND_DOCS, "schema.prisma");
  if (!fs.existsSync(file)) return "";
  return fs.readFileSync(file, "utf8");
}

function prismaModels() {
  const text = prismaText();
  const names = [];
  for (const m of text.matchAll(/^model\s+(\w+)\s*\{/gm)) {
    names.push(m[1]);
  }
  return names;
}

function prismaModelBlock(name) {
  const text = prismaText();
  const re = new RegExp(`^model\\s+${name}\\s*\\{[\\s\\S]*?^\\}`, "m");
  const match = text.match(re);
  return match ? match[0] : null;
}

function textContent(text) {
  return { content: [{ type: "text", text }] };
}

function callTool(name, args = {}) {
  if (name === "list_endpoints") {
    const search = String(args.search ?? "").toLowerCase();
    const tag = String(args.tag ?? "").toLowerCase();
    const limit = Number(args.limit ?? 100);
    const index = endpointIndex();
    if (index.length > 0) {
      const rows = index.filter((e) => {
        if (search && !`${e.path} ${e.method} ${e.tag ?? ""}`.toLowerCase().includes(search)) {
          return false;
        }
        if (tag && String(e.tag ?? "").toLowerCase() !== tag) return false;
        return true;
      });
      return textContent(
        rows.slice(0, limit).map(formatIndexEntry).join("\n") || "No endpoints matched."
      );
    }
    const rows = endpointRows().filter((row) => !search || row.toLowerCase().includes(search));
    return textContent(rows.slice(0, limit).join("\n") || "No endpoints matched.");
  }
  if (name === "get_endpoint") {
    const query = String(args.path ?? "").toLowerCase();
    const index = endpointIndex();
    if (index.length > 0) {
      const rows = index.filter((e) => e.path.toLowerCase().includes(query));
      return textContent(
        rows.map(formatIndexEntry).join("\n") || `Endpoint not found: ${args.path}`
      );
    }
    const rows = endpointRows().filter((row) => row.toLowerCase().includes(query));
    return textContent(rows.join("\n") || `Endpoint not found: ${args.path}`);
  }
  if (name === "search_endpoints") {
    const query = String(args.query ?? "").toLowerCase();
    const limit = Number(args.limit ?? 100);
    const index = endpointIndex();
    if (index.length > 0) {
      const rows = index.filter((e) =>
        `${e.path} ${e.method} ${e.auth} ${e.tag ?? ""}`.toLowerCase().includes(query)
      );
      return textContent(
        rows.slice(0, limit).map(formatIndexEntry).join("\n") || "No endpoints matched."
      );
    }
    const rows = endpointRows().filter((row) => row.toLowerCase().includes(query));
    return textContent(rows.slice(0, limit).join("\n") || "No endpoints matched.");
  }
  if (name === "list_models") {
    const search = String(args.search ?? "").toLowerCase();
    const limit = Number(args.limit ?? 200);
    const models = prismaModels().filter((n) => !search || n.toLowerCase().includes(search));
    return textContent(models.slice(0, limit).join("\n") || "No models matched.");
  }
  if (name === "get_model") {
    const nameArg = String(args.name ?? "").trim();
    const block = prismaModelBlock(nameArg);
    return textContent(block ?? `Model not found: ${nameArg}`);
  }
  if (name === "search_schema") {
    const query = String(args.query ?? "").toLowerCase();
    const limit = Number(args.limit ?? 40);
    const lines = prismaText().split("\n");
    const hits = lines.filter((line) => line.toLowerCase().includes(query));
    return textContent(hits.slice(0, limit).join("\n") || "No schema matches.");
  }
  if (name === "get_auth_flow") {
    return textContent(
      [
        "Canlifal mobile auth:",
        "- Base URL: https://canlifal.com",
        "- Canonical prefix: /api",
        "- Login/register/refresh: /api/auth/mobile-*",
        "- Authenticated calls: Authorization: Bearer <accessToken>",
        "- Refresh: POST /api/auth/mobile-refresh",
        "- Runtime MCP: not used by Flutter; Flutter uses REST/SSE/TRTC.",
        "- Music !istek (prod): music-request-by-query 404 → song-request + youtube search"
      ].join("\n")
    );
  }
  if (name === "read_audit") {
    return textContent(readDoc(String(args.file)));
  }
  if (name === "read_backend_doc") {
    return textContent(readBackendDoc(String(args.file)));
  }
  throw new Error(`Unknown tool: ${name}`);
}

function response(id, result) {
  return { jsonrpc: "2.0", id, result };
}

function errorResponse(id, error) {
  return {
    jsonrpc: "2.0",
    id,
    error: { code: -32000, message: error instanceof Error ? error.message : String(error) }
  };
}

function handle(message) {
  const { id, method, params } = message;
  try {
    if (method === "initialize") {
      return response(id, {
        protocolVersion: "2024-11-05",
        capabilities: { tools: {}, resources: {} },
        serverInfo: { name: "canlifal-backend", version: "1.1.0" }
      });
    }
    if (method === "tools/list") {
      return response(id, { tools });
    }
    if (method === "tools/call") {
      return response(id, callTool(params?.name, params?.arguments));
    }
    if (method === "resources/list") {
      return response(id, {
        resources: [
          { uri: "endpoints://index", name: "Backend endpoint index (JSON)" },
          { uri: "schema://prisma", name: "Prisma schema" },
          { uri: "openapi://spec", name: "OpenAPI spec (large)" },
          { uri: "audit://parity-b112", name: "B1.12 parity audit" },
          { uri: "audit://endpoint-matrix", name: "API endpoint matrix" }
        ]
      });
    }
    if (method === "resources/read") {
      const byUri = {
        "endpoints://index": () => readBackendDoc("endpoints_index.json"),
        "schema://prisma": () => prismaText(),
        "openapi://spec": () => readBackendDoc("openapi.json"),
        "audit://parity-b112": () => readBackendDoc("B1_12_API_MCP_FLUTTER_PARITY.md"),
        "audit://endpoint-matrix": () => readDoc("API_ENDPOINT_MATRIX.md")
      };
      const reader = byUri[params?.uri];
      if (!reader) throw new Error(`Unknown resource: ${params?.uri}`);
      const mimeType = params?.uri?.includes("json") ? "application/json" : "text/plain";
      return response(id, {
        contents: [{ uri: params.uri, mimeType, text: reader() }]
      });
    }
    if (id !== undefined) {
      return response(id, {});
    }
    return null;
  } catch (error) {
    return errorResponse(id, error);
  }
}

function send(payload) {
  if (!payload) return;
  const body = JSON.stringify(payload);
  process.stdout.write(`Content-Length: ${Buffer.byteLength(body, "utf8")}\r\n\r\n${body}`);
}

if (process.argv.includes("--selftest")) {
  const index = endpointIndex();
  const models = prismaModels();
  console.log(
    JSON.stringify({
      status: "OK",
      endpointIndex: index.length,
      prismaModels: models.length,
      tools: tools.length,
      backendDocs: fs.existsSync(BACKEND_DOCS)
    })
  );
  process.exit(0);
}

let buffer = Buffer.alloc(0);
process.stdin.on("data", (chunk) => {
  buffer = Buffer.concat([buffer, chunk]);
  while (true) {
    const headerEnd = buffer.indexOf("\r\n\r\n");
    if (headerEnd < 0) return;
    const header = buffer.slice(0, headerEnd).toString("utf8");
    const match = /Content-Length:\s*(\d+)/i.exec(header);
    if (!match) {
      buffer = Buffer.alloc(0);
      return;
    }
    const length = Number(match[1]);
    const bodyStart = headerEnd + 4;
    const bodyEnd = bodyStart + length;
    if (buffer.length < bodyEnd) return;
    const raw = buffer.slice(bodyStart, bodyEnd).toString("utf8");
    buffer = buffer.slice(bodyEnd);
    try {
      send(handle(JSON.parse(raw)));
    } catch (error) {
      send(errorResponse(null, error));
    }
  }
});
