require 'formula'

class DockerComposeOroplatform < Formula
  url "/Users/scherepanov/homebrew-docker-compose-oroplatform", :using => :git
  version "0.7.3"
  revision 5

  depends_on 'yq'
  depends_on 'jq'
  depends_on 'coreutils'
  depends_on 'rsync'
  depends_on 'mutagen-io/mutagen/mutagen' if OS.mac?

  def install
    libexec.install "bin/orodc"
    libexec.install "bin/orodc-sync"
    bin.write_exec_script libexec/"orodc"

    pkgshare.install "compose"
  end

  def caveats
    s = <<~EOS
      docker-compose-oroplatform was installed
    EOS
    s
  end
end
