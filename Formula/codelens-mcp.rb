class CodelensMcp < Formula
  desc "Rust MCP server for bounded code intelligence, gated mutation, and auditable agent workflows"
  homepage "https://github.com/mupozg823/codelens-mcp-plugin"
  version "1.9.56"
  license "Apache-2.0"

  on_macos do
    # ARM64 only — Intel Macs can use Rosetta 2
    url "https://github.com/mupozg823/codelens-mcp-plugin/releases/download/v#{version}/codelens-mcp-darwin-arm64.tar.gz"
    sha256 "a25f3a6633fb758861a7f69490c7094a7f5dd97adb41d0625189254e619233c3"
  end

  on_linux do
    # x86_64 only — ARM64 Linux not yet supported (ort cross-compile issue)
    url "https://github.com/mupozg823/codelens-mcp-plugin/releases/download/v#{version}/codelens-mcp-linux-x86_64.tar.gz"
    sha256 "581db451522f5b8a73724b2151a7a2d0bd2251cd36a2e3521f91add97f46507f"
  end

  def install
    bin.install "codelens-mcp"
  end

  def caveats
    <<~EOS
      Add to your Claude Code MCP config (~/.claude.json):

        "codelens": {
          "type": "stdio",
          "command": "#{opt_bin}/codelens-mcp",
          "args": ["."]
        }
    EOS
  end

  test do
    output = shell_output("#{bin}/codelens-mcp . --cmd get_capabilities --args '{}' 2>&1")
    assert_match "codelens", output
  end
end
