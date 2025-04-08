require 'formula'

class DockerComposeOroplatform < Formula
  url "https://github.com/digitalspacestdio/homebrew-docker-compose-oroplatform.git", :using => :git
  version "0.5.3"
  revision 2

  depends_on 'coreutils'
  depends_on 'rsync'
  depends_on 'mutagen-io/mutagen/mutagen' if OS.mac?

  def install
    #bin.install "docker-compose-oroplatform"
    libexec.install Dir["*"]
    bin.write_exec_script libexec/"dc-oro"
  end

  def caveats
    s = <<~EOS
      docker-compose-oroplatform was installed
    EOS
    s
  end
end
