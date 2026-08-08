#!/usr/bin/env node
import fs from "node:fs";
import path from "node:path";

const ROOT = path.resolve(path.dirname(new URL(import.meta.url).pathname), "..");
const DOCS = path.join(ROOT, "docs");

const tools = [
  {
    name: "list_endpoints",
    description: "List backend endpoint matrix rows from docs/API_ENDPOINT_MATRIX.md.",
    inputSchema: {
      type: "object",
      properties: {
        search: { type: "string" },
        limit: { type: "number" }
      }
    }
  },
  {
    name: "get_endpoint",
    description: "Return matrix rows matching an exact or partial endpoint path.",
    inputSchema: {
      type: "object",
      properties: { path: { type: "string" } },
      required: ["path"]
    }
  },
  {
    name: "search_endpoints",
    description: "Search endpoint matrix by path, method, auth, status or Flutter symbol.",
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
    description: "Read one generated audit/matrix report.",
    inputSchema: {
      type: "object",
      properties: {
        file: {
          type: "string",
          enum: [
            "API_INTEGRATION_AUDIT.md",
            "API_ENDPOINT_MATRIX.md",
            "MCP_INTEGRATION_MATRIX.md",
            "API_PARITY_FINAL_REPORT.md"
          ]
        }
      },
      required: ["file"]
    }
  }
];

function readDoc(file) {
  const full = path.resolve(DOCS, file);
  if (!full.startsWith(DOCS + path.sep)) {
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

function textContent(text) {
  return { content: [{ type: "text", text }] };
}

function callTool(name, args = {}) {
  if (name === "list_endpoints") {
    const search = String(args.search ?? "").toLowerCase();
    const limit = Number(args.limit ?? 100);
    const rows = endpointRows().filter((row) => !search || row.toLowerCase().includes(search));
    return textContent(rows.slice(0, limit).join("\n") || "No endpoints matched.");
  }
  if (name === "get_endpoint") {
    const query = String(args.path ?? "").toLowerCase();
    const rows = endpointRows().filter((row) => row.toLowerCase().includes(query));
    return textContent(rows.join("\n") || `Endpoint not found: ${args.path}`);
  }
  if (name === "search_endpoints") {
    const query = String(args.query ?? "").toLowerCase();
    const limit = Number(args.limit ?? 100);
    const rows = endpointRows().filter((row) => row.toLowerCase().includes(query));
    return textContent(rows.slice(0, limit).join("\n") || "No endpoints matched.");
  }
  if (name === "get_auth_flow") {
    return textContent([
      "Canlifal mobile auth:",
      "- Base URL: https://canlifal.com",
      "- Canonical prefix: /api",
      "- Login/register/refresh: /api/auth/mobile-*",
      "- Authenticated calls: Authorization: Bearer <accessToken>",
      "- Refresh: POST /api/auth/mobile-refresh",
      "- Runtime MCP: not used by Flutter; Flutter uses REST/SSE/TRTC."
    ].join("\n"));
  }
  if (name === "read_audit") {
    return textContent(readDoc(String(args.file)));
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
        serverInfo: { name: "canlifal-backend", version: "1.0.0" }
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
          { uri: "audit://api-integration", name: "API integration audit" },
          { uri: "audit://endpoint-matrix", name: "API endpoint matrix" },
          { uri: "audit://mcp-matrix", name: "MCP integration matrix" },
          { uri: "audit://parity-final", name: "API parity final report" }
        ]
      });
    }
    if (method === "resources/read") {
      const fileByUri = {
        "audit://api-integration": "API_INTEGRATION_AUDIT.md",
        "audit://endpoint-matrix": "API_ENDPOINT_MATRIX.md",
        "audit://mcp-matrix": "MCP_INTEGRATION_MATRIX.md",
        "audit://parity-final": "API_PARITY_FINAL_REPORT.md"
      };
      const file = fileByUri[params?.uri];
      if (!file) throw new Error(`Unknown resource: ${params?.uri}`);
      return response(id, {
        contents: [{ uri: params.uri, mimeType: "text/markdown", text: readDoc(file) }]
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
  const rows = endpointRows();
  console.log(JSON.stringify({ status: "OK", endpointRows: rows.length, tools: tools.length }));
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
