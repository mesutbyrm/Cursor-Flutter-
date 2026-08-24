# MCP Integration Matrix

Source: uploaded MCP README and `cursor-mcp.example`. MCP is read-only developer tooling and is not a Flutter runtime dependency.

| MCP | Amaç | Backendde mevcut | Flutter gerekli mi | Kullanıldığı yer | Status |
|---|---|---|---|---|---|
| `list_endpoints` | Endpoint listesi | Evet, MCP server tool | Hayır | Cursor/agent geliştirme ortamı | CONNECTED_TOOLING |
| `get_endpoint` | Tek endpoint detayı + kaynak | Evet, MCP server tool | Hayır | Cursor/agent geliştirme ortamı | CONNECTED_TOOLING |
| `search_endpoints` | Endpoint arama | Evet, MCP server tool | Hayır | Cursor/agent geliştirme ortamı | CONNECTED_TOOLING |
| `list_models` | Prisma model listesi | Evet, MCP server tool | Hayır | Cursor/agent geliştirme ortamı | CONNECTED_TOOLING |
| `get_model` | Model detayı | Evet, MCP server tool | Hayır | Cursor/agent geliştirme ortamı | CONNECTED_TOOLING |
| `search_schema` | Schema arama | Evet, MCP server tool | Hayır | Cursor/agent geliştirme ortamı | CONNECTED_TOOLING |
| `get_auth_flow` | Auth akışı | Evet, MCP server tool | Hayır | Cursor/agent geliştirme ortamı | CONNECTED_TOOLING |
| `read_source` | Kaynak okuma | Evet, MCP server tool | Hayır | Cursor/agent geliştirme ortamı | CONNECTED_TOOLING |
| `list_services` | Backend servis listesi | Evet, MCP server tool | Hayır | Cursor/agent geliştirme ortamı | CONNECTED_TOOLING |
| `search_source` | Backend kaynak arama | Evet, MCP server tool | Hayır | Cursor/agent geliştirme ortamı | CONNECTED_TOOLING |

Flutter normal uygulama işlevleri MCP üzerinden çağırmayacak; REST API kullanacak.
