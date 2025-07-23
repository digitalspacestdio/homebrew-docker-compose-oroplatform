class OrodcGo < Formula
  desc "Oro Docker Compose CLI utility (Golang version)"
  homepage "https://github.com/zelpex/homebrew-docker-compose-oroplatform"
  url "file://#{Dir.pwd}", using: :git, branch: "golang-based"
  version "0.7.24"
  license "MIT"

  depends_on "go" => :build

  def install
    system "go", "build", *std_go_args(output: bin/"orodc-go")
  end

  def caveats
    <<~EOS
      ✅ 'orodc-go' was installed successfully!

      ➤ Run `orodc-go --help` to get started.
    EOS
  end

  test do
    system "#{bin}/orodc-go", "--help"
  end
end
