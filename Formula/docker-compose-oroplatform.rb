require 'formula'

class DockerComposeOroplatform < Formula
  url "https://github.com/digitalspacestdio/docker-compose-oroplatform.git", :using => :git
  version "0.1.0"
  revision 1

  depends_on 'coreutils'
  depends_on 'rsync'
  depends_on 'mutagen-io/mutagen/mutagen'

  def install
    #bin.install "docker-compose-oroplatform"
    libexec.install Dir["*"]
    bin.write_exec_script libexec/"docker-compose-oroplatform"
  end

  def caveats
    s = <<~EOS
      docker-compose-oroplatform was installed
    EOS
    s
  end
end
