require 'formula'

class DockerComposeOroplatform < Formula
  url "https://github.com/digitalspacestdio/homebrew-docker-compose-oroplatform.git", :using => :git
  version "0.6.10"
  revision 1

  depends_on 'yq'
  depends_on 'jq'
  depends_on 'coreutils'
  depends_on 'rsync'
  depends_on 'mutagen-io/mutagen/mutagen' if OS.mac?

  def install
    libexec.install "bin/dc-oro"
    libexec.install "bin/dc-oro-sync"
    bin.write_exec_script libexec/"dc-oro"

    pkgshare.install "compose"
  end

  def caveats
    s = <<~EOS
      docker-compose-oroplatform was installed
    EOS
    s
  end
end
