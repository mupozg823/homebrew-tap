class CodelensMcp < Formula
  desc "Agent-native Rust MCP server for code intelligence — 90+ tools, 25 languages"
  homepage "https://github.com/mupozg823/codelens-mcp-plugin"
  version "1.9.38"
  license "Apache-2.0"

  on_macos do
    # ARM64 only — Intel Macs can use Rosetta 2
    url "https://github.com/mupozg823/codelens-mcp-plugin/releases/download/v#{version}/codelens-mcp-darwin-arm64.tar.gz"
    sha256 "ae83ef22dad3e5e58cb281ec9a3ca3a5de490b440642fa9f5e9858140da6ba32"
  end

  on_linux do
    # x86_64 only — ARM64 Linux not yet supported (ort cross-compile issue)
    url "https://github.com/mupozg823/codelens-mcp-plugin/releases/download/v#{version}/codelens-mcp-linux-x86_64.tar.gz"
    sha256 "6f3a2fd09872d6eef129959f830e2f72b948631c83d41de34e3c1de2fc4fdf38"
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
